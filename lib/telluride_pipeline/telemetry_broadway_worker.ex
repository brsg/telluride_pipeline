defmodule TelluridePipeline.TelemetryBroadwayWorker do
  use Broadway

  require Logger

  alias Broadway.Message
  alias TelluridePipeline.SensorMessage
  alias TelluridePipeline.DataContainer.{BroadwayConfig, SensorTracker}
  alias TelluridePipeline.Data.SensorAggregate

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(opts) do
    IO.puts("\nTelluridePipeline.TelemetryBroadwayWorker.start_link() w/ opts #{inspect opts} \n")

    handle_message = fn message, _ ->

      {batch_partition, key} =
        case is_even(partition(message)) do
          false ->
            key = batcher_key(message, BroadwayConfig.sensor_batcher_one_concurrency)
            {:sensor_batcher_one, key}
          true ->
            key = batcher_key(message, BroadwayConfig.sensor_batcher_two_concurrency)
            {:sensor_batcher_two, key}
        end

      batch_key = to_string(batch_partition) <> "_" <> to_string(key)
      # IO.inspect(batch_key, label: "\nbatch_key:\t")

      message
      |> Message.put_batch_key(batch_key)
      |> Message.put_batcher(batch_partition)
    end

    origin_pid = self()

    Broadway.start_link(__MODULE__,
      name: Broadway1,
      context: %{
        # handle_batch: handle_batch,
        handle_message: handle_message,
        origin_pid: origin_pid
      },
      producer: [
        module: {BroadwayRabbitMQ.Producer, [
          queue: "sensor_reading_queue",
          bindings: [{"sensor_events", []}],
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

  def handle_batch(:sensor_batcher_one, messages, _batch_info, %{origin_pid: _origin_pid} = _context) do
    # IO.puts("\nsensor_batch_one\n")

    track_sensor_aggregate(messages)

    messages
    |> Enum.into([], fn %Message{} = message -> message.data end)

  end

  def handle_batch(:sensor_batcher_two, messages, _batch_info, %{origin_pid: _origin_pid} = _context) do
    # IO.puts("\nsensor_batch_two\n")

    track_sensor_aggregate(messages)

    messages
    |> Enum.into([], fn %Message{} = message -> message.data end)

  end

  def handle_failed(messages, _context) do
    messages
    |> Enum.each(fn message -> Logger.error("Failed message: #{inspect message}") end)

    messages
  end

  ## Helpers
  defp track_sensor_aggregate(messages) do
    messages
    |> Enum.into([], fn %Message{} = msg -> sensor_message(msg) end)
    |> Enum.group_by(fn %SensorMessage{} = msg -> sensor_key(msg) end)
    # |> IO.inspect(label: "grouped_batch: ")
    |> compute_by_sensor()
  end

  defp compute_by_sensor(%{} = sensor_map) do
    Map.keys(sensor_map)
    |> Enum.each(fn key ->
      aggregate_sensor(key, Map.get(sensor_map, key))
    end)
    :ok
  end

  defp aggregate_sensor(key, sensor_messages) do
    sensor_aggregate =
      sensor_messages
      |> Enum.reduce(nil, fn %SensorMessage{} = s_msg, _accum_agg ->
        sensor_agg = SensorTracker.find(key)
        SensorAggregate.combine(sensor_agg, s_msg)
      end)

    ## Save to in-memory data container
    SensorTracker.upsert(sensor_aggregate)
  end

  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, :ack_data}
    }
  end

  def ack(:ack_id, _success_list, _fail_list) do
    :ok
  end

  def batcher_key(message, concurrency) do
    message
    |> line_device_sensor_key()
    |> :erlang.phash2(concurrency)
  end

  def partition(message) do
    message
    |> sensor_key()
    |> :erlang.phash2(BroadwayConfig.producer_concurrency())
  end

  def sensor_message(%Broadway.Message{data: broadway_message_data}) do
    %Broadway.Message{data: rmq_data} = broadway_message_data
    # IO.inspect(rmq_data, label: "rmq_data: ")
    rmq_data_list = SensorMessage.msg_string_to_list(rmq_data)
    SensorMessage.new(rmq_data_list)
  end

  def line_device_sensor_key(%Broadway.Message{} = message) do
    %SensorMessage{} = sensor_message = sensor_message(message)
    line_device_sensor_key(sensor_message)
  end
  def line_device_sensor_key(%SensorMessage{line_id: line_id, device_id: device_id, sensor_id: sensor_id}) do
    line_id <> ":" <> device_id <> ":" <> sensor_id
  end

  def sensor_key(%Broadway.Message{} = message) do
    %SensorMessage{} = sensor_message = sensor_message(message)
    sensor_key(sensor_message)
  end
  def sensor_key(%SensorMessage{sensor_id: sensor_id}) do
    sensor_id
  end

  def terminate(_, _) do
    # Logger.info("TelemetryBroadwayWorker.terminate normal with state #{inspect state}")
    Logger.info("TelemetryBroadwayWorker.terminate normal ")
    # IO.inspect(state, label: "terminate state: ")
    IO.puts("TelemetryBroadwayWorker.terminate")
    # state
  end

  ## Helping

  defp is_even(dividend) when is_integer(dividend) do
    ## For purposes of this function, zero is treated as even
    rem(dividend, 2) != 1
  end

end
