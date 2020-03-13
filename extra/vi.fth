get-order internals swap 1 + set-order definitions
wordlist constant widEditor
get-order widEditor swap 1 + set-order definitions
wordlist constant widEditorInternals
get-order widEditorInternals swap 1+ set-order definitions

64 constant	width
16 constant height

variable current_block

variable ^buffer

variable	xpos
variable	ypos

variable	visual_start
variable	visual_end

variable	mode
0 constant mode_quit
1 constant mode_command
2 constant mode_lastline
3 constant mode_insert
4 constant mode_visual
5 constant mode_visual_line

defer enter_command_mode

\ -------------------------------------------------------------------------------------
\ 
\ General 
\
\ -------------------------------------------------------------------------------------

: minmax			\ a b -- min max
  2dup > if swap then
;

: firstchar			\ c-addr u -- c-addr u char
  dup 0= if -1 else
  over c@ then
;

: lastchar			\ c-addr u -- c-addr u char
  dup 0= if -1 else
  2dup 1- + c@ then
;

: strip				\ c-addr u --
  begin
	firstchar bl =
  while
    1 - swap 1 + swap
  repeat
  begin
    lastchar bl =
  while
    1-
  repeat
;

\ -------------------------------------------------------------------------------------
\ 
\ -------------------------------------------------------------------------------------

: beep 7 emit ;
: esc 27 emit [char] [ emit ;
: console_clear	esc ." 2J" ;
: color_text	esc ." 0m";
: color_itext	esc ." 39;49m" esc ." 7m" ;
: color_border	esc ." 31;49m" ;
: color_title	esc ." 32;49m" ;
: color_status	esc ." 33;49m" ;
: hline color_border width begin ?dup while [char] - emit 1- repeat ;
: locate xpos @ 3 + ypos @ 3 + at-xy ;
: hide esc ." ?25l" ;
: show esc ." ?25h" ;

\ -------------------------------------------------------------------------------------
\
\ -------------------------------------------------------------------------------------

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

\ -------------------------------------------------------------------------------------
\ 
\ -------------------------------------------------------------------------------------

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

: drawstatus
  3 height 3 + at-xy hline
  color_status
  3 height 4 + at-xy status-buffer count dup >r type width r> - spaces
  3 height 5 + at-xy hline
  locate
;

\ -------------------------------------------------------------------------------------
\
\ -------------------------------------------------------------------------------------

: drawedges
  color_border
  height 6 + 0 ?do
    0 i at-xy 
	i 3 - 0 16 within if i 3 - 2 .r else 2 spaces then
	[char] | emit
    width 3 + i at-xy [char] | emit
  loop
;

\ -------------------------------------------------------------------------------------
\
\ -------------------------------------------------------------------------------------

: drawblock
  hide
  xpos @ >r ypos @ >r 0 xpos !
  ^buffer @
  height 0 ?do
    i ypos ! locate
	width 0 ?do
	  dup visual_start @ visual_end @ 1+ within if color_itext else color_text then
	  dup c@ emit 1+
	loop
  loop	
  drop
  r> ypos ! 
  r> xpos !
  color_text
  show
  locate
;

\ -------------------------------------------------------------------------------------
\
\ -------------------------------------------------------------------------------------

: current_char
  ypos @ width * xpos @ + ^buffer @ + c@
;

\ -------------------------------------------------------------------------------------
\
\ -------------------------------------------------------------------------------------

: at-eol?
  xpos @ width 1- =
;

: cursor_left   xpos @ 0 > if -1 xpos +! then locate ;
: cursor_right	xpos @ width 1- < if 1 xpos +! then locate ;
: cursor_up		ypos @ 0> if -1 ypos +! then locate ;
: cursor_down	ypos @ height 1- < if 1 ypos +! then locate ;

: cursor_end_of_line
  width 1- xpos !
  begin
    current_char bl =
    xpos @ 0 >
    and
  while
	-1 xpos +!
  repeat
  locate
;

\ -------------------------------------------------------------------------------------
\
\ -------------------------------------------------------------------------------------

: switch_block 
  current_block !
  current_block @ block ^buffer !
  1024 0 do ^buffer @ i + c@ 0= if bl ^buffer @ i + c! then loop
  drawtitle
  drawblock
  drawstatus
;

: prevblock current_block @ 1 = if beep else current_block @ 1 - switch_block then ;

: nextblock current_block @ 65535 = if beep else current_block @ 1 + switch_block then ;

\ -------------------------------------------------------------------------------------

: ^bufferpos	\ x y -- c-addr
  width * + ^buffer @ +
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

: merge_next_line 
  ypos @ height 1- <> if 
    ^buffer @ ypos @ 1 + width * + width	
	strip
	?dup 0= if
	  drop exit
    else
	  width xpos @ -		\ c-addr u space --
	  over > 0= if
		2drop beep
	  else
		cursor_end_of_line
		cursor_right 
		cursor_right 
		^buffer @ ypos @ width * + xpos @ + swap move
		ypos @ 1+ remove-line
		drawblock
	  then
    then
  then
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

: newline-after		\ idx -- success-flag
  >r
  r@ height 1- <> last-line-blank? and if
    r@ insert-line-after
	true
  else
    r@ find-blank-line-after dup 0 < if
	  drop 
	  r@ find-blank-line-before dup 0< if
	    drop false
      else
		remove-line 
		r@ 1- insert-line-after
		true
	  then
	else
	  remove-line
	  r@ insert-line-after
      true
    then
  then
  r> drop
;

\ -------------------------------------------------------------------------------------
\
\ Edit Mode
\
\ -------------------------------------------------------------------------------------

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
  else r@ 9 = if
	bl recurse
	xpos @ width 1- <> if
		xpos @ 1 and if
		  bl recurse
        then
    then
  else r@ 27 = if
	enter_command_mode
  else r@ 127 = if
	xpos @ 0= if
		beep
	else
		cursor_left
		delete_current_char
		drawblock
	then
  else r@ 10 = if		\ refactor this as a generic insert-line
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
  then then then then then then then then
  r> drop
;

\ -------------------------------------------------------------------------------------
\
\ Last Line Mode
\
\ -------------------------------------------------------------------------------------

64 buffer:  lastline
0 lastline c!

: lastline_key \ key --
  case
  27 of
	enter_command_mode
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
		enter_command_mode
		0 lastline c!
	then
	endof
  \ default 
    dup lastline count + c!
    lastline c@ 1+ lastline c!
    new-status s" :" >status lastline count >status drawstatus
  endcase
;

\ -------------------------------------------------------------------------------------
\
\ Yank buffer
\
\ -------------------------------------------------------------------------------------

variable yank_length
1024 buffer: yank_buffer

: yank-line			\ idx --
  width * ^buffer @ + yank_buffer width move
  width yank_length !
;

: yank-paste
  yank_length @ width <> if beep beep beep exit then	\ not done

  ypos @ insert-line-after 0= if beep else
	1 ypos +!
	yank_buffer 0 ypos @ ^bufferpos width move
  then
;

\ -------------------------------------------------------------------------------------
\
\ Visual Mode
\
\ -------------------------------------------------------------------------------------

variable visual_start_x
variable visual_start_y

: update_visual_range
  mode @ mode_visual_line = if
	0 visual_start_y @ ypos @ minmax width 1- swap
	2>r ^bufferpos 2r> ^bufferpos
  else
	visual_start_x @ visual_start_y @ ^bufferpos
	xpos @ ypos @ ^bufferpos
    minmax
  then
  new-status S" range " >status over n>status s"  -> " >status dup n>status s"   : " >status ^buffer @ n>status drawstatus
  visual_end !
  visual_start !
  drawblock
;

: enter_visual_mode
  mode !
  new-status S" -- VISUAL --" >status drawstatus
  xpos @ visual_start_x ! 
  ypos @ visual_start_y ! 
  update_visual_range
;

: yank_range beep 0 visual_start ! 0 visual_end ! enter_command_mode ;
: delete_range beep 0 visual_start ! 0 visual_end ! enter_command_mode ;

: visual_key
  case
  27 of
	0 visual_start !
	0 visual_end !
	drawblock
	enter_command_mode
    endof
  [char] d of delete_range endof
  [char] y of yank_range endof
  k-up of cursor_up update_visual_range endof
  k-down of cursor_down update_visual_range endof
  k-left of cursor_left update_visual_range endof
  k-right of cursor_right update_visual_range endof
  [char] h of cursor_left update_visual_range endof
  [char] l of cursor_right update_visual_range endof
  [char] j of cursor_down update_visual_range endof
  [char] 10 of cursor_down update_visual_range endof
  [char] k of cursor_up update_visual_range endof
  [char] 11 of cursor_up update_visual_range endof
  \ default
  beep
  endcase
;

\ -------------------------------------------------------------------------------------
\
\ Command Mode
\
\ -------------------------------------------------------------------------------------

variable number_prefix
0 number_prefix !

: +number number_prefix @ 10 * + number_prefix ! ;

:noname
  mode_command mode !
  0 number_prefix !
  new-status drawstatus
  drawblock
;
 
' enter_command_mode defer!

: command_key	\ key --
  dup case
  27 of endof	\ already in command mode
  [char] : of mode_lastline mode ! new-status s" :" >status drawstatus 0 lastline c! endof
  [char] i of mode_insert mode !  new-status s" -- INSERT --" >status drawstatus endof
  [char] v of mode_visual enter_visual_mode  endof
  [char] V of mode_visual_line enter_visual_mode endof
  [char] 0 of number_prefix @ 0= if 0 xpos ! locate else dup +number then endof
  [char] 1 of dup +number endof
  [char] 2 of dup +number endof
  [char] 3 of dup +number endof
  [char] 4 of dup +number endof
  [char] 5 of dup +number endof
  [char] 6 of dup +number endof
  [char] 7 of dup +number endof
  [char] 8 of dup +number endof
  [char] 9 of dup +number endof
  4 of nextblock endof
  21 of prevblock endof
  [char] $ of cursor_end_of_line endof

  [char] h of cursor_left endof
  k-left of cursor_left endof
  [char] l of cursor_right endof
  k-right of cursor_right endof
  [char] k of cursor_up endof
  [char] 11 of cursor_up endof
  k-up of cursor_up endof
  [char] j of cursor_down endof
  [char] 10 of cursor_down endof
  k-down of cursor_down endof

\ ^  cursor to first non space on line
\ w cursor next word
\ b cursor back one word
\ G cursor end of file ( in my case block )
\ gg start of file ( or if number prefix then line )
\ o new line below cursor
\ O new line above cursor
  [char] a of cursor_right [char] i recurse endof
  [char] A of cursor_end_of_line [char] a recurse endof
  [char] J of merge_next_line endof
  [char] x of delete_current_char drawblock endof
  [char] d of key case
				  [char] w of beep endof				\ delete-word
				  [char] 0 of beep endof				\ delete to start of line	
				  [char] $ of beep endof				\ delete to end of line
				  [char] d of ypos @ dup yank-line remove-line endof
				  \ default
				  beep
				  endcase
				  drawblock
  endof
  [char] y of key case
				  [char] y of ypos @ yank-line endof
				  \ default
				  beep
				  endcase
  endof
  [char] p of ypos @ yank-paste drawblock endof

  new-status s" Unhandled command key " >status dup n>status drawstatus beep
  endcase

  [char] 0 [char] 9 1+ within 0= if 0 number_prefix ! then
;

\ -------------------------------------------------------------------------------------
\
\ Main
\
\ -------------------------------------------------------------------------------------

: runeditor
  enter_command_mode
  0 current_block !
  0 xpos !
  0 ypos !
  0 yank_length !
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
	mode_visual of swap visual_key endof
	mode_visual_line of swap visual_key endof
	nip	\ unknown mode, lose key
    new-status s" unknown mode, " >status dup n>status s" , drop key" >status drawstatus
	endcase
  repeat
;

\ -------------------------------------------------------------------------------------
\
\ Debug
\
\ -------------------------------------------------------------------------------------

: d console_clear drawtitle drawedges drawblock drawstatus 0 25 at-xy ;

\ -------------------------------------------------------------------------------------
\
\ Entrypoints
\
\ -------------------------------------------------------------------------------------

widEditor set-current

: vi
  1 ['] runeditor catch 
  save-buffers
  color_text 
  0 25 at-xy console_clear
  throw ;

forth-wordlist set-current

: editor get-order widEditor swap 1+ set-order ;

only forth definitions

