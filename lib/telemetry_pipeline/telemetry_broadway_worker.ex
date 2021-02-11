defmodule TelemetryPipeline.TelemetryBroadwayWorker do
  use Broadway

  require Logger

  alias Broadway.Message
  alias TelemetryPipeline.SensorMessage
  alias TelemetryPipeline.DataContainer.BroadwayConfig

  @num_processes 2

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(opts) do
    IO.puts("\nTelemetryPipeline.TelemetryBroadwayWorker.start_link() w/ opts #{inspect opts} \n")

    handle_message = fn message, _ ->
      batch_partition =
        case partition(message) do
          0 -> :sensor_batcher_one
          1 -> :sensor_batcher_two
          unexpected -> Logger.error("Unexpected batch partition #{inspect unexpected}")
        end
      message
      |> Message.put_batch_key(batch_partition)
      |> Message.put_batcher(batch_partition)
    end

    handle_batch = fn _batcher, batch, _batch_info, _ ->
      batch
      |> IO.inspect(label: "batch: ")
      |> Enum.into([], fn %Message{} = msg ->
        msg.data
      end)
    end

    origin_pid = self()

    Broadway.start_link(__MODULE__,
      name: Broadway1,
      context: %{
        handle_batch: handle_batch,
        handle_message: handle_message,
        origin_pid: origin_pid
      },
      producer: [
        module: {BroadwayRabbitMQ.Producer, [
          queue: "events",
          on_success: :ack,
          on_failure: :reject
        ]},
        transformer: {__MODULE__, :transform, []},
        rate_limiting: [allowed_messages: BroadwayConfig.rate_limit_allowed(), interval: BroadwayConfig.rate_limit_interval()],
        concurrency: BroadwayConfig.producer_concurrency()
      ],
      processors: [default: [concurrency: BroadwayConfig.processor_concurrency()]],
      batchers: [
        sensor_batcher_one: [concurrency: BroadwayConfig.sensor_batcher_one_concurrency(), batch_size: BroadwayConfig.sensor_batcher_one_batch_size()],
        sensor_batcher_two: [concurrency: BroadwayConfig.sensor_batcher_two_concurrency(), batch_size: BroadwayConfig.sensor_batcher_two_batch_size()]
      ],
      partition_by: &__MODULE__.partition/1
    )

  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def handle_message(_processor_atom, message, %{origin_pid: _origin_pid, handle_message: message_handler} = context) do
    message_handler.(message, context)
  end

  def handle_batch(batcher, messages, batch_info, %{origin_pid: _origin_pid, handle_batch: batch_handler} = context) do
    batch_handler.(batcher, messages, batch_info, context)
    # messages
    # |> Enum.into([], fn %Message{} = message -> message.data end)
  end

  def handle_failed(messages, _context) do
    messages
    |> Enum.each(fn message -> Logger.error("Failed message: #{inspect message}") end)

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

  def partition(message) do
    message
    |> line_device_sensor_key()
    |> IO.inspect(label: "line_device_sensor_key: ")
    |> :erlang.phash2(@num_processes)
  end

  def line_device_sensor_key(%Broadway.Message{data: broadway_message_data} = _message) do
    %Broadway.Message{data: rmq_data} = broadway_message_data
    IO.inspect(rmq_data, label: "rmq_data: ")
    rmq_data_list = SensorMessage.msg_string_to_list(rmq_data)
    %SensorMessage{} = sensor_message = SensorMessage.new(rmq_data_list)
    line_device_sensor_key(sensor_message)
  end
  def line_device_sensor_key(%SensorMessage{line_id: line_id, device_id: device_id, sensor_id: sensor_id}) do
    line_id <> ":" <> device_id <> ":" <> sensor_id
  end

  def terminate(_, _) do
    # Logger.info("TelemetryBroadwayWorker.terminate normal with state #{inspect state}")
    Logger.info("TelemetryBroadwayWorker.terminate normal ")
    # IO.inspect(state, label: "terminate state: ")
    IO.puts("TelemetryBroadwayWorker.terminate")
    # state
  end

end
