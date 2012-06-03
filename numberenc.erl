-module(numberenc).

-include_lib("eunit/include/eunit.hrl"). 

-compile(export_all). 

-import(dict, [append/3, fetch/2, from_list/1, is_key/2, store/3]).

-import(file, [read_file/1, read_line/1]). 

-import(lists, [duplicate/2, map/2, reverse/1]).

-import(string, [tokens/2]). 

% We consider dictionary lexicographically sorted with unitary structure of phone-to-code correlative appendable relationship. 

main([PhoneNum]) -> 
  {ok, Bin} = read(PhoneNum),
  Phone = parse_map(Bin),
  io:format("~w: ~w ~n", [Phone, encodephone(Phone)]),
  erlang:halt(). 

read(File) -> 
  case file:read_line(File) of
        {ok, Data} -> [Data | read(File)];
        eof -> []
  end.
    
phone_map() ->
  Dictionary = "dictionary.txt", 
  {ok, Bin} = read(Dictionary),
  str2l(binary_to_list(Bin), []).
  
str2l("\n" ++ Str, Acc) -> [lists:reverse([$\n|Acc])|str2l(Str,[])];
str2l([H|T], Acc) -> str2l(T, [H|Acc]);
str2l([], Acc) -> [lists:reverse(Acc)].

% For large dictionaries, i. e. up to 75 000 entries, it could be better to parallelize the dictionary parsing. 

parse_map(Bin) when is_binary(Bin) -> 
    parse_map(binary_to_list(Bin));
parse_map(Str) when is_list(Str) -> 
    dict:from_list(multimap(fun split_keyvalue/1,[ T || T <- string:tokens(Str,"\n")])).
    
multimap(F, L) -> 
    S = self(), 
    R = erlang:make_ref(), 
    Pids = lists:map(fun(Q) -> 
			      spawn(fun() -> 
					      push_f(S, R, F, Q) 
					   end)
			  end, L),
    combine(Pids, R). 
    
push_f(Par, R, F, Q) -> 
    Par ! {self(), R, (catch F(Q))}. 
    
combine([Pid|T], R) -> 
    receive 
	{Pid, R, Return} -> [Return|combine(T, R)]
    end; 
combine([], _) -> []. 

split_keyvalue(Str) ->
  try  
      [K|V]=string:tokens(Str,"\s+"),
      L=length(V),
      lists:zip(V,lists:duplicate(L,list_to_atom(K)))
  catch 
    error:badarg -> 
      fail 
  end.

% Basic implementation of mapping-based encoding inspired by LZW decompressing step. 

encodephone(OldVal, [H|T], Dict) ->
    case dict:is_key([H|T], Dict) of 
      true -> 
	Compare = dict:fetch(H, Dict); 
      false -> 
	Compare = dict:fetch(T, Dict)
    end, 
  NewVal = OldVal ++ [hd(Compare)], 
  Compare ++ encodephone(Compare, T, dict:append([H], NewVal, Dict));
encodephone(_,[],_) -> [].  
  
encodephone([H|T]) -> 
    Map = phone_map(), 
    K = parse_map(Map),  
    [H] ++ encodephone([H], T, K).
    
% For testing purposes, we'll create decoding function inspired by LZW compressing step, with all assumptions aforementioned being true as well. 
    
decodephone(Enc, [H|T], Dict) -> 
  Enc1 = Enc ++ [H],
    case dict:is_key(Enc1, Dict) of
      true -> 
	decodephone(Enc1, T, Dict);
      false -> 
	KeySniffer = dict:fetch(Enc, Dict),
	[KeySniffer] ++ decodephone([H], T, dict:store(Enc1, [KeySniffer], Dict))
    end;
decodephone(Enc, [], Dict) -> 
    case dict:is_key(Enc, Dict) of 
      true -> 
	  [dict:fetch(Enc, Dict)];
      false -> 
	  {ok, Enc} 
      end. 
      
decodephone([H|T]) -> 
    Map = phone_map(),
    K = parse_map(Map), 
    decodephone([H], T, K). 
    
% Test-generating function. 

numberenc_test_([PhoneNum]) -> 
  {ok, Bin} = read(PhoneNum),
  Phone = parse_map(Bin),
  ?_assertEqual(Phone, decodephone(encodephone(Phone))). 