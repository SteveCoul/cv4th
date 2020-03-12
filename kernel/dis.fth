
ext-wordlist forth-wordlist internals 3 set-order definitions

: isconstantdef		\ head -- flag
  link>name count +	\ ptr
  dup c@ opDOLIT = if
	1+ cell+
	c@ opRET = 
  else
    dup c@ opDOLIT_U8 = if 
	  2 +
	  c@ opRET = 
    else
      drop false 
    then
  then
;

: opcodename 		\ value -- caddr u | -- 0
  internals begin	@ ?dup while					
    dup link>name	
    dup c@ 2 > if									
      dup 1+ c@ [char] o = if	
        dup	2 + c@ [char] p = if			
          over isconstantdef if			
            over link>xt execute		
              3 pick = if nip nip count exit then
            then
          then
        then
      then
    drop
  repeat drop 0
;

: dis-branch
  ." branch" dup 1+ w@ [char] [ emit over + 3 + .4 [char] ] emit 3 +
;

: (dis)		\ a-addr len --														
  base @ >r hex
  over + swap		\ end p --
  begin
    2dup u>
  while
    cr dup .8 ." : " 
\	dup c@ .2 space dup c@ aschar emit ."  | " 

	\ I ned to process anything here that has inline data, anything else can be in opcodename
  	dup c@ opSHORT_CALL =   if dup 1+ w@ >name ctype 3 +	else
	dup c@ opCALL = 	    if dup 1+ @ >name ctype 1+ cell+ else
	dup c@ opDOLIT = 	    if dup 1+ @ .N 1+ cell+ else
	dup c@ opDOLIT_U8 =     if dup 1+ c@ .2 2 + else
	dup c@ opRET = 		    if ." Ret" drop dup	else
	dup c@ opBRANCH = 		if dis-branch else
	dup c@ opQBRANCH = 		if [char] ? emit dis-branch else
	dup c@ opDOCSTR =		if [char] c emit [char] " emit space dup 1+ count type [char] " emit 1+ dup c@ 1+ + else
	dup c@ opcodename ?dup 	if type 1+ else
	dup c@ ." code " .N 1+ 
    then then then then then then then then then
  repeat
  2drop
  r> base !
;

' (dis) is dis

only forth definitions

