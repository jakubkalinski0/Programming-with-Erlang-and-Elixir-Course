%%%-------------------------------------------------------------------
%%% @author Jakub Kalinski
%%% @end
%%%-------------------------------------------------------------------
-module(pingpong).
-export([start/0, stop/0, play/1]).
-export([ping_loop/1, pong_loop/0]). % Eksportowane dla spawn

-define(TIMEOUT, 20000). % 20 sekund w milisekundach

start() ->
    case whereis(ping) of
        undefined ->
            PongPid = spawn_link(?MODULE, pong_loop, []),
            register(pong, PongPid),
            PingPid = spawn_link(?MODULE, ping_loop, [0]), % Zaczynamy z sumą 0
            register(ping, PingPid),
            io:format("Ping-Pong: Procesy ping i pong uruchomione i zarejestrowane.~n"),
            {ok, {ping, PingPid}, {pong, PongPid}};
        _ ->
            io:format("Ping-Pong: Procesy już działają.~n"),
            {error, already_started}
    end.

stop() ->
    case whereis(ping) of
        undefined ->
            io:format("Ping-Pong: Procesy nie są uruchomione.~n"),
            {error, not_started};
        PingPid ->
            ping ! stop,
            pong ! stop,
            io:format("Ping-Pong: Wyslano wiadomosc stop do ping i pong.~n"),
            % Czekanie na zakończenie dla czystości (opcjonalne, ale dobre)
            receive after 500 -> ok end, % Dajmy im chwilę na zakończenie
            unregister(ping),
            unregister(pong),
            io:format("Ping-Pong: Procesy zatrzymane i wyrejestrowane.~n"),
            ok
    end.

play(N) when is_integer(N), N > 0 ->
    case whereis(ping) of
        undefined ->
            io:format("Ping-Pong: Proces ping nie jest uruchomiony. Uruchom go najpierw (start/0).~n"),
            {error, ping_not_started};
        _PingPid ->
            ping ! {play, N, self()}, % self() dla ewentualnej odpowiedzi, chociaz nie jest wymagane
            io:format("Ping-Pong: Rozpoczynam gre z ~p odbiciami.~n", [N]),
            ok
    end;
play(N) ->
    io:format("Ping-Pong: Liczba odbic musi byc dodatnia liczba calkowita, otrzymano: ~p.~n", [N]),
    {error, invalid_N}.


ping_loop(CurrentSum) ->
    receive
        {play, N, _FromPong} -> % _FromPong jest tu nieużywane, bo pong jest zarejestrowany
            io:format("Ping (~p): Otrzymalem polecenie gry na ~p odbic. Suma: ~p~n", [self(), N, CurrentSum]),
            pong ! {ping, N, self()}, % Wyślij do zarejestrowanego 'pong'
            ping_loop(CurrentSum + N); % Dodajemy N do sumy
        {pong, 0, PongPid} ->
            io:format("Ping (~p): Pong (~p) zakonczyl odbijanie. Aktualna suma: ~p~n", [self(), PongPid, CurrentSum]),
            ping_loop(CurrentSum);
        {pong, Count, PongPid} when Count > 0 ->
            io:format("Ping (~p): Otrzymalem PONG (~p) od ~p. Aktualna suma: ~p~n", [self(), Count, PongPid, CurrentSum]),
            timer:sleep(500), % Zwiększenie czytelności
            pong ! {ping, Count -1, self()},
            ping_loop(CurrentSum);
        stop ->
            io:format("Ping (~p): Otrzymalem sygnal stop. Koncze dzialanie. Finalna suma: ~p~n", [self(), CurrentSum]),
            exit(normal);
        Other ->
            io:format("Ping (~p): Otrzymalem nieznana wiadomosc: ~p. Suma: ~p~n", [self(), Other, CurrentSum]),
            ping_loop(CurrentSum)
    after ?TIMEOUT ->
        io:format("Ping (~p): Przekroczono czas bezczynnosci. Koncze dzialanie. Finalna suma: ~p~n", [self(), CurrentSum]),
        exit(timeout)
    end.

pong_loop() ->
    receive
        {ping, 0, PingPid} ->
            io:format("Pong (~p): Ping (~p) zakonczyl odbijanie.~n", [self(), PingPid]),
            pong_loop();
        {ping, Count, PingPid} when Count > 0 ->
            io:format("Pong (~p): Otrzymalem PING (~p) od ~p.~n", [self(), Count, PingPid]),
            timer:sleep(500), % Zwiększenie czytelności
            PingPid ! {pong, Count, self()},
            pong_loop();
        stop ->
            io:format("Pong (~p): Otrzymalem sygnal stop. Koncze dzialanie.~n", [self()]),
            exit(normal);
        Other ->
            io:format("Pong (~p): Otrzymalem nieznana wiadomosc: ~p~n", [self(), Other]),
            pong_loop()
    after ?TIMEOUT ->
        io:format("Pong (~p): Przekroczono czas bezczynnosci. Koncze dzialanie.~n", [self()]),
        exit(timeout)
    end.