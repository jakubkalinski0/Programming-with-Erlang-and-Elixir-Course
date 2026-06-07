-module(pollution_server_test).
-author("Jakub Kalinski").
-include_lib("eunit/include/eunit.hrl").

pollution_server_test_() ->
    {setup,
     fun setup_server/0,
     fun teardown_server/1,
     [
         fun add_station_test_/1,
         fun add_value_and_get_one_test_/1,
         fun get_station_mean_test_/1,
         fun remove_value_test_/1,
         fun get_daily_mean_test_/1
     ]}.

setup_server() ->
    pollution_server:stop(),
    {ok, _Pid} = pollution_server:start(),
    ok.

teardown_server(_Status) ->
    pollution_server:stop(),
    ok.

add_station_test_(_Status) ->
    ?assert(is_map(pollution_server:add_station("Stacja1", {1.0, 1.0}))),
    ?assertMatch({error, "Station with this name already exists"},
                 pollution_server:add_station("Stacja1", {2.0, 2.0})),
    ?assertMatch({error, "Station with these coordinates already exists"},
                 pollution_server:add_station("Stacja2", {1.0, 1.0})).

add_value_and_get_one_test_(_Status) ->
    Time = calendar:local_time(),
    pollution_server:add_station("StacjaGet", {10.0, 10.0}),
    ?assert(is_map(pollution_server:add_value("StacjaGet", Time, "PM10", 42.5))),
    ?assertEqual(42.5, pollution_server:get_one_value("StacjaGet", Time, "PM10")),
    ?assertMatch({error, "Measurement not found"},
                 pollution_server:get_one_value("StacjaGet", Time, "PM2.5")).

get_station_mean_test_(_Status) ->
    pollution_server:add_station("StacjaStats", {20.0, 20.0}),
    DT1 = {{2024, 1, 1}, {10, 0, 0}},
    DT2 = {{2024, 1, 1}, {11, 0, 0}},
    DT3 = {{2024, 1, 1}, {12, 0, 0}},
    pollution_server:add_value("StacjaStats", DT1, "NO2", 10.0),
    pollution_server:add_value("StacjaStats", DT2, "NO2", 20.0),
    pollution_server:add_value("StacjaStats", DT3, "NO2", 5.0),
    ?assertEqual(35.0 / 3, pollution_server:get_station_mean("StacjaStats", "NO2")).

remove_value_test_(_Status) ->
    pollution_server:add_station("StacjaRemove", {30.0, 30.0}),
    Time = calendar:local_time(),
    pollution_server:add_value("StacjaRemove", Time, "O3", 100.0),
    ?assert(is_map(pollution_server:remove_value("StacjaRemove", Time, "O3"))),
    ?assertMatch({error, "Measurement not found"},
                 pollution_server:get_one_value("StacjaRemove", Time, "O3")).

get_daily_mean_test_(_Status) ->
    Date = {2024, 5, 15},
    pollution_server:add_station("S_DM_1", {40.0, 40.0}),
    pollution_server:add_station("S_DM_2", {41.0, 41.0}),
    pollution_server:add_value("S_DM_1", {Date, {10, 0, 0}}, "CO", 5.0),
    pollution_server:add_value("S_DM_2", {Date, {11, 0, 0}}, "CO", 15.0),
    pollution_server:add_value("S_DM_1", {{2024, 5, 16}, {10, 0, 0}}, "CO", 25.0),
    ?assertEqual(10.0, pollution_server:get_daily_mean("CO", Date)).