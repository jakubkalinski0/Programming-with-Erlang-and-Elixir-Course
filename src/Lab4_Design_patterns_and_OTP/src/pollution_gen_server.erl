-module(pollution_gen_server).
-author("pawel"). % Zachowuję Twoje autorstwo

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2]). % Dodano handle_info/2 na wszelki wypadek

%% API klienta
-export([add_station/2, add_value/4, remove_value/3]).
-export([get/0, get_one_value/3, get_station_mean/2, get_daily_mean/2, get_correlation/3]). % Dodano get_station_mean/2

-define(SERVER_NAME, pollution_gen_server). % Możesz użyć ?MODULE, jeśli nazwa pliku to pollution_gen_server.erl
-define(INITIAL_ARGS, []). % Argumenty przekazywane do init/1

%% Funkcja pomocnicza (opcjonalna, ale używana w Twoim oryginalnym kodzie)
print_error(Context, Error_message) ->
  io:format("~p: ERROR [~p]: ~p~n", [?MODULE, Context, Error_message]),
  ok.

%% ===================================================================
%% API Funkcje dla klienta
%% ===================================================================

add_station(Name, Coordinates) ->
  gen_server:cast(?SERVER_NAME, {add_station, Name, Coordinates}).

add_value(Station_id, Date_time, Reading_type, Reading_value) ->
  gen_server:cast(?SERVER_NAME, {add_value, Station_id, Date_time, Reading_type, Reading_value}).

remove_value(Station_id, Reading_date_time, Reading_type) ->
  gen_server:cast(?SERVER_NAME, {remove_value, Station_id, Reading_date_time, Reading_type}).

get() ->
  gen_server:call(?SERVER_NAME, get).

get_one_value(Station_id, Reading_date_time, Reading_type) ->
  gen_server:call(?SERVER_NAME, {get_one_value, Station_id, Reading_date_time, Reading_type}).

get_station_mean(Station_id, Reading_type) -> % Dodana funkcja API
  gen_server:call(?SERVER_NAME, {get_station_mean, Station_id, Reading_type}).

get_daily_mean(Reading_type, Date) ->
  gen_server:call(?SERVER_NAME, {get_daily_mean, Reading_type, Date}).

get_correlation(Station_id, Reading_type1, Reading_type2) ->
  gen_server:call(?SERVER_NAME, {get_correlation, Station_id, Reading_type1, Reading_type2}).

%% ===================================================================
%% gen_server callbacks
%% ===================================================================

start_link() ->
  io:format("~p: DEBUG [start_link]: Trying to start and register as '~p'~n", [?MODULE, ?SERVER_NAME]),
  gen_server:start_link({local, ?SERVER_NAME}, ?MODULE, ?INITIAL_ARGS, []).

init(Args) ->
  io:format("~p: DEBUG [init]: Called with Args: ~p~n", [?MODULE, Args]),
  try
    Monitor = pollution:create_monitor(),
    io:format("~p: DEBUG [init]: pollution:create_monitor() successful. Initial monitor: ~p~n", [?MODULE, Monitor]),
    {ok, Monitor}
  catch
    ExceptionType:Exception:Stacktrace ->
      io:format("~p: CRITICAL ERROR [init]: Exception ~p:~p~nStacktrace: ~p~n",
        [?MODULE, ExceptionType, Exception, Stacktrace]),
      {stop, {init_failed, {ExceptionType, Exception}}}
  end.

handle_call(Call_arguments, From, Current_monitor) ->
  io:format("~p: DEBUG [handle_call]: Received ~p from ~p. Current state (monitor): ~p~n", [?MODULE, Call_arguments, From, Current_monitor]),
  Result = case Call_arguments of
             get ->
               Current_monitor;

             {get_one_value, Station_id, Reading_date_time, Reading_type} ->
               pollution:get_one_value(Station_id, Reading_date_time, Reading_type, Current_monitor);

             {get_station_mean, Station_id, Reading_type} -> % Dodana obsługa
               pollution:get_station_mean(Station_id, Reading_type, Current_monitor);

             {get_daily_mean, Reading_type, Date} ->
               pollution:get_daily_mean(Reading_type, Date, Current_monitor);

             {get_correlation, Station_id, Reading_type1, Reading_type2} ->
               pollution:get_correlation(Station_id, Reading_type1, Reading_type2, Current_monitor);

             _UnknownCall ->
               io:format("~p: WARNING [handle_call]: Received unknown call: ~p~n", [?MODULE, _UnknownCall]),
               {error, {unknown_call, _UnknownCall}}
           end,

  io:format("~p: DEBUG [handle_call]: Result from pollution module: ~p~n", [?MODULE, Result]),

  Reply = case Result of
            {error, _Reason} = ErrorTuple ->
              ErrorTuple; % Przekaż krotkę błędu jako odpowiedź
            NormalReply ->
              NormalReply % Przekaż normalny wynik jako odpowiedź
          end,

  io:format("~p: DEBUG [handle_call]: Replying with: ~p~n", [?MODULE, Reply]),
  {reply, Reply, Current_monitor}.


handle_cast(Cast_arguments, Current_monitor) ->
  io:format("~p: DEBUG [handle_cast]: Received ~p. Current state (monitor): ~p~n", [?MODULE, Cast_arguments, Current_monitor]),
  NewMonitor = case Cast_arguments of
                 {add_station, Name, Coordinates} ->
                   pollution:add_station(Name, Coordinates, Current_monitor);

                 {add_value, Station_id, Date_time, Reading_type, Reading_value} ->
                   pollution:add_value(Station_id, Date_time, Reading_type, Reading_value, Current_monitor);

                 {remove_value, Station_id, Reading_date_time, Reading_type} ->
                   pollution:remove_value(Station_id, Reading_date_time, Reading_type, Current_monitor);

                 _UnknownCast ->
                   print_error(handle_cast, {unknown_cast_argument, Cast_arguments}),
                   Current_monitor % Nie zmieniaj stanu przy nieznanym cast
               end,

  % Sprawdzenie, czy pollution:funkcja nie zwróciła błędu
  FinalMonitor = case NewMonitor of
                   {error, Error_message} ->
                     print_error(handle_cast, {operation_failed, Cast_arguments, Error_message}),
                     Current_monitor; % Zachowaj stary stan w przypadku błędu
                   ValidNewMonitor ->
                     ValidNewMonitor
                 end,

  io:format("~p: DEBUG [handle_cast]: New state (monitor) after cast: ~p~n", [?MODULE, FinalMonitor]),
  {noreply, FinalMonitor}.

terminate(Reason, State) ->
  io:format("~p: INFO [terminate]: Terminating with reason: ~p. Last state: ~p~n", [?MODULE, Reason, State]),
  ok.