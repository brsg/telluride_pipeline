defmodule TelluridePipeline.Metrics.SimpleMovingAverage do
  @moduledoc """
  SimpleMovingAverage manages a fixed sized number of numeric data
  points and can compute a simple moving average over the data points
  as new data points are added.
  """
  alias __MODULE__

  @typedoc """
      Type that represents a re-computable simple moving average.
  """
  @type t :: %SimpleMovingAverage{buffer: %RingBuffer{}, sum: integer, value: number}

  defstruct [
    buffer: nil, 
    sum: nil,
    value: nil
  ]

  @spec new(max_sample :: integer) :: t()
  def new(max_samples) when is_integer(max_samples) do
    %SimpleMovingAverage{
      buffer: RingBuffer.new(max_samples),
      sum: 0,
      value: 0
    }
  end

  @spec compute(sma :: t(), newest :: number) :: t()
  def compute(%SimpleMovingAverage{} = sma, newest) when is_number(newest) do
    new_buffer = RingBuffer.put(sma.buffer, newest)
    oldest = if new_buffer.evicted, do: new_buffer.evicted, else: 0
    new_sum = sma.sum - oldest + newest
    new_avg = new_sum / new_buffer.size
    %SimpleMovingAverage{buffer: new_buffer, sum: new_sum, value: new_avg}
  end

end