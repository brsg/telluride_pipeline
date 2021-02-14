defmodule TelemetryPipeline.Messaging.BroadwayConfigConsumer do
  use GenServer
  use AMQP

  alias TelemetryPipeline.Messaging.AMQPConnectionManager

  @exchange         "sensor_events"
  @message_queue    "broadway_config_queue"
  @routing_key      "sensor.config"

  @dlx_queue        "dlx_queue"
  @dlx_routing_key  "dlx_key"
  ################################################################################
  # Client interface
  ################################################################################

  def start_link do
    IO.puts("TelemetryPipeline.Messaging.BroadwayConfigConsumer.start_link")
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def child_spec(_) do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, []}
      }
  end

  def channel_available(chan) do
    IO.puts("BroadwayConfigConsumer.channel_available called with #{inspect chan}")
    GenServer.cast(__MODULE__, {:channel_available, chan})
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def init(_) do
    IO.puts("BroadwayConfigConsumer.init/1")
    AMQPConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  def handle_cast({:channel_available, channel}, _state) do
    setup_queue(channel)
    :ok = AMQP.Basic.qos(channel, prefetch_count: 10)
    {:ok, _consumer_tag} = AMQP.Basic.consume(channel, @message_queue)
    {:noreply, channel}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, channel) do
    {:noreply, channel}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, channel) do
    {:stop, :normal, channel}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, channel) do
    {:noreply, channel}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, channel) do
    consume(channel, tag, redelivered, payload)
    {:noreply, channel}
  end

  ################################################################################
  # Private
  ################################################################################

  defp setup_queue(channel) do
    IO.puts("BroadwayConfigConsumer.setup_queue(#{inspect channel})")

    # Declare the error queue
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @dlx_queue,
      durable: true
    )

    # Declare the message queue
    # Messages that cannot be delivered to any consumer in the
    # message queue will be routed to the error queue
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @message_queue,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", @exchange},
        {"x-dead-letter-routing-key", @dlx_routing_key}
      ]
    )

    # Declare an exchange of type direct
    :ok = AMQP.Exchange.direct(channel, @exchange, durable: true)

    # Bind the main queue to the exchange
    :ok = AMQP.Queue.bind(channel, @message_queue, @exchange, routing_key: @routing_key)
  end

  defp consume(channel, tag, _redelivered, payload) do
    case JSON.decode(payload) do
      {:ok, event_info} ->
        IO.puts("BroadwayConfigConsumer.consume received #{inspect event_info}")
        AMQP.Basic.ack(channel, tag)
      {:error, changeset} ->
        Basic.reject channel, tag, requeue: false
        IO.puts("error processing payload: #{inspect payload} with changeset: #{inspect changeset}")
      err ->
        Basic.reject channel, tag, requeue: false
        IO.puts("error #{inspect err} processing payload: #{inspect payload}")
        err
    end
  end
end
