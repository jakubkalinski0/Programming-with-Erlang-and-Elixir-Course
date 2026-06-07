%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @copyright (C) 2025, <COMPANY>
%%% @doc
%%% Implementation of the QuickSort algorithm in Erlang, along with utility functions.
%%% - less_than/2: Filters elements less than a given pivot.
%%% - grt_eq_than/2: Filters elements greater than or equal to a given pivot.
%%% - qs/1: Implements the recursive QuickSort algorithm.
%%% - random_elems/3: Generates a list of random numbers within a given range.
%%% - compare_speeds/3: Compares execution times of two sorting algorithms.
%%%
%%% @end
%%% Created : 19. Mar 2025 13:32
%%%-------------------------------------------------------------------
-module(quick_sort).
-author("Jakub Kalinski").

%% API
-export([less_than/2, grt_eq_than/2, qs/1, random_elems/3, compare_speeds/3]).

%% @doc Filters elements in the list that are strictly less than the given argument.
less_than([], _) -> [];
less_than(List, Arg) -> [X || X <- List, X < Arg].

%% @doc Filters elements in the list that are greater than or equal to the given argument.
grt_eq_than([], _) -> [];
grt_eq_than(List, Arg) -> [X || X <- List, X >= Arg].

%% @doc Implements the QuickSort algorithm recursively.
%% The first element (pivot) is used to partition the list into two subsets:
%% - Elements smaller than the pivot
%% - Elements greater than or equal to the pivot
%% The algorithm then recursively sorts both partitions and concatenates the results.
qs([]) -> [];
qs([Pivot | Tail]) ->
    qs(less_than(Tail, Pivot)) ++ [Pivot] ++ qs(grt_eq_than(Tail, Pivot)).

%% @doc Generates a list of N random integers within the range [Min, Max].
%% If Min > Max, an error is returned. If N is negative or zero, an error is returned.
random_elems(_, Min, Max) when Min > Max -> error;
random_elems(N, _, _) when N =< 0 -> error;
random_elems(N, Min, Max) -> [rand:uniform(Max - Min + 1) + Min - 1 || _ <- lists:seq(1, N)].

%% @doc Compares the execution times of two sorting functions.
%% The functions Fun1 and Fun2 are applied to the given list,
%% and their execution times are measured using timer:tc/2.
%% The function prints the execution times and indicates which algorithm was faster.
compare_speeds([], _, _) -> none;
compare_speeds(List, Fun1, Fun2) ->
    {Time1, _} = timer:tc(Fun1, [List]),
    {Time2, _} = timer:tc(Fun2, [List]),
    io:format("Algorithm 1 took ~p microseconds.~n", [Time1]),
    io:format("Algorithm 2 took ~p microseconds.~n", [Time2]),
    case Time1 < Time2 of
        true -> io:format("Algorithm 1 is faster.~n");
        false -> io:format("Algorithm 2 is faster or they are equal.~n")
    end.