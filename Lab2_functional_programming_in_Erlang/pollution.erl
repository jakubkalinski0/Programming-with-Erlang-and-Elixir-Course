%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @copyright (C) 2025, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. kwi 2025 01:15
%%%-------------------------------------------------------------------
-module(pollution).
-author("Jakub Kalinski").

%% API
-export([
    create_monitor/0,
    add_station/3,
    add_value/5,
    remove_value/4,
    get_one_value/4,
    get_station_mean/3,
    get_daily_mean/3,
    get_maximum_growth_time/3,
    get_hourly_mean/4
]).

% Create a new monitor
create_monitor() ->
    #{
        stations => #{},  % Map of stations by name
        coords => #{},    % Map of station names by coordinates
        data => #{}       % Map of measurements
    }.

% Add a new station to the monitor
add_station(Name, Coords, Monitor) ->
    #{stations := Stations, coords := Coords_Map} = Monitor,

    % Check if station with this name already exists
    case maps:is_key(Name, Stations) of
        true ->
            {error, "Station with this name already exists"};
        false ->
            % Check if station with these coordinates already exists
            case maps:is_key(Coords, Coords_Map) of
                true ->
                    {error, "Station with these coordinates already exists"};
                false ->
                    % Add the new station
                    NewStations = maps:put(Name, Coords, Stations),
                    NewCoords = maps:put(Coords, Name, Coords_Map),
                    Monitor#{stations := NewStations, coords := NewCoords}
            end
    end.

% Helper function to find station by name or coordinates
find_station(NameOrCoords, Monitor) ->
    #{stations := Stations, coords := Coords_Map} = Monitor,

    case is_tuple(NameOrCoords) of
        true ->
            % NameOrCoords is coordinates
            case maps:find(NameOrCoords, Coords_Map) of
                {ok, StationName} -> {ok, StationName, maps:get(StationName, Stations)};
                error -> {error, "Station not found"}
            end;
        false ->
            % NameOrCoords is a name
            case maps:find(NameOrCoords, Stations) of
                {ok, StationCoords} -> {ok, NameOrCoords, StationCoords};
                error -> {error, "Station not found"}
            end
    end.

% Add a measurement value to a station
add_value(NameOrCoords, DateTime, Type, Value, Monitor) ->
    #{data := Data} = Monitor,

    % Find the station
    case find_station(NameOrCoords, Monitor) of
        {ok, StationName, StationCoords} ->
            % Create a key for the measurement
            MeasurementKey = {StationCoords, DateTime, Type},

            % Check if this measurement already exists
            case maps:is_key(MeasurementKey, Data) of
                true ->
                    {error, "Measurement already exists"};
                false ->
                    % Add the new measurement
                    NewData = maps:put(MeasurementKey, Value, Data),
                    Monitor#{data := NewData}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

% Remove a measurement value from a station
remove_value(NameOrCoords, DateTime, Type, Monitor) ->
    #{data := Data} = Monitor,

    % Find the station
    case find_station(NameOrCoords, Monitor) of
        {ok, _StationName, StationCoords} ->
            % Create a key for the measurement to remove
            MeasurementKey = {StationCoords, DateTime, Type},

            % Check if the measurement exists
            case maps:is_key(MeasurementKey, Data) of
                true ->
                    % Remove the measurement
                    NewData = maps:remove(MeasurementKey, Data),
                    Monitor#{data := NewData};
                false ->
                    {error, "Measurement not found"}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

% Get a single measurement value
get_one_value(NameOrCoords, DateTime, Type, Monitor) ->
    #{data := Data} = Monitor,

    % Find the station
    case find_station(NameOrCoords, Monitor) of
        {ok, _StationName, StationCoords} ->
            % Create a key for the measurement
            MeasurementKey = {StationCoords, DateTime, Type},

            % Get the measurement value
            case maps:find(MeasurementKey, Data) of
                {ok, Value} -> Value;
                error -> {error, "Measurement not found"}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

% Calculate the mean value of a type for a specific station
get_station_mean(NameOrCoords, Type, Monitor) ->
    #{data := Data} = Monitor,

    % Find the station
    case find_station(NameOrCoords, Monitor) of
        {ok, _StationName, StationCoords} ->
            % Filter measurements for this station and type
            Values = [Value || {{Coords, _DateTime, MeasType}, Value} <- maps:to_list(Data),
                Coords =:= StationCoords, MeasType =:= Type],

            % Calculate mean value if there are measurements
            case Values of
                [] -> {error, "No measurements found for this station and type"};
                _ -> lists:sum(Values) / length(Values)
            end;
        {error, Reason} ->
            {error, Reason}
    end.

% Calculate the daily mean value of a type across all stations
get_daily_mean(Type, Date, Monitor) ->
    #{data := Data} = Monitor,

    % Filter measurements for this date and type
    Values = [Value || {{_Coords, {DateVal, _Time}, MeasType}, Value} <- maps:to_list(Data),
        DateVal =:= Date, MeasType =:= Type],

    % Calculate mean value if there are measurements
    case Values of
        [] -> {error, "No measurements found for this date and type"};
        _ -> lists:sum(Values) / length(Values)
    end.

% Find the hour with maximum growth of pollution level of a specific type for a station
get_maximum_growth_time(NameOrCoords, Type, Monitor) ->
    #{data := Data} = Monitor,

    % Find the station
    case find_station(NameOrCoords, Monitor) of
        {ok, _StationName, StationCoords} ->
            % Filter measurements for this station and type
            Measurements = [{{DateTime, Value}} || {{Coords, DateTime, MeasType}, Value} <- maps:to_list(Data),
                Coords =:= StationCoords, MeasType =:= Type],

            % Sort measurements by time
            SortedMeasurements = lists:sort(Measurements),

            % Calculate growth between consecutive measurements
            case calculate_growth(SortedMeasurements) of
                [] -> {error, "Not enough measurements to calculate growth"};
                Growth ->
                    % Find maximum growth
                    {MaxGrowthTime, _MaxGrowth} = lists:max(Growth, fun({_, Growth1}, {_, Growth2}) -> Growth1 > Growth2 end),
                    MaxGrowthTime
            end;
        {error, Reason} ->
            {error, Reason}
    end.

% Helper function to calculate growth between consecutive measurements
calculate_growth(Measurements) ->
    calculate_growth(Measurements, []).

calculate_growth([_], Acc) ->
    lists:reverse(Acc);
calculate_growth([{DateTime1, Value1}, {DateTime2, Value2} | Rest], Acc) ->
    Growth = Value2 - Value1,
    % Using DateTime2 as the time of growth
    calculate_growth([{DateTime2, Value2} | Rest], [{DateTime2, Growth} | Acc]).

% Calculate the mean value of a type for a specific station at a specific hour of every day
get_hourly_mean(NameOrCoords, Type, Hour, Monitor) ->
    #{data := Data} = Monitor,

    % Find the station
    case find_station(NameOrCoords, Monitor) of
        {ok, _StationName, StationCoords} ->
            % Filter measurements for this station, type, and hour
            Values = [Value || {{Coords, {_Date, {H, _, _}}, MeasType}, Value} <- maps:to_list(Data),
                Coords =:= StationCoords, MeasType =:= Type, H =:= Hour],

            % Calculate mean value if there are measurements
            case Values of
                [] -> {error, "No measurements found for this station, type, and hour"};
                _ -> lists:sum(Values) / length(Values)
            end;
        {error, Reason} ->
            {error, Reason}
    end.