%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @copyright (C) 2025, <COMPANY>
%%% @doc
%%% This module provides utility functions for list operations.
%%% Includes:
%%% - Checking if an element is in a list.
%%% - Duplicating elements in a list.
%%% - Summing floating-point numbers in a list (normal and tail-recursive versions).
%%%
%%% @end
%%% Created : 16. mar 2025 19:14
%%%-------------------------------------------------------------------
-module(myLists).
-author("Jakub Kalinski").

%% Exported functions
-export([contains/2, duplicateElements/1, sumFloats/1, sumFloatsTail/1]).

%% @doc Checks if element X exists in the list.
%% Returns `true` if X is in the list, otherwise `false`.
contains(_, []) -> false;               % Base case: empty list, return false
contains(X, [X | _]) -> true;           % Match found, return true
contains(X, [_ | T]) -> contains(X, T). % Recurse with tail of the list

%% @doc Duplicates each element in the list.
%% Example: [a, b, c] -> [a, a, b, b, c, c]
duplicateElements([]) -> [];            % Base case: empty list, return empty list
duplicateElements([H | T]) -> [H, H | duplicateElements(T)]. % Duplicate head, recurse

%% @doc Sums only floating-point numbers in the list using list comprehensions.
%% Example: [1.5, 2, 3.5, "x"] -> 5.0
sumFloats(List) ->
    lists:sum([X || X <- List, is_float(X)]).  % List comprehension filters floats

%% @doc Tail-recursive version of sumFloats/1.
%% Uses an accumulator to improve efficiency.
sumFloatsTail(List) -> sumFloatsTail(List, 0). % Initialize accumulator

sumFloatsTail([], Sum) -> Sum;                 % Base case: return accumulated sum
sumFloatsTail([H | T], Sum) when is_float(H) -> % Add float values
    sumFloatsTail(T, Sum + H);
sumFloatsTail([_ | T], Sum) ->                 % Ignore non-float values
    sumFloatsTail(T, Sum).