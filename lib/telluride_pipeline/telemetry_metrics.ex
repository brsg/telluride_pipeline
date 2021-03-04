defmodule TelluridePipeline.TelemetryMetrics do
  require Logger

  alias TelluridePipeline.DataContainer.{InstrumentationTracker, ThroughputTracker}
  alias TelluridePipeline.Data.{NodeMetric, Throughput}
  alias Broadway.{BatchInfo, Message}

  def handle_event([:broadway, :processor, :start], _measurements, _metadata, _config) do
    # Logger.info("[:broadway, :processor, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :stop] = _msg, measurements, metadata, _config) do
    name_list =
      metadata[:name]
      |> to_string()
      |> String.split(~r{\.})
      |> List.last()
      |> String.split("_")

    [_node|tail] = name_list
    [name|tail] = tail
    [partition|_tail] = tail

    metric_map =
      %{
        node_type: "producer",
        name: name,
        partition: String.to_integer(partition),
        call_count: 1,
        msg_count: 1,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        sma_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\n(A) processor:\t")
    # IO.inspect(metadata, label: "\n(A) metadata:\t")
    InstrumentationTracker.upsert(metric)
  end
  def handle_event([:broadway, :batcher, :start], _measurements, _metadata, _config) do
    # Logger.info("processor_name #{name} [:broadway, :batcher, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :batcher, :stop] = _msg, measurements, metadata, _config) do
    name =
      metadata[:name]
      |> to_string()
      |> String.split(~r{\.})
      |> List.last()
      |> String.replace_prefix("Batcher_", "")

    metric_map =
      %{
        node_type: "batcher",
        name: name,
        partition: 0,
        call_count: 1,
        msg_count: 1,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        sma_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\n(C) batcher:\t")
    # IO.inspect(metadata, label: "\n(C) metadata:\t")
    InstrumentationTracker.upsert(metric)
   end
  def handle_event([:broadway, :consumer, :start], _measurements, _metadata, _config) do
    # Logger.info("name #{name} [:broadway, :consumer, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :consumer, :stop], measurements, metadata, _config) do
    track_batcher_instrumentation( measurements, metadata)
    track_throughput(measurements, metadata)
  end
  def handle_event([:broadway, :processor, :message, :start], _measurements, _metadata, _config) do
    # Logger.info("name #{name} [:broadway, :processor, :message, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :message, :stop], measurements, metadata, _config) do

    name_list =
      metadata[:name]
      |> to_string()
      |> String.split(~r{\.})
      |> List.last()
      |> String.split("_")

    [_node | tail] = name_list
    [name | tail] = tail
    [partition | _tail] = tail

    # %Message{} = batch_message = metadata[:message]
    # message = batch_message.data
    # batcher = Map.get(message, :batcher)
    size = 1
    metric_map =
      %{
        node_type: "processor",
        name: name,
        partition: partition,
        call_count: 1,
        msg_count: size,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        sma_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\n(B) processor message:\t")
    # IO.inspect(metadata, label: "\n(B) metadata:\t")
    InstrumentationTracker.upsert(metric)
  end

  defp track_batcher_instrumentation(%{} = measurements, %{} = metadata) do
    # IO.inspect(metadata, label: "\ntelemetry_metrics track_batcher_instrumentation:\t")

    %BatchInfo{} = info = metadata[:batch_info]
    # IO.inspect(info, label: "\nBatchInfo:\t")

    ## batcher_processor "partition" is the number assigned to
    ## the batch_key
    revised_partition =
      Map.get(info, :batch_key)
      |> String.split("_")
      |> List.last()
      |> String.to_integer()

    batcher = Map.get(info, :batcher)
    size = Map.get(info, :size)

    metric_map =
      %{
        node_type: "batcher_processor",
        name: batcher,
        partition: revised_partition,
        call_count: 1,
        msg_count: size || 1,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        sma_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\n(D) consumer message:\t")
    # IO.inspect(metadata, label: "\n(D) metadata:\t")
    InstrumentationTracker.upsert(metric)
  end

  def track_throughput(%{} = measurements, %{} = metadata) do

    %BatchInfo{} = info = metadata[:batch_info]
    size = Map.get(info, :size)

    failed_message_count =
      metadata[:failed_messages]
      |> Enum.count()

    success_message_count =
      metadata[:successful_messages]
      |> Enum.count()

    throughput_map =
      %{
        raw_time: measurements[:time],
        message_count: size,
        fail_count: failed_message_count,
        success_count: success_message_count
      }

    throughput = Throughput.new(throughput_map)

    ThroughputTracker.upsert(throughput)

  end

end
