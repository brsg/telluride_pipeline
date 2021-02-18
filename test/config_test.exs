defmodule TelluridePipeline.ConfigTest do
  use ExUnit.Case, async: true

  describe "expected environment" do
    @tag :env_test
    test "exist" do
      assert Application.get_env(:telluride_pipeline, :sensor_batcher_two_batch_size)
      assert Application.get_env(:telluride_pipeline, :sensor_batcher_two_concurrency)
      assert Application.get_env(:telluride_pipeline, :sensor_batcher_one_batch_size)
      assert Application.get_env(:telluride_pipeline, :sensor_batcher_one_concurrency)
      assert Application.get_env(:telluride_pipeline, :processor_concurrency)
      assert Application.get_env(:telluride_pipeline, :producer_concurrency)
      assert Application.get_env(:telluride_pipeline, :rate_limit_allowed)
      assert Application.get_env(:telluride_pipeline, :rate_limit_interval)
    end
  end
end
