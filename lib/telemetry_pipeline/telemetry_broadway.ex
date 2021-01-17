defmodule TelemetryPipeline.TelemetryBroadway do
  use Broadway

  alias Broadway.Message

  def start_link(opts) do
    Broadway.start_link(__MODULE__, opts)
  end

  def handle_message(processor_atom, message, %{test_pid: test_pid, handle_message: message_handler} = context) do
    # IO.inspect(processor_atom, label: "message processor_atom: ")
    send( test_pid, {:message_handled, message.data})
    # message
    message_handler.(message, context)
  end

  def handle_batch(batcher, messages, batch_info, %{test_pid: test_pid, handle_batch: batch_handler} = context) do
    IO.inspect(batcher, label: "batch batcher: ")
    IO.inspect(messages, label: "batch messages: ")
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

end
