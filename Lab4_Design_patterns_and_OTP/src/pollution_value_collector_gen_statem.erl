-module(pollution_value_collector_gen_statem).
-author("pawel").

-behaviour(gen_statem).

%% API
-export([start_link/0]).
-export([set_station/1, add_value/2, add_value/3, store_data/0]).

%% gen_statem callbacks
-export([init/1, terminate/3, callback_mode/0]).
-export([station_not_set/3, station_set/3]).


-define(SERVER, ?MODULE).

-record(state, {
  monitor,        % Oczekujemy tu monitora z modułu pollution
  station_id = none, % Może być atom, string, tuple lub none
  new_readings = []  % Lista rekordów #reading{}
}).
-record(reading, {
  type,           % string()
  value,          % float() | integer()
  date_time       % calendar:datetime()
}).

%% Funkcja pomocnicza do logowania błędów
print_error(Error_message) ->
  io:format("~p: ERROR: ~p~n", [?MODULE, Error_message]),
  ok.

%% API Functions
start_link() ->
  gen_statem:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
  InitialMonitor = pollution:create_monitor(),
  {ok, station_not_set, #state{monitor = InitialMonitor, station_id = none, new_readings = []}}.

set_station(Station_id) ->
  gen_statem:cast(?SERVER, {set_station, Station_id}).

add_value(Reading_type, Reading_value) ->
  add_value(Reading_type, Reading_value, calendar:local_time()).

add_value(Reading_type, Reading_value, Date_time) ->
  gen_statem:cast(?SERVER, {add_value, Reading_type, Reading_value, Date_time}).

store_data() ->
  gen_statem:cast(?SERVER, {store_data}).

%% State handling functions
callback_mode() ->
  handle_event_function.

station_not_set(_EventType, {set_station, Station_id}, State = #state{}) ->
  case pollution:get_station(Station_id, State#state.monitor) of
    {error, Error_message} ->
      print_error({station_not_found, Station_id, Error_message}),
      {keep_state_and_data, []};
    _Station -> % Stacja istnieje
      {next_state, station_set, State#state{station_id = Station_id}, []}
  end.

station_set(_EventType, {add_value, Reading_type, Reading_value, Date_time}, State = #state{}) ->
  New_reading = #reading{type = Reading_type, value = Reading_value, date_time = Date_time},
  Updated_reading_list = [New_reading | State#state.new_readings],
  {keep_state, State#state{new_readings = Updated_reading_list}, []};

station_set(_EventType, {store_data}, State = #state{}) ->
  case State#state.station_id of
    none ->
      print_error({store_data_called_without_station_set}),
      {keep_state_and_data, []};
    Station_id ->
      FinalMonitor = commit_readings(State#state.new_readings, Station_id, State#state.monitor),
      NewStateData = #state{
        monitor = FinalMonitor,
        station_id = none,
        new_readings = []
      },
      {next_state, station_not_set, NewStateData, []}
  end.

%% Helper function to commit readings and return the updated monitor
commit_readings([], _Station_id, Monitor) ->
  Monitor;
commit_readings([Reading = #reading{} | Tail], Station_id, CurrentMonitor) ->
  case pollution:add_value(Station_id, Reading#reading.date_time, Reading#reading.type, Reading#reading.value, CurrentMonitor) of
    {error, Error_message} ->
      print_error({failed_to_add_reading, Reading, Error_message}),
      commit_readings(Tail, Station_id, CurrentMonitor);
    NewMonitorAfterAdd ->
      commit_readings(Tail, Station_id, NewMonitorAfterAdd)
  end.

terminate(Reason, StateName, StateData) ->
  io:format("~p: Terminating.~nReason: ~p.~nIn state: ~p.~nWith data: ~p.~n",
    [?MODULE, Reason, StateName, StateData]),
  ok.