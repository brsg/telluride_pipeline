defmodule TelemetryPipeline.TelemetryMetrics do
  require Logger

  alias TelemetryPipeline.DataContainer.InstrumentationTracker
  alias TelemetryPipeline.Data.NodeMetric
  alias Broadway.{BatchInfo, Message}

  def handle_event([:broadway, :processor, :start], _measurements, _metadata, _config) do
    # Logger.info("[:broadway, :processor, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :stop] = _msg, _measurements, _metadata, _config) do
    # IO.inspect(msg, label: "\nhandle_event msg:\t")
    # track_instrumentation( measurements, metadata)
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
        name: name,
        partition: 0,
        call_count: 1,
        msg_count: 1,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    InstrumentationTracker.upsert(metric)
   end
  def handle_event([:broadway, :consumer, :start], _measurements, _metadata, _config) do
    # Logger.info("name #{name} [:broadway, :consumer, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :consumer, :stop], measurements, metadata, _config) do
    track_batcher_instrumentation( measurements, metadata)
  end
  def handle_event([:broadway, :processor, :message, :start], _measurements, _metadata, _config) do
    # Logger.info("name #{name} [:broadway, :processor, :message, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :message, :stop] = _msg, _measurements, _metadata, _config) do
    # IO.inspect(msg, label: "\nhandle_event message msg:\t")
    # track_message_instrumentation(measurements, metadata)
  end

  defp track_message_instrumentation(measurements, metadata) do
    # IO.inspect(metadata, label: "\ntelemetry_metrics track_message_instrumentation:\t")
    %Message{} = message = metadata[:message]
    # IO.inspect(message, label: "\nMessage:\t")
    batcher = Map.get(message, :batcher)
    partition = Map.get(message, :processor_key)
    size = 1
    metric_map =
      %{
        name: batcher,
        partition: to_string(partition),
        call_count: 1,
        msg_count: size,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\ntelemetry_metrics message metric:\t")
    # InstrumentationTracker.upsert(metric)

  end

  defp track_batcher_instrumentation(measurements, metadata) do
    # IO.inspect(metadata, label: "\ntelemetry_metrics track_batcher_instrumentation:\t")

    %BatchInfo{} = info = metadata[:batch_info]
    # IO.inspect(info, label: "\nBatchInfo:\t")

    batcher = Map.get(info, :batcher)
    partition = Map.get(info, :partition)
    size = Map.get(info, :size)

    metric_map =
      %{
        name: batcher,
        partition: to_string(partition),
        call_count: 1,
        msg_count: size || 1,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\ntelemetry_metrics batcher metric:\t")
    InstrumentationTracker.upsert(metric)
  end

  defp track_instrumentation(measurements, metadata) do
    IO.inspect(measurements, label: "\ntelemetry_metrics measurements:\t")
    IO.inspect(metadata, label: "\ntelemetry_metrics metadata:\t")

    name_list =
      metadata[:name]
      |> IO.inspect(label: "\nname:\t")
      |> to_string()
      |> IO.inspect(label: "\nname string:\t")
      |> String.split(~r{\.})
      |> IO.inspect(label: "\nsplit:\t")
      |> List.last()
      |> IO.inspect(label: "\nlast:\t")
      |> String.split("_")
      |> IO.inspect(label: "\nname_list:\t")

    [_node|tail] = name_list
    [name|tail] = tail
    [partition|_tail] = tail

    IO.inspect(name, label: "\nname:\t")
    IO.inspect(partition, label: "\npartition:\t")

    # metric_map =
      # %{
        # name: name,
        # partition: String.to_integer(partition),
        # call_count: 1,
        # msg_count: 1,
        # last_duration: measurements[:duration],
        # min_duration: measurements[:duration],
        # max_duration: measurements[:duration],
        # mean_duration: measurements[:duration],
        # first_time: measurements[:time],
        # last_time: measurements[:time]
      # }
    # metric = NodeMetric.new(metric_map)
    # IO.inspect(metric, label: "\ntelemetry_metrics metric:\t")
    # InstrumentationTracker.upsert(metric)
  end

end
