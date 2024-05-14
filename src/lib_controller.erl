%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2024, c50
%%% @doc
%%%
%%% @end
%%% Created : 11 Jan 2024 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_controller).
  

-include("controller.hrl").
  
%% API
-export([
	 load_start/1,
	 stop_unload/1,
	 stop_unload/2

	
	]).

-export([

	]).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% 
%% @end
%%--------------------------------------------------------------------
load_start(ApplicationFileName)->
    %% Get ApplicationId info , crash if doesnt exists
       
    {ok,ApplicationIdPaths}=catalog:get_application_paths(ApplicationFileName),
    {ok,ApplicationIdApp}=catalog:get_application_app(ApplicationFileName),
    {ok,ApplicationName}=catalog:get_application_name(ApplicationFileName),
  
    %% Create new worker node
    {ok,WorkerInfo}=lib_worker_controller:create_worker(ApplicationName),

    WorkerNode=maps:get(node,WorkerInfo),
    NodeName=maps:get(nodename,WorkerInfo),

    %% Load and start ApplicationId and start as permanent so if it crashes the node crashes
    [rpc:call(WorkerNode,code,add_patha,[Path],5000)||Path<-ApplicationIdPaths],
    ok=rpc:call(WorkerNode,application,load,[ApplicationIdApp],5000),
    ok=rpc:call(WorkerNode,application,start,[ApplicationIdApp,permanent],60*1000),
    pong=rpc:call(WorkerNode,ApplicationIdApp,ping,[],5*5000),
    pong=rpc:call(WorkerNode,log,ping,[],3*5000),
    pong=rpc:call(WorkerNode,rd,ping,[],3*5000),
    pong=net_adm:ping(WorkerNode),
    NodeId=maps:get(id,WorkerInfo),
    DeploymentInfo=#{
		     application_id=>ApplicationName,
		     app=>ApplicationIdApp,
		     node=>WorkerNode,
		     nodename=>NodeName,
		     node_id=>NodeId,
		     time=>{date(),time()},
		     state=>started
		    },

    % Add where to store log information 
    case filelib:is_dir(?MainLogDir) of
	false->
	    ok=file:make_dir(?MainLogDir);
	true->
	    no_action
    end,
    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
    ok=rpc:call(WorkerNode,log,create_logger,[NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes],5000),
    timer:sleep(1000),
    {ok,DeploymentInfo}.
    
    
%%--------------------------------------------------------------------
%% @doc
%% 
%% 
%% @end
%%--------------------------------------------------------------------
stop_unload(WorkerNode,ApplicationFileName)->
    App=catalog:get_application_app(ApplicationFileName),
    rpc:call(WorkerNode,application,stop,[App],5000),
    rpc:call(WorkerNode,application,unload,[App],5000),
    slave:stop(WorkerNode),
    timer:sleep(1000),
    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% 
%% @end
%%--------------------------------------------------------------------
stop_unload(ApplicationFileName)->
     [{Node,FileName}|_]=[{Node,FileName}||{Node,FileName}<-lib_reconciliate:active_applications(),
				   FileName=:=ApplicationFileName],
    App=catalog:get_application_app(ApplicationFileName),
    rpc:call(Node,application,stop,[App],5000),
    rpc:call(Node,application,unload,[App],5000),
    slave:stop(Node),
    timer:sleep(1000),
    ok.
    


%%%===================================================================
%%% Internal functions
%%%===================================================================
