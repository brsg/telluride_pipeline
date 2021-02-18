defmodule TelluridePipeline.DataContainer.ThroughputTracker do
  @moduledoc """
  ThroughputTracker is a singleton data container server process that tracks
  overall throughput as earliest raw time, latest raw time, total message count,
  total failed message count, and total successful message count.
  """
  use GenServer

  alias __MODULE__
  alias TelluridePipeline.Data.Throughput
  alias TelluridePipeline.Messaging.ThroughputProducer

  @publish_interval 1_000

  ## Supervision Tree

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## Client API

  def upsert(%Throughput{} = throughput) do
    GenServer.cast(__MODULE__, {:upsert, throughput})
  end

  def publish() do
    GenServer.cast(__MODULE__, {:publish})
  end

  ## Server Callbacks

  @impl GenServer
  def init(_args) do
    schedule_publish_task(@publish_interval)
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:upsert, %Throughput{} = next}, throughput) do
    throughput_prime = Throughput.combine(throughput, next)

    {:noreply, throughput_prime}
  end

  @impl GenServer
  def handle_cast({:publish}, throughput) do
    if throughput do
      ThroughputProducer.publish(Throughput.as_map(throughput))
    end

    {:noreply, throughput}
  end

  @impl GenServer
  def handle_info({:publish}, state) do

    ThroughputTracker.publish()

    schedule_publish_task(@publish_interval)

    {:noreply, state}
  end

  ## Helping / Private
  defp schedule_publish_task(time) do
    Process.send_after(self(), {:publish}, time)
  end

end
