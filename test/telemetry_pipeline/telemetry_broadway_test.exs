defmodule TelemetryPipeline.TelemetryBroadwayTest do
  use ExUnit.Case, async: true
  doctest TelemetryPipeline.TelemetryBroadway

  import Integer

  alias Broadway.Message
  alias TelemetryPipeline.{TelemetryBroadway, TelemetryMetrics, SensorMessage}

  setup %{} = context do
    test_pid = self()

    :ok =
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

    broadway_name = TelemetryBroadway.new_unique_name()

    handle_message = fn message, _ ->
      partition = TelemetryBroadway.partition(message)
      batch_partition = String.to_atom(~s|batch_#{partition}|)
      message
      |> Message.put_batch_key(batch_partition)
      |> Message.put_batcher(batch_partition)
      |> IO.inspect(label: "batcher_assigned_message: ")
    end

    handle_batch = fn batcher, batch, batch_info, _ ->
      IO.inspect(batch, label: "handle_batch: ")
      # send(test_pid, {:batch_handled, batcher, batch_info})
      batch
    end

    context = %{
      test_pid: test_pid,
      handle_message: handle_message,
      handle_batch: handle_batch
    }

    opts = [
      name: broadway_name,
      context: context,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
          queue: "events"
        },
        transformer: {TelemetryPipeline.TelemetryBroadway, :transform, []},
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
      partition_by: &TelemetryBroadway.partition/1
    ]

    {:ok, _broadway} = TelemetryBroadway.start_link(opts)

    Map.put(context, :broadway_name, broadway_name)
  end

  @tag :telemetry_broadway
  test "test_message/3", %{broadway_name: broadway_name} do
    refute false
    # assert Broadway.test_message(broadway_name, 0, [])
    # IO.puts("test_message/3")
  end

end
