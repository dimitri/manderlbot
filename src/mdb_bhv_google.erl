%%% File    : mdb_bhv_google.erl
%%% Author  : Nicolas Niclausse <nico@niclux.org>
%%% Purpose : ask google for the first match of a given keyword
%%% Created : 16 Jul 2002 by Nicolas Niclausse <nico@niclux.org>

-module(mdb_bhv_google).
-author('nico@niclux.org').
-revision(' $Id$ ').
-vsn(' $Revision$ ').

-export([behaviour/5]). % MDB behaviour API
-export([search/5, parse/1, set_request/1]).

-include("mdb.hrl").

-define(google_name, "www.google.com").
-define(google_port, 80).

%%%----------------------------------------------------------------------
%%% Function: behaviour/5
%%% Purpose:  ask google and give the first response
%%%----------------------------------------------------------------------
behaviour(Input, BotName, Data, BotPid, Channel) ->
    io:format("GOOGLE input: ~p~n", [Input#data.body]),

    [Key | Args] = string:tokens(Input#data.body," "),
    Criteria= misc_tools:join("+", Args),
	
    io:format("GOOGLE criteria: ~p~n", [Criteria]),

    search(Criteria, Input, BotPid, BotName, Channel).


search(Keywords, Input, BotPid, BotName, Channel) ->
    mdb_search:search({Keywords,
                       Input, BotPid, BotName, Channel,
                       #search_param{type   = ?MODULE, 
                                     server = ?google_name,
                                     port   = ?google_port }
                      }).

%%----------------------------------------------------------------------
%% Func: parse/1
%% Purpose: Parse data
%% Returns: {stop, Result} | {stop} | {continue} | {continue, Result}
%%      continue -> continue parsing of incoming data
%%      stop     -> stop parsing of incoming data
%%      Result   -> String to be printed by mdb
%%----------------------------------------------------------------------
parse(Data) ->
	case regexp:first_match(Data, "Location: http://[^\"]+") of
		{match,Start,Length} -> % ok, found
		    {stop, string:substr(Data, 11, length(Data)-12) };
		_ -> 
		    {continue}
    end.

%%----------------------------------------------------------------------
%% Func: set_request/1
%% Purpose: Set the request given Keywords 
%% Returns: String
%%----------------------------------------------------------------------
set_request(Keywords) ->
    "GET /search?q=" ++ Keywords ++"&hl=fr&btnI=J%27ai+de+la+chance HTTP/1.0"
	++ io_lib:nl() ++ io_lib:nl().