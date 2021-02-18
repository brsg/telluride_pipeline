defmodule TelluridePipeline.DataContainer.SensorTrackerTest do
  use ExUnit.Case, async: true

  alias TelluridePipeline.Data.SensorAggregate
  alias TelluridePipeline.DataContainer.SensorTracker

  describe "upsert" do
    setup do
      %{
        sensor_id: "xyz-123",
        total_reads: 55,
        min:  105.23,
        max:  110.85,
        mean: 109.35
      }
    end

    @tag :sensor_aggregate
    test "create and read", %{} = agg_map do
      assert %SensorAggregate{} = agg = SensorAggregate.new(agg_map)
      assert :ok = SensorTracker.upsert(agg)
      assert agg_prime = SensorTracker.find(agg.sensor_id)
      assert agg == agg_prime

    end
  end
end
