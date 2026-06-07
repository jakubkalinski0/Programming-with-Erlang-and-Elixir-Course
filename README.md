# Programming with Erlang and Elixir

Rozwiązania laboratoryjne z kursu *Programming in Erlang and Elixir* (AGH UST).

## Laboratories

### [Lab 1 — Erlang language basics](src/Lab1_Erlang_language_basics/)

Podstawy języka Erlang: listy, rekurencja, kalkulator jakości powietrza.

### [Lab 2 — Functional programming in Erlang](src/Lab2_functional_programming_in_Erlang/)

Programowanie funkcyjne: funkcje anonimowe, quicksort, moduł `pollution`.

### [Lab 3 — Process programming in Erlang](src/Lab3_Process_programming_in_Erlang/)

Procesy: ping-pong, obliczenia równoległe (parcel locker), serwer `pollution_server`.

### [Lab 4 — Design patterns and OTP](src/Lab4_Design_patterns_and_OTP/)

OTP: `gen_server`, `supervisor`, `gen_statem`, projekt rebar3 `pollution_server`.

### [Lab 5 — Introduction to Elixir](src/Lab5_Introduction_to_Elixir/)

Podstawy Elixira i integracja z aplikacją Erlang (notatnik LiveBook `lab5.livemd`).

> Przed uruchomieniem Lab 5 wykonaj `rebar3 compile` w katalogu Lab 4.

### [Lab 6 — Databases in Elixir](src/Lab6_Databases_in_Elixir/)

Mix, Ecto, SQLite — aplikacja `pollutiondb` z parserem CSV i loaderem danych.

### [Lab 7 — Phoenix web application](src/Lab7_Phoenix_web_application/)

Aplikacja webowa Phoenix z LiveView — projekt `pollutiondb`.
