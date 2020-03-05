
#ifndef __forth_h__
#define __forth_h__

#include "machine.h"

#define SIZE_INPUT_BUFFER				128
#define SIZE_PICTURED_NUMERIC			64
#define SIZE_ORDER						10

#define A_HEADER						0
#define	A_HERE							1*CELL_SIZE
#define A_DICTIONARY_SIZE				2*CELL_SIZE
#define A_SIZE_DATASTACK				3*CELL_SIZE
#define A_SIZE_RETURNSTACK				4*CELL_SIZE
#define A_LIST_OF_WORDLISTS				5*CELL_SIZE
/* wid-link ptr for forth-wordlist */
#define A_FORTH_WORDLIST				7*CELL_SIZE
/* wid-link ptr for internals */
#define A_INTERNALS_WORDLIST			9*CELL_SIZE
/* wid-link ptr for locals 	*/
#define A_LOCALS_WORDLIST				11*CELL_SIZE
#define A_QUIT							12*CELL_SIZE
#define A_BASE							13*CELL_SIZE
#define A_STATE							14*CELL_SIZE
#define A_TIB							15*CELL_SIZE
#define A_HASH_TIB						16*CELL_SIZE
#define A_TOIN							17*CELL_SIZE
#define A_CURRENT						18*CELL_SIZE
#define A_THROW							19*CELL_SIZE
#define A_ORDER							20*CELL_SIZE
#define A_PICTURED_NUMERIC				A_ORDER + ( SIZE_ORDER * CELL_SIZE )
#define A_INPUT_BUFFER					A_PICTURED_NUMERIC + SIZE_PICTURED_NUMERIC
#define START_HERE						A_INPUT_BUFFER+SIZE_INPUT_BUFFER

#endif

