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

: locate xpos @ 3 + ypos @ 3 + at-xy ;

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
    0 i at-xy 
	i 3 - 0 16 within if i 3 - 2 .r else 2 spaces then
	[char] | emit
    width 3 + i at-xy [char] | emit
  loop
;

: drawstatus
  3 height 3 + at-xy hline
  color_status
  3 height 4 + at-xy status-buffer count dup >r type width r> - spaces
  3 height 5 + at-xy hline
  locate
;

: drawtitle 
  3 0 at-xy hline
  3 1 at-xy
  current_block @ 0 <# bl hold #s s" block " holds #> 
  width over - 2 / dup >r spaces
  color_title
  dup >r type
  width r> - r> - spaces
  3 2 at-xy hline locate
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
  1024 0 do ^buffer @ i + c@ 0= if bl ^buffer @ i + c! then loop
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

: fill-line		\ index char --
  swap
  width * ^buffer @ + width rot fill
;

: split-line
  ^buffer @ ypos @ width * + xpos @ +
  ^buffer @ ypos @ 1+ width * +
  width xpos @ -
  move
  ^buffer @ ypos @ width * + xpos @ + width xpos @ - bl fill
;

: copy-line-down		\ idx --
  height @ 1- over = if drop exit then
  width * ^buffer @ + dup width + width cmove>
;

: copy-line-up			\ idx --
  ?dup if
	width * ^buffer @ +
	dup width -
	width move
  then
;

: remove-line			\ idx --
  dup height 1- = if drop else
	height swap 1+ ?do
	  i copy-line-up
	loop
  then
  height 1- bl fill-line
;

: insert-line-after		\ idx --
  dup height 1- = if drop exit then
  dup height 2 - <> if
 	 dup height 2 - ?do
		i copy-line-down
  	-1 +loop
  then
  1+ bl fill-line
;

: line-is-blank?		\ idx -- flag
  width * ^buffer @ +
  width 0 ?do
	dup i + c@ bl <> if drop false unloop exit then
  loop
  drop true
;

: find-blank-line-before \ idx -- position | -1
  0 ?do
	i line-is-blank? if i unloop exit then
  loop
  -1
;

: find-blank-line-after	\ idx -- position | -1
  1+ height 1- 
  ?do
    i line-is-blank? if i unloop exit then
  -1 +loop
  -1
;

: last-line-blank?		\ -- flag
  height 1- line-is-blank?
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
	ypos @ height 1- <> last-line-blank? and if
		ypos @ insert-line-after
		split-line
		1 ypos +!
		0 xpos !
		drawblock
	else
		ypos @ find-blank-line-after dup 0 < if
			drop 
			ypos @ find-blank-line-before dup 0< if
				drop beep
			else
				remove-line -1 ypos +!
				ypos @ insert-line-after
				split-line
				1 ypos +!
				0 xpos !
				drawblock
			then
		else
			remove-line
			ypos @ insert-line-after
			split-line
			1 ypos +!
			0 xpos !
			drawblock
		then
	then
  else
	at-eol? if
	  lastcharonline bl = if
	    r@ replace_cur_char drawblock
	  else
	    beep
	  then
	else
	  lastcharonline bl = if
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
		lastline 1+ c@ [char] w = if
			update save-buffers
			new-status s" saved" >status drawstatus
		else
			new-status s" unknown command" >status drawstatus
		then
	then
	mode @ mode_quit <> if
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

: d console_clear drawtitle drawedges drawblock drawstatus 0 25 at-xy ;

\ widEditor set-current

: vi
  1 ['] runeditor catch 
  save-buffers
  color_text 
  0 25 at-xy console_clear
  throw ;

\ forth-wordlist set-current

: editor get-order widEditor swap 1+ set-order ;

\ only forth definitions
here pad @ - cr .( Editor took ) . .(  bytes ) cr

