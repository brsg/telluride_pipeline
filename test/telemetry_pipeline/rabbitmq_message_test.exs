defmodule TelluridePipeline.RabbitmqMessageTest do
  use ExUnit.Case, async: true

  alias TelluridePipeline.SensorMessage

  @rmq_msg "{\"device_id\":\"DEV_A\",\"line_id\":\"line_AAA\",\"reading\":119.7549023828733,\"sensor_id\":123,\"timestamp\":\"2021-01-21T19:21:19.370968Z\"}"

  describe "parse RMQ message" do
    @tag :rmq_parse
    test "parse message" do
      assert msg_list = SensorMessage.msg_string_to_list(@rmq_msg)
      assert SensorMessage.new(msg_list)
    end
  end
end
