defmodule TelemetryPipeline.TelemetryMetrics do
  require Logger

  ##
  ## TODO: These functions are invoked synchronously.
  ## TODO: For further processing, use send to asynchronously care for this information
  ##
  def handle_event([:broadway, :processor, :start], _measurements, metadata, _config) do
    # Logger.info("[:broadway, :processor, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :processor, :start] name #{name}")
  end
  def handle_event([:broadway, :processor, :stop], measurements, metadata, _config) do
    duration_ms = as_milliseconds(measurements)
    # Logger.info("duration #{duration_ms} [:broadway, :processor, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :processor, :stop] name #{name} duration #{duration_ms}")
  end
  def handle_event([:broadway, :batcher, :start], _measurements, metadata, _config) do
    # Logger.info("[:broadway, :batcher, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :batcher, :start] name #{name}")
  end
  def handle_event([:broadway, :batcher, :stop], measurements, metadata, _config) do
    duration_ms = as_milliseconds(measurements)
    # Logger.info("duration #{duration_ms} [:broadway, :batcher, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :batcher, :stop] name #{name} duration #{duration_ms}")
  end
  def handle_event([:broadway, :consumer, :start], _measurements, metadata, _config) do
    # Logger.info("[:broadway, :consumer, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :consumer, :start] name #{name}")
  end
  def handle_event([:broadway, :consumer, :stop], measurements, metadata, _config) do
    duration_ms = as_milliseconds(measurements)
    # Logger.info("duration #{duration_ms} [:broadway, :consumer, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :consumer, :stop] name #{name} duration #{duration_ms}")
  end
  def handle_event([:broadway, :processor, :message, :start], _measurements, metadata, _config) do
    # Logger.info("[:broadway, :processor, :message, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :processor, :message, :start] name #{name}")
  end
  def handle_event([:broadway, :processor, :message, :stop], measurements, metadata, _config) do
    duration_ms = as_milliseconds(measurements)
    # Logger.info("duration #{duration_ms} [:broadway, :processor, :message, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
    name = processor_name(metadata)
    Logger.info("[:broadway, :processor, :message, :stop] name #{name} duration #{duration_ms}")
  end

  def processor_name(%{name: name} = _metadata), do: name

  def as_milliseconds(%{duration: duration}), do: as_milliseconds(duration)
  def as_milliseconds(duration) when is_integer(duration), do: System.convert_time_unit(duration, :native, :millisecond)

end
