defmodule TelluridePipeline.Messaging.BroadwayConfigConsumer do
  use GenServer
  use AMQP

  require Logger

  alias TelluridePipeline.Messaging.AMQPConnectionManager
  alias TelluridePipeline.DataContainer.BroadwayConfig

  @exchange         "sensor_events"
  @message_queue    "broadway_config_queue"
  @routing_key      "sensor.config"

  @dlx_queue        "dlx_queue"
  @dlx_routing_key  "dlx_key"
  ################################################################################
  # Client interface
  ################################################################################

  def start_link do
    IO.puts("TelluridePipeline.Messaging.BroadwayConfigConsumer.start_link")
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

    ## Apply configuration
    decoded_payload = JSON.decode!(payload)
    apply_configuration(decoded_payload)

    ## Signal Broadway to stop so Supervisor will restart with new config
    GenServer.stop(Broadway1, :normal)
    |> IO.inspect(label: "\nSTOP result:\t")

    consume(channel, tag, redelivered, payload)
    {:noreply, channel}
  end

  ################################################################################
  # Private
  ################################################################################

  defp apply_configuration(%{} = config_map) do
    Map.keys(config_map)
    |> Enum.each(fn key ->
      value = Map.get(config_map, key)
      :ok = apply_to_broadway_config(key, value)
    end)
  end

  defp apply_to_broadway_config("processor_concurrency", value) when is_integer(value) do
    BroadwayConfig.assign_processor_concurrency(value)
  end
  defp apply_to_broadway_config("producer_concurrency", value) when is_integer(value) do
    BroadwayConfig.assign_producer_concurrency(value)
  end
  defp apply_to_broadway_config("rate_limit_allowed", value) when is_integer(value) do
    BroadwayConfig.assign_rate_limit_allowed(value)
  end
  defp apply_to_broadway_config("rate_limit_interval", value) when is_integer(value) do
    BroadwayConfig.assign_rate_limit_interval(value)
  end
  defp apply_to_broadway_config("sensor_batcher_one_batch_size", value) when is_integer(value) do
    BroadwayConfig.assign_sensor_batcher_one_batch_size(value)
  end
  defp apply_to_broadway_config("sensor_batcher_one_concurrency", value) when is_integer(value) do
    BroadwayConfig.assign_sensor_batcher_one_concurrency(value)
  end
  defp apply_to_broadway_config("sensor_batcher_two_batch_size", value) when is_integer(value) do
    BroadwayConfig.assign_sensor_batcher_two_batch_size(value)
  end
  defp apply_to_broadway_config("sensor_batcher_two_concurrency", value) when is_integer(value) do
    BroadwayConfig.assign_sensor_batcher_two_concurrency(value)
  end
  defp apply_to_broadway_config(key, value) do
    Logger.error("Unknown config key #{inspect key} or value #{inspect value}")
    :error
  end

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
