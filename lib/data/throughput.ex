defmodule TelluridePipeline.Data.Throughput do
  alias __MODULE__

  defstruct [
    earliest_raw_time: nil,
    last_raw_time: nil,
    total_message_count: nil,
    total_failed_count: nil,
    total_successful_count: nil
  ]

  def new(%{
    raw_time: raw_time,
    message_count: message_count,
    fail_count: fail_count,
    success_count: success_count
  }) do
    %__MODULE__{
      earliest_raw_time: raw_time,
      last_raw_time: raw_time,
      total_message_count: message_count,
      total_failed_count: fail_count,
      total_successful_count: success_count
    }
  end

  def combine(nil, %Throughput{} = next) do
    current =
      %Throughput{
        earliest_raw_time: next.earliest_raw_time,
        last_raw_time: next.last_raw_time,
        total_message_count: 0,
        total_failed_count: 0,
        total_successful_count: 0
      }
    combine(current, next)
  end
  def combine(%Throughput{} = current, %Throughput{} = next) do
    %Throughput{
      earliest_raw_time: min(current.earliest_raw_time, next.earliest_raw_time),
      last_raw_time: max(current.last_raw_time, next.last_raw_time),
      total_message_count: current.total_message_count + next.total_message_count,
      total_failed_count: current.total_failed_count + next.total_failed_count,
      total_successful_count: current.total_successful_count + next.total_successful_count
    }
  end

  def as_map(%Throughput{} = throughput) do
    %{
      earliest_raw_time: throughput.earliest_raw_time,
      last_raw_time: throughput.last_raw_time,
      total_message_count: throughput.total_message_count,
      total_failed_count: throughput.total_failed_count,
      total_successful_count: throughput.total_successful_count
    }
  end
end
