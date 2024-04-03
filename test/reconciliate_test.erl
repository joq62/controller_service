%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%%  Testcase 
%%%  Normal: add - delete :  reconciliate_test
%%%  Nodedown 
%%%    
%%%  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(reconciliate_test).      
 
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
 %   ok=empty_test(),
 %   ok=simple_add_test(),
 %   ok=simple_delete_test(),

    %
    ok=multi_add_test(),
    ok=multi_delete_test(),
 %   ok=simple_delete_test(),
  %  ok=divi_test(),
  %  ok=add_load_start_delete_stop_unload(),
%    ok=check_monitoring(),
%    ok=deploy_remove_normal(),

    io:format("Test OK !!! ~p~n",[?MODULE]),
  %  timer:sleep(1000),
  %  init:stop(),
    ok.



%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
multi_add_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    %% start 3 adder ad 2 divi
    []=controller:read_deployment_info(),

    ok=controller:add_application("adder"),
    ok=controller:add_application("divi"),
    ok=controller:add_application("adder"),
    ok=controller:add_application("adder"),
    ok=controller:add_application("divi"),
    
    %% reconciliate

    ok=controller:reconciliate(),
    timer:sleep(3000),
    [NodeA1,NodeA2,NodeA3]=rd:fetch_resources(adder),
    [NodeD1,NodeD2]=rd:fetch_resources(divi),
 
    %% Test application access
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),

    pong=rd:call(divi,divi,ping,[],5000),
    42.0=rd:call(divi,divi,divi,[420,10],5000),

    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
multi_delete_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    
    5=erlang:length(controller:read_deployment_info()),
    5=erlang:length(nodes()),
    %% Test application access
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),
    pong=rd:call(divi,divi,ping,[],5000),
    42.0=rd:call(divi,divi,divi,[420,10],5000),

    %% delete 1 adder ad 1 divi
    ok=controller:delete_application("adder"),
    ok=controller:delete_application("divi"),
    ok=controller:reconciliate(),
    timer:sleep(2000),  
    
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),
    pong=rd:call(divi,divi,ping,[],5000),
    42.0=rd:call(divi,divi,divi,[420,10],5000),
    3=erlang:length(controller:read_deployment_info()),
    3=erlang:length(nodes()),

    %% delete 1 adder ad 1 divi
    ok=controller:delete_application("adder"),
    ok=controller:delete_application("divi"),
    timer:sleep(2000), 
    ok=controller:reconciliate(),
    timer:sleep(2000),  
   
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),
    {error,[eexists_resources]}=rd:call(divi,divi,ping,[],5000),
    {error,[eexists_resources]}=rd:call(divi,divi,divi,[420,10],5000),
    1=erlang:length(controller:read_deployment_info()),
    1=erlang:length(nodes()),
    %% delete last adder 

    ok=controller:delete_application("adder"),
    {error,["Application doesnt exists ","divi"]}=controller:delete_application("divi"),
    ok=controller:reconciliate(),
    timer:sleep(2000),  

    {error,[eexists_resources]}=rd:call(adder,adder,ping,[],5000),
    {error,[eexists_resources]}=rd:call(adder,adder,add,[20,22],5000),
    {error,[eexists_resources]}=rd:call(divi,divi,ping,[],5000),
    {error,[eexists_resources]}=rd:call(divi,divi,divi,[420,10],5000),
    0=erlang:length(controller:read_deployment_info()),
    0=erlang:length(nodes()),
   

    ok.



%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
simple_add_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    %% Adder1 but not started
    ok=controller:add_application("adder"),
    [DeploymentAdder_1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,DeploymentAdder_1),
    scheduled=maps:get(state,DeploymentAdder_1),
    {error,[eexists_resources]}=rd:call(adder,adder,add,[20,22],5000),

    %% Start DeploymentAdder_1
    ok=controller:reconciliate(),
    timer:sleep(3000),
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),

    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
simple_delete_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    %% check adder after reco
    [DeploymentAdder_1]=controller:read_deployment_info(),
    "adder"=maps:get(application_id,DeploymentAdder_1),
    started=maps:get(state,DeploymentAdder_1),
    pong=rd:call(adder,adder,ping,[],5000),
    42=rd:call(adder,adder,add,[20,22],5000),

    %% Delete DeploymentAdder_1
    ok=controller:delete_application("adder"),
    ok=controller:reconciliate(),
    timer:sleep(3000),
    []=controller:read_deployment_info(),
    {error,[eexists_resources]}=rd:call(adder,adder,add,[20,22],5000),
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
empty_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    []=controller:read_deployment_info(),
    ok=controller:reconciliate(),
    timer:sleep(3000),
    []=controller:read_deployment_info(),



    
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
