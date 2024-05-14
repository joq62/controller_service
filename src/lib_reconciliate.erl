%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2024, c50
%%% @doc
%%%
%%% @end
%%% Created : 11 Jan 2024 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_reconciliate).
   
-include("controller.hrl").
-include("log.api").
 
  
%% API
-export([
	 start/0
	]).

-export([
	 wanted_applications/0,
	 active_applications/0,
	 applications_to_start/0,
	 applications_to_stop/0

	]).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% Creates a new workernode , load and start infra services (log and resource discovery)
%% and  the wanted application ApplicationId
%% @end
%%--------------------------------------------------------------------
start()->
 %   io:format(" START Reconcilaition ******************** ~p~n",[{?ReconciliationInterval,?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(?ReconciliationInterval),
    ApplicationFileNamesToStart=applications_to_start(),
    start_applications(ApplicationFileNamesToStart),
    ApplicationFileNamesToStop=applications_to_stop(),
    stop_applications(ApplicationFileNamesToStop),
  %  io:format(" END Reconcilaition ========================== ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
  %  rpc:cast(node(),controller,reconciliate,[])
    rpc:cast(node(),controller,reconciliate,[ApplicationFileNamesToStart,ApplicationFileNamesToStop]).
   

start_applications([])->
    ok;
start_applications([ApplicationFileName|T])->
    case rpc:call(node(),lib_controller,load_start,[ApplicationFileName],6*10000) of
	{ok,DeploymentInfo}->
	    WorkerNode=maps:get(node,DeploymentInfo),
	    ?LOG2_NOTICE("Application started on node",[ApplicationFileName,WorkerNode]),
	    ?LOG_NOTICE("Application started on node",[ApplicationFileName,WorkerNode]),
	    ok;
	ErrorEvent->
	    ?LOG2_WARNING("Failed to start Application",[ApplicationFileName,ErrorEvent]),
	    ?LOG_WARNING("Failed to start Application",[ApplicationFileName,ErrorEvent])
    end,
    timer:sleep(1000),
    start_applications(T).

stop_applications([])->
    ok;
stop_applications([{WorkerNode,ApplicationFileName}|T])->
    lib_controller:stop_unload(WorkerNode,ApplicationFileName),
    ?LOG2_NOTICE("Application stopped",[ApplicationFileName]),
    ?LOG_NOTICE("Application stopped",[ApplicationFileName]),
    timer:sleep(1000),
    stop_applications(T).
  
%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
applications_to_stop()->
    WantedApplications=wanted_applications(),
    ActiveApplications=active_applications(),
    applications_to_stop(WantedApplications,ActiveApplications).

applications_to_stop([],[])->
    [];
applications_to_stop(_WantedApplications,[])->
    [];
applications_to_stop([],ActiveApplications)->
    ActiveApplications;
applications_to_stop([WantedApplicationFile|T],ActiveApplications)->
    case lists:keyfind(WantedApplicationFile,2,ActiveApplications) of
	{WorkerNode,FileName}->
	    NewActiveApplications=lists:delete({WorkerNode,FileName},ActiveApplications);
	false ->
	    NewActiveApplications=ActiveApplications
    end,
    applications_to_stop(T,NewActiveApplications).


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
applications_to_start()->
    WantedApplications=wanted_applications(),
    ActiveApplications=active_applications(),
    applications_to_start(WantedApplications,ActiveApplications).

applications_to_start(WantedApplications,ActiveApplications)->
    applications_to_start(WantedApplications,ActiveApplications,[]).

applications_to_start([],_ActiveApplications,Acc)->
    Acc;
applications_to_start([WantedApplicationFile|T],ActiveApplications,Acc)->
    case lists:keyfind(WantedApplicationFile,2,ActiveApplications) of
	{WorkerNode,FileName}->
	    NewActiveApplications=lists:delete(	{WorkerNode,FileName},ActiveApplications),
	    NewAcc=Acc;
	false ->
	    NewActiveApplications=ActiveApplications,
	    NewAcc=[WantedApplicationFile|Acc]
    end,
    applications_to_start(T,NewActiveApplications,NewAcc).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
wanted_applications()->
    {ok,FileNames}=deployment:all_filenames(),
    get_wanted_applications(FileNames).

get_wanted_applications(FileNames)->
    get_wanted_applications(FileNames,[]).

get_wanted_applications([],Acc)->
    Acc;
get_wanted_applications([FileName|T],Acc)->
    {ok,[Map]}=deployment:read_file(FileName),
    {ok,HostName}=net:gethostname(),
    R=[ApplicationFileName||{ApplicationFileName,WantedHostName}<-maps:get(deployments,Map),
		      HostName==WantedHostName],
    NewAcc=lists:append(R,Acc),
    get_wanted_applications(T,NewAcc).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
active_applications()->
    ActiveNodes=get_active_workers(),
    AllApps=all_apps(),
    node_filenames(ActiveNodes,AllApps).
    
node_filenames(ActiveNodes,AllApps)->   
    node_filenames(ActiveNodes,AllApps,[]).
node_filenames([],_AllApps,Acc)->
    Acc;
node_filenames([WorkerNode|T],AllApps,Acc)->
    ApplicationInfo=rpc:call(WorkerNode,application,which_applications,[],5000),
    NodeFileNames=check_apps(ApplicationInfo,WorkerNode,AllApps),
    NewAcc=lists:append(NodeFileNames,Acc),
    node_filenames(T,AllApps,NewAcc).


check_apps(ApplicationInfo,WorkerNode,AllApps)->
    check_apps(ApplicationInfo,WorkerNode,AllApps,[]).
check_apps([],_,_,Acc)->
    Acc;
check_apps({badrpc,nodedown},_,_,Acc)->
    Acc;
check_apps([{App,_,_}|T],WorkerNode,AllApps,Acc)->
    NewAcc=case lists:member(App,AllApps) of
	       false->
		   Acc;
	       true ->
		   {ok,FileName}=catalog:which_filename(App),
		   [{WorkerNode,FileName}|Acc]
	   end,
    check_apps(T,WorkerNode,AllApps,NewAcc).
				
all_apps()->
    {ok,FileNames}=catalog:all_filenames(),
    all_apps(FileNames).
all_apps(FileNames)->
    all_apps(FileNames,[]).		
all_apps([],Acc)->	   
    Acc;
all_apps([FileName|T],Acc) ->
    NewAcc=case lists:member(FileName,?InfraApplicationFileNames) of
	       false->
		   {ok,[Map]}=catalog:read_file(FileName),
		   App=maps:get(app,Map),
		   [App|Acc];
	       true->
		   Acc
	   end,
    all_apps(T,NewAcc).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_active_workers()->
    {ok,ThisHostName}=net:gethostname(),
    ActiveWorkerNodesOnThisHost=[Node||Node<-[node()|nodes()],
				 {ok,ThisHostName}==rpc:call(Node,net,gethostname,[],5000)],
    ActiveWorkerNodesOnThisHost.



