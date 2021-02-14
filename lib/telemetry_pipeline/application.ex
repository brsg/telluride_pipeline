defmodule TelemetryPipeline.Application do
  use Application

  @doc false

  def start(_type, _args) do
    IO.puts("TelemetryPipeline.Application.start/2")
    children = [
      TelemetryPipeline.DataContainer.BroadwayConfig,
      TelemetryPipeline.DataContainer.SensorTracker,
      TelemetryPipeline.DataContainer.InstrumentationTracker,
      TelemetryPipeline.Messaging.AMQPConnectionManager,
      TelemetryPipeline.TelemetryBroadwayManager,
      TelemetryPipeline.TelemetryBroadwayWorker
    ]

    opts = [strategy: :one_for_one, name: TelemetryPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
