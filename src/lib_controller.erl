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
	 stop_unload/2,

	 deploy_application/1,
	 remove_application/1,
	 remove_application/2,
	 nodedown/2,

	 clean_up/2	 
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
    
    
    {ok,ApplicationIdPaths}=rd:call(catalog,get_application_paths,[ApplicationFileName],3*5000),
    {ok,ApplicationIdApp}=rd:call(catalog,get_application_app,[ApplicationFileName],3*5000),
    {ok,ApplicationName}=rd:call(catalog,get_application_name,[ApplicationFileName],3*5000),
  
    %% Create new worker node
    {ok,WorkerInfo}=lib_worker_controller:create_worker(ApplicationName),

    WorkerNode=maps:get(node,WorkerInfo),
    NodeName=maps:get(nodename,WorkerInfo),

    %% Load and start ApplicationId and start as permanent so if it crashes the node crashes
    [rpc:call(WorkerNode,code,add_patha,[Path],5000)||Path<-ApplicationIdPaths],
    ok=rpc:call(WorkerNode,application,load,[ApplicationIdApp],5000),
    ok=rpc:call(WorkerNode,application,start,[ApplicationIdApp,permanent],5000),
    pong=rpc:call(WorkerNode,ApplicationIdApp,ping,[],5000),
    pong=rpc:call(WorkerNode,log,ping,[],5000),
    pong=rpc:call(WorkerNode,rd,ping,[],5000),
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
    App=rd:call(catalog,get_application_app,[ApplicationFileName],3*5000),
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
    App=rd:call(catalog,get_application_app,[ApplicationFileName],3*5000),
    rpc:call(Node,application,stop,[App],5000),
    rpc:call(Node,application,unload,[App],5000),
    slave:stop(Node),
    timer:sleep(1000),
    ok.
    


%%--------------------------------------------------------------------
%% @doc
%% when a node craches controller uses this function to sort out what to do
%% and  the wanted application ApplicationId
%% @end
%%--------------------------------------------------------------------
nodedown(WorkerNode,DeploymentInfoList)->
    [DeploymentInfo]=[DeploymentInfo||DeploymentInfo<-DeploymentInfoList,
				      WorkerNode==maps:get(node,DeploymentInfo)],
    WorkerNode=maps:get(node,DeploymentInfo),
    %% stop monitoring the node
    erlang:monitor_node(WorkerNode,false),
    slave:stop(WorkerNode),
    ApplicationId=maps:get(glurk,DeploymentInfo),
    UpdatedDeploymentInfoList=case maps:get(state,DeploymentInfo) of
				  delete->
				    %  io:format("delete ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,WorkerNode,ApplicationId}]),
				      lists:delete(DeploymentInfo,DeploymentInfoList);
				  started->
				    %  io:format("started ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,WorkerNode,ApplicationId}]),
				      Info=#{
					     application_id=>ApplicationId,
					     app=>na,
					     node=>na,
					     nodename=>na,
					     node_id=>na,
					     time=>na,
					     state=>scheduled},
				      [Info|lists:delete(DeploymentInfo,DeploymentInfoList)];
				  scheduled->
				    %  io:format("started ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,WorkerNode,ApplicationId}]),
				      Info=#{
					     application_id=>ApplicationId,
					     app=>na,
					     node=>na,
					     nodename=>na,
					     node_id=>na,
					     time=>na,
					     state=>scheduled},
				      [Info|lists:delete(DeploymentInfo,DeploymentInfoList)]
			      end,  
    {ok,UpdatedDeploymentInfoList}.
%%--------------------------------------------------------------------
%% @doc
%% Creates a new workernode , load and start infra services (log and resource discovery)
%% and  the wanted application ApplicationId
%% @end
%%--------------------------------------------------------------------
deploy_application(ApplicationId)->

    %% Get ApplicationId info , crash if doesnt exists
    {ok,ApplicationIdPaths}=rd:call(catalog,get_application_paths,[ApplicationId],5000),
    {ok,ApplicationIdApp}=rd:call(catalog,get_application_app,[ApplicationId],5000),
  
    %% Create new worker node
    {ok,WorkerInfo}=lib_worker_controller:create_worker(ApplicationId),

    WorkerNode=maps:get(node,WorkerInfo),
    NodeName=maps:get(nodename,WorkerInfo),
    
    %% Load and start log
    {ok,LogPaths}=rd:call(catalog,get_application_paths,["log.application"],5000),
    {ok,LogApp}=rd:call(catalog,get_application_app,["log.application"],5000),
    [rpc:call(WorkerNode,code,add_patha,[Path],5000)||Path<-LogPaths],
    ok=rpc:call(WorkerNode,application,load,[LogApp],5000),
    ok=rpc:call(WorkerNode,application,start,[LogApp],5000),
    pong=rpc:call(WorkerNode,LogApp,ping,[],5000),
    % Add where to store log information 
    case filelib:is_dir(?MainLogDir) of
	false->
	    ok=file:make_dir(?MainLogDir);
	true->
	    no_action
    end,
    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
    ok=rpc:call(WorkerNode,log,create_logger,[NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes],5000),
    

    %% Load and start resource discovery
    {ok,RdPaths}=rd:call(catalog,get_application_paths,["resource_discovery"],5000),
    {ok,RdApp}=rd:call(catalog,get_application_app,["resource_discovery"],5000),
    [rpc:call(WorkerNode,code,add_patha,[Path],5000)||Path<-RdPaths],
    ok=rpc:call(WorkerNode,application,load,[RdApp],5000),
    ok=rpc:call(WorkerNode,application,start,[RdApp],5000),
    pong=rpc:call(WorkerNode,RdApp,ping,[],5000),
    
    %% Load and start ApplicationId and start as permanent so if it crashes the node crashes
    [rpc:call(WorkerNode,code,add_patha,[Path],5000)||Path<-ApplicationIdPaths],
    ok=rpc:call(WorkerNode,application,load,[ApplicationIdApp],5000),
    ok=rpc:call(WorkerNode,application,start,[ApplicationIdApp,permanent],5000),
    pong=rpc:call(WorkerNode,ApplicationIdApp,ping,[],5000),
    NodeId=maps:get(id,WorkerInfo),
    DeploymentInfo=#{
		     application_id=>ApplicationId,
		     app=>ApplicationIdApp,
		     node=>WorkerNode,
		     nodename=>NodeName,
		     node_id=>NodeId,
		     time=>{date(),time()},
		     state=>started
		    },
    {ok,DeploymentInfo}.
	

%%--------------------------------------------------------------------
%% @doc
%% Creates a new workernode , load and start infra services (log and resource discovery)
%% and  the wanted application ApplicationId
%% @end
%%--------------------------------------------------------------------
remove_application(ApplicationId,DeploymentInfoList)->
    
    %% Get DeploymetInfo for an deployment with ApplicationId, crash if doesnt exists
    [DeploymentInfo|_]=[DeploymentInfo||DeploymentInfo<-DeploymentInfoList,
				ApplicationId==maps:get(application_id,DeploymentInfo)],
    %% stop monitoring the node
    WorkerNode=maps:get(node,DeploymentInfo),
    case WorkerNode of
	na->
	    ok;
	_->
	    erlang:monitor_node(WorkerNode,false),
	    case net_adm:ping(WorkerNode) of
		pong->
		    %% stop  ApplicationId
		    ApplicationIdApp=maps:get(app,DeploymentInfo),
		    ok=rpc:call(WorkerNode,application,stop,[ApplicationIdApp],5000),
		    ok=rpc:call(WorkerNode,application,unload,[ApplicationIdApp],5000),
	  
		    %% stop  resource discovery
		    {ok,RdApp}=rd:call(catalog,get_application_app,["resource_discovery"],5000),
		    ok=rpc:call(WorkerNode,application,stop,[RdApp],5000),
		    ok=rpc:call(WorkerNode,application,unload,[RdApp],5000),
		    
		    %% stop log
		    {ok,LogApp}=rd:call(catalog,get_application_app,["log.application"],5000),
		    ok=rpc:call(WorkerNode,application,stop,[LogApp],5000),
		    ok=rpc:call(WorkerNode,application,unload,[LogApp],5000),
		    
		    %% stope slave node
		    slave:stop(WorkerNode);
		pang->
		    ok
	    end
    end,
  
    
    %% All good
    UpdatedDeploymentInfoList=lists:delete(DeploymentInfo,DeploymentInfoList),
    io:format("DeploymentInfo ~p~n",[{?MODULE,?LINE,DeploymentInfo}]),
    io:format("DeploymentInfoList ~p~n",[{?MODULE,?LINE,DeploymentInfoList}]),
    io:format("UpdatedDeploymentInfoList ~p~n",[{?MODULE,?LINE,UpdatedDeploymentInfoList}]),
    {ok,UpdatedDeploymentInfoList}.

%%--------------------------------------------------------------------
%% @doc
%% Creates a new workernode , load and start infra services (log and resource discovery)
%% and  the wanted application ApplicationId
%% @end
%%--------------------------------------------------------------------
remove_application(DeploymentInfo)->
    
    WorkerNode=maps:get(node,DeploymentInfo),
    case WorkerNode of
	na->
	    ok;
	_->
	    erlang:monitor_node(WorkerNode,false),
	    case net_adm:ping(WorkerNode) of
		pong->
		    %% stop  ApplicationId
		    ApplicationIdApp=maps:get(app,DeploymentInfo),
		    ok=rpc:call(WorkerNode,application,stop,[ApplicationIdApp],5000),
		    ok=rpc:call(WorkerNode,application,unload,[ApplicationIdApp],5000),
	  
		    %% stop  resource discovery
		    {ok,RdApp}=rd:call(catalog,get_application_app,["resource_discovery"],5000),
		    ok=rpc:call(WorkerNode,application,stop,[RdApp],5000),
		    ok=rpc:call(WorkerNode,application,unload,[RdApp],5000),
		    
		    %% stop log
		    {ok,LogApp}=rd:call(catalog,get_application_app,["log.application"],5000),
		    ok=rpc:call(WorkerNode,application,stop,[LogApp],5000),
		    ok=rpc:call(WorkerNode,application,unload,[LogApp],5000),
		    
		    %% stope slave node
		    slave:stop(WorkerNode);
		pang->
		    ok
	    end
    end,
  
    
    %% All good
    ok.


%%--------------------------------------------------------------------
%% @doc
%% Creates a new workernode , load and start infra services (log and resource discovery)
%% and  the wanted application ApplicationId
%% @end
%%--------------------------------------------------------------------
clean_up(WorkerNode,DeploymentInfoList)->
    [DeploymentInfo|_]=[DeploymentInfo||DeploymentInfo<-DeploymentInfoList,
					WorkerNode==maps:get(node,DeploymentInfo)],
    WorkerNode=maps:get(node,DeploymentInfo),
    %% stop monitoring the node
    erlang:monitor_node(WorkerNode,false),
    slave:stop(WorkerNode),
    
    %% All good
    ApplicationId=maps:get(application_id,DeploymentInfo),
    UpdatedDeploymentInfo=#{
			    application_id=>ApplicationId,
			    app=>na,
			    node=>na,
			    nodename=>na,
			    node_id=>na,
			    time=>na,
			    state=>scheduled
			   },

    UpdatedDeploymentInfoList=[UpdatedDeploymentInfo|lists:delete(DeploymentInfo,DeploymentInfoList)],
    
    {ok,UpdatedDeploymentInfoList}.


%%%===================================================================
%%% Internal functions
%%%===================================================================
