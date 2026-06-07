-module(pollution_server).
-author("Jakub Kalinski").

-export([
    add_station/2,
    add_value/4,
    get_one_value/3,
    get_station_mean/2,
    remove_value/3,
    get_daily_mean/2,
    get_maximum_growth_time/2,
    get_hourly_mean/3
]).
-export([start/0, stop/0]).
-export([init/0, loop/1]).

-define(SERVER_NAME, pollution_server_process).

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
    io:format("~p: Serwer zanieczyszczen zainicjowany z monitorem: ~p~n", [self(), Monitor]),
    loop(Monitor).

loop(Monitor) ->
    receive
        {FromPid, {add_station, Name, Coords}} ->
            Result = pollution:add_station(Name, Coords, Monitor),
            NewMonitor =
                case Result of
                    {error, _} -> Monitor;
                    UpdatedMonitor -> UpdatedMonitor
                end,
            FromPid ! {?SERVER_NAME, Result},
            loop(NewMonitor);

        {FromPid, {add_value, NameOrCoords, DateTime, Type, Value}} ->
            Result = pollution:add_value(NameOrCoords, DateTime, Type, Value, Monitor),
            NewMonitor =
                case Result of
                    {error, _} -> Monitor;
                    UpdatedMonitor -> UpdatedMonitor
                end,
            FromPid ! {?SERVER_NAME, Result},
            loop(NewMonitor);

        {FromPid, {get_one_value, NameOrCoords, DateTime, Type}} ->
            Result = pollution:get_one_value(NameOrCoords, DateTime, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {get_station_mean, NameOrCoords, Type}} ->
            Result = pollution:get_station_mean(NameOrCoords, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {remove_value, NameOrCoords, DateTime, Type}} ->
            Result = pollution:remove_value(NameOrCoords, DateTime, Type, Monitor),
            NewMonitor =
                case Result of
                    {error, _} -> Monitor;
                    UpdatedMonitor -> UpdatedMonitor
                end,
            FromPid ! {?SERVER_NAME, Result},
            loop(NewMonitor);

        {FromPid, {get_daily_mean, Type, Date}} ->
            Result = pollution:get_daily_mean(Type, Date, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {get_maximum_growth_time, NameOrCoords, Type}} ->
            Result = pollution:get_maximum_growth_time(NameOrCoords, Type, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, {get_hourly_mean, NameOrCoords, Type, Hour}} ->
            Result = pollution:get_hourly_mean(NameOrCoords, Type, Hour, Monitor),
            FromPid ! {?SERVER_NAME, Result},
            loop(Monitor);

        {FromPid, stop} ->
            io:format("~p: Serwer zanieczyszczen otrzymal polecenie stop od ~p.~n", [self(), FromPid]),
            FromPid ! {?SERVER_NAME, {ok, "Server stopping"}},
            exit(normal);

        Unknown ->
            io:format("~p: Serwer zanieczyszczen otrzymal nieznana wiadomosc: ~p~n", [self(), Unknown]),
            loop(Monitor)
    end.

stop() ->
    case whereis(?SERVER_NAME) of
        undefined ->
            {error, not_started};
        ServerPid ->
            ServerPid ! {self(), stop},
            receive
                {?SERVER_NAME, Reply} ->
                    unregister(?SERVER_NAME),
                    Reply;
                Other ->
                    {error, {unexpected_reply, Other}}
            after 5000 ->
                {error, timeout}
            end
    end.

call_server(Request) ->
    case whereis(?SERVER_NAME) of
        undefined ->
            {error, server_not_started};
        ServerPid ->
            ServerPid ! {self(), Request},
            receive
                {?SERVER_NAME, Reply} -> Reply
            after 5000 ->
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

remove_value(NameOrCoords, DateTime, Type) ->
    call_server({remove_value, NameOrCoords, DateTime, Type}).

get_daily_mean(Type, Date) ->
    call_server({get_daily_mean, Type, Date}).

get_maximum_growth_time(NameOrCoords, Type) ->
    call_server({get_maximum_growth_time, NameOrCoords, Type}).

get_hourly_mean(NameOrCoords, Type, Hour) ->
    call_server({get_hourly_mean, NameOrCoords, Type, Hour}).
