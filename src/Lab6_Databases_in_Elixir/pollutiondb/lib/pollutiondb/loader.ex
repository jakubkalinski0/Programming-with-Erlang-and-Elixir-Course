defmodule Pollutiondb.Loader do
  alias Pollutiondb.{CSVLoader, Station, Reading}

  def load(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.map(&CSVLoader.parse_line/1)
    |> Enum.each(&insert_record/1)
  end

  defp insert_record(%{name: name, lon: lon, lat: lat, date: date, time: time, type: type, value: value}) do
    station =
      case Station.findByName(name) do
        nil ->
          {:ok, s} = Station.createNewStation(name, lon, lat)
          s

        s ->
          s
      end

    datetime =
      date
      |> DateTime.new!(time)
      |> DateTime.truncate(:second)

    Reading.add(%Pollutiondb.Reading{
      station: station,
      type: type,
      value: value,
      datetime: datetime
    })
  end
end
