%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(controller_test).      
 
-export([start/0]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

 
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    ok=setup(),
    ok=init_test(),
    ok=start_test(),
    ok=stop_test(),
    ok=too_many(),
  %  ok=add_load_start_delete_stop_unload(),
  %  ok=check_monitoring(),
  %  ok=deploy_remove_normal(),

    io:format("Test OK !!! ~p~n",[?MODULE]),
  %  timer:sleep(1000),
  %  init:stop(),
    ok.


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------

too_many()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    {ok,_}=controller:load_start("adder.application"),
    {ok,_}=controller:load_start("adder.application"),
    {ok,_}=controller:load_start("adder.application"),
    {ok,_}=controller:load_start("divi.application"),
    {ok,_}=controller:load_start("divi.application"),
    42=rd:call(adder,add,[20,22],5000),
    42.0=rd:call(divi,divi,[420,10],5000),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    [
     {_,"adder.application"},
     {_,"adder.application"},
     {_,"adder.application"},
     {_,"divi.application"},
     {_,"divi.application"}
    ]=lists:sort(lib_reconciliate:active_applications()),
    []=lists:sort(lib_reconciliate:applications_to_start()),
    []=lists:sort(lib_reconciliate:applications_to_stop()),

    {ok,_}=controller:load_start("divi.application"),
    ok=controller:stop_unload("adder.application"),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    [
     {_,"adder.application"},
     {_,"adder.application"},
     {_,"divi.application"},
     {_,"divi.application"},
     {_,"divi.application"}
    ]=lists:sort(lib_reconciliate:active_applications()),
    ["adder.application"]=lists:sort(lib_reconciliate:applications_to_start()),
    [{_,"divi.application"}]=lists:sort(lib_reconciliate:applications_to_stop()),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    ok.
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------

init_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ["adder.application",
     "adder.application",
     "adder.application",
     "divi.application",
     "divi.application"
    ]=lists:sort(lib_reconciliate:wanted_applications()),
    [
     
    ]=lib_reconciliate:active_applications(),
     [
     "adder.application",
     "adder.application",
     "adder.application",
     "divi.application",
     "divi.application"
    ]=lists:sort(lib_reconciliate:applications_to_start()),
    []=lists:sort(lib_reconciliate:applications_to_stop()),
    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------

stop_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    42=rd:call(adder,add,[20,22],5000),
    [
     {_,"adder.application"},
     {_,"adder.application"}
    ]=lists:sort(lib_reconciliate:active_applications()),
     [
       "adder.application",
      "divi.application",
      "divi.application"
     ]=lists:sort(lib_reconciliate:applications_to_start()),
    []=lists:sort(lib_reconciliate:applications_to_stop()),
    
    ok=controller:stop_unload("adder.application"),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    42=rd:call(adder,add,[20,22],5000),
    ok=controller:stop_unload("adder.application"),
    [
    ]=lists:sort(lib_reconciliate:active_applications()),
     [
      "adder.application",
      "adder.application",
      "adder.application",
      "divi.application",
      "divi.application"
     ]=lists:sort(lib_reconciliate:applications_to_start()),
    []=lists:sort(lib_reconciliate:applications_to_stop()),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    {error,[eexists_resources]}=rd:call(adder,add,[20,22],5000),
  
    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------

start_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    controller:stop_unload("adder.application"),
    {ok,_}=controller:load_start("adder.application"),
    42=rd:call(adder,add,[20,22],5000),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    [
     {_,"adder.application"}
    ]=lists:sort(lib_reconciliate:active_applications()),
     [
      "adder.application",
      "adder.application",
      "divi.application",
      "divi.application"
     ]=lists:sort(lib_reconciliate:applications_to_start()),
    []=lists:sort(lib_reconciliate:applications_to_stop()),
    {ok,_}=controller:load_start("adder.application"),
    io:format("nodes() ~p~n",[{nodes(),?FUNCTION_NAME,?MODULE,?LINE}]),
    [
     {_,"adder.application"},
     {_,"adder.application"}
    ]=lists:sort(lib_reconciliate:active_applications()),
    [
     "adder.application",
     "divi.application",
     "divi.application"
    ]=lists:sort(lib_reconciliate:applications_to_start()),
    []=lists:sort(lib_reconciliate:applications_to_stop()),
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
add_load_start_delete_stop_unload()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    %% Empty system 
    []=controller:read_deployment_info(),
    {error,["Application doesnt exists ","adder"]}=controller:delete_application("adder"),
    
    %% Add "adder"
    ok=controller:add_application("adder"),

    %% Simulate reconciliation loop,
    [DeploymentInfo1]=[DeploymentInfo||DeploymentInfo<-controller:read_deployment_info(),
				       scheduled==maps:get(state,DeploymentInfo)],
    %% 1) Deploy application
    ApplicationId=maps:get(application_id,DeploymentInfo1),
    {ok,DeploymentInfo}=lib_controller:deploy_application(ApplicationId),
    42=rd:call(adder,adder,add,[20,22],5000),
    
    %% Delete adder 
    ok=controller:add_application("adder"),
    ok.
    
    

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
add_delete()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    %% Empty system 
    []=controller:read_deployment_info(),
     {error,["Application doesnt exists ","adder"]}=controller:delete_application("adder"),

    %% Add "adder"
    ok=controller:add_application("adder"),
    [AdderDeploy1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,AdderDeploy1),
    scheduled=maps:get(state,AdderDeploy1),
    ok=controller:delete_application("adder"),
    []=controller:read_deployment_info(),
    {error,["Application doesnt exists ","adder"]}=controller:delete_application("adder"),
    
    %% Add "adder" and "divi"
    ok=controller:add_application("adder"),
    ok=controller:add_application("divi"),
    [DiviDeploy1,AdderDeploy1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,AdderDeploy1),
    scheduled=maps:get(state,AdderDeploy1),
    "divi"=maps:get(application_id,DiviDeploy1),
    scheduled=maps:get(state,DiviDeploy1),
    ok=controller:delete_application("adder"),
    [DiviDeploy1]=controller:read_deployment_info(),
    ok=controller:delete_application("divi"),
    []=controller:read_deployment_info(),
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
check_monitoring()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    {error,[eexists_resources]}=rd:call(adder,adder,ping,[],5000),
    ok=controller:deploy_application("adder"),
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),
    
    ["adder"]=controller:read_wanted_state(),
    [AdderDeploy1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,AdderDeploy1),
    started=maps:get(state,AdderDeploy1),
    
    [{adder,Node}]=rd:fetch_resources(adder),
    rpc:call(Node,init,stop,[],5000),
    timer:sleep(2000),
    [UpdatedAdderDeploy1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,UpdatedAdderDeploy1),
    scheduled=maps:get(state,UpdatedAdderDeploy1),
    
    ["adder"]=controller:read_wanted_state(),
    ok=controller:remove_application("adder"),
    []=controller:read_wanted_state(),
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
deploy_remove_normal()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    
    {error,[eexists_resources]}=rd:call(adder,adder,ping,[],5000),
    ok=controller:deploy_application("adder"),
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),

    ["adder"]=controller:read_wanted_state(),
    [AdderDeploy1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,AdderDeploy1),
    started=maps:get(state,AdderDeploy1),
    

    %% Remove the only one
    ok=controller:remove_application("adder"),
    {error,[eexists_resources]}=rd:call(adder,adder,ping,[],5000),
    {error,[eexists_resources]}=rd:call(adder,adder,add,[20,22],5000),

    []=controller:read_wanted_state(),
    []=controller:read_deployment_info(),
    
    %% Add two 
    ok=controller:deploy_application("adder"),
    ok=controller:deploy_application("adder"),
    42=rd:call(adder,adder,add,[20,22],5000),
    ["adder","adder"]=controller:read_wanted_state(),
   
    [
     AdderDeploy2,
     AdderDeploy3
    ]=controller:read_deployment_info(),
    
    if
	AdderDeploy2==AdderDeploy3->
	    AdderDeploy2=crash;
	true->
	    ok
    end,
	
    "adder"=maps:get(application_id,AdderDeploy2),
    started=maps:get(state,AdderDeploy2),
    "adder"=maps:get(application_id,AdderDeploy3),
    started=maps:get(state,AdderDeploy3),
    

    %% Remove the  one
    ok=controller:remove_application("adder"),
    42=rd:call(adder,adder,add,[20,22],5000),
    ["adder"]=controller:read_wanted_state(),
    [
     AdderDeploy3
    ]=controller:read_deployment_info(),
    
  %% Remove the  last
    ok=controller:remove_application("adder"),
    {error,[eexists_resources]}=rd:call(adder,adder,add,[20,22],5000),
    []=controller:read_wanted_state(),
    []=controller:read_deployment_info(),
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    pong=controller:ping(),
    [rd:add_target_resource_type(TargetType)||TargetType<-[adder,divi]],
    rd:trade_resources(),
    timer:sleep(3000),
    ok.
