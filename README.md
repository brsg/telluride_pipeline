# TelemetryPipeline

## Usage of TelemetryPipeline.Ets.BroadwayConfig to manage Broadway configuration.

```Elixir
alias TelemetryPipeline.Ets.BroadwayConfig
:ok = BroadwayConfig.upsert(key, value)   # key must be binary
value = BroadwayConfig.find(key)            # key must be binary
```

## Notes on how to stop

How to stop a GenServer using a binary pid by converting it to a PID:

```Elixir
Process.flag(:trap_exit, true)
a_pid = :erlang.list_to_pid(String.to_charlist("<0.316.0>"))
GenServer.stop(a_pid, :normal)
```

## How to Run

To run:

Start RabbitMQ through one of sensor_simulator or telemetry_pipeline:

```Elixir
cd sensor_simulator/
bin/rmq-up.sh 
```

or 

```elixir
cd telemetry_pipeline/
docker-compose up -d
```

Start sensor_simulator according to sensor_simulator/README.md.

Start telemetry_pipeline:

```Elixir
iex -S mix
# From within iex:
TelemetryPipeline.TelemetryBroadwayManager.start_or_replace_telemetry_pipeline/1
```

To run test: 

```elixir
mix test --only telemetry_broadway
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `telemetry_pipeline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telemetry_pipeline, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/telemetry_pipeline](https://hexdocs.pm/telemetry_pipeline).

