%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2024, c50
%%% @doc
%%%
%%% @end
%%% Created : 11 Jan 2024 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_worker_controller).
  

 
  
%% API
-export([
	 create_worker/1,
	 delete_worker/1
	 
	]).

-export([

	]).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% Workers nodename convention Id_UniqueNum_cookie 
%% UniqueNum=integer_to_list(erlang:system_time(microsecond),36)
%% @end
%%--------------------------------------------------------------------
create_worker(Id)->
    UniqueNum=integer_to_list(erlang:system_time(microsecond),36),
    {ok,HostName}=net:gethostname(),
    CookieStr=atom_to_list(erlang:get_cookie()),
    NodeName=Id++"_"++UniqueNum++"_"++CookieStr,
    Args=" -setcookie "++CookieStr,
    {ok,Node}=slave:start(HostName,NodeName,Args),
    [rpc:call(Node,net_adm,ping,[N],5000)||N<-[node()|nodes()]],
    true=erlang:monitor_node(Node,true),
    WorkerInfo=#{
		 node=>Node,
		 nodename=>NodeName,
		 id=>Id,
		 time=>{date(),time()}
		},
    {ok,WorkerInfo}.

%%--------------------------------------------------------------------
%% @doc
%% Workers nodename convention ApplicationId_UniqueNum_cookie 
%% UniqueNum=erlang:system_time(microsecond)
%% @end
%%--------------------------------------------------------------------
delete_worker(Node)->
    erlang:monitor_node(Node,false),
    slave:stop(Node),
    ok.
    

%%%===================================================================
%%% Internal functions
%%%===================================================================
