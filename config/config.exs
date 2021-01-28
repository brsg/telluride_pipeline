use Mix.Config

##
## Assign default Broadway startup configuration variables
##
config :telemetry_pipeline,
  device_batcher_batch_size: 3,
  device_batcher_concurrency: 1,
  line_batcher_batch_size: 3,
  line_batcher_concurrency: 1,
  processor_concurrency: 4,
  producer_concurrency: 1,
  rate_limit_allowed: 10,
  rate_limit_interval: 1_000
