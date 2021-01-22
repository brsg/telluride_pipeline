defmodule TelemetryPipeline.TelemetryBroadway do
  use Broadway

  alias Broadway.Message
  alias TelemetryPipeline.SensorMessage

  @num_processes 5

  def start_link(opts) do
    Broadway.start_link(__MODULE__, opts)
  end

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

  ##
  ## Helpers
  def new_unique_name() do
    :"Elixir.Broadway#{System.unique_integer([:positive, :monotonic])}"
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

end
