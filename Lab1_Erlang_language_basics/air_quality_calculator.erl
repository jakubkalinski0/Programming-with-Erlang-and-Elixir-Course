%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @copyright (C) 2025, <COMPANY>
%%% @doc
%%% This module provides functions for processing air quality data.
%%% It allows extracting measurements, counting readings for a specific date,
%%% finding the maximum value of a given measurement type, and calculating the mean value.
%%%
%%% @end
%%% Created : 16. mar 2025 21:38
%%%-------------------------------------------------------------------
-module(air_quality_calculator).
-author("Jakub Kalinski").

%% Exported API functions
-export([sample_data/0, number_of_readings/2, calculate_max/2, calculate_mean/2]).

%% @doc Returns sample air quality data.
%% Each entry contains:
%% - Station name
%% - Date (Year, Month, Day)
%% - Time (Hour, Minute)
%% - List of measurements [{Type, Value}]
sample_data() ->
    [
        {"Station A", {2025,3,16}, {12,30}, [{pm10, 50.5}, {pm25, 30}, {temp, 15.2}]},
        {"Station B", {2025,3,16}, {13,00}, [{pm10, 40}, {pm25, 20.1}, {humidity, 60}]},
        {"Station A", {2025,3,16}, {14,00}, [{pm10, 55.3}, {pm25, 35}, {temp, 16.8}]},
        {"Station C", {2025,3,16}, {15,00}, [{pm10, 35}, {pm25, 18.7}, {pressure, 1015}]},
        {"Station A", {2025,3,17}, {10,00}, [{pm10, 60.2}, {pm25, 40}, {temp, 17.5}]},
        {"Station B", {2025,3,17}, {11,30}, [{pm10, 45}, {pm25, 25.6}, {humidity, 55}]},
        {"Station C", {2025,3,17}, {12,00}, [{pm10, 38.9}, {pm25, 22}, {pressure, 1012.4}]},
        {"Station A", {2025,3,18}, {09,00}, [{pm10, 65}, {pm25, 42.3}, {temp, 18.1}]},
        {"Station B", {2025,3,18}, {10,30}, [{pm10, 50}, {pm25, 28.4}, {humidity, 58}]},
        {"Station C", {2025,3,18}, {11,00}, [{pm10, 42.1}, {pm25, 24}, {pressure, 1010.5}]},
        {"Station D", {2025,3,19}, {08,45}, [{pm10, 48.7}, {pm25, 27.5}, {temp, 14.9}, {humidity, 59.8}]},
        {"Station D", {2025,3,19}, {09,45}, [{pm10, 52.3}, {pm25, 29.1}, {temp, 15.3}, {humidity, 60.2}]},
        {"Station A", {2025,3,19}, {10,30}, [{pm10, 61.5}, {pm25, 38.2}, {pressure, 1013.2}]}
    ].

%% @doc Counts the number of readings for a given date.
%% - `Date` is in the format {Year, Month, Day}.
%% - Returns the total count of measurements taken on that date.
number_of_readings([], _) -> 0;
number_of_readings([{_, {Y, M, D}, _, _} | T], {Y, M, D}) ->
    1 + number_of_readings(T, {Y, M, D});
number_of_readings([_ | T], Date) ->
    number_of_readings(T, Date).

%% @doc Finds the maximum recorded value of a given measurement type.
%% - `Readings` is the dataset.
%% - `Type` is the type of measurement (e.g., pm10, pm25).
%% - Returns the highest recorded value for the given type.
calculate_max(Readings, Type) ->
    Values = extract_type_values(Readings, Type),
    case Values of
        [] -> error({unknown_type, Type});
        _ -> find_max(Values)
    end.

%% @doc Computes the mean value of a given measurement type.
%% - `Readings` is the dataset.
%% - `Type` is the type of measurement (e.g., pm10, pm25).
%% - Returns the mean value of all occurrences of the given type.
calculate_mean(Readings, Type) ->
    Values = extract_type_values(Readings, Type),
    case Values of
        [] -> error({unknown_type, Type});
        _ ->
            {Sum, Count} = sum_and_count(Values),
            Sum / Count
    end.

%% @doc Extracts all values of a given measurement type from the dataset.
extract_type_values(Readings, Type) ->
    extract_type_values(Readings, Type, []).
extract_type_values([], _, Values) -> Values;
extract_type_values([{_, _, _, Measurements} | T], Type, Values) ->
    extract_type_values(T, Type, extract_type_value_from_measurements(Measurements, Type, Values)).

%% @doc Searches for a given measurement type in a list of measurements.
%% Returns a list of extracted values.
extract_type_value_from_measurements([], _, Values) -> Values;
extract_type_value_from_measurements([{Type, Value} | T], Type, Values) ->
    extract_type_value_from_measurements(T, Type, [Value | Values]);
extract_type_value_from_measurements([_ | T], Type, Values) ->
    extract_type_value_from_measurements(T, Type, Values).

%% @doc Finds the maximum value in a list using recursion.
%% - Assumes the list is non-empty.
find_max([H | T]) -> find_max(T, H).
find_max([], Max) -> Max;
find_max([H | T], Max) when H > Max ->
    find_max(T, H);
find_max([_ | T], Max) ->
    find_max(T, Max).

%% @doc Computes the sum and count of a list in a single pass (tail-recursive).
%% - Returns `{Sum, Count}`.
sum_and_count(List) ->
    sum_and_count(List, 0, 0).
sum_and_count([], Sum, Count) -> {Sum, Count};
sum_and_count([H | T], Sum, Count) ->
    sum_and_count(T, Sum + H, Count + 1).