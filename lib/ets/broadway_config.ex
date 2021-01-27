defmodule TelemetryPipeline.Ets.BroadwayConfig do
  use GenServer

  ## Client API

  @doc """
  A singleton server providing global access to the ETS table with
  Broadway configuration information.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :broadway_config, name: __MODULE__)
  end

  @doc """
  A binary key with any value is inserted to ETS, replacing any existing
  key-value pair of the same key.
  """
  def upsert(key, value) when is_binary(key) do
    GenServer.cast(__MODULE__, {:upsert, {key, value}})
  end

  @doc """
  Return the value for the provided binary key or nil if it does not yet exist
  in this ETS table.
  """
  def find(key) when is_binary(key) do
    GenServer.call(__MODULE__, {:find, key})
  end

  ## Server Callbacks

  def init(table_name) do
    IO.inspect(table_name, label: "init arg: ")
    table_pid = :ets.new(table_name, [:named_table, read_concurrency: true])
    IO.inspect(table_pid, label: "table_pid: ")
    {:ok, table_name}
  end

  def handle_cast({:upsert, {key, value}}, table_name) do
    case :ets.insert(table_name, {key, value}) do
      value ->
        IO.inspect(value, label: "upsert result: ")
        {:noreply, table_name}
    end
  end

  def handle_call({:find, key}, _, table_name) when is_binary(key) do
    case lookup(table_name, key) do
      {:ok, value} -> {:reply, value, table_name}
      :error -> {:reply, nil, table_name}
    end
  end

  ## Helper

  def lookup(table, name) do
    case :ets.lookup(table, name) do
      [{^name, value}] -> {:ok, value}
      [] -> :error
    end
  end

 end
