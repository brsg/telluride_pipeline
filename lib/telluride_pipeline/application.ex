defmodule TelluridePipeline.Application do
  use Application

  @doc false

  def start(_type, _args) do
    IO.puts("TelluridePipeline.Application.start/2")
    children = [
      TelluridePipeline.DataContainer.BroadwayConfig,
      TelluridePipeline.DataContainer.SensorTracker,
      TelluridePipeline.DataContainer.InstrumentationTracker,
      TelluridePipeline.DataContainer.ThroughputTracker,
      TelluridePipeline.Messaging.AMQPConnectionManager,
      TelluridePipeline.TelemetryBroadwayManager,
      TelluridePipeline.TelemetryBroadwayWorker
    ]

    opts = [strategy: :one_for_one, name: TelluridePipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
