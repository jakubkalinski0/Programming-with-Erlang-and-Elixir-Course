%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @copyright (C) 2025, <COMPANY>
%%% @doc
%%% Implementation of various anonymous functions in Erlang for data processing.
%%% - sample_data/0: Provides sample environmental measurement data.
%%% - replace_chars/1: Replaces occurrences of 'o' with 'e' and vice versa in a string.
%%% - count_divisible_by_three1/1: Counts numbers in a list divisible by 3 using lists:filter/2.
%%% - count_divisible_by_three2/1: Counts numbers in a list divisible by 3 using lists:foldl/3.
%%% - average_measurement/2: Computes the average value of a specific measurement type from data.
%%%
%%% @end
%%% Created : 01. kwi 2025 22:19
%%%-------------------------------------------------------------------
-module(anonymous_functions).
-author("Jakub Kalinski").

%% API
-export([sample_data/0, replace_chars/1, count_divisible_by_three1/1, count_divisible_by_three2/1, average_measurement/2]).

%% @doc Provides sample environmental measurement data, including various stations, timestamps, and sensor readings.
%% Each entry consists of:
%% - Station name
%% - Date of measurement
%% - Time of measurement
%% - List of sensor readings, which include a measurement type and its value.
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

%% @doc Replaces occurrences of 'o' with 'e' and vice versa in a given string.
%% The function utilizes lists:map/2 to iterate through each character of the string,
%% checking if it is 'o' or 'e' and swapping them accordingly. All other characters remain unchanged.
replace_chars(Str) ->
    lists:map(fun($o) -> ($e);
        ($e) -> ($o);
        (X) -> X
              end, Str
    ).

%% @doc Counts the number of elements in a list that are divisible by 3.
%% This implementation uses lists:filter/2 to filter only numbers that satisfy X rem 3 == 0,
%% and then computes the length of the resulting list.
count_divisible_by_three1(List) ->
    length(lists:filter(fun(X) -> X rem 3 == 0 end, List)).

%% @doc Counts the number of elements in a list that are divisible by 3.
%% This implementation utilizes lists:foldl/3, iterating through the list
%% and incrementing an accumulator when an element is divisible by 3.
count_divisible_by_three2(List) ->
    lists:foldl(fun(X, Acc) ->
        if X rem 3 == 0 -> Acc + 1;
            true -> Acc
        end
                end, 0, List).

%% @doc Computes the average value of a specified measurement type from environmental data.
%% Steps:
%% 1. Extract all sensor reading lists from data entries.
%% 2. Flatten the nested lists to create a single list of {Type, Value} tuples.
%% 3. Filter only readings matching the specified Type.
%% 4. Extract numerical values from the filtered tuples.
%% 5. Compute the sum of these values and divide by their count to get the average.
%% If no matching values are found, the function returns 0.
average_measurement(Type, Data) ->
    ExtractedReadings = lists:map(fun({_, _, _, Readings}) -> Readings end, Data),
    Flattened = lists:foldl(fun(X, Acc) -> Acc ++ X end, [], ExtractedReadings),
    FilteredValues = lists:filter(fun({T, _}) -> T == Type end, Flattened),
    Values = lists:map(fun({_, Value}) -> Value end, FilteredValues),
    %% FilteredValues = [Value || {T, Value} <- Flattened, T == Type],
    case Values of
        [] -> 0;
        _ -> lists:sum(Values) / length(Values)
    end.