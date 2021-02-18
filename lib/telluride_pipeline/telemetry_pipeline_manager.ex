defmodule TelluridePipeline.TelemetryBroadwayManager do
  use DynamicSupervisor

  alias Broadway.Message
  alias TelluridePipeline.{TelemetryBroadwayWorker, TelemetryMetrics}

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_or_replace_telluride_pipeline(opts \\ [] ) do
    IO.inspect(opts, label: "start_or_replace_telluride_pipeline opts: ")

    {:ok, tbw_pid} = TelemetryBroadwayWorker.start_link([])
    IO.inspect(tbw_pid, label: "Broadway pid: ")

    DynamicSupervisor.start_child(__MODULE__, {TelemetryBroadwayWorker, []})
  end

  def stop_sensor(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def list_sensors do
    DynamicSupervisor.which_children(__MODULE__)
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  @impl true
  def init(init_arg) do
    # One-time initialization of Broadway telemetry
    :ok = compose_telemetry()

    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end

  defp compose_telemetry() do
    :telemetry.attach_many(
      __MODULE__,
      [
        [:broadway, :processor, :start],
        [:broadway, :processor, :stop],
        [:broadway, :batcher, :start],
        [:broadway, :batcher, :stop],
        [:broadway, :consumer, :start],
        [:broadway, :consumer, :stop],
        [:broadway, :processor, :message, :start],
        [:broadway, :processor, :message, :stop],
        [:broadway, :processor, :message, :exception]
      ],
      &TelemetryMetrics.handle_event/4,
      nil
    )
  end

end
