defmodule TelluridePipeline.Data.SensorAggregate do
  alias __MODULE__
  alias TelluridePipeline.SensorMessage
  @high_value 1_000_000_000

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

  def combine(nil, %SensorMessage{} = s_msg) do
    agg = %__MODULE__{
      sensor_id: s_msg.sensor_id,
      total_reads: 0,
      min: @high_value,   # high enough to ensure s_msg.reading is lower
      max: 0,
      mean: 0
    }
    combine(agg, s_msg)
  end
  def combine(%SensorAggregate{} = agg, %SensorMessage{} = s_msg) do
    total_reads = agg.total_reads + 1
    mean = ((agg.total_reads * agg.mean) + s_msg.reading) / total_reads
    %__MODULE__{
      sensor_id: agg.sensor_id,
      total_reads: total_reads,
      min: min(agg.min, s_msg.reading),
      max: max(agg.max, s_msg.reading),
      mean: mean
    }
  end

  def as_map(%SensorAggregate{} = agg) do
    %{
      sensor_id: agg.sensor_id,
      total_reads: agg.total_reads,
      min: agg.min,
      max: agg.max,
      mean: agg.mean
    }
  end
end
