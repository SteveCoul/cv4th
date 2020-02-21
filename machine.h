#ifndef __machine_h__
#define __machine_h__

#include <stdint.h>

#ifdef VM_16BIT
#define HEADER_ID 0x1144
typedef uint16_t cell_t;
#else
#define HEADER_ID 0x11223344
typedef uint32_t cell_t;
#endif

typedef struct {
	void*		memory;
	cell_t*		datastack;
	cell_t*		returnstack;
	cell_t		DP;
	cell_t		RP;
	cell_t		LP;
	uint16_t	(*swap16)( uint16_t v );
	cell_t		(*swapCELL)( cell_t v );
} machine_t;

typedef enum {
	ENDIAN_LITTLE,
	ENDIAN_BIG,
	ENDIAN_NATIVE,
	ENDIAN_SWAP
} machine_endian_t;

extern void machine_init( machine_t* machine );
extern void machine_set_endian( machine_t* machine, machine_endian_t which );

#define CELL_SIZE						sizeof(cell_t)
#define ABS_PTR( mach, r_addr )			(void*)(((uint8_t*)(mach->memory))+r_addr)

#define GET_BYTE(mach,r_addr)	 		((uint8_t*)( ((uint8_t*)(mach->memory) + r_addr) ))[0]
#define WRITE_BYTE(mach,r_addr, value)	((uint8_t*)(mach->memory))[ r_addr ] = (uint8_t)value

#define GET_CELL(mach,r_addr)	 		(mach->swapCELL(((cell_t*)(((uint8_t*)(mach->memory) + r_addr)))[0]))
#define WRITE_CELL(mach,r_addr, value) 	((cell_t*)(((uint8_t*)(mach->memory) + r_addr)))[0] = mach->swapCELL(value)
#define GET_WORD(mach,r_addr)	 		(mach->swap16(((uint16_t*)(((uint8_t*)(mach->memory) + r_addr)))[0]))
#define WRITE_WORD(mach,r_addr, value) 	((uint16_t*)(((uint8_t*)(mach->memory) + r_addr)))[0] = mach->swap16(value)

extern void machine_execute( machine_t* machine, cell_t xt );

#endif

