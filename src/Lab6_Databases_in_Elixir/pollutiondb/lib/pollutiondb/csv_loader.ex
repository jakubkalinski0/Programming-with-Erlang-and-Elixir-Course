defmodule Pollutiondb.CSVLoader do
  alias Pollutiondb.{Station, Reading}

  def parse_line(line) do
    [datetime, type, val, _id, name, coord_str] = String.split(line, ";")
    {{year, month, day}, {hour, min, sec}} = parse_datetime(datetime)
    [lat, lon] = coord_str |> String.split(",") |> Enum.map(&String.to_float/1)

    %{
      name: name,
      lon: lon,
      lat: lat,
      date: Date.new!(year, month, day),
      time: Time.new!(hour, min, sec, 0),
      type: type,
      value: String.to_float(val)
    }
  end

  defp parse_datetime(str) do
    y = String.slice(str, 0..3) |> String.to_integer()
    m = String.slice(str, 5..6) |> String.to_integer()
    d = String.slice(str, 8..9) |> String.to_integer()
    h = String.slice(str, 11..12) |> String.to_integer()
    min = String.slice(str, 14..15) |> String.to_integer()
    s = String.slice(str, 17..18) |> String.to_integer()
    {{y, m, d}, {h, min, s}}
  end
end
