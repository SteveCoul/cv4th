
( Try and figure out some vector table hacking )

0 [if]

hex
E000ED00 constant SCB
08 offset VTOR

1C offset EXTINT_IRQ0
( .. and on to 15 )

decimal

1 15 + 137 + constant	#vectors
256 4 * constant vector_align

: va-align
  begin here @ vector_align mod while 0 c, repeat 
;

va-align
here
vector_align allot
constant new-vector-table

: vtor SCB VTOR 0 d32@ ;

: copy-vectors
  256 0 ?do
    vtor i cells + 0 d32@
    new-vector-table i cells + !		\ Requires 32bit build
  loop
;

: newvtor
  new-vector-table REL>ABS SCB VTOR 0 d32!
;

[then]

