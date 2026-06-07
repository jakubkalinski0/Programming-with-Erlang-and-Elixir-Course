%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @copyright (C) 2025, <COMPANY>
%%% @doc
%%% This module implements a function to calculate the power of a number
%%% using recursion.
%%%
%%% @end
%%% Created : 16. mar 2025 18:51
%%%-------------------------------------------------------------------
-module(power).
-author("Jakub Kalinski").

%% Exported function
-export([power/2]).

%% @doc Computes Base^Exp recursively.
%% Special cases:
%% - power(0, 0) is undefined, so we return `none`
%% - Any number to the power of 0 is 1
%% - 0 to any positive power is 0
%% - Positive exponent: multiply Base recursively
%% - Negative exponent: compute reciprocal power(Base, -Exp)
power(0, 0) -> none;                      % Undefined case: 0^0
power(_, 0) -> 1;                          % Any number to the power of 0 is 1
power(0, _) -> 0;                          % 0 raised to any positive power is 0
power(Base, Exp) when Exp > 0 ->           % Recursive case for positive exponent
    Base * power(Base, Exp - 1);
power(Base, Exp) when Exp < 0 ->           % Handling negative exponent
    1 / power(Base, -Exp).