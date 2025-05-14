%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%%-------------------------------------------------------------------
-module(pollution_server_test).
-include_lib("eunit/include/eunit.hrl").

% Setup i Teardown dla każdego zestawu testów (fixture)
server_fixture() ->
  {setup,
    fun setup_server/0,
    fun teardown_server/1,
    [
      fun add_station_test_/1,
      fun add_value_and_get_one_test_/1,
      fun get_station_min_max_mean_test_/1,
      fun remove_value_test_/1,
      fun get_daily_mean_test_/1,
      fun get_maximum_growth_time_test_/1,
      fun get_hourly_mean_test_/1,
      fun error_handling_test_/1
    ]
  }.

setup_server() ->
  {ok, _Pid} = pollution_server:start(), % Upewnij się, że serwer startuje
  ok. % Setup function should return 'ok' or a state for teardown

teardown_server(_Status) -> % Status from setup or 'ok'
  pollution_server:stop(),
  ok.

% Testy
% Znak '_' na końcu nazwy funkcji testowej jest konwencją dla testów w fixture

add_station_test_(_Status) ->
  ?assertEqual({ok, pollution:add_station("Stacja1", {1.0, 1.0}, pollution:create_monitor())}, pollution_server:add_station("Stacja1", {1.0, 1.0})),
  ?assertMatch({error, "Station with this name already exists"}, pollution_server:add_station("Stacja1", {2.0, 2.0})),
  ?assertMatch({error, "Station with these coordinates already exists"}, pollution_server:add_station("Stacja2", {1.0, 1.0})).

add_value_and_get_one_test_(_Status) ->
  Time = calendar:local_time(),
  pollution_server:add_station("StacjaGet", {10.0, 10.0}),
  ExpectedMonitorAfterAdd = pollution:add_value({10.0, 10.0}, Time, "PM10", 42.5, pollution:add_station("StacjaGet", {10.0, 10.0}, pollution:create_monitor())),
  ?assertEqual({ok, ExpectedMonitorAfterAdd}, pollution_server:add_value("StacjaGet", Time, "PM10", 42.5)),
  ?assertEqual({ok, 42.5}, pollution_server:get_one_value("StacjaGet", Time, "PM10")),
  ?assertMatch({error, "Measurement not found"}, pollution_server:get_one_value("StacjaGet", Time, "PM2.5")).

get_station_min_max_mean_test_(_Status) ->
  pollution_server:add_station("StacjaStats", {20.0, 20.0}),
  DT1 = {{2024,1,1},{10,0,0}}, Val1 = 10.0,
  DT2 = {{2024,1,1},{11,0,0}}, Val2 = 20.0,
  DT3 = {{2024,1,1},{12,0,0}}, Val3 = 5.0,
  pollution_server:add_value("StacjaStats", DT1, "NO2", Val1),
  pollution_server:add_value("StacjaStats", DT2, "NO2", Val2),
  pollution_server:add_value("StacjaStats", DT3, "NO2", Val3),

  ?assertEqual({ok, Val3}, pollution_server:get_station_min("StacjaStats", "NO2")),
  ?assertEqual({ok, (Val1+Val2+Val3)/3}, pollution_server:get_station_mean("StacjaStats", "NO2")).

remove_value_test_(_Status) ->
  pollution_server:add_station("StacjaRemove", {30.0, 30.0}),
  Time = calendar:local_time(),
  pollution_server:add_value("StacjaRemove", Time, "O3", 100.0),
  ?assertMatch({ok, _}, pollution_server:remove_value("StacjaRemove", Time, "O3")), % Sprawdź czy usunięcie się powiodło
  ?assertMatch({error, "Measurement not found"}, pollution_server:get_one_value("StacjaRemove", Time, "O3")). % Wartość nie powinna istnieć

get_daily_mean_test_(_Status) ->
  Date = {2024, 5, 15},
  pollution_server:add_station("S_DM_1", {40.0, 40.0}),
  pollution_server:add_station("S_DM_2", {41.0, 41.0}),
  pollution_server:add_value("S_DM_1", {Date, {10,0,0}}, "CO", 5.0),
  pollution_server:add_value("S_DM_2", {Date, {11,0,0}}, "CO", 15.0),
  pollution_server:add_value("S_DM_1", {{2024,5,16},{10,0,0}}, "CO", 25.0), % Inny dzień
  ?assertEqual({ok, (5.0+15.0)/2}, pollution_server:get_daily_mean("CO", Date)).

get_maximum_growth_time_test_(_Status) ->
  pollution_server:add_station("StacjaGrowth", {50.0, 50.0}),
  DT1 = {{2024,1,2},{10,0,0}}, Val1 = 10.0,
  DT2 = {{2024,1,2},{11,0,0}}, Val2 = 30.0, % Wzrost o 20
  DT3 = {{2024,1,2},{12,0,0}}, Val3 = 35.0, % Wzrost o 5
  pollution_server:add_value("StacjaGrowth", DT1, "SO2", Val1),
  pollution_server:add_value("StacjaGrowth", DT2, "SO2", Val2),
  pollution_server:add_value("StacjaGrowth", DT3, "SO2", Val3),
  ?assertEqual({ok, DT2}, pollution_server:get_maximum_growth_time("StacjaGrowth", "SO2")).

get_hourly_mean_test_(_Status) ->
  pollution_server:add_station("StacjaHourly", {60.0, 60.0}),
  Date1 = {2024,3,3}, Hour = 14,
  pollution_server:add_value("StacjaHourly", {Date1,{Hour,0,0}}, "PM1", 20.0),
  pollution_server:add_value("StacjaHourly", {{2024,3,4},{Hour,0,0}}, "PM1", 40.0), % Inny dzień, ta sama godzina
  pollution_server:add_value("StacjaHourly", {Date1,{15,0,0}}, "PM1", 50.0),      % Ta sama data, inna godzina
  ?assertEqual({ok, (20.0+40.0)/2}, pollution_server:get_hourly_mean("StacjaHourly", "PM1", Hour)).

error_handling_test_(_Status) ->
  ?assertMatch({error, "Station not found by name"}, pollution_server:get_station_min("NieistniejacaStacja", "TypX")),
  pollution_server:add_station("StacjaError", {70.0, 70.0}),
  ?assertMatch({error, "No measurements for station min"}, pollution_server:get_station_min("StacjaError", "TypY")).