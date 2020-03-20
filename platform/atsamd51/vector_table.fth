
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

: rel>abs ;

hex
: defineISR		( counter ident number[0..15] -- )
  create
	68 c, 46 c,									\ 00: mov r0, sp
	20 c, f0 c, 07 c, 01 c,						\ 02: bic.w   r1, r0, #7
	8d c, 46 c,									\ 06: mov sp, r1
	81 c, b4 c,									\ 08: push    {r0, r7}
	00 c, af c,									\ 0A: add r7, sp, #0
	07 c, 4b c,									\ 0C: ldr r3, [pc, #28]   ; (2c <start+0x2c>)
	1b c, 68 c,									\ 0E: ldr r3, [r3, #0]

	case
    0 of 43 c, f0 c, 01 c, 02 c, endof			\ 10: orr.w   r2, r3, #1
    1 of 43 c, f0 c, 02 c, 02 c, endof			\ 10: orr.w   r2, r3, #2
    2 of 43 c, f0 c, 04 c, 02 c, endof			\ 10: orr.w   r2, r3, #4
    3 of 43 c, f0 c, 08 c, 02 c, endof			\ 10: orr.w   r2, r3, #8
    4 of 43 c, f0 c, 10 c, 02 c, endof			\ 10: orr.w   r2, r3, #16
    5 of 43 c, f0 c, 20 c, 02 c, endof			\ 10: orr.w   r2, r3, #32
    6 of 43 c, f0 c, 40 c, 02 c, endof			\ 10: orr.w   r2, r3, #64
    7 of 43 c, f0 c, 80 c, 02 c, endof			\ 10: orr.w   r2, r3, #128
    8 of 43 c, f4 c, 80 c, 72 c, endof			\ 10: orr.w   r2, r3, #256
    9 of 43 c, f4 c, 00 c, 72 c, endof			\ 10: orr.w   r2, r3, #512
    A of 43 c, f4 c, 80 c, 62 c, endof			\ 10: orr.w   r2, r3, #1024
    B of 43 c, f4 c, 00 c, 62 c, endof			\ 10: orr.w   r2, r3, #2048
    C of 43 c, f4 c, 80 c, 52 c, endof			\ 10: orr.w   r2, r3, #4096
    D of 43 c, f4 c, 00 c, 52 c, endof			\ 10: orr.w   r2, r3, #8192
    E of 43 c, f4 c, 80 c, 42 c, endof			\ 10: orr.w   r2, r3, #16384
    F of 43 c, f4 c, 00 c, 42 c, endof			\ 10: orr.w   r2, r3, #32768
	1 abort" invalid shift"
	endcase

	05 c, 4b c,									\ 14: ldr r3, [pc, #20]   ; (2c <start+0x2c>)
	1a c, 60 c,									\ 16: str r2, [r3, #0]
	05 c, 4b c,									\ 18: ldr r3, [pc, #20]   ; (30 <start+0x30>)
	1b c, 68 c,									\ 1A: ldr r3, [r3, #0]
	5a c, 1c c,									\ 1C: adds    r2, r3, #1
	04 c, 4b c,									\ 1E: ldr r3, [pc, #16]   ; (30 <start+0x30>)
	1a c, 60 c,									\ 20: str r2, [r3, #0]
	bd c, 46 c,									\ 22: mov sp, r7
	81 c, bc c,									\ 24: pop {r0, r7}
	85 c, 46 c,									\ 26: mov sp, r0
	70 c, 47 c,									\ 28: bx  lr
	00 c, bf c,									\ 2A: nop
    \ replace with address of interrupt			\ 2C: xx xx xx xx
	\ called mask (offset 44)
	rel>abs dup FF and c, 8 rshift dup FF and c, 
	8 rshift dup FF and c, 8 rshift FF and c,
	\ replace with counter variable (offset 48)	\ 30: xx xx xx xx
	rel>abs dup FF and c, 8 rshift dup FF and c, 
	8 rshift dup FF and c, 8 rshift FF and c,
;
decimal


