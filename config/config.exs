use Mix.Config

##
## Assign default Broadway startup configuration variables.
## These atoms are expected to be the same as found in
## TelemetryPipeline.DataContainer.BroadwayConfig.
##
config :telluride_pipeline,
  sensor_batcher_two_batch_size: 10,
  sensor_batcher_two_concurrency: 4,
  sensor_batcher_one_batch_size: 10,
  sensor_batcher_one_concurrency: 4,
  processor_concurrency: 4,
  producer_concurrency: 4,
  rate_limit_allowed: 1_000,
  rate_limit_interval: 1_000
