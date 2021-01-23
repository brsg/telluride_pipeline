defmodule TelemetryPipeline.TelemetryBroadwayWorker do
  use Broadway

  require Logger

  alias Broadway.Message
  alias TelemetryPipeline.SensorMessage

  @num_processes 5

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(opts) do
    IO.puts("\nTelemetryPipeline.TelemetryBroadwayWorker.start_link() w/ opts #{inspect opts} \n")
    # IO.inspect(opts, label: "worker opts: ")
    # Broadway.start_link(__MODULE__, opts)
    handle_message = fn message, _ ->
      partition = partition(message)
      batch_partition = String.to_atom(~s|batch_#{partition}|)
      message
      |> Message.put_batch_key(batch_partition)
      |> Message.put_batcher(batch_partition)
      |> IO.inspect(label: "batcher_assigned_message: ")
    end

    handle_batch =fn batcher, batch, batch_info, _ ->
      IO.inspect(batch, label: "handle_batch: ")
      # send(test_pid, {:batch_handled, batcher, batch_info})
      batch
    end

    test_pid = self()

    Broadway.start_link(__MODULE__,
      name: Broadway1,
      context: %{
        handle_batch: handle_batch,
        handle_message: handle_message,
        test_pid: test_pid
      },
      producer: [
        module: {BroadwayRabbitMQ.Producer, [queue: "events"]},
        transformer: {__MODULE__, :transform,
        []}
      ],
      processors: [default: [concurrency: 10]],
      batchers: [
        batch_0: [concurrency: 1, batch_size: 5],
        batch_1: [concurrency: 2, batch_size: 5],
        batch_2: [concurrency: 3, batch_size: 5],
        batch_3: [concurrency: 4, batch_size: 5],
        batch_4: [concurrency: 5, batch_size: 5]
      ],
      partition_by: &__MODULE__.partition/1
    )

  end

  ################################################################################
  # Server callbacks
  ################################################################################

   @spec handle_message(any, atom | %{data: any}, %{
          handle_message: (any, any -> any),
          test_pid: atom | pid | port | {atom, atom}
        }) :: any
  def handle_message(_processor_atom, message, %{test_pid: test_pid, handle_message: message_handler} = context) do
    # IO.inspect(processor_atom, label: "message processor_atom: ")
    send( test_pid, {:message_handled, message.data})
    # message
    message_handler.(message, context)
  end

  def handle_batch(batcher, messages, batch_info, %{test_pid: test_pid, handle_batch: batch_handler} = context) do
    # IO.inspect(batcher, label: "batch batcher: ")
    # IO.inspect(messages, label: "batch messages: ")
    messages
    |> Enum.into([], fn message -> message.data end)
    |> Enum.into(~s||, fn value -> ~s|#{value}, | end)
    |> IO.inspect(label: "Batch: ")

    send(test_pid, {:batch_handle, batcher, messages})
    # messages
    batch_handler.(batcher, messages, batch_info, context)
  end

  ## Helpers
  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, :ack_data}
    }
  end

  def ack(:ack_id, _success_list, _fail_list) do
    :ok
  end

  def partition(message) do
    message
    |> line_device_key()
    |> IO.inspect(label: "line_device_key: ")
    |> :erlang.phash2(@num_processes)
  end

  def line_device_key(%Broadway.Message{data: broadway_message_data} = _message) do
    %Broadway.Message{data: rmq_data} = broadway_message_data
    IO.inspect(rmq_data, label: "rmq_data: ")
    rmq_data_list = SensorMessage.msg_string_to_list(rmq_data)
    %SensorMessage{} = sensor_message = SensorMessage.new(rmq_data_list)
    line_device_key(sensor_message)
  end
  def line_device_key(%SensorMessage{line_id: line_id, device_id: device_id}) do
    line_id <> ":" <> device_id
  end

  def terminate(_, _) do
    # Logger.info("TelemetryBroadwayWorker.terminate normal with state #{inspect state}")
    Logger.info("TelemetryBroadwayWorker.terminate normal ")
    # IO.inspect(state, label: "terminate state: ")
    IO.puts("TelemetryBroadwayWorker.terminate")
    # state
  end

end
