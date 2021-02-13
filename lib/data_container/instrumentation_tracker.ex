defmodule TelemetryPipeline.DataContainer.InstrumentationTracker do
  @moduledoc """
  InstrumentationTracker is a singleton server process acting as a data container for
  Broadway metric summarization and publishing to RMQ.
  """
  use GenServer

  alias __MODULE__
  alias TelemetryPipeline.Data.NodeMetric
  alias TelemetryPipeline.Messaging.MetricProducer

  @dirty_pool :alarm_handler
  @publish_interval 1_000

  ## Supervision Tree

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## Client API

  def upsert(%NodeMetric{} = metric) do
    GenServer.cast(__MODULE__, {:upsert, metric})
  end

  def publish() do
    GenServer.cast(__MODULE__, {:publish})
  end

  ## Server Callbacks

  @impl GenServer
  def init(_arg) do
    schedule_publish_task(@publish_interval)
    node_map = Map.put(%{}, @dirty_pool, [])
    {:ok, node_map}
  end

  @impl GenServer
  def handle_cast({:upsert, %NodeMetric{} = metric}, node_map) do
    key = NodeMetric.key(metric)
    current_metric = Map.get(node_map, key)
    combined_metric = NodeMetric.combine(current_metric, metric)
    node_map = Map.put(node_map, key, combined_metric)
    dirty_pool = Map.get(node_map, @dirty_pool)
    dirty_pool = [key | dirty_pool]
    node_map = Map.put(node_map, @dirty_pool, dirty_pool)
    {:noreply, node_map}
  end

  @impl GenServer
  def handle_cast({:publish}, node_map) do
    IO.inspect(node_map, label: "handle_cast node_map: ")
    Map.get(node_map, @dirty_pool)
    |> Enum.each(fn key ->
      node_metric = Map.get(node_map, key)
      MetricProducer.publish(NodeMetric.as_map(node_metric))
      # IO.inspect(node_metric, label: "\nUpdated NodeMetric:\t")
    end)

    node_map = Map.put(node_map, @dirty_pool, [])

    {:noreply, node_map}
  end

  @impl GenServer
  def handle_info({:publish}, node_map) do
    InstrumentationTracker.publish()

    schedule_publish_task(@publish_interval)

    {:noreply, node_map}
  end

  ## Helping / Private

  defp schedule_publish_task(ms) do
    Process.send_after(self(), :publish, ms)
  end

end
