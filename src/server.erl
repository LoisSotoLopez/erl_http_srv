-module(server).
-export([start/1, stop/0]).
-include_lib("kernel/include/logger.hrl").

-define(SERVER,server).

start(Port) ->
  Pid = spawn(fun () -> 
    {ok,Sock} = gen_tcp:listen(Port, [{active,false},{packet,http}]),
    loop(Sock) end),
  register(?SERVER, Pid),
  Pid.

% TODO - Do doc sharing connections properly exit?
stop() ->
  exit(whereis(?SERVER), ok).

loop(Sock) ->
  {ok, Conn} = gen_tcp:accept(Sock),
  Handler = spawn(fun () -> handle(Conn) end),
  gen_tcp:controlling_process(Conn, Handler),
  loop(Sock).

handle(Conn) ->
  logger:info("Got new connection"),
  gen_tcp:send(Conn, response("Hello World")),
  gen_tcp:close(Conn).

response(Str) ->
  B = iolist_to_binary(Str),
  iolist_to_binary(
    io_lib:fwrite(
      "HTTP/1.0 200 OK\nContent-Type: text/html\nContent-Length: ~p\n\n~s",
      [size(B), B])).