defmodule TelluridePipeline.SensorMessage do
  defstruct device_id: nil,
    line_id: nil,
    reading: nil,
    sensor_id: nil,
    timestamp: nil

  def new(message_list) when is_list(message_list) do
    message_list
    |> Enum.reduce(%{}, fn element, accum_map ->
      {k, v} = match_element(element)
      Map.put(accum_map, k, v)
    end)
    |> new()
  end
  def new(%{
    device_id: device_id,
    line_id: line_id,
    reading: reading,
    sensor_id: sensor_id,
    timestamp: timestamp
  } ) do
    %__MODULE__{
      device_id: device_id,
      line_id: line_id,
      reading: reading,
      sensor_id: sensor_id,
      timestamp: timestamp
    }
  end

  def msg_string_to_list(msg) when is_binary(msg) do
    msg
    |> String.replace_leading("{", "")
    |> String.replace_trailing("}", "")
    |> String.split(",")
    |> Enum.into([], fn element ->
        [a, b] = String.split(element, ":", parts: 2)
        a_prime = String.replace(a, "\"", "")
        b_prime = String.replace(b, "\"", "")
        {a_prime, b_prime}
      end)
  end

  defp match_element({"device_id", value}), do: {:device_id, value}
  defp match_element({"line_id", value}), do: {:line_id, value}
  defp match_element({"reading", value}) when is_float(value), do: {:reading, value}
  defp match_element({"reading", value}) when is_binary(value) do
    {float_value, _} = Float.parse(value)
    {:reading, float_value}
  end
  defp match_element({"sensor_id", value}), do: {:sensor_id, value}
  defp match_element({"timestamp", value}), do: {:timestamp, value}
  defp match_element(unknown) do
    IO.inspect(unknown, label: "match_element unknown: ")
  end

end
