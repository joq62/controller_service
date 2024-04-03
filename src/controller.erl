%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%% 
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(controller). 
 
-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").

-include("controller.hrl").
-include("controller.rd").

-include("specs.hrl").




%% API
-export([
	 reconciliate/0,
	 load_start/1,
	 stop_unload/1,
	 
	 add_application/1,
	 delete_application/1
	]).

%% OaM 
-export([


	]).

%% admin

-export([
	 start/0,
	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).
	

-record(state, {
	
	       }).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% This a loop that starts after the interval ReconcilationInterval 
%% The loop checks what to start or stop 
%% 
%% @end
%%--------------------------------------------------------------------
-spec reconciliate() -> 
	  ok .
reconciliate() ->
    gen_server:cast(?SERVER,{reconciliate}).

%%--------------------------------------------------------------------
%% @doc
%% Add application with ApplicationId to be deployed 
%% 
%% @end
%%--------------------------------------------------------------------
-spec load_start(ApplicationFileName::string()) -> 
	  {ok,Map::map()} | {error, Error :: term()}.
load_start(ApplicationFileName) ->
    gen_server:call(?SERVER,{load_start,ApplicationFileName},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Add application with ApplicationId to be deployed 
%% 
%% @end
%%--------------------------------------------------------------------
-spec stop_unload(ApplicationFileName::string()) -> 
	  ok | {error, Error :: term()}.
stop_unload(ApplicationFileName) ->
    gen_server:call(?SERVER,{stop_unload,ApplicationFileName},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Add application with ApplicationId to be deployed 
%% 
%% @end
%%--------------------------------------------------------------------
-spec add_application(ApplicationId::string()) -> 
	  ok | {error, Error :: term()}.
add_application(ApplicationId) ->
    gen_server:call(?SERVER,{add_application,ApplicationId},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Delete application ApplicationId from the deployment list 
%% 
%% @end
%%--------------------------------------------------------------------
-spec delete_application(ApplicationId::string()) -> 
	  ok | {error, Error :: term()}.
delete_application(ApplicationId) ->
    gen_server:call(?SERVER,{delete_application,ApplicationId},infinity).


%%--------------------------------------------------------------------
%% @doc
%%  
%% 
%% @end
%%--------------------------------------------------------------------
start()->
    application:start(?MODULE).


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong | Error::term().
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%stop()-> gen_server:cast(?SERVER, {stop}).
stop()-> gen_server:stop(?SERVER).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    
    {ok, #state{
	   
	    
	   },0}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.


handle_call({load_start,ApplicationFileName}, _From, State) ->
  %  io:format(" ~p~n",[{?FUNCTION_NAME,?MODULE,?LINE}]),
    Result=try lib_controller:load_start(ApplicationFileName) of
	       {ok,R}->
		   {ok,R};
	       {error,Reason}->
		   {error,Reason}
	   catch
	       Event:Reason:Stacktrace ->
		   {Event,Reason,Stacktrace,?MODULE,?LINE}
	   end,
    Reply=case Result of
	      {ok,DeploymentInfo}->
		   {ok,DeploymentInfo};
	      ErrorEvent->
		  io:format("ErrorEvent ~p~n",[{ErrorEvent,?MODULE,?LINE}]),
		  ErrorEvent
	  end,
    {reply, Reply, State};

handle_call({stop_unload,ApplicationFileName}, _From, State) ->
  %  io:format(" ~p~n",[{?FUNCTION_NAME,?MODULE,?LINE}]),
    Result=try lib_controller:stop_unload(ApplicationFileName) of
	       ok->
		   ok;
	       {error,Reason}->
		   {error,Reason}
	   catch
	       Event:Reason:Stacktrace ->
		   {Event,Reason,Stacktrace,?MODULE,?LINE}
	   end,
    Reply=case Result of
	      ok->
		  ok;
	      ErrorEvent->
		  io:format("ErrorEvent ~p~n",[{ErrorEvent,?MODULE,?LINE}]),
		  ErrorEvent
	  end,
    {reply, Reply, State};

handle_call({read_state}, _From, State) ->
    Reply=State,
    {reply, Reply, State};

handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call(UnMatchedSignal, From, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------


handle_cast({reconciliate}, State) ->
    spawn(fun()->lib_reconciliate:start() end),
    {noreply, State};

handle_cast({stop}, State) ->
    
    {stop,normal,ok,State};

handle_cast(UnMatchedSignal, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.

handle_info({nodedown,Node}, State) ->
    ?LOG_WARNING("nodedown,Node ",[Node]),
    
    {noreply, State};


handle_info(timeout, State) ->
    
    initial_trade_resources(),
    spawn(fun()->lib_reconciliate:start() end),
    ?LOG_NOTICE("Server started ",[?MODULE]),
    {noreply, State};


handle_info(Info, State) ->
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
initial_trade_resources()->
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-?LocalResourceTuples],
    [rd:add_target_resource_type(TargetType)||TargetType<-?TargetTypes],
    rd:trade_resources(),
    timer:sleep(3000),
    ok.
