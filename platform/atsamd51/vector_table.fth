
( I am assuming 32bit - better ensure )

require extra/thread.fth

internals ext-wordlist forth-wordlist 3 set-order 

internals set-current

hex
E000ED08 constant SCB-VTOR

40002800 14 + constant EIC-INTFLAG

1C constant EXTINT_IRQ0

38 constant size-isr-routine
10 constant num-isrs

size-isr-routine num-isrs * buffer: isrs

variable isr_events
num-isrs cells buffer: isr_counts

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
  SCB-VTOR 0 d32!
;

: copy-vectors
  100 0 ?do
    vtor i cells + 0 d32@
    my-vector-table i cells + !		\ Requires 32bit build
  loop
;

: s,			( ptr value -- ptr+1 )
  over c! 1+ ;

: defineISR		( counter ident number[0..15] -- )

  rot rel>abs drop
  rot rel>abs drop
  rot

  dup size-isr-routine * isrs +			( counter ident num ptr -- )

  80 s, b4 s,									\ 00: push {r7}
  00 s, af s,									\ 02: add r7, sp, #0
  09 s, 4b s,									\ 04: ldr r3, [pc, #36]		; 2C
  09 s, 4a s,									\ 06: ldr r2, [pc, #36]		; 2C
  12 s, 68 s,									\ 08: ldr r2, [r2, #0]

  swap				( counter ident ptr num -- )
  dup >r
  case
  0 of drop 42 s, f0 s, 01 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #1
  1 of drop 42 s, f0 s, 02 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #2
  2 of drop 42 s, f0 s, 04 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #4
  3 of drop 42 s, f0 s, 08 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #8
  4 of drop 42 s, f0 s, 10 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #16
  5 of drop 42 s, f0 s, 20 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #32
  6 of drop 42 s, f0 s, 40 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #64
  7 of drop 42 s, f0 s, 80 s, 02 s, 0 endof		\ 0a: orr.w   r2, r2, #128
  8 of drop 42 s, f4 s, 80 s, 72 s, 0 endof		\ 0a: orr.w   r2, r2, #256
  9 of drop 42 s, f4 s, 00 s, 72 s, 0 endof		\ 0a: orr.w   r2, r2, #512
  A of drop 42 s, f4 s, 80 s, 62 s, 0 endof		\ 0a: orr.w   r2, r2, #1024
  B of drop 42 s, f4 s, 00 s, 62 s, 0 endof		\ 0a: orr.w   r2, r2, #2048
  C of drop 42 s, f4 s, 80 s, 52 s, 0 endof		\ 0a: orr.w   r2, r2, #4096
  D of drop 42 s, f4 s, 00 s, 52 s, 0 endof		\ 0a: orr.w   r2, r2, #8192
  E of drop 42 s, f4 s, 80 s, 42 s, 0 endof		\ 0a: orr.w   r2, r2, #16384
  F of drop 42 s, f4 s, 00 s, 42 s, 0 endof		\ 0a: orr.w   r2, r2, #32768
  1 abort" invalid shift"
  endcase
  ( counter ident ptr -- )

  1a s, 60 s,									\ 0e: str r2, [r3, #0]
  07 s, 4b s,									\ 10: ldr r3, [pc, #28]
  07 s, 4a s, 									\ 12: ldr r2, [pc, #28]
  12 s, 68 s,									\ 14: ldr r2, [r2, #0]

  r> case
  0 of drop 42 s, f0 s, 01 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #1
  1 of drop 42 s, f0 s, 02 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #2
  2 of drop 42 s, f0 s, 04 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #4
  3 of drop 42 s, f0 s, 08 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #8
  4 of drop 42 s, f0 s, 10 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #16
  5 of drop 42 s, f0 s, 20 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #32
  6 of drop 42 s, f0 s, 40 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #64
  7 of drop 42 s, f0 s, 80 s, 02 s, 0 endof		\ 16: orr.w   r2, r2, #128
  8 of drop 42 s, f4 s, 80 s, 72 s, 0 endof		\ 16: orr.w   r2, r2, #256
  9 of drop 42 s, f4 s, 00 s, 72 s, 0 endof		\ 16: orr.w   r2, r2, #512
  A of drop 42 s, f4 s, 80 s, 62 s, 0 endof		\ 16: orr.w   r2, r2, #1024
  B of drop 42 s, f4 s, 00 s, 62 s, 0 endof		\ 16: orr.w   r2, r2, #2048
  C of drop 42 s, f4 s, 80 s, 52 s, 0 endof		\ 16: orr.w   r2, r2, #4096
  D of drop 42 s, f4 s, 00 s, 52 s, 0 endof		\ 16: orr.w   r2, r2, #8192
  E of drop 42 s, f4 s, 80 s, 42 s, 0 endof		\ 16: orr.w   r2, r2, #16384
  F of drop 42 s, f4 s, 00 s, 42 s, 0 endof		\ 16: orr.w   r2, r2, #32768
  1 abort" invalid shift"
  endcase
  ( counter ident ptr -- )

  1a s, 60 s,									\ 1a: str r2, [r3,#0]	
  05 s, 4b s,									\ 1c: ldr r3, [pc, #20] ; 34
  1a s, 68 s,									\ 1e: ldr r2, [r3, #0]
  01 s, 32 s,									\ 20: adds r2, #1
  1a s, 60 s,									\ 22: str r2, [r3, #0]
  bd s, 46 s,									\ 24: mov sp, r7
  5d s, f8 s, 04 s, 7b s,						\ 26: ldr.w r7, [sp], #4
  70 s, 47 s,									\ 2a: bx lr

  \ EIT.INTFLAG address							\ 2C: xx xx xx xx
  14 s, 28 s, 00 s, 40 s,

  \ replace with address of interrupt			\ 30: xx xx xx xx
  \ called mask (offset 44)
  over FF and s,
  over 8 rshift FF and s,
  over 10 rshift FF and s,
  swap 18 rshift FF and s,
  \ replace with counter variable (offset 48)	\ 34: xx xx xx xx
  over FF and s,
  over 8 rshift FF and s,
  over 10 rshift FF and s,
  swap 18 rshift FF and s,
  drop
;
decimal

ext-wordlist set-current

defer EXTINT0	:noname cr ." EXTINT0 invoked " ; is EXTINT0
defer EXTINT1	:noname cr ." EXTINT1 invoked " ; is EXTINT1
defer EXTINT2	:noname cr ." EXTINT2 invoked " ; is EXTINT2
defer EXTINT3	:noname cr ." EXTINT3 invoked " ; is EXTINT3
defer EXTINT4	:noname cr ." EXTINT4 invoked " ; is EXTINT4
defer EXTINT5	:noname cr ." EXTINT5 invoked " ; is EXTINT5
defer EXTINT6	:noname cr ." EXTINT6 invoked " ; is EXTINT6
defer EXTINT7	:noname cr ." EXTINT7 invoked " ; is EXTINT7
defer EXTINT8	:noname cr ." EXTINT8 invoked " ; is EXTINT8
defer EXTINT9	:noname cr ." EXTINT9 invoked " ; is EXTINT9
defer EXTINT10	:noname cr ." EXTINT10 invoked " ; is EXTINT10
defer EXTINT11	:noname cr ." EXTINT11 invoked " ; is EXTINT11
defer EXTINT12	:noname cr ." EXTINT12 invoked " ; is EXTINT12
defer EXTINT13	:noname cr ." EXTINT13 invoked " ; is EXTINT13
defer EXTINT14	:noname cr ." EXTINT14 invoked " ; is EXTINT14
defer EXTINT15	:noname cr ." EXTINT15 invoked " ; is EXTINT15

: (poll-interrupts)
  isr_events @ ?dup if
   dup 1 and if EXTINT0 then
   dup 2 and if EXTINT1 then
   dup 4 and if EXTINT2 then
   dup 8 and if EXTINT3 then
   dup 16 and if EXTINT4 then
   dup 32 and if EXTINT5 then
   dup 64 and if EXTINT6 then
   dup 128 and if EXTINT7 then
   dup 256 and if EXTINT8 then
   dup 512 and if EXTINT9 then
   dup 1024 and if EXTINT10 then
   dup 2048 and if EXTINT11 then
   dup 4096 and if EXTINT12 then
   dup 8192 and if EXTINT13 then
   dup 16384 and if EXTINT14 then
   dup 32768 and if EXTINT15 then
   drop 0 isr_events !
  then
  schedule
;

: interrupt-count	( n --  v )
  cells isr_counts + @
;

: poll-interrupts
  begin ['] (poll-interrupts) catch >except .except again
;

' poll-interrupts thread: poll-interrupt-thread

: initInterrupts
  \ clear count fields for each isr
  isr_counts num-isrs cells 0 fill
  0 isr_events !

  \ define our ISRS
  num-isrs 0 ?do
	isr_counts i cells + isr_events i defineISR
  loop
	
  copy-vectors

  num-isrs 0 ?do
	isrs i size-isr-routine * + rel>abs drop 1+ 
	my-vector-table EXTINT_IRQ0 cells + i cells + !
  loop
  my-vector-table >vtor
;

onboot: newVectorTable
	initInterrupts
onboot;

( 

   0:	b480      	push	{r7}
   2:	af00      	add	r7, sp, #0
   4:	4b09      	ldr	r3, [pc, #36]	; 2c <c+0x24>
   6:	4a09      	ldr	r2, [pc, #36]	; 2c <c+0x24>
   8:	6812      	ldr	r2, [r2, #0]
   a:	f042 0201 	orr.w	r2, r2, #1
   e:	601a      	str	r2, [r3, #0]
  10:	4b07      	ldr	r3, [pc, #28]	; 30 <c+0x28>
  12:	4a07      	ldr	r2, [pc, #28]	; 30 <c+0x28>
  14:	6812      	ldr	r2, [r2, #0]
  16:	f042 0201 	orr.w	r2, r2, #1
  1a:	601a      	str	r2, [r3, #0]
  1c:	4b05      	ldr	r3, [pc, #20]	; 34 <c+0x2c>
  1e:	681a      	ldr	r2, [r3, #0]
  20:	3201      	adds	r2, #1
  22:	601a      	str	r2, [r3, #0]
  24:	46bd      	mov	sp, r7
  26:	f85d 7b04 	ldr.w	r7, [sp], #4
  2a:	4770      	bx	lr
  2c:	40002814 	.word	0x40002814	; EIC intflag to clear value
  30:	11223344 	.word	0x11223344	; my isr flags in Forth
  34:	55667788 	.word	0x55667788	; counter for this ISR

80 b4 00 af 09 4b 09 4a 12 68 42 f0  
01 02 1a 60 07 4b 07 4a 12 68 42 f0 01 02 1a 60
05 4b 1a 68 01 32 1a 60 bd 46 5d f8 04 7b 70 47 
14 28 00 40 44 33 22 11 88 77 66 55 

)

