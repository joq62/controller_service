%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Test crashes and recovery 
%%% 1.1 Node crash -> application shall be restarted
%%% 1.2 Node crashes -> application shall not be started
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(destructive_test).      
 
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
    ok=node_crash1(),
    ok=node_crash2(),
    ok=application_crash(),

  %  ok=add_delete(),
  %  ok=add_load_start_delete_stop_unload(),
%    ok=check_monitoring(),
%    ok=deploy_remove_normal(),

    io:format("Test OK !!! ~p~n",[?MODULE]),
  %  timer:sleep(1000),
  %  init:stop(),
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: 
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

    

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
node_crash1()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    %% Empty system 
    []=controller:read_deployment_info(),
    
    %% Add "adder"
    ok=controller:add_application("adder"),
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    [{adder,A1}]=rd:fetch_resources(adder),
    42=rpc:call(A1,adder,add,[20,22],5000),
    [started]=[maps:get(state,M)||M<-controller:read_deployment_info()],
    %% Kill node
    rpc:call(A1,init,stop,[],5000),
    timer:sleep(2000),
    {badrpc,_}=rpc:call(A1,adder,add,[20,22],5000),
    [scheduled]=[maps:get(state,M)||M<-controller:read_deployment_info()],

    %%  check restarted
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    [{adder,A2}]=rd:fetch_resources(adder),
    42=rpc:call(A2,adder,add,[20,22],5000),
    [started]=[maps:get(state,M)||M<-controller:read_deployment_info()],

    %% check deleted 
    ok=controller:delete_application("adder"),
    [delete]=[maps:get(state,M)||M<-controller:read_deployment_info()],
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    []=controller:read_deployment_info(),
    
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
node_crash2()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    %% Empty system 
    []=controller:read_deployment_info(),
    
    %% Add 2* "adder" +  divi
    ok=controller:add_application("adder"),
    ok=controller:add_application("divi"),
    ok=controller:add_application("adder"),
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    [{adder,A1},{adder,A2}]=rd:fetch_resources(adder),
    42=rpc:call(A1,adder,add,[20,22],5000),  
    42=rpc:call(A2,adder,add,[20,22],5000),  
    [{divi,D1}]=rd:fetch_resources(divi),
    42.0=rpc:call(D1,divi,divi,[420,10],5000),
    [started,started,started]=[maps:get(state,M)||M<-controller:read_deployment_info()],
    %% Kill node
    rpc:call(A1,init,stop,[],5000),
    rpc:call(D1,init,stop,[],5000),
    timer:sleep(2000),
    {badrpc,_}=rpc:call(A1,adder,add,[20,22],5000),
    {badrpc,_}=rpc:call(D1,divi,divi,[420,10],5000),
    [scheduled,scheduled,started]=[maps:get(state,M)||M<-controller:read_deployment_info()],

    %%  check restarted
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    [{adder,A2},{adder,A3}]=rd:fetch_resources(adder),
    42=rpc:call(A2,adder,add,[20,22],5000),  
    42=rpc:call(A3,adder,add,[20,22],5000),  
    [{divi,D2}]=rd:fetch_resources(divi),
    42.0=rpc:call(D2,divi,divi,[420,10],5000),
    [started,started,started]=[maps:get(state,M)||M<-controller:read_deployment_info()],

    %% check deleted 
    ok=controller:delete_application("adder"),
    ok=controller:delete_application("adder"),
    ok=controller:delete_application("divi"),
    [delete,delete,delete]=[maps:get(state,M)||M<-controller:read_deployment_info()],
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    []=controller:read_deployment_info(),
    
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
application_crash()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
 %% Empty system 
    []=controller:read_deployment_info(),
    
    %% Add "adder"
    ok=controller:add_application("adder"),
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    [{adder,A1}]=rd:fetch_resources(adder),
    42=rpc:call(A1,adder,add,[20,22],5000),
    [started]=[maps:get(state,M)||M<-controller:read_deployment_info()],
    %% Kill application

    {badrpc,_}=rpc:call(A1,adder,kill,[],5000),
    {badrpc,_}=rpc:call(A1,adder,add,[20,22],5000),
    timer:sleep(2000),
    [scheduled]=[maps:get(state,M)||M<-controller:read_deployment_info()],

    %%  check restarted
    ok=controller:reconciliate(),
    timer:sleep(3000), 
    [{adder,A2}]=rd:fetch_resources(adder),
    42=rpc:call(A2,adder,add,[20,22],5000),
    [started]=[maps:get(state,M)||M<-controller:read_deployment_info()],

    %% check deleted 
    ok=controller:delete_application("adder"),
    [delete]=[maps:get(state,M)||M<-controller:read_deployment_info()],
    ok=controller:reconciliate(),
    timer:sleep(3000), 
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
