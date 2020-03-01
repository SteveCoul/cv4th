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

typedef struct tagMachine_t {
	void*		memory;
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

extern void machine_execute( machine_t* machine, cell_t a_throw, int run_once );

#endif

