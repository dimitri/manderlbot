%%%----------------------------------------------------------------------
%%% File    : mdb_behaviours_new.erl
%%% Author  : Dimitri Fontaine <tapoueh@free.fr>
%%% Purpose : 
%%% Created : 27 Feb 2002 by Dimitri Fontaine <tapoueh@free.fr>
%%%----------------------------------------------------------------------

-module(mdb_behaviours).
-author('tapoueh@free.fr').

%% Exported behaviours
-export([say/4, action/4, answer/4, random/4, timer/4, bloto/4,
	 google/4, rejoin/4, reconf/4]).

-include("mdb.hrl").
-define(TIME, 2000).
-define(RNDTIME, 3000).

%% A plugin function for behaviour is of the form:
%% Fun(Input, BotName, Data, BotPid)



%%%----------------------------------------------------------------------
%%% Function: say/4
%%% Purpose:  Say the data in the channel or to the speaker
%%%----------------------------------------------------------------------
say(Input = #data{header_to=BotName}, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),

    lists:map(fun(String) ->
		      mdb_bot:say(NickFrom, BotPid, String)
	      end,
	      Data);

say(Input, BotName, Data, BotPid) ->
    lists:map(fun(String) ->
		      mdb_bot:say(BotPid, String)
	      end,
	      Data).


%%%----------------------------------------------------------------------
%%% Function: action/4
%%% Purpose:  Answer with Action IRC usage - /me
%%%----------------------------------------------------------------------
action(Input = #data{header_to=BotName}, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),

    lists:map(fun(String) ->
		      mdb_bot:action(NickFrom, BotPid, String)
	      end,
	      Data);

action(Input, BotName, Data, BotPid) ->
    lists:map(fun(String) ->
		      mdb_bot:action(BotPid, String)
	      end,
	      Data).


%%%----------------------------------------------------------------------
%%% Function: answer/4
%%% Purpose:  Answer the given (config) data to the one who talk
%%%----------------------------------------------------------------------
answer(Input = #data{header_to=BotName}, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),

    lists:map(fun(String) ->
		      mdb_bot:say(NickFrom, BotPid, String)
	      end,
	      Data);

answer(Input, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),
    lists:map(fun(String) ->
		      mdb_bot:say(BotPid, NickFrom ++ ": " ++ String)
	      end,
	      Data).


%%%----------------------------------------------------------------------
%%% Function: random/4
%%% Purpose:  Choose at random a line in Data and answer it.
%%%----------------------------------------------------------------------
random(Input = #data{header_to=BotName}, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),

    {A, B, C} = now(),
    random:seed(A, B, C),
    mdb_bot:say(NickFrom, BotPid,
		lists:nth(random:uniform(length(Data)), Data));

random(Input, BotName, Data, BotPid) ->
    {A, B, C} = now(),
    random:seed(A, B, C),
    mdb_bot:say(BotPid, lists:nth(random:uniform(length(Data)), Data)).


%%%----------------------------------------------------------------------
%%% Function: timer/4
%%% Purpose:  Answer the given data, but waiting for random time
%%%           between the 2 lines to say.
%%%----------------------------------------------------------------------
timer(Input = #data{header_to=BotName}, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),
    case length(Data) of
	1 ->
	    [String] = Data,
	    mdb_bot:say(NickFrom, BotPid, String);

	2 ->
	    [H|T] = Data,
	    mdb_bot:say(NickFrom, BotPid, H),
	    %% we sleep for a random time
	    {A, B, C} = now(),
	    random:seed(A, B, C),
	    timer:sleep(random:uniform(?RNDTIME) + ?TIME),
	    mdb_bot:say(NickFrom, BotPid, T);

	More ->
	    say(Input, BotName, Data, BotPid)
    end;

timer(Input, BotName, Data, BotPid) ->
    case length(Data) of
	1 ->
	    [String] = Data,
	    mdb_bot:say(BotPid, String);

	2 ->
	    [H|T] = Data,
	    mdb_bot:say(BotPid, H),
	    %% we sleep for a random time
	    {A, B, C} = now(),
	    random:seed(A, B, C),
	    timer:sleep(random:uniform(?RNDTIME) + ?TIME),
	    mdb_bot:say(BotPid, T);

	More ->
	    say(Input, BotName, Data, BotPid)
    end.


%%%----------------------------------------------------------------------
%%% Function: bloto/4
%%% Purpose:  Play to business loto...
%%%----------------------------------------------------------------------
bloto(Input, BotName, Data, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),

    case bloto:add(NickFrom) of
	{winner, Nick} ->
	    mdb_bot:say(BotPid, Nick ++ " " ++ Data);

	Other ->
	    ok
    end.


%%%----------------------------------------------------------------------
%%% Function: rejoin/4
%%% Purpose:  When kicked, rejoin the chan
%%%----------------------------------------------------------------------
rejoin(Input, BotName, Data, BotPid) ->
    mdb_bot:rejoin(BotPid).


%%%----------------------------------------------------------------------
%%% Function: reconf/4
%%% Purpose:  Re-read now the config file
%%%----------------------------------------------------------------------
reconf(Input, BotName, ConfigFile, BotPid) ->
    [NickFrom|IpFrom] = string:tokens(Input#data.header_from, "!"),
    mdb_bot:reconf(BotPid, NickFrom, ConfigFile).		     


%%%----------------------------------------------------------------------
%%% Function: google/4
%%% Purpose:  ask google and give the first response
%%%----------------------------------------------------------------------
google(Input, BotName, ConfigFile, BotPid) ->
    io:format("GOOGLE input: ~p~n", [Input#data.body]),

    Criteria = lists:foldl(
		 fun(Str, "") ->
			 Str;
		    (Str, Acc) ->
			 Acc ++ "+" ++ Str
		 end,
		 "",
		 string:tokens(
		   string:strip(string:substr(Input#data.body,
					      string:len("google") + 1)),
		   " ")),

    io:format("GOOGLE criteria: ~p~n", [Criteria]),

    case google:search(Criteria) of
	{stop, connfailed} ->
	    mdb_bot:say(BotPid, "google: connection failed !");

	{error, Reason} ->
	    mdb_bot:say(BotPid, "google: " ++ Reason);

	Result ->
	    mdb_bot:say(BotPid, Result)
    end.