defmodule TelemetryPipeline.TelemetryBroadwayTest do
  use ExUnit.Case, async: true
  doctest TelemetryPipeline.TelemetryBroadway

  import Integer

  alias Broadway.Message
  alias TelemetryPipeline.TelemetryBroadway, as: TB

  setup %{} = context do
    test_pid = self()
    broadway_name = new_unique_name()

    handle_message = fn message, _ ->
      if is_odd(message.data) do
        message
        |> Message.put_batch_key(:odd)
        |> Message.put_batcher(:odd)
      else
        message
        |> Message.put_batch_key(:even)
        |> Message.put_batcher(:even)
      end
    end

    handle_batch = fn batcher, batch, batch_info, _ ->
      send(test_pid, {:batch_handled, batcher, batch_info})
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
        module: {TelemetryPipeline.TelemetryProducer, 0},
        transformer: {TelemetryPipeline.TelemetryBroadway, :transform, []},
      ],
      processors: [
        default: [concurrency: 10]
      ],
      batchers: [
        # default: [concurrency: 2, batch_size: 5]
        even: [concurrency: 2, batch_size: 5],
        odd: [concurrency: 2, batch_size: 5]
      ],
      partition_by: &partition/1
    ]

    {:ok, _broadway} = TB.start_link(opts)

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
