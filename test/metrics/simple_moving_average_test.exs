defmodule TelluridePipeline.Metrics.SimpleMovingAverageTest do
  use ExUnit.Case, async: true

  alias TelluridePipeline.Metrics.SimpleMovingAverage

  test "initializes correctly on creation" do
    sma = SimpleMovingAverage.new(7)
    assert 7 = sma.buffer.max_size
    assert 0 = sma.sum
    assert 0 = sma.value
  end

  test "test compute" do
    sma = SimpleMovingAverage.new(3)

    sma = SimpleMovingAverage.compute(sma, 4)
    avg = 4 / 1
    assert avg = sma.value

    sma = SimpleMovingAverage.compute(sma, 18)
    avg = (4 + 18) / 2
    assert avg = sma.value

    sma = SimpleMovingAverage.compute(sma, 6)
    avg = (4 + 18 + 6) / 3
    assert avg = sma.value

    sma = SimpleMovingAverage.compute(sma, 32)
    avg = (18 + 6 + 32) / 3
    assert avg = sma.value

    sma = SimpleMovingAverage.compute(sma, 77)
    avg = (6 + 32 + 77) / 3
    assert avg = sma.value
  end

end