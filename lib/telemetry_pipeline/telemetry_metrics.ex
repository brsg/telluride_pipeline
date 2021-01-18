defmodule TelemetryPipeline.TelemetryMetrics do
  require Logger

  def handle_event([:broadway, :processor, :start], measurements, metadata, _config) do
    Logger.info("[:broadway, :processor, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :stop], measurements, metadata, _config) do
    Logger.info("[:broadway, :processor, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :batcher, :start], measurements, metadata, _config) do
    Logger.info("[:broadway, :batcher, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :batcher, :stop], measurements, metadata, _config) do
    Logger.info("[:broadway, :batcher, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :consumer, :start], measurements, metadata, _config) do
    Logger.info("[:broadway, :consumer, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :consumer, :stop], measurements, metadata, _config) do
    Logger.info("[:broadway, :consumer, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :message, :start], measurements, metadata, _config) do
    Logger.info("[:broadway, :processor, :message, :start] measurement #{inspect measurements} metadata #{inspect metadata}")
  end
  def handle_event([:broadway, :processor, :message, :stop], measurements, metadata, _config) do
    Logger.info("[:broadway, :processor, :message, :stop] measurement #{inspect measurements} metadata #{inspect metadata}")
  end

end
