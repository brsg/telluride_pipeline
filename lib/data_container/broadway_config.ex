defmodule TelemetryPipeline.DataContainer.BroadwayConfig do
  @moduledoc """
  BroadwayConfig is a data container singleton that keeps the
  variable configuration values for a Broadway behaviour.
  """
  use GenServer

  ## Supervision Tree

  @doc """
  A singleton server providing global access to the
  Broadway configuration information.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## Client API

  @doc """
  Assigns an integer value to device_batcher_concurrency variable on a
  Broadway startup configuration.
  """
  def assign_device_batcher_concurrency(value) when is_integer(value) do
    upsert(:device_batcher_concurrency, value)
  end

  @doc """
  Return the value for device_batcher_concurrency or nil if it does not yet exist
  in this data container.
  """
  def device_batcher_concurrency(), do: find(:device_batcher_concurrency)

  @doc """
  Assigns an integer value to device_batcher_batch_size variable on a
  Broadway startup configuration.
  """
  def assign_device_batcher_batch_size(value) when is_integer(value) do
    upsert(:device_batcher_batch_size, value)
  end

  @doc """
  Return the value for device_batcher_batch_size or nil if it does not yet exist
  in this data container.
  """
  def device_batcher_batch_size(), do: find(:device_batcher_batch_size)

  @doc """
  Assigns an integer value to line_batcher_batch_size variable on a
  Broadway startup configuration.
  """
  def assign_line_batcher_batch_size(value) when is_integer(value) do
    upsert(:line_batcher_batch_size, value)
  end

  @doc """
  Return the value for line_batcher_batch_size or nil if it does not yet exist
  in this data container.
  """
  def line_batcher_batch_size(), do: find(:line_batcher_batch_size)

  @doc """
  Assigns an integer value to line_batcher_concurrency variable on a
  Broadway startup configuration.
  """
  def assign_line_batcher_concurrency(value) when is_integer(value) do
    upsert(:line_batcher_concurrency, value)
  end

  @doc """
  Return the value for line_batcher_concurrency or nil if it does not yet exist
  in this data container.
  """
  def line_batcher_concurrency(), do: find(:line_batcher_concurrency)

  @doc """
  Assigns an integer value to processor_concurrency variable on a
  Broadway startup configuration.
  """
  def assign_processor_concurrency(value) when is_integer(value) do
    upsert(:processor_concurrency, value)
  end

  @doc """
  Return the value for processor_concurrency or nil if it does not yet exist
  in this data container.
  """
  def processor_concurrency(), do: find(:processor_concurrency)

  @doc """
  Assigns an integer value to producer_concurrency variable on a
  Broadway startup configuration.
  """
  def assign_producer_concurrency(value) when is_integer(value) do
    upsert(:producer_concurrency, value)
  end

  @doc """
  Return the value for producer_concurrency or nil if it does not yet exist
  in this data container.
  """
  def producer_concurrency(), do: find(:producer_concurrency)

  @doc """
  Assigns an integer value to rate_limit_allowed variable on a
  Broadway startup configuration.
  """
  def assign_rate_limit_allowed(value) when is_integer(value) do
    upsert(:rate_limit_allowed, value)
  end

  @doc """
  Return the value for rate_limit_allowed or nil if it does not yet exist
  in this data container.
  """
  def rate_limit_allowed(), do: find(:rate_limit_allowed)

  @doc """
  Assigns an integer value to rate_limit_interval variable on a
  Broadway startup configuration.
  """
  def assign_rate_limit_interval(value) when is_integer(value) do
    upsert(:rate_limit_interval, value)
  end

  @doc """
  Return the value for rate_limit_interval or nil if it does not yet exist
  in this data container.
  """
  def rate_limit_interval(), do: find(:rate_limit_interval)

  ## Client Helpers

  defp upsert(key, value) when is_atom(key) do
    GenServer.cast(__MODULE__, {:upsert, {key, value}})
  end

  defp find(key) when is_atom(key) do
    GenServer.call(__MODULE__, {:find, key})
  end

  ## Server Callbacks

  @impl true
  def init(_args) do
    ## Initialized with an empty Map to serve as the basis for this data container.
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:upsert, {key, value}}, %{} = config_map) do
    config_map = Map.put(config_map, key, value)
    {:noreply, config_map}
  end

  @impl true
  def handle_call({:find, key}, _, config_map) when is_atom(key) do
    value =
      case Map.get(config_map, key) do
        nil -> Application.get_env(:telemetry_pipeline, key)
        value -> value
      end
    {:reply, value, config_map}
  end

 end
