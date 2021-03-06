defmodule TelluridePipeline.Data.NodeMetric do

  require Logger
  alias __MODULE__
  alias TelluridePipeline.Metrics.SimpleMovingAverage

  @high_value 1_000_000_000_000
  @sma_size 60

  defstruct [
    node_type: nil,
    name: nil,
    partition: nil,
    call_count: nil,
    msg_count: nil,
    last_duration: nil,
    min_duration: nil,
    max_duration: nil,
    mean_duration: nil,
    sma_duration: nil,
    first_time: nil,
    last_time: nil,
    sma: nil
  ]

  def new(%{
    node_type: node_type,
    name: name,
    partition: partition,
    call_count: call_count,
    msg_count: msg_count,
    last_duration: last_duration,
    min_duration: min_duration,
    max_duration: max_duration,
    mean_duration: mean_duration,
    sma_duration: sma_duration,
    first_time: first_time,
    last_time: last_time
  }) do
    name = ensure_binary(name)
    %__MODULE__{
      node_type: node_type,
      name: name,
      partition: partition,
      call_count: call_count,
      msg_count: msg_count,
      last_duration: last_duration,
      min_duration: min_duration,
      max_duration: max_duration,
      mean_duration: mean_duration,
      sma_duration: sma_duration,
      first_time: first_time,
      last_time: last_time,
      sma: SimpleMovingAverage.new(@sma_size)
    }
  end

  def key(%NodeMetric{node_type: _node_type, name: _name, partition: partition} = metric)
  when is_integer(partition) do
    key(%NodeMetric{metric | partition: to_string(partition)})
  end
  def key(%NodeMetric{node_type: _node_type, name: name, partition: _partition} = metric) when is_atom(name) do
    key(%NodeMetric{metric | name: to_string(name)})
  end
  def key(%NodeMetric{node_type: node_type, name: name, partition: partition})
  when is_binary(partition) do
    node_type <> "::" <> name <> "::" <> partition
  end

  def combine(nil, %NodeMetric{} = next) do
    name = ensure_binary(next.name)
    nil_metric =
      %__MODULE__{
        node_type: next.node_type,
        name: name,
        partition: next.partition,
        call_count: 0,
        msg_count: 0,
        last_duration: 0,
        min_duration: @high_value,  # Ensure next is lower
        max_duration: 0,
        mean_duration: 0,
        sma_duration: 0,
        first_time: next.first_time,
        last_time: next.last_time,
        sma: SimpleMovingAverage.new(@sma_size)
      }
    combine(nil_metric, next)
  end
  def combine(%NodeMetric{} = current, %NodeMetric{} = next) do
    total_count = current.call_count + 1
    msg_count = current.msg_count + next.msg_count
    mean_duration = ((current.mean_duration * current.call_count) + next.last_duration) / total_count
    next_sma = SimpleMovingAverage.compute(current.sma, next.last_duration)

    %__MODULE__{
      node_type: current.node_type,
      name: current.name,
      partition: current.partition,
      call_count: total_count,
      msg_count: msg_count,
      last_duration: next.last_duration,
      min_duration: min(current.min_duration, next.min_duration),
      max_duration: max(current.max_duration, next.max_duration),
      mean_duration: mean_duration,
      sma_duration: next_sma.value,
      first_time: min(current.first_time, next.first_time),
      last_time: max(current.last_time, next.last_time),
      sma: next_sma
    }
  end

  def as_map(%NodeMetric{} = metric) do
    %{
      node_type: metric.node_type,
      name: metric.name,
      partition: metric.partition,
      call_count: metric.call_count,
      msg_count: metric.msg_count,
      last_duration: metric.last_duration,
      min_duration: metric.min_duration,
      max_duration: metric.max_duration,
      mean_duration: metric.mean_duration,
      sma_duration: metric.sma_duration,
      first_time: metric.first_time,
      last_time: metric.last_time
    }
  end

  ## Helping / Private

  defp ensure_binary(term) when is_atom(term), do: to_string(term)
  defp ensure_binary(term) when is_binary(term), do: term
  defp ensure_binary(term) do
    Logger.warn("Unexpectedly not atom or binary, #{inspect term}")
    ""
  end
end
