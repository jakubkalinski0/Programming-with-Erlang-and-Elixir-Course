%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @end
%%%-------------------------------------------------------------------
-module(sensor_dist).
-export([
    get_rand_locations/1,
    dist/2,
    find_for_person/2,
    find_closest_sequential/2,
    find_for_person_worker/3,
    find_closest_parallel/2,
    run_comparison/2
]).

get_rand_locations(Number) when is_integer(Number), Number > 0 ->
    [ {rand:uniform(10000), rand:uniform(10000)} || _ <- lists:seq(1, Number) ];
get_rand_locations(_) ->
    {error, invalid_number}.

dist({X1, Y1}, {X2, Y2}) ->
    Dx = X1 - X2,
    Dy = Y1 - Y2,
    math:sqrt(Dx * Dx + Dy * Dy).

% Wersja sekwencyjna
find_for_person(PersonLocation, SensorsLocations) ->
    Distances = [{dist(PersonLocation, SensorLoc), {PersonLocation, SensorLoc}} || SensorLoc <- SensorsLocations],
    case Distances of
        [] -> {infinity, {PersonLocation, undefined_sensor}}; % Obsługa pustej listy sensorów
        _  -> lists:min(Distances)
    end.

find_closest_sequential(PeopleLocations, SensorsLocations) ->
    Results = [find_for_person(PersonLoc, SensorsLocations) || PersonLoc <- PeopleLocations],
    case Results of
        [] -> {infinity, {undefined_person, undefined_sensor}}; % Obsługa pustej listy osób
        _  -> lists:min(Results)
    end.

% Wersja równoległa
find_for_person_worker(PersonLocation, SensorsLocations, ParentPID) ->
    Result = find_for_person(PersonLocation, SensorsLocations),
    ParentPID ! {result, self(), Result}. % Wysyłamy też własny PID dla debugowania/śledzenia

find_closest_parallel(PeopleLocations, SensorsLocations) ->
    Parent = self(),
    NumPeople = length(PeopleLocations),
    if
        NumPeople == 0 -> {infinity, {undefined_person, undefined_sensor}};
        true ->
            % Uruchomienie workerów
            _Pids = [spawn_link(?MODULE, find_for_person_worker, [PersonLoc, SensorsLocations, Parent]) || PersonLoc <- PeopleLocations],

            % Zbieranie wyników
            Results = [receive
                           {result, _WorkerPid, R} -> R
                       after 5000 -> % Timeout na wypadek gdyby worker się zawiesił
                    io:format("Timeout waiting for worker result.~n"),
                    {infinity, {timeout_person, timeout_sensor}}
                       end || _ <- PeopleLocations], % Odbierz tyle wyników, ile osób
            lists:min(Results)
    end.

run_comparison(NumSensors, NumPeople) ->
    io:format("Generowanie danych: ~p sensorów, ~p osób...~n", [NumSensors, NumPeople]),
    Sensors = get_rand_locations(NumSensors),
    People = get_rand_locations(NumPeople),
    io:format("Dane wygenerowane.~n"),

    io:format("Uruchamianie wersji sekwencyjnej...~n"),
    {TimeSequential, ResultSequential} = timer:tc(?MODULE, find_closest_sequential, [People, Sensors]),
    io:format("Wersja sekwencyjna: czas = ~p us, wynik = ~p~n", [TimeSequential, ResultSequential]),

    io:format("Uruchamianie wersji równoległej...~n"),
    {TimeParallel, ResultParallel} = timer:tc(?MODULE, find_closest_parallel, [People, Sensors]),
    io:format("Wersja równoległa: czas = ~p us, wynik = ~p~n", [TimeParallel, ResultParallel]),

    if
        TimeSequential < TimeParallel ->
            io:format("Wersja sekwencyjna była szybsza.~n");
        TimeParallel < TimeSequential ->
            io:format("Wersja równoległa była szybsza.~n");
        true ->
            io:format("Czasy wykonania były takie same (lub błąd w pomiarze).~n")
    end,
    {sequential, TimeSequential, ResultSequential},
    {parallel, TimeParallel, ResultParallel}.