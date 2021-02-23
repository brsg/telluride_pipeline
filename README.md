# TelluridePipeline

TelluridePipeline collaborates with [TellurideSensor](https://github.com/brsg/telluride_sensor) and [TellurideUI](https://github.com/brsg/telluride_ui) to provide an example of a [Broadway](https://github.com/dashbitco/broadway) pipeline consuming a stream of simulated IoT sensor reading messages from a `RabbitMQ` queue, in batches, computing some simple aggregate metrics over the stream of messages, and then publishlishing those metrics in a batch-oriented way to a queue on `RabbitMQ` by way of the [BroadwayRabbitMQ](https://github.com/dashbitco/broadway_rabbitmq) producer.  The point of this example is not the domain, which is contrived, but the mechanics of `Broadway` and Rabbit MQ working together.

`Broadway` is built on [GenStage](https://github.com/elixir-lang/gen_stage) that is in turn a `GenServer`.  This hierarchy of relationships is leveraged to configure, start, supervise, stop, and restart `Broadway` in this example.  

See [Getting Started](#getting-started) below for instructions on starting this example.

## Stack

[Elixir](https://elixir-lang.org/)

<img src="https://elixir-lang.org/images/logo/logo.png" height="60" />

[RabbitMQ](https://www.rabbitmq.com/)

<img src="https://avatars.githubusercontent.com/u/96669?s=200&v=4" height="60" />

with:
* [broadway](https://github.com/dashbitco/broadway) library
* [broadway_rabbitmq](https://github.com/dashbitco/broadway_rabbitmq) library


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

#### Rabbit MQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ----- | ----------- | ----- |
| sensor_events | direct | sensor.config | broadway_config_queue |

#### Message Shape

```
%{
  "processor_concurrency" => 6, 
  "producer_concurrency" => 2, 
  "rate_limit_allowed" => 50, 
  "rate_limit_interval" => 1000, 
  "sensor_batcher_one_batch_size" => 6, 
  "sensor_batcher_one_concurrency" => 4, 
  "sensor_batcher_two_batch_size" => 6, 
  "sensor_batcher_two_concurrency" => 4
}
```

### BroadwayRabbitMQ

Our `Broadway` producer is a RabbitMQ consumer.  In our case, can be found in `TelemetryBroadwayWorker`, we expect messages in the shape of the struct represented by `SensorMessage`.  The shape of the message is completely up to you, the domain, and the source of the data.

#### Rabbit MQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ----- | ----------- | ----- |
| sensor_events | direct | sensor.reading | sensor_readings_queue |

#### Message Shape

```
%SensorMessage{
  device_id: "line_two_device_02",
  line_id: "line_two",
  reading: 156.09505261601717,
  sensor_id: "line_two::line_two_device_02",
  timestamp: "2021-02-18T22:18:12.588910Z"
}
```

### SensorAggregateProducer

Our simple example partitions messages by `sensor_id` across two batchers, each with a configurable concurrency and batch size.  The partition_by option in combination with :erlang.phash2/1 ensure that messages associated with a given sensor is always processed by the same Broadway processes.  

Our simple domain simply computes a running mean, min, and max value for the sensor.  It collaborates with another `GenServer` data container, `SensorTracker`, to keep this running tally and to publish those that have changed in a given period back to Rabbit MQ by way of `SensorAggregateProducer`.  

#### Rabbit MQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ----- | ----------- | ----- |
| sensor_events | direct | sensor.health | sensor_health_queue |

#### Message Shape

```
%SensorAggregate{
  max: 101.75975626404166,
  mean: 95.0549809719666,
  min: 89.0575969722796,
  sensor_id: "line_two::line_two_device_03",
  total_reads: 43
}
```

### MetricProducer

`Broadway` includes telemetry and we take advantage of these call backs to track: node-level min, max, and mean, as well as time so that throughput can be calculated.  This information is published to Rabbit MQ by way of `MetricProducer` in collaboration with a `GenServer` data container, `InstrumentationTracker`.

#### Rabbit MQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ----- | ----------- | ----- |
| sensor_events | direct | sensor.metric | sensor_metric_queue |

#### Message Shape

```
%NodeMetric{
  call_count: 46,
  first_time: -576460750997645000,
  last_duration: 589000,
  last_time: -576460747795139000,
  max_duration: 4405000,
  mean_duration: 1381586.9565217393,
  min_duration: 376000,
  msg_count: 446,
  name: "sensor_batcher_two",
  node_type: "batcher_processor",
  partition: 1
}
```

### ThroughputTracker

`Broadway` is comprised of a configurable number of concurrent processes.  We use the built-in telemetry to capture overall throughput by way of the collaboration of a `GenServer` data container, `ThroughputTracker`, and a Rabbit MQ producer, `ThroughputProducer`.  

#### Rabbit MQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ----- | ----------- | ----- |
| sensor_events | direct | broadway.throughput | broadway_throughput_queue |

#### Message Shape

```
%Throughput{
  earliest_raw_time: -576460751035217000,
  last_raw_time: -576460741745295000,
  total_failed_count: 0,
  total_message_count: 1056,
  total_successful_count: 1056
}
```
 
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

## <a name="getting-started"></a> Getting Started

1. Start RabbitMQ.

A `docker-compose.yaml` that includes RabbitMQ is provided in `telluride_pipeline`. Start RabbitMQ by executing:

```elixir
cd telluride_pipeline/
docker-compose up -d
```

2. Start [TelluridePipeline](https://github.com/brsg/telluride_pipeline) by executing:

```Elixir
cd telluride_pipeline/
iex -S mix
```

and then, from within iex, execute:

```
TelluridePipeline.TelemetryBroadwayManager.start_or_replace_telluride_pipeline/1
```

To run the `telluride_pipeline` tests:

```elixir
mix test --only telemetry_broadway
```

3. Start [TellurideSensor](https://github.com/brsg/telluride_sensor) by executing:

```elixir
cd telluride_sensor/
iex -S mix
```

4. Start [TellurideUI](https://github.com/brsg/telluride_ui) by executing:
```Elixir
cd telluride_ui/
iex -S mix
```

## Consulting or Partnership

If you need help with your Elixir projects, contact <info@brsg.io> or visit <https://brsg.io>.

## Acknowledgements

This project was inspired by Marlus Saraiva's ElixirConf 2019 talk [Build Efficient Data Processing Pipelines](https://youtu.be/tPu-P97-cbE).


## License and Copyright

Copyright 2021 - Blue River Systems Group, LLC - All Rights Reeserved

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
