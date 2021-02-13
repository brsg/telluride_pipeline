defmodule TelemetryPipeline.DataContainer.SensorTracker do
  @moduledoc """
  SensorTracker is a singleton server process acting as a data container for
  aggregate sensor that tracks min, max, and mean.  It is
  understood that the client calling this data container
  has been serialized on sensor_id (that there is only
  one single process in the VM that is a client to this
  data container for the given sensor_id).
  """
  use GenServer

  alias __MODULE__
  alias TelemetryPipeline.Data.SensorAggregate
  alias TelemetryPipeline.Messaging.SensorAggregateProducer

  @dirty_pool :dirty_pool
  @publish_interval 1_000

  ## Supervision Tree

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## Client API

  def upsert(%SensorAggregate{} = aggregate) do
    GenServer.cast(__MODULE__, {:upsert, aggregate})
  end

  def find(sensor_id) do
    GenServer.call(__MODULE__, {:find, sensor_id})
  end

  def publish() do
    GenServer.cast(__MODULE__, {:publish})
  end

  ## Server Callbacks

  @impl GenServer
  def init(_args) do
    schedule_publish_task(@publish_interval)
    sensor_map = Map.put(%{}, @dirty_pool, [])
    {:ok, sensor_map}
  end

  @impl GenServer
  def handle_cast({:upsert, %SensorAggregate{} = aggregate}, sensor_map) do
    dirty_pool = Map.get(sensor_map, @dirty_pool)
    dirty_pool = [aggregate.sensor_id | dirty_pool]
    sensor_map = Map.put(sensor_map, aggregate.sensor_id, aggregate)
    sensor_map = Map.put(sensor_map, @dirty_pool, dirty_pool)
    {:noreply, sensor_map}
  end

  @impl GenServer
  def handle_cast({:publish}, sensor_map) do
    Map.get(sensor_map, @dirty_pool)
    |> Enum.reverse()
    |> Enum.uniq()
    |> Enum.each(fn sensor_id ->
      s_agg = Map.get(sensor_map, sensor_id)
      # IO.inspect(s_agg, label: "\nsensor_tracker SensorAggregate:\t")
      ## Publish to RMQ
      SensorAggregateProducer.publish(SensorAggregate.as_map(s_agg))
      # IO.inspect(s_agg, label: "\nUpdated SensorAggregate:\t")
    end)

    sensor_map = Map.put(sensor_map, @dirty_pool, [])

    {:noreply, sensor_map}
  end

  @impl GenServer
  def handle_info({:publish}, sensor_map) do
    # IO.inspect(sensor_map, label: "args: ")

    SensorTracker.publish()

    schedule_publish_task(@publish_interval)

    {:noreply, sensor_map}
  end

  @impl GenServer
  def handle_call({:find, sensor_id}, _, sensor_map) do
    value = Map.get(sensor_map, sensor_id)
    {:reply, value, sensor_map}
  end

  ## Helping / Private
  defp schedule_publish_task(time) do
    Process.send_after(self(), {:publish}, time)
  end

end
