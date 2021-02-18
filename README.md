# TelluridePipeline

TelluridePipeline collaborates with [TellurideSensor](https://github.com/brsg/telluride_sensor) and [TellurideUI](https://github.com/brsg/telluride_ui) to provide an example of a [Broadway](https://github.com/dashbitco/broadway) pipeline consuming messages from a `RabbitMQ` queue, in batches, computing some simple aggregate metrics over the stream of messages, and then publishlishing metrics in a batch-oriented way to a queue on `RabbitMQ` by way of the [BroadwayRabbitMQ](https://github.com/dashbitco/broadway_rabbitmq) producer.  The point of this example is not the domain, which is contrived, but the mechanics of `Broadway` and Rabbit MQ working together.

`Broadway` is built on [GenStage](https://github.com/elixir-lang/gen_stage) that is in turn a `GenServer`.  This hierarchy of relationships is leveraged to configure, start, supervise, stop, and restart `Broadway` in this example.  

## Broadway Configuration & Re-Configuration

`TelemetryBroadwayWorker` is the `Broadway` module, and its configuration is in its' start_link/1 function.  While start_link/1 is a bit verbose, the mileage that is achieved in terms of worker processes is tremendous.

For this example, we take advantage of the ability to pass in behavior by way of handler(s) in the `:context` option.  The logic for partitioning messages is defined as a fn and assigned to `:handle_message`.  `:context` is provided to every callback.  

In our example, configuration in start_link/1 collaborates with a `GenServer` data container called `BroadwayConfig`.  `BroadwayConfig` has client functions for setting and obtaining each of the available configuration options which it keeps in its state.  The only arguments that it allows are the integers for each assign function.  start_link/1 fetches the assigned value or a sensible default for each configuration option.

### Broadway Safe Restart for New Configuration

The `BroadwayConfigConsumer` listens on a Rabbit MQ queue for a message where any of these `BroadwayConfig` elements can be changed.  When such a message is received, the configuration elements are updated and then `TelemetryBroadwayWorker` is sent a :stop message under :normal circumstances.  This causes `Broadway` to: 1) safely drain existing messages, 2) and then terminate Broadway. The Supervisor notices that Broadway is stopped and restarts it allowing start_link/1 to pick up the new configuration.

## Rabbit MQ Queues & Messages

As with all things Elixir, messages are required to cause work to happen.  In this example, after startup, the messages originate from Rabbit MQ.  

### Broadway Configuration

`Broadway` configuration default values are obtained from config/config.exs.  Once started, our example can be reconfigured by way of `BroadwayConfigConsumer` which expects that the received JSON payload will decode to key-value pairs as found in config/config.exs.

### BroadwayRabbitMQ

Our `Broadway` producer is a RabbitMQ consumer.  In our case, can be found in `TelemetryBroadwayWorker`, we expect messages in the shape of the struct represented by `SensorMessage`.  The shape of the message is completely up to you, the domain, and the source of the data.

### SensorAggregateProducer

Our simple example partitions messages by `sensor_id` across two batchers, each with a configurable concurrency and batch size.  The partition_by option in combination with :erlang.phash2/1 ensure that messages associated with a given sensor is always processed by the same Broadway processes.  

Our simple domain simply computes a running mean, min, and max value for the sensor.  It collaborates with another `GenServer` data container, `SensorTracker`, to keep this running tally and to publish those that have changed in a given period back to Rabbit MQ by way of `SensorAggregateProducer`.  

### MetricProducer

`Broadway` includes telemetry and we take advantage of these call backs to track: node-level min, max, and mean, as well as time so that throughput can be calculated.  This information is published to Rabbit MQ by way of `MetricProducer` in collaboration with a `GenServer` data container, `InstrumentationTracker`.

### ThroughputTracker

`Broadway` is comprised of a configurable number of concurrent processes.  We use the built-in telemetry to capture overall throughput by way of the collaboration of a `GenServer` data container, `ThroughputTracker`, and a Rabbit MQ producer, `ThroughputProducer`.  

# Getting Started

## Usage of TelluridePipeline.Ets.BroadwayConfig to manage Broadway configuration.

```Elixir
alias TelluridePipeline.Ets.BroadwayConfig
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

Start RabbitMQ through one of sensor_simulator or telluride_pipeline:

```Elixir
cd sensor_simulator/
bin/rmq-up.sh 
```

or 

```elixir
cd telluride_pipeline/
docker-compose up -d
```

Start sensor_simulator according to sensor_simulator/README.md.

Start telluride_pipeline:

```Elixir
iex -S mix
# From within iex:
TelluridePipeline.TelemetryBroadwayManager.start_or_replace_telluride_pipeline/1
```

To run test: 

```elixir
mix test --only telemetry_broadway
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `telluride_pipeline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telluride_pipeline, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/telluride_pipeline](https://hexdocs.pm/telluride_pipeline).

