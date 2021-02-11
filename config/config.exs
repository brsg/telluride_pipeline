use Mix.Config

##
## Assign default Broadway startup configuration variables.
## These atoms are expected to be the same as found in
## TelemetryPipeline.DataContainer.BroadwayConfig.
##
config :telemetry_pipeline,
  sensor_batcher_two_batch_size: 3,
  sensor_batcher_two_concurrency: 1,
  sensor_batcher_one_batch_size: 3,
  sensor_batcher_one_concurrency: 1,
  processor_concurrency: 4,
  producer_concurrency: 1,
  rate_limit_allowed: 10,
  rate_limit_interval: 1_000
