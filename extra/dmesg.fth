
ext-wordlist get-order 1+ set-order

private-namespace

32 buffer: dmbuff

ext-wordlist set-current

: $dmesg
  S" dmesg://" r/w open-file abort" failed to open dmesg"
  >r 
  13 dmbuff c!
  10 dmbuff 1+ c!
  dmbuff 2 r@ write-file drop
  r@ write-file drop
  r> close-file drop
;

: dmesg"
  state @ if
	postpone s"
	postpone $dmesg
  else
	[char] " parse
	$dmesg
  then
; immediate

: dmesg
  S" dmesg://" r/w open-file drop
  >r
  begin
    dmbuff 32 r@ read-file drop
    ?dup
  while
    dmbuff swap type
  repeat
  r> close-file drop 
;

only forth definitions

