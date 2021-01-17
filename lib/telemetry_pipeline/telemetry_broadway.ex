defmodule TelemetryPipeline.TelemetryBroadway do
  use Broadway

  alias Broadway.Message

  def start_link(opts) do
    Broadway.start_link(__MODULE__, opts)
  end

  def handle_message(_processor_atom, message, %{test_pid: test_pid} = _context) do
    IO.inspect(test_pid, label: "message test_pid: ")
    send( test_pid, {:message_handled, message.data})
    message
  end

  def handle_batch(batcher, messages, _, %{test_pid: test_pid} = _context) do
    IO.inspect(batcher, label: "batch batcher: ")
    send(test_pid, {:batch_handle, batcher, messages})
    messages
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
