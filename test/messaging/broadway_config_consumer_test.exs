defmodule TelluridePipeline.Messaging.BroadwayConfigConsumerTest do
  use ExUnit.Case, async: true

  @exchange         "sensor_events"
  @message_queue    "broadway_config_queue"
  @routing_key      "sensor.config"

  @dlx_queue        "dlx_queue"
  @dlx_routing_key  "dlx_key"

  describe "produce message" do
    setup context do
      {:ok, connection} = AMQP.Connection.open()
      {:ok, channel} = AMQP.Channel.open(connection)
      {:ok, v} =
        AMQP.Queue.declare(
          channel,
          @message_queue,
          durable: true,
          arguments: [
            {"x-dead-letter-exchange", @exchange},
            {"x-dead-letter-routing-key", @dlx_routing_key}
          ]
         )
      :ok = AMQP.Exchange.direct(channel, @exchange, durable: true)
      :ok = AMQP.Queue.bind(channel, @message_queue, @exchange, routing_key: @routing_key)
      context = Map.put(context, :connection, connection)
      context = Map.put(context, :channel, channel)
      on_exit(fn -> cleanup(context) end)
      context
    end

    @tag :broadway_config
    test "complete configuration", context do
      receiver = AMQP.Basic.return(context[:channel], self())
      broadway_config_map = broadway_config_map()
      case JSON.encode(broadway_config_map) do
        {:ok, config_json} ->
          :ok = AMQP.Basic.publish(
            context[:channel],
            @exchange,
            @routing_key,
            config_json,
            persistent: true,
            content_type: "application/json"
          )
        other ->
          IO.inspect(other, label: "Failed encoding other: ")
      end
      AMQP.Basic.cancel_return(context[:channel])
    end
  end

  defp broadway_config_map() do
    %{
      sensor_batcher_one_batch_size: 6,
      sensor_batcher_one_concurrency: 4,
      sensor_batcher_two_batch_size: 6,
      sensor_batcher_two_concurrency: 4,
      processor_concurrency: 6,
      producer_concurrency: 2,
      rate_limit_allowed: 50,
      rate_limit_interval: 1_000
    }
  end

  ## Helping / Private

  defp cleanup(context) do
    AMQP.Connection.close(context[:connection])
  end
end
