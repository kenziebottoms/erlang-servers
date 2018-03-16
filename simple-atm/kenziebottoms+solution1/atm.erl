-module(atm).

-export([start/0, stop/0, deposit/2]).

start() ->
    case whereis(atm) of
        undefined ->
            register(atm,spawn(fun init/0)),
            started;
        _ ->
            'Already there!'
    end.

stop() ->
    call(stop).

deposit(AccountNumber, Amount) ->
    call({deposit, AccountNumber, Amount}).

call(Message) ->
    case whereis(atm) of
        undefined ->
            atm_closed;
        _ ->
            atm ! {request, self(), Message},
            receive
                {reply, Reply} -> Reply
            end
    end.
    
init() ->
    Accounts = dict:new(),
    loop(Accounts).

loop(Accounts) ->
    receive
        {request, Pid, stop} ->
            io:format("Shutting down...~n"),
            reply(Pid, stopped);
        {request, Pid, {deposit, AccountNumber, Amount}} ->
            {NewAccounts, Reply} = deposit(Accounts, AccountNumber, Amount),
            reply(Pid, Reply),
            loop(NewAccounts)
    end.

deposit(Accounts, AccountNumber, Amount) ->
    OldTransactions = case dict:find(AccountNumber, Accounts) of
        {ok, Transactions} ->   %% if the account exists
            Transactions;
        error ->
            []                  %% if there is no established account
    end,
    NewTransactions = [Amount|OldTransactions],
    NewAccounts = [dict:store(AccountNumber, NewTransactions, Accounts)],
    {NewAccounts, {new_balance, lists:sum(NewTransactions)}}.            %% "returns" {NewAccounts, {...}}

reply(Pid, Reply) ->
    Pid ! {reply, Reply}.

%% atm:check_balance(AccountNumber) -> 
%%     {balance, Amount} | no_such_account | atm_closed

%% atm:withdraw(AccountNumber, Amount) -> 
%%     {new_balance, Amount} | overdrawn | no_such_account | atm_closed

%% atm:deposit(AccountNumber, Amount) -> 
%%     {new_balance, Amount} | atm_closed