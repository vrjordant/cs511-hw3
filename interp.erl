-module(interp).
-export([scanAndParse/1,runFile/1,runStr/1]).
-include("types.hrl").

loop(InFile,Acc) ->
    case io:request(InFile,{get_until,prompt,lexer,token,[1]}) of
        {ok,Token,_EndLine} ->
            loop(InFile,Acc ++ [Token]);
        {error,token} ->
            exit(scanning_error);
        {eof,_} ->
            Acc
    end.

scanAndParse(FileName) ->
    {ok, InFile} = file:open(FileName, [read]),
    Acc = loop(InFile,[]),
    file:close(InFile),
    {Result, AST} = parser:parse(Acc),
    case Result of 
	ok -> AST;
	_ -> io:format("Parse error~n")
    end.


-spec runFile(string()) -> valType().
runFile(FileName) ->
    valueOf(scanAndParse(FileName),env:new()).

scanAndParseString(String) ->
    {_ResultL, TKs, _L} = lexer:string(String),
    parser:parse(TKs).

-spec runStr(string()) -> valType().
runStr(String) ->
    {Result, AST} = scanAndParseString(String),
    case Result  of 
    	ok -> valueOf(AST,env:new());
    	_ -> io:format("Parse error~n")
    end.


-spec numVal2Num(numValType()) -> integer().
numVal2Num({num, N}) ->
    N.

-spec boolVal2Bool(boolValType()) -> boolean().
boolVal2Bool({bool, B}) ->
    B.

-spec valueOf(expType(),envType()) -> valType().
valueOf(Exp,Env) ->
    case Exp of 
        %{num, Val} -> {num, Val};
        %{bool, Val} -> {bool, Val};
        {numExp, {num, _, Val}} -> 
            {num, Val};
        {idExp ,{id , _, Val}} -> 
            env:lookup(Env,Val);
        {plusExp, Exp1, Exp2} -> 
            {num, numVal2Num(valueOf(Exp1,Env)) + numVal2Num(valueOf(Exp2,Env))};
        {diffExp, Exp1, Exp2} -> 
            {num, numVal2Num(valueOf(Exp1,Env)) - numVal2Num(valueOf(Exp2,Env))};
        {isZeroExp, NewExp} -> 
            {bool, numVal2Num(valueOf(NewExp,Env)) == 0};
        {ifThenElseExp, Exp1, Exp2, Exp3} -> 
            case boolVal2Bool(valueOf(Exp1,Env)) of
                true -> 
                    valueOf(Exp2,Env);
                false ->
                    valueOf(Exp3,Env)
            end
    end.
             

