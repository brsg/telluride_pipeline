defmodule TelluridePipeline.Messaging.MetricProducer do
  use GenServer

  alias __MODULE__

  @exchange       "sensor_events"
  @message_queue  "sensor_metric_queue"
  @routing_key    "sensor.metric"

  @dlx_queue        "dlx_queue"
  @dlx_routing_key  "dlx_key"
  ################################################################################
  # Client interface
  ################################################################################

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def channel_available(channel) do
    GenServer.cast(__MODULE__, {:channel_available, channel})
  end

  def publish(message) when is_map(message) do
    {:ok, json} = JSON.encode(message)
    MetricProducer.publish(json)
  end

  def publish(message) when is_binary(message) do
    GenServer.call(__MODULE__, {:publish, message, @routing_key})
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  @impl GenServer
  def init(_) do
    TelluridePipeline.Messaging.AMQPConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:channel_available, channel}, _state) do
    setup_queue(channel)
    {:noreply, channel}
  end

  @impl GenServer
  def handle_call({:publish, message, @routing_key}, _from, channel) do
    AMQP.Basic.publish(
      channel,
      @exchange,
      @routing_key,
      message,
      persistent: true,
      content_type: "application/json"
    )
    {:reply, :ok, channel}
  end

  ################################################################################
  # Private
  ################################################################################

  defp setup_queue(channel) do
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
end
