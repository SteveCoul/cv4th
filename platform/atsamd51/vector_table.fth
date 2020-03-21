
( I am assuming 32bit - better ensure )

ext-wordlist forth-wordlist 2 set-order definitions

hex
E000ED08 constant SCB-VTOR

1C 
dup 0 + constant EXTINT_IRQ0
dup 1 + constant EXTINT_IRQ1
dup 2 + constant EXTINT_IRQ2
dup 3 + constant EXTINT_IRQ3
dup 4 + constant EXTINT_IRQ4
dup 5 + constant EXTINT_IRQ5
dup 6 + constant EXTINT_IRQ6
dup 7 + constant EXTINT_IRQ7
dup 8 + constant EXTINT_IRQ8
dup 9 + constant EXTINT_IRQ9
dup A + constant EXTINT_IRQ10
dup B + constant EXTINT_IRQ11
dup C + constant EXTINT_IRQ12
dup D + constant EXTINT_IRQ13
dup E + constant EXTINT_IRQ14
    F + constant EXTINT_IRQ15

here
100 cells 100 + allot
constant my-vector-table-storage

: my-vector-table		\ have to do this at runtime because its the absolute address that needs aligning 
  my-vector-table-storage 100 + rel>abs drop FF invert and
  0 rel>abs drop -
;

: vtor SCB-VTOR 0 d32@ ;

: >vtor
  rel>abs drop 
  cr ." I'm about to write VTOR with " dup .
  SCB-VTOR 0 d32!
;

: copy-vectors
  100 0 ?do
    vtor i cells + 0 d32@
    my-vector-table i cells + !		\ Requires 32bit build
  loop
;

: le32,
  dup FF and c, 8 rshift
  dup FF and c, 8 rshift
  dup FF and c, 8 rshift
  FF and c,
;

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
	rel>abs drop le32,
	\ replace with counter variable (offset 48)	\ 30: xx xx xx xx
	rel>abs drop le32,
;
decimal

variable ident 0 ident !
variable counter0  counter0  ident 0  defineISR isr0
variable counter1  counter1  ident 1  defineISR isr1
variable counter2  counter2  ident 2  defineISR isr2
variable counter3  counter3  ident 3  defineISR isr3
variable counter4  counter4  ident 4  defineISR isr4
variable counter5  counter5  ident 5  defineISR isr5
variable counter6  counter6  ident 6  defineISR isr6
variable counter7  counter7  ident 7  defineISR isr7
variable counter8  counter8  ident 8  defineISR isr8
variable counter9  counter9  ident 9  defineISR isr9
variable counter10 counter10 ident 10 defineISR isr10
variable counter11 counter11 ident 11 defineISR isr11
variable counter12 counter12 ident 12 defineISR isr12
variable counter13 counter13 ident 13 defineISR isr13
variable counter14 counter14 ident 14 defineISR isr14
variable counter15 counter15 ident 15 defineISR isr15

: newvt
  cr ." Install a new vector table"
  copy-vectors
  isr0  rel>abs drop 1+ my-vector-table EXTINT_IRQ0 cells + !
  isr1  rel>abs drop 1+ my-vector-table EXTINT_IRQ1 cells + !
  isr2  rel>abs drop 1+ my-vector-table EXTINT_IRQ2 cells + !
  isr3  rel>abs drop 1+ my-vector-table EXTINT_IRQ3 cells + !
  isr4  rel>abs drop 1+ my-vector-table EXTINT_IRQ4 cells + !
  isr5  rel>abs drop 1+ my-vector-table EXTINT_IRQ5 cells + !
  isr6  rel>abs drop 1+ my-vector-table EXTINT_IRQ6 cells + !
  isr7  rel>abs drop 1+ my-vector-table EXTINT_IRQ7 cells + !
  isr8  rel>abs drop 1+ my-vector-table EXTINT_IRQ8 cells + !
  isr9  rel>abs drop 1+ my-vector-table EXTINT_IRQ9 cells + !
  isr10 rel>abs drop 1+ my-vector-table EXTINT_IRQ10 cells + !
  isr11 rel>abs drop 1+ my-vector-table EXTINT_IRQ11 cells + !
  isr12 rel>abs drop 1+ my-vector-table EXTINT_IRQ12 cells + !
  isr13 rel>abs drop 1+ my-vector-table EXTINT_IRQ13 cells + !
  isr14 rel>abs drop 1+ my-vector-table EXTINT_IRQ14 cells + !
  isr15 rel>abs drop 1+ my-vector-table EXTINT_IRQ15 cells + !
  my-vector-table >vtor
;

: show
  base @ >r
  cr ." ident " 2 base ! ident @ . decimal
  cr ."  0: " counter0 @ .
  cr ."  1: " counter1 @ .
  cr ."  2: " counter2 @ .
  cr ."  3: " counter3 @ .
  cr ."  4: " counter4 @ .
  cr ."  5: " counter5 @ .
  cr ."  6: " counter6 @ .
  cr ."  7: " counter7 @ .
  cr ."  8: " counter8 @ .
  cr ."  9: " counter9 @ .
  cr ." 10: " counter10 @ .
  cr ." 11: " counter11 @ .
  cr ." 12: " counter12 @ .
  cr ." 13: " counter13 @ .
  cr ." 14: " counter14 @ .
  cr ." 15: " counter15 @ .
  r> base !
;

: reset 0 ident ! ;

