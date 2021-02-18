defmodule TelluridePipeline.TelemetryProducer do
  @behaviour Broadway.Producer
  use GenStage

  def start_link(number) do
    GenStage.start_link(__MODULE__, number)
  end

  def init(telemetry_value) do
    {:producer, telemetry_value}
  end

  def handle_demand(demand, telemetry_value) when demand > 0 do
    events = Enum.to_list(telemetry_value..telemetry_value + demand - 1)
    {:noreply, events, telemetry_value + demand}
  end
end
