defmodule TelemetryPipeline.TelemetryBroadwayManager do
  use DynamicSupervisor

  alias Broadway.Message
  alias TelemetryPipeline.{TelemetryBroadwayWorker, TelemetryMetrics}

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_or_replace_telemetry_pipeline(opts \\ [] ) do
    IO.inspect(opts, label: "start_or_replace_telemetry_pipeline opts: ")
    broadway_opts = compose_broadway_options()
    IO.inspect(broadway_opts, label: "broadway_opts: ")
    # TelemetryBroadwayWorker.start_link(broadway_opts)
    # child_spec = {TelemetryPipeline.TelemetryBroadwayWorker, broadway_opts}
    # DynamicSupervisor.start_child(__MODULE__, child_spec)
    # DynamicSupervisor.start_child(__MODULE__, {TelemetryBroadwayWorker, broadway_opts})
    # TelemetryBroadwayWorker.start_link([])

    # case DynamicSupervisor.start_child(__MODULE__, {TelemetryPipeline.TelemetryBroadwayWorker, []}) do
      # {:ok, child} -> IO.puts("Broadway added as child #{inspect child} to dynamic supervisor")
      # {:ok, child, info} -> IO.puts("Broadway added as child #{inspect child} to dynamic supervisor with info #{inspect info}")
      # {:error, error} -> IO.puts("Error #{inspect error} adding to dynamic supervisor")
      # :ignore -> IO.puts(":ignore returned, child not added")
    # end

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

  defp compose_broadway_options() do
    pid = self()
    broadway_name = new_unique_name()
    handle_message = compose_handle_message()
    handle_batch = compose_handle_batch()
    context = %{
      test_pid: pid,
      handle_message: handle_message,
      handle_batch: handle_batch
    }

      [
        name: broadway_name,
        context: context,
        producer: [
          module: {BroadwayRabbitMQ.Producer,
            queue: "events"
          },
          transformer: {TelemetryPipeline.TelemetryBroadwayWorker, :transform, []},
        ],
        processors: [
          default: [concurrency: 10]
        ],
        batchers: [
          batch_0: [concurrency: 1, batch_size: 5],
          batch_1: [concurrency: 2, batch_size: 5],
          batch_2: [concurrency: 3, batch_size: 5],
          batch_3: [concurrency: 4, batch_size: 5],
          batch_4: [concurrency: 5, batch_size: 5]
        ],
        partition_by: &TelemetryBroadwayWorker.partition/1
      ]
  end

  defp compose_handle_batch() do
    fn batcher, batch, batch_info, _ ->
      IO.inspect(batch, label: "handle_batch: ")
      # send(test_pid, {:batch_handled, batcher, batch_info})
      batch
    end
  end

  defp compose_handle_message() do
    fn message, _ ->
      partition = TelemetryBroadwayWorker.partition(message)
      batch_partition = String.to_atom(~s|batch_#{partition}|)
      message
      |> Message.put_batch_key(batch_partition)
      |> Message.put_batcher(batch_partition)
      |> IO.inspect(label: "batcher_assigned_message: ")
    end
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

  ##
  ## Helpers
  def new_unique_name() do
    :"Elixir.Broadway#{System.unique_integer([:positive, :monotonic])}"
  end

end
