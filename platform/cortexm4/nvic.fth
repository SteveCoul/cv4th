
hex
E000E100 constant NVIC
decimal

: ISER ;
: ICER 128 + ;
: ISPR 256 + ;
: ICPR 384 + ;
: IABR 512 + ;
: IP 768 + ;
: STIR 3584 + ;

: nvicDisableIRQ		( irqn -- )
  dup 5 rshift cells NVIC ICER +	
  1 rot 31 and lshift		
  swap s>d d32!
;

: nvicEnableIRQ			( irqn -- )
  dup 5 rshift cells NVIC ISER +	
  1 rot 31 and lshift		
  swap s>d d32!
;

: nvicClearPending		( irqn -- )
  dup 5 rshift cells NVIC ICPR +	
  1 rot 31 and lshift		
  swap s>d d32!
;

