numberenc
=========
This module generalizes initial phone number encoding problem formulation in some aspects.  I didn't make
particular assumptions concerning phone mapping, insofar as symbol correctness is hard to validate without somewhat exhaustive search, but instead choose to explore pre-structured sample dictionary and, if needs be, to reconstruct it partially from phone code and then append. I consider it lexicographically sorted with unitary structure of phone-to-code correlative appendable relationship. 

One could imagine dictionary pattern in text file "dictionary.txt" as "Phone␣CodePhrase"  with space symbol as tokens delimiter and next line marker as signifier of the end of a dictionary line.

This way one could transform whole dictionary into a binary and then, after converting to list, snatch off the lines. 

A single key can be associated with a lot of values in dict-type KV-list. Splitting complexity is linear. 

Basic implementation of mapping-based encoding inspired by well-known LZW decompressing step, written with the goal of being compact, not necessary the best among existing implementations.  

If the string dictionary is of finite size, i.e. 75 000 entries maximum, it is possible that after some time, as Mark Nelson noted for C implementation in 1989, no more entries can be added. Also, later sections of the file may have different characteristics and, in fact, need slightly different comparison mechanism. One could monitor the encoding compression ratios in numerical experiments with time control. 

In the following code, I prefer tail recursion for search via comparison and insertion of keys. 

Running time is implementation-dependent, from O(N) to O(N log N). For the best case number of comparisons the algorithm must perform is about 2 ln N,  whilst height-balanced data structure is not so usual for appendable dictionary. Instead of use brutally balanced trees, we'll rely upon the dictionary quality. 

For testing purposes, I've created decoding function inspired by LZW compressing step.