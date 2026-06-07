-module(pollution).
-author("pawel").

%% API
-export([create_monitor/0, add_station/3, add_value/5, remove_value/4, get_one_value/4, get_station_mean/3,
  get_daily_mean/3, get_correlation/4]).
-export([get_station/2]). % Zakładam, że ta funkcja jest częścią Twojego API


-record(monitor, {name_map, coordinate_map}).
-record(station, {name, coordinates, readings=[]}).
-record(reading, {type, value, date_time}).


create_monitor() ->
  io:format("~p: DEBUG [create_monitor]: Called~n", [?MODULE]),
  Monitor = #monitor{name_map = maps:new(), coordinate_map = maps:new()},
  io:format("~p: DEBUG [create_monitor]: Returning monitor: ~p~n", [?MODULE, Monitor]),
  Monitor.

%% "Private" (lub pomocnicze, jeśli nie eksportowane, ale używane wewnętrznie)
get_station_name_and_coordinates(Station_id, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error; % Przekaż błąd dalej
    Station = #station{} -> {Station#station.name, Station#station.coordinates}
  end.

update_station_readings(Station_id, New_readings, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error; % Jeśli stacja nie istnieje, zwróć błąd
    Station = #station{} ->
      {Station_name, Station_coordinates} = {Station#station.name, Station#station.coordinates}, % Już mamy Station
      Updated_station = Station#station{readings = New_readings},
      #monitor{
        name_map = maps:put(Station_name, Updated_station, Monitor#monitor.name_map),
        coordinate_map = maps:put(Station_coordinates, Updated_station, Monitor#monitor.coordinate_map)
      }
  end.

get_standard_deviation(Station = #station{}, Reading_type) -> % Dodano dopasowanie Station
  Get_delta = fun
                F([]) -> [];
                F([_]) -> []; % Zwróć pustą listę lub 0, jeśli pojedynczy element oznacza brak delty? Zależy od logiki.
                F([El1, El2 | Tail]) -> [El2 - El1 | F([El2 | Tail])]
              end,
  Readings_of_type = lists:filter(fun(R = #reading{}) -> (R#reading.type == Reading_type) end, Station#station.readings),

  % Sprawdzenie czy Readings_of_type nie jest puste przed mapowaniem
  if length(Readings_of_type) < 1 -> % Mniej niż 1 odczyt, brak delty
    {error, no_readings_for_delta};
    length(Readings_of_type) == 1 -> % Jeden odczyt, odchylenie standardowe delty to 0
      0;
    true ->
      Deltas = Get_delta(lists:map(fun(R = #reading{}) -> R#reading.value end, Readings_of_type)),
      case length(Deltas) of
        0 -> 0; % Jeśli Get_delta zwróci pustą listę (np. tylko jeden odczyt typu)
        Length ->
          Mean = lists:sum(Deltas) / Length,
          math:sqrt(
            lists:sum([math:pow(X - Mean, 2) || X <- Deltas]) / Length
          )
      end
  end.

%% "Public" API Functions

get_station(Station_id, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case Station_id of
    Name when is_list(Name) -> % Zakładamy, że nazwa stacji to string (lista charów)
      maps:get(Name, Monitor#monitor.name_map, {error, {no_such_station_name, Name}});
    Coords when is_tuple(Coords) ->
      maps:get(Coords, Monitor#monitor.coordinate_map, {error, {no_such_coordinates, Coords}});
    _ ->
      {error, {illegal_station_id_format, Station_id}}
  end.

add_station(Name, Coordinates, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  Is_name_present = maps:is_key(Name, Monitor#monitor.name_map),
  Is_coords_present = maps:is_key(Coordinates, Monitor#monitor.coordinate_map),

  if Is_name_present -> {error, {station_name_not_unique, Name}};
    Is_coords_present -> {error, {station_coordinates_not_unique, Coordinates}};
    true ->
      New_station = #station{name = Name, coordinates = Coordinates, readings = []},
      #monitor{
        name_map = maps:put(Name, New_station, Monitor#monitor.name_map),
        coordinate_map = maps:put(Coordinates, New_station, Monitor#monitor.coordinate_map)
      }
  end.

add_value(Station_id, Date_time, Reading_type, Reading_value, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error; % Stacja nie istnieje
    Station = #station{} ->
      % Sprawdzenie unikalności pomiaru (współrzędne/nazwa stacji, data/godzina, typ)
      % W tej strukturze, unikalność jest per stacja, data/godzina, typ
      Existing_value = get_one_value_internal(Station, Date_time, Reading_type), % Funkcja pomocnicza
      case Existing_value of
        {error, no_such_value} -> % Pomiar nie istnieje, można dodać
          New_reading = #reading{type = Reading_type, value = Reading_value, date_time = Date_time},
          Updated_readings_list = [New_reading | Station#station.readings], % Dodaj na początek listy
          update_station_readings(Station_id, Updated_readings_list, Monitor);
        _Value -> % Pomiar już istnieje
          {error, {value_already_exists, Station_id, Date_time, Reading_type}}
      end
  end.

remove_value(Station_id, Reading_date_time, Reading_type, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error;
    Station = #station{} ->
      Original_length = length(Station#station.readings),
      Updated_readings_list = lists:filter(
        fun(R = #reading{}) ->
          not (R#reading.type == Reading_type andalso R#reading.date_time == Reading_date_time)
        end,
        Station#station.readings
      ),
      if length(Updated_readings_list) == Original_length -> % Nic nie usunięto
        {error, {value_to_remove_does_not_exist, Station_id, Reading_date_time, Reading_type}};
        true ->
          update_station_readings(Station_id, Updated_readings_list, Monitor)
      end
  end.

% Funkcja pomocnicza dla add_value, aby uniknąć ponownego get_station
get_one_value_internal(Station = #station{}, Reading_date_time, Reading_type) ->
  Station_readings_list = Station#station.readings,
  Readings_matching = lists:filter(
    fun(R = #reading{}) -> (R#reading.type == Reading_type) andalso (R#reading.date_time == Reading_date_time) end,
    Station_readings_list
  ),
  case Readings_matching of
    [] -> {error, no_such_value};
    [Reading = #reading{}] -> Reading#reading.value; % Zakładamy, że jest tylko jeden pasujący
    Multiple -> {error, {multiple_values_found, Multiple}} % Na wszelki wypadek, jeśli logika by na to pozwoliła
  end.

get_one_value(Station_id, Reading_date_time, Reading_type, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error;
    Station = #station{} ->
      get_one_value_internal(Station, Reading_date_time, Reading_type)
  end.

get_station_mean(Station_id, Reading_type, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error;
    Station = #station{} ->
      Readings_of_type = lists:filter(
        fun(R = #reading{}) -> (R#reading.type == Reading_type) end,
        Station#station.readings
      ),
      case Readings_of_type of
        [] -> {error, {no_such_readings_for_type, Reading_type}};
        List_of_readings ->
          Sum = lists:foldl(fun(R = #reading{}, Acc) -> Acc + R#reading.value end, 0, List_of_readings),
          Sum / length(List_of_readings)
      end
  end.

get_daily_mean(Reading_type, Date, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  Fun_DateTime_Into_Date = fun({{Y,M,D}, {_H,_Min,_S}}) -> {Y,M,D} end,

  All_readings_for_type_and_date = lists:flatmap(
    fun(Station = #station{}) ->
      lists:filter(
        fun(R = #reading{}) ->
          (R#reading.type == Reading_type) andalso (Fun_DateTime_Into_Date(R#reading.date_time) == Date)
        end,
        Station#station.readings)
    end,
    maps:values(Monitor#monitor.name_map) % Pobierz wszystkie stacje z mapy nazw
  ),

  case All_readings_for_type_and_date of
    [] -> {error, {no_such_readings_this_day_for_type, Date, Reading_type}};
    Day_readings ->
      Sum = lists:foldl(fun(R = #reading{}, Acc) -> Acc + R#reading.value end, 0, Day_readings),
      Sum / length(Day_readings)
  end.

get_correlation(Station_id, Reading_type1, Reading_type2, Monitor = #monitor{}) -> % Dodano dopasowanie Monitor
  case get_station(Station_id, Monitor) of
    {error, _Reason} = Error -> Error;
    Station = #station{} ->
      % Dla uproszczenia, załóżmy, że get_standard_deviation zwraca wartość liczbową lub {error, ...}
      % Można by tu dodać bardziej zaawansowaną obsługę korelacji
      {get_standard_deviation(Station, Reading_type1),
        get_standard_deviation(Station, Reading_type2)}
  end.