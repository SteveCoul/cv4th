
get-order internals swap 1+ set-order definitions

here constant start

variable current_block 

64 constant width
16 constant height

variable ^buffer
width 1+ buffer: status_buffer
0 status_buffer c!

0 value xpos
0 value ypos

: esc 27 emit [char] [ emit ;
: console_black	esc ." 39m" ;
: console_red	esc ." 31m" ;
: console_at	esc 1+ . [char] ; emit 1+ . [char] H emit ;
: console_clear	esc ." 2J" ;
: locate xpos 3 + ypos at-xy ;

: hline 
  0 swap console_at width 4 + 0 do [char] - emit loop 
;

: draw_status
  console_red
  height hline
  0 height 1+ console_at width spaces
  0 height 1+ console_at status_buffer count type
  height 2 + hline
  console_black
  locate
;

: draw_screen
  ^buffer @ >r
  console_red
  height 0 
  begin
	2dup >
  while
	0 over console_at dup 2 .r [char] | emit console_black
	width 0
    begin
      2dup >
    while
	  r@ c@ emit r> 1+ >r
      1+
    repeat
	2drop
	console_red [char] | emit
    1+
  repeat
  2drop
  r> drop
  locate
;

: cursorbol 0 to xpos locate ;

: cursorleft xpos if xpos 1- to xpos locate then ;

: cursorup ypos if ypos 1- to ypos locate then ;

: cursoreol 
  64 0 do
    ^buffer @ 64 ypos * + 64 i - + c@ bl <> if
		64 i - 1+ 63 min to xpos
	    leave
	then
  loop
  locate
;

: cursorright
  xpos 1+ to xpos
  xpos width = if cursorleft then
  locate
;

: cursordown
  ypos 1+ to ypos
  ypos height = if cursorup then
  locate
;

: newline
  ypos height 1- < if
    0 to xpos
	ypos 1+ to ypos
	\ todo if this line has anything but whitespace jump to first char?
    locate
  then
;

: s>status
  status_buffer count +		\ c-addr u dest
  rot swap 2 pick			\ u c-addr dest u
  move
  status_buffer c@ + status_buffer c!
;

: n>status
  0 <# #s #> s>status
;

: new_status
  0 status_buffer c!
;

: normalkey
  ^buffer @ ypos width * + xpos + c! cursorright draw_screen
  update
;

: switch_block
  current_block !
  current_block @ block ^buffer !
  \ not sure about this - might be better if 0 counted as white space in the interpreter
  \ otherwise - this will update non-source (binary) blocks if I just view them
  1024 0 do ^buffer @ i + c@ 0= if bl ^buffer @ i + c! update then loop
  new_status s" Block " s>status current_block @ n>status draw_status
  draw_screen
  locate
;

: run_editor
  console_clear
  0 to xpos
  0 to ypos

  switch_block

  begin
	ekey
    dup 32 127 within if
		xpos width = if drop else
			normalkey
		then
	else
		case
		k-delete of 
			xpos if
				cursorleft
				bl normalkey
				cursorleft
			then
		endof
		9 of 
			xpos 1 and if
				bl normalkey
				bl normalkey
			else
				bl normalkey
			then
		endof
		13 of endof
		10 of newline endof
		27 of console_clear drop save-buffers console_black exit endof
		1 of  cursoreol endof
		2 of  cursorbol endof
		4 of current_block @ 1+ switch_block endof
		21 of current_block @ dup 1 > if 1 - switch_block else drop then endof
		k-up of cursorup endof
		k-down of cursordown endof
		k-left of cursorleft endof
		k-right of cursorright endof
		new_status s" Unhandled key " s>status dup n>status draw_status
		endcase
	then
  again
;

here start - s" Editor takes " type . s"  bytes" type 

wordlist constant wid-editor
get-order wid-editor swap 1+ set-order definitions

: edit
  run_editor
;

forth-wordlist set-current
: editor get-order wid-editor swap 1+ set-order ;
-1 set-order definitions

