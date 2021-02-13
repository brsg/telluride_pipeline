defmodule TelemetryPipeline.TelemetryMetrics do
  require Logger

  alias TelemetryPipeline.DataContainer.InstrumentationTracker
  alias TelemetryPipeline.Data.NodeMetric

  def handle_event([:broadway, :processor, :start], _measurements, _metadata, _config) do
    # Logger.info("[:broadway, :processor, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :stop], measurements, metadata, _config) do
    track_instrumentation( measurements, metadata)
  end
  def handle_event([:broadway, :batcher, :start], _measurements, _metadata, _config) do
    # Logger.info("processor_name #{name} [:broadway, :batcher, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :batcher, :stop], measurements, metadata, _config) do
    track_instrumentation( measurements, metadata)
  end
  def handle_event([:broadway, :consumer, :start], _measurements, _metadata, _config) do
    # Logger.info("name #{name} [:broadway, :consumer, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :consumer, :stop], measurements, metadata, _config) do
    track_instrumentation( measurements, metadata)
  end
  def handle_event([:broadway, :processor, :message, :start], _measurements, _metadata, _config) do
    # Logger.info("name #{name} [:broadway, :processor, :message, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :message, :stop], measurements, metadata, _config) do
    track_instrumentation(measurements, metadata)
  end

  defp track_instrumentation(measurements, metadata) do
    metric_map =
      %{
        name: metadata[:batcher],
        partition: metadata[:partition],
        call_count: 1,
        msg_count: metadata[:size] || 1,
        last_duration: measurements[:duration],
        min_duration: measurements[:duration],
        max_duration: measurements[:duration],
        mean_duration: measurements[:duration],
        first_time: measurements[:time],
        last_time: measurements[:time]
      }
    metric = NodeMetric.new(metric_map)
    IO.inspect(metric, label: "\ntelemetry_metrics metric:\t")
    InstrumentationTracker.upsert(metric)
  end

end
