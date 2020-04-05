
ext-wordlist get-order 1+ set-order
open-namespace core

:noname
	dup . space [char] " emit
	case
    -1	of ." ABORT" endof
    -2	of ." ABORT-quote" endof
    -3	of ." stack overflow" endof
    -4	of ." stack underflow" endof
    -5	of ." return stack overflow" endof
    -6	of ." return stack underflow" endof
    -7	of ." do-loops nested too deeply during execution" endof
    -8	of ." dictionary overflow" endof
    -9	of ." invalid memory address" endof
    -10	of ." division by zero" endof
    -11	of ." result out of range" endof
    -12	of ." argument type mismatch" endof
    -13	of ." undefined word" endof
    -14	of ." interpreting a compile-only word" endof
    -15	of ." invalid FORGET" endof
    -16	of ." attempt to use zero-length string as a name" endof
    -17	of ." pictured numeric output string overflow" endof
    -18	of ." parsed string overflow" endof
    -19	of ." definition name too long" endof
    -20	of ." write to a read-only location" endof
    -21	of ." unsupported operation" endof
    -22	of ." control structure mismatch" endof
    -23	of ." address alignment exception" endof
    -24	of ." invalid numeric argument" endof
    -25	of ." return stack imbalance" endof
    -26	of ." loop parameters unavailable" endof
    -27	of ." invalid recursion" endof
    -28	of ." user interrupt" endof
    -29	of ." compiler nesting" endof
    -30	of ." obsolescent feature" endof
    -31	of ." >BODY used on non-CREATEd definition" endof
    -32	of ." invalid name argument (e.g., TO name)" endof
    -33	of ." block read exception" endof
    -34	of ." block write exception" endof
    -35	of ." invalid block number" endof
    -36	of ." invalid file position" endof
    -37	of ." file I/O exception" endof
    -38	of ." non-existent file" endof
    -39	of ." unexpected end of file" endof
    -40	of ." invalid BASE for floating point conversion" endof
    -41	of ." loss of precision" endof
    -42	of ." floating-point divide by zero" endof
    -43	of ." floating-point result out of range" endof
    -44	of ." floating-point stack overflow" endof
    -45	of ." floating-point stack underflow" endof
    -46	of ." floating-point invalid argument" endof
    -47	of ." compilation word list deleted" endof
    -48	of ." invalid POSTPONE" endof
    -49	of ." search-order overflow" endof
    -50	of ." search-order underflow" endof
    -51	of ." compilation word list changed" endof
    -52	of ." control-flow stack overflow" endof
    -53	of ." exception stack overflow" endof
    -54	of ." floating-point underflow" endof
    -55	of ." floating-point unidentified fault" endof
    -56	of ." QUIT" endof
    -57	of ." exception in sending or receiving a character" endof
    -58	of ." [IF], [ELSE], or [THEN] exception" endof
    -59	of ." ALLOCATE" endof
    -60	of ." FREE" endof
    -61	of ." RESIZE" endof
    -62	of ." CLOSE-FILE" endof
    -63	of ." CREATE-FILE" endof
    -64	of ." DELETE-FILE" endof
    -65	of ." FILE-POSITION" endof
    -66	of ." FILE-SIZE" endof
    -67	of ." FILE-STATUS" endof
    -68	of ." FLUSH-FILE" endof
    -69	of ." OPEN-FILE" endof
    -70	of ." READ-FILE" endof
    -71	of ." READ-LINE" endof
    -72	of ." RENAME-FILE" endof
    -73	of ." REPOSITION-FILE" endof
    -74	of ." RESIZE-FILE" endof
    -75	of ." WRITE-FILE" endof
    -76	of ." WRITE-LINE" endof
    -77	of ." Malformed xchar" endof
    -78	of ." SUBSTITUTE" endof
    -79	of ." REPLACES" endof
	." unknown"
	endcase
	[char] " emit
; is .exception

only forth definitions

