
#ifndef __forth_h__
#define __forth_h__

#include "machine.h"

#define SIZE_DATA_STACK					256
#define SIZE_RETURN_STACK				256
#define SIZE_FORTH						29*1024
#define SIZE_INPUT_BUFFER				128
#define SIZE_PICTURED_NUMERIC			64
#define SIZE_ORDER						10

#define	A_HERE							0
#define A_LIST_OF_WORDLISTS				1*CELL_SIZE
/* wid-link ptr for forth-wordlist */
#define A_FORTH_WORDLIST				3*CELL_SIZE
/* wid-link ptr for internals */
#define A_INTERNALS_WORDLIST			5*CELL_SIZE
/* wid-link ptr for locals 	*/
#define A_LOCALS_WORDLIST				7*CELL_SIZE
#define A_QUIT							8*CELL_SIZE
#define A_BASE							9*CELL_SIZE
#define A_STATE							10*CELL_SIZE
#define A_TIB							11*CELL_SIZE
#define A_HASH_TIB						12*CELL_SIZE
#define A_TOIN							13*CELL_SIZE
#define A_CURRENT						14*CELL_SIZE
#define A_THROW							15*CELL_SIZE
#define A_ORDER							16*CELL_SIZE
#define A_PICTURED_NUMERIC				A_ORDER + ( SIZE_ORDER * CELL_SIZE )
#define A_INPUT_BUFFER					A_PICTURED_NUMERIC + SIZE_PICTURED_NUMERIC
#define START_HERE						A_INPUT_BUFFER+SIZE_INPUT_BUFFER

#endif

