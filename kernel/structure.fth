
only forth definitions

: begin-structure create here 0 0 , does> @ ;				\ FACILTY
: end-structure swap ! ;									\ FACILTY
: +field create  over , + does> @ + ;						\ FACILTY
: field: aligned 1 cells +field ;							\ FACILTY
: cfield: 1 chars +field ;									\ FACILTY

