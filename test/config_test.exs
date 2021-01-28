defmodule TelemetryPipeline.ConfigTest do
  use ExUnit.Case, async: true

  describe "expected environment" do
    @tag :env_test
    test "exist" do
      assert Application.get_env(:telemetry_pipeline, :device_batcher_batch_size)
      assert Application.get_env(:telemetry_pipeline, :device_batcher_concurrency)
      assert Application.get_env(:telemetry_pipeline, :line_batcher_batch_size)
      assert Application.get_env(:telemetry_pipeline, :line_batcher_concurrency)
      assert Application.get_env(:telemetry_pipeline, :processor_concurrency)
      assert Application.get_env(:telemetry_pipeline, :producer_concurrency)
      assert Application.get_env(:telemetry_pipeline, :rate_limit_allowed)
      assert Application.get_env(:telemetry_pipeline, :rate_limit_interval)
    end
  end
end
