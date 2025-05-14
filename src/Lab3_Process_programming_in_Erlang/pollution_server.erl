%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @end
%%%-------------------------------------------------------------------
-module(pollution_server).
-author("Jakub Kalinski").

% Nie używamy -import, lepiej jawnie kwalifikować pollution:fun()
% -import(pollution, [create_monitor/0, add_station/3, add_value/5, get_one_value/4, get_station_mean/3, get_station_min/3, remove_value/4, get_daily_mean/3, get_maximum_growth_time/3, get_hourly_mean/4]).

%% API Klienckie
-export([
    add_station/2,
    add_value/4,
    get_one_value/3,
    get_station_mean/2,
    get_station_min/2,
    remove_value/3,
    get_daily_mean/2,
    get_maximum_growth_time/2,
    get_hourly_mean/3 % Dodana funkcja
]).
%% API Zarządzania serwerem
-export([start/0, stop/0]).
%% Wewnętrzne API (dla spawn)
-export([init/0, loop/1]).

-define(SERVER_NAME, pollution_server_process). % Zmieniona nazwa dla unikalności

start() ->
    case whereis(?SERVER_NAME) of
        undefined ->
            Pid = spawn_link(?MODULE, init, []),
            register(?SERVER_NAME, Pid),
            {ok, Pid};
        Pid ->
            {error, {already_started, Pid}}
    end.

init() ->
    Monitor = pollution:create_monitor(),
    io:format("~p: Serwer zanieczyszczeń zainicjowany z monitorem: ~p~n", [self(), Monitor]),
    loop(Monitor).

loop(Monitor) ->
    receive
        {FromPid, {add_station, Name, Coords}} ->
            Result = pollution:add_station(Name, Coords, Monitor),
            NewMonitor = case Result of
                             {error, _} -> Monitor;
                             UpdatedMonitor -> UpdatedMonitor % add_station zwraca nowy monitor lub error
                         end,
            FromPid ! {?SERVER_NAME, Result},
            loop(NewMonitor);

        {FromPid, {add_value, NameOrCoords, DateTime, Type, Value}} ->
            Result = pollution:add_value(NameOrCoords, DateTime, Type, Value, Monitor),
            NewMonitor = case Result of
                             {error, _} -> Monitor;
                             UpdatedMonitor -> UpdatedMonitor
                         end,
            FromPid ! {?SERVER_NAME, Result},
            loop(NewMonitor);

        {FromPid, {get_one_value, NameOrCoords, DateTime, Type}} ->
            Result = pollution:get_one_value(NameOrCoords, DateTime, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor); % Stan monitora się nie zmienia

        {FromPid, {get_station_mean, NameOrCoords, Type}} ->
            Result = pollution:get_station_mean(NameOrCoords, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {get_station_min, NameOrCoords, Type}} ->
            Result = pollution:get_station_min(NameOrCoords, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {remove_value, NameOrCoords, DateTime, Type}} ->
            Result = pollution:remove_value(NameOrCoords, DateTime, Type, Monitor),
            NewMonitor = case Result of
                             {error, _} -> Monitor;
                             UpdatedMonitor -> UpdatedMonitor
                         end,
            FromPid ! {?SERVER_NAME, Result},
            loop(NewMonitor);

        {FromPid, {get_daily_mean, Type, Date}} -> % Zgodnie z pollution.erl to Date, nie DateTime
            Result = pollution:get_daily_mean(Type, Date, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {get_maximum_growth_time, NameOrCoords, Type}} -> % Poprawione argumenty
            Result = pollution:get_maximum_growth_time(NameOrCoords, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {get_hourly_mean, NameOrCoords, Type, Hour}} -> % Dodana funkcja
            Result = pollution:get_hourly_mean(NameOrCoords, Type, Hour, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, stop} ->
            io:format("~p: Serwer zanieczyszczeń otrzymal polecenie stop od ~p.~n", [self(), FromPid]),
            FromPid ! {?SERVER_NAME, {ok, "Server stopping"}},
            exit(normal); % Kończy pętlę i proces

        Unknown ->
            io:format("~p: Serwer zanieczyszczeń otrzymał nieznaną wiadomość: ~p~n", [self(), Unknown]),
            loop(Monitor)
    end.

stop() ->
    case whereis(?SERVER_NAME) of
        undefined -> {error, not_started};
        ServerPid ->
            ServerPid ! {self(), stop},
            receive
                {?SERVER_NAME, Reply} ->
                    unregister(?SERVER_NAME), % Wyrejestruj po potwierdzeniu
                    Reply;
                Other ->
                    {error, {unexpected_reply, Other}}
            after 5000 ->
                {error, timeout}
            end
    end.

%% Funkcje klienckie
call_server(Request) ->
    case whereis(?SERVER_NAME) of
        undefined -> {error, server_not_started};
        ServerPid ->
            ServerPid ! {self(), Request},
            receive
                {?SERVER_NAME, Reply} -> Reply
            after 5000 -> % Timeout dla klienta
                {error, {server_timeout, Request}}
            end
    end.

add_station(Name, Coords) ->
    call_server({add_station, Name, Coords}).

add_value(NameOrCoords, DateTime, Type, Value) ->
    call_server({add_value, NameOrCoords, DateTime, Type, Value}).

get_one_value(NameOrCoords, DateTime, Type) ->
    call_server({get_one_value, NameOrCoords, DateTime, Type}).

get_station_mean(NameOrCoords, Type) ->
    call_server({get_station_mean, NameOrCoords, Type}).

get_station_min(NameOrCoords, Type) ->
    call_server({get_station_min, NameOrCoords, Type}).

remove_value(NameOrCoords, DateTime, Type) ->
    call_server({remove_value, NameOrCoords, DateTime, Type}).

get_daily_mean(Type, Date) -> % Zgodnie z pollution.erl to Date
    call_server({get_daily_mean, Type, Date}).

get_maximum_growth_time(NameOrCoords, Type) -> % Poprawione argumenty
    call_server({get_maximum_growth_time, NameOrCoords, Type}).

get_hourly_mean(NameOrCoords, Type, Hour) -> % Dodana funkcja
    call_server({get_hourly_mean, NameOrCoords, Type, Hour}).