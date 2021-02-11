defmodule TelemetryPipeline.Data.SensorAggregate do
  defstruct [
    sensor_id: nil,
    total_reads: nil,
    min: nil,
    max: nil,
    mean: nil
  ]

  def new(%{
    sensor_id: sensor_id,
    total_reads: total_reads,
    min: min,
    max: max,
    mean: mean
  }) do
    %__MODULE__{
      sensor_id: sensor_id,
      total_reads: total_reads,
      min: min,
      max: max,
      mean: mean
    }
  end
end
