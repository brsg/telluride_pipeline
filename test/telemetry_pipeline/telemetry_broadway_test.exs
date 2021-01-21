defmodule TelemetryPipeline.TelemetryBroadwayTest do
  use ExUnit.Case, async: true
  doctest TelemetryPipeline.TelemetryBroadway

  import Integer

  alias Broadway.Message
  alias TelemetryPipeline.{TelemetryBroadway, TelemetryMetrics}

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

    broadway_name = new_unique_name()

    handle_message = fn message, _ ->
      IO.inspect(message, label: "handle_message: ")
      # if message[:"device_id"] == "DEV_A" do
        # message
        # |> Message.put_batch_key(:odd)
        # |> Message.put_batcher(:odd)
      # else
        # message
        # |> Message.put_batch_key(:even)
        # |> Message.put_batcher(:even)
      # end
      message
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
        default: [concurrency: 2, batch_size: 5]
        # even: [concurrency: 2, batch_size: 5],
        # odd: [concurrency: 2, batch_size: 5]
      ]
      # ,
      # partition_by: &partition/1
    ]

    {:ok, _broadway} = TelemetryBroadway.start_link(opts)

    Map.put(context, :broadway_name, broadway_name)
  end

  @tag :telemetry_broadway
  test "test_message/3", %{broadway_name: broadway_name} do
    assert Broadway.test_message(broadway_name, 0, [])
    # IO.puts("test_message/3")
  end

  ##
  ## Helpers
  defp new_unique_name() do
    :"Elixir.Broadway#{System.unique_integer([:positive, :monotonic])}"
  end

  def partition(message), do: rem(message.data, 2)

end
