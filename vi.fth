here pad !
\ get-order internals swap 1 + set-order definitions
wordlist constant widEditor
\ get-order widEditor swap 1 + set-order definitions
wordlist constant widEditorInternals
\ get-order widEditorInternals swap 1+ set-order definitions

64 constant	width
16 constant height

variable current_block

variable ^buffer

variable	xpos
variable	ypos

0 constant mode_quit
1 constant mode_command
2 constant mode_lastline
3 constant mode_insert

variable	mode
64 buffer:  lastline

: beep 7 emit ;
: esc 27 emit [char] [ emit ;
: console_clear	esc ." 2J" ;
: color_text	esc ." 39m" ;
: color_border	esc ." 31m" ;
: color_title	esc ." 32m" ;
: color_status	esc ." 33m" ;
: hline color_border width begin ?dup while [char] - emit 1- repeat ;

: locate xpos @ 1 + ypos @ 3 + at-xy ;

width 1+ buffer: status-buffer
0 status-buffer c!

: >status
  status-buffer count +		\ c-addr u dest
  rot swap 2 pick			\ u c-addr dest u
  move
  status-buffer c@ + status-buffer c!
;

: n>status
  0 <# #s #> >status
;

: new-status
  0 status-buffer c!
;

: drawedges
  color_border
  height 6 + 0 ?do
    0 i at-xy [char] | emit
    width 1+ i at-xy [char] | emit
  loop
;

: drawstatus
  1 height 3 + at-xy hline
  color_status
  1 height 4 + at-xy status-buffer count dup >r type width r> - spaces
  1 height 5 + at-xy hline
  locate
;

: drawtitle 
  1 0 at-xy hline
  1 1 at-xy
  current_block @ 0 <# bl hold #s s" block " holds #> 
  width over - 2 / dup >r spaces
  color_title
  dup >r type
  width r> - r> - spaces
  1 2 at-xy hline locate
;  

: drawblock
  color_text
  xpos @ >r ypos @ >r 0 xpos !
  height 0 ?do
    i ypos ! locate
	width 0 ?do
	  ^buffer @ j width * + i + c@ emit
	loop
  loop	
  r> ypos ! 
  r> xpos !
  locate
;

: at-eol?
  xpos @ width 1- =
;

: replace_cur_char \ key --
  ^buffer @ ypos @ width * + xpos @ + c!
;

: lastcharonline \ -- c
  ^buffer @ ypos @ width * + width 1- + c@
;

: get_rest_current_line	\ -- c-addr u
  ^buffer @ ypos @ width * + xpos @ +
  width xpos @ -
;

: delete_current_char
  ^buffer @ ypos @ width * + xpos @ + 
  dup 1+ swap
  width xpos @ - move
  bl ^buffer @ ypos @ width * + width 1 - + c!
;

: cursor_left   xpos @ 0 > if -1 xpos +! then locate ;
: cursor_right	xpos @ width 1- < if 1 xpos +! then locate ;
: cursor_up		ypos @ 0> if -1 ypos +! then locate ;
: cursor_down	ypos @ height 1- < if 1 ypos +! then locate ;

: switch_block
  current_block !
  current_block @ block ^buffer !
  \ not sure about this - might be better if 0 counted as white space in the interpreter
  \ otherwise - this will update non-source (binary) blocks if I just view them
  1024 0 do ^buffer @ i + c@ 0= if bl ^buffer @ i + c! update then loop
  drawtitle
  drawblock
  drawstatus
;

: prevblock
  current_block @ 1 = if 7 emit else 
	current_block @ 1 - switch_block
  then
;

: nextblock
  current_block @ 65535 = if 7 emit else 
	current_block @ 1 + switch_block
  then
;

: command_key	\ key --
  case
  27 of endof	\ already in command mode
  4 of nextblock endof
  21 of prevblock endof
  k-up of cursor_up endof
  k-down of cursor_down endof
  k-left of cursor_left endof
  k-right of cursor_right endof
  [char] h of cursor_left endof
  [char] l of cursor_right endof
  [char] j of cursor_down endof
  [char] 10 of cursor_down endof
  [char] k of cursor_up endof
  [char] 11 of cursor_up endof
  [char] : of mode_lastline mode ! new-status s" :" >status drawstatus 0 lastline c! endof
  [char] x of delete_current_char drawblock endof
  [char] i of mode_insert mode !  new-status s" -- INSERT --" >status drawstatus endof
  new-status s" Unhandled command key " >status dup n>status drawstatus beep
  endcase
;

: fill-line
  width * ^buffer @ + width bl fill
;

: splitline
  ^buffer @ ypos @ 2 + width * +
  dup width +
  width height *
  ypos @ 2 + width * -
  cmove>
  

  ypos @ 1+ fill-line
  ^buffer @ ypos @ width * + xpos @ +
  ^buffer @ ypos @ 1+ width * +
  width xpos @ -
  cmove>
  ^buffer @ ypos @ width * + xpos @ + width xpos @ - bl fill
  0 xpos !
  1 ypos +!
;

: set-last-line-empty
  height 1- fill-line
;

: remove-line	 \ i --
  dup height 1- = if	\ don't need to remove the actual last line, just overwrite it
	drop
  else
	dup width * ^buffer @ +
	dup width + swap			\ i buffer+line buffer --
	rot 1+ height swap - width *
	cmove>
  then
  set-last-line-empty
;

: is-line-blank?	\ line# -- flag
  ^buffer @ 
  swap width * +
  width 0 do dup i + c@ bl <> if unloop drop false exit then loop
  drop
  true
;

: remove-any-blank-line-after? \ i -- flag
  cr ." remove any blank line after " dup .
  height 1-
  begin
    2dup <>
  while
	dup is-line-blank? if
		cr ." line " dup . ." looks blank"
		nip remove-line true exit
	then
	1-
  repeat
  2drop
;

: last-line-is-blank?
  height 1- is-line-blank?
;

: insert_key	\ key --
  >r
  r@ k-up = if 
	cursor_up 
  else r@ k-down = if 
	cursor_down
  else r@ k-left = if 
	cursor_left
  else r@ k-right = if  
    cursor_right 
  else r@ 27 = if
	mode_command mode ! new-status drawstatus 
  else r@ 127 = if
	xpos @ 0= if
		beep
	else
		cursor_left
		delete_current_char
		drawblock
	then
  else r@ 10 = if
	color_text 0 25 at-xy 20 0 ?do 0 25 i + at-xy 100 spaces loop 0 25 at-xy
	ypos @ height 1- = if
		beep
	else
		last-line-is-blank? if
			cr ." last line is blank"
			splitline
		else
			ypos @ remove-any-blank-line-after? if
				splitline
			else
				beep
			then
		then
		locate
		drawblock
	then
  else
	at-eol? if
	  lastcharonline bl = if
	    r@ replace_cur_char drawblock
	  else
	    beep
	  then
	else
	  get_rest_current_line + 1- c@ bl = if
		get_rest_current_line over 1+ swap 1- cmove>
		r@ replace_cur_char cursor_right drawblock
	  else
		beep
	  then
	then
  then then then then then then then
  r> drop
;

: lastline_key \ key --
  case
  27 of
	mode_command mode !
	new-status drawstatus
    endof
  10 of
    lastline 1+ c@ [char] q = if
		new-status s" QUIT" >status drawstatus
		mode_quit mode !
	else
		new-status s" unknown command" >status drawstatus
		mode_command mode !
		0 lastline c!
	then
	endof
  \ default 
    dup lastline count + c!
    lastline c@ 1+ lastline c!
    new-status s" :" >status lastline count >status drawstatus
  endcase
;

: runeditor
  mode_command mode !
  0 current_block !
  0 xpos !
  0 ypos !
  new-status
  console_clear
  drawedges

  switch_block

  begin
    mode @ mode_quit <>
  while
    ekey 
	mode @
	case
	mode_command of swap command_key endof
	mode_lastline of swap lastline_key endof
	mode_insert of swap insert_key endof
	nip	\ unknown mode, lose key
    new-status s" unknown mode, " >status dup n>status s" , drop key" >status drawstatus
	endcase
  repeat
;

\ widEditor set-current

: vi
  1 ['] runeditor catch 
  save-buffers
  color_text 
  console_clear
  throw ;

\ forth-wordlist set-current

: editor get-order widEditor swap 1+ set-order ;

\ only forth definitions
here pad @ - cr .( Editor took ) . .(  bytes ) cr

