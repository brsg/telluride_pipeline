defmodule TelemetryPipeline.Ets.BroadwayConfig do
  @moduledoc """
  BroadwayConfig is a data container that keeps the variable configuration
  values for a Broadway behaviour.
  """
  use GenServer

  ## Client API

  @doc """
  A singleton server providing global access to the
  Broadway configuration information.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  A binary key with any value is to be set in this data container,
  replacing any existing key-value pair of the same key.
  """
  def upsert(key, value) when is_binary(key) do
    GenServer.cast(__MODULE__, {:upsert, {key, value}})
  end

  @doc """
  Return the value for the provided binary key or nil if it does not yet exist
  in this data container.
  """
  def find(key) when is_binary(key) do
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
  def handle_call({:find, key}, _, config_map) when is_binary(key) do
    value = Map.get(config_map, key)
    {:reply, value, config_map}
  end

 end
