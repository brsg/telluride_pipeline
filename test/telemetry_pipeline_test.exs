defmodule TelemetryPipelineTest do
  use ExUnit.Case
  doctest TelemetryPipeline

  test "greets the world" do
    assert TelemetryPipeline.hello() == :world
  end
end
