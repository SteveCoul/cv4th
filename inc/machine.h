#ifndef __machine_h__
#define __machine_h__

#include <stdint.h>

#ifdef VM_16BIT
#define HEADER_ID 0x1144
typedef uint16_t cell_t;
typedef int16_t s_cell_t;
#define CELL_MASK 0xFFFF
#define CELL_BITS 16
#else
#define HEADER_ID 0x11223344
typedef uint32_t cell_t;
typedef int32_t s_cell_t;
#define CELL_MASK 0xFFFFFFFF
#define CELL_BITS 32
#endif

#define SIZE_INPUT_BUFFER				256
#define SIZE_PICTURED_NUMERIC			66
#define SIZE_ORDER						10

#define A_HEADER						0*CELL_SIZE
#define	A_HERE							1*CELL_SIZE
#define A_DICTIONARY_SIZE				2*CELL_SIZE
#define A_DATASTACK						3*CELL_SIZE
#define A_SIZE_DATASTACK				4*CELL_SIZE
#define A_RETURNSTACK					5*CELL_SIZE
#define A_SIZE_RETURNSTACK				6*CELL_SIZE
#define A_LIST_OF_WORDLISTS				7*CELL_SIZE
#define widlinkptr_FORTHWORDLIST		8*CELL_SIZE
#define A_FORTH_WORDLIST				9*CELL_SIZE
#define widlinkptr_INTERNALS			10*CELL_SIZE
#define A_INTERNALS_WORDLIST			11*CELL_SIZE
#define widlinkptr_LOCALS				12*CELL_SIZE
#define A_LOCALS_WORDLIST				13*CELL_SIZE
#define widlinkptr_EXT					14*CELL_SIZE
#define A_EXT_WORDLIST					15*CELL_SIZE
#define A_QUIT							16*CELL_SIZE
#define A_SETUP							17*CELL_SIZE
#define A_BASE							18*CELL_SIZE
#define A_STATE							19*CELL_SIZE
#define A_TIB							20*CELL_SIZE
#define A_HASH_TIB						21*CELL_SIZE
#define A_TOIN							22*CELL_SIZE
#define A_CURRENT						23*CELL_SIZE
#define A_THROW							24*CELL_SIZE
#define A_ORDER							25*CELL_SIZE
#define A_PICTURED_NUMERIC				A_ORDER + ( SIZE_ORDER * CELL_SIZE )
#define A_INPUT_BUFFER					A_PICTURED_NUMERIC + SIZE_PICTURED_NUMERIC
#define START_HERE						A_INPUT_BUFFER+SIZE_INPUT_BUFFER

/*
	context:
			instruction-pointer
			datastack-pointer
			returnstack-pointer
			locals-pointer
			datastack-base
			returnstack-base
*/
#define CONTEXT_SIZE 6

typedef struct tagMachine_t {
	cell_t*		memory;
	cell_t*		datastack;
	cell_t*		returnstack;
	cell_t		DP;
	cell_t		RP;
	cell_t		LP;
	cell_t		IP;
	cell_t		(*swapCell)( cell_t v );
	uint16_t	(*getWord)( struct tagMachine_t* machine, cell_t r_address );
	void		(*putWord)( struct tagMachine_t* machine, cell_t r_address, cell_t value );
	cell_t		(*getCell)( struct tagMachine_t* machine, cell_t r_address );
	void		(*putCell)( struct tagMachine_t* machine, cell_t r_address, cell_t value );
} machine_t;

#define GET_BYTE(mach,r_addr)           ((uint8_t*)( ((uint8_t*)(mach->memory) + r_addr) ))[0]
#define WRITE_BYTE(mach,r_addr, value)  ((uint8_t*)(mach->memory))[ r_addr ] = (uint8_t)value

#define GET_CELL( machine, r_address )	(machine)->getCell( machine, r_address )
#define GET_WORD( machine, r_address )	(machine)->getWord( machine, r_address )

#define WRITE_CELL( machine, r_address, value )	(machine)->putCell( machine, r_address, value )
#define WRITE_WORD( machine, r_address, value )	(machine)->putWord( machine, r_address, value )

typedef enum {
	ENDIAN_LITTLE,
	ENDIAN_BIG,
	ENDIAN_NATIVE,
	ENDIAN_SWAP
} machine_endian_t;

extern void machine_init( machine_t* machine );
extern void machine_set_endian( machine_t* machine, machine_endian_t which, int unaligned_workaround );

#define CELL_SIZE						sizeof(cell_t)
#define ABS_PTR( mach, r_addr )			(void*)(((uint8_t*)(mach->memory))+r_addr)

/* runmode, -ve means run forever, 0 means run_once ( IE run until opRET on top of stack ) +ve means
	run for N instructions */
extern void machine_execute( machine_t* machine, cell_t a_throw, int run_mode );

#endif

