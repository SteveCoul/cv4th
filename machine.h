#ifndef __machine_h__
#define __machine_h__

typedef struct {
	void*		memory;
	uint32_t*	datastack;
	uint32_t*	returnstack;
	uint32_t	DP;
	uint32_t	RP;
	uint32_t	LP;
	uint16_t(*swap16)( uint16_t v );
	uint32_t(*swap32)( uint32_t v );
} machine_t;

typedef enum {
	ENDIAN_LITTLE,
	ENDIAN_BIG,
	ENDIAN_NATIVE,
	ENDIAN_SWAP
} machine_endian_t;

extern void machine_init( machine_t* machine );
extern void machine_set_endian( machine_t* machine, machine_endian_t which );

#define ABS_PTR( mach, r_addr )			(void*)(((uint8_t*)(mach->memory))+r_addr)

#define GET_BYTE(mach,r_addr)	 		((uint8_t*)( ((uint8_t*)(mach->memory) + r_addr) ))[0]
#define WRITE_BYTE(mach,r_addr, value)	((uint8_t*)(mach->memory))[ r_addr ] = value

#define GET_CELL(mach,r_addr)	 		(mach->swap32(((uint32_t*)(((uint8_t*)(mach->memory) + r_addr)))[0]))
#define WRITE_CELL(mach,r_addr, value) 	((uint32_t*)(((uint8_t*)(mach->memory) + r_addr)))[0] = mach->swap32(value)
#define GET_WORD(mach,r_addr)	 		(mach->swap16(((uint16_t*)(((uint8_t*)(mach->memory) + r_addr)))[0]))
#define WRITE_WORD(mach,r_addr, value) 	((uint16_t*)(((uint8_t*)(mach->memory) + r_addr)))[0] = mach->swap16(value)

extern void machine_execute( machine_t* machine, uint32_t xt );

#endif

