#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "common.h"
#include "io.h"
#include "io_file.h"
#include "io_dmesg.h"
#include "platform.h"
#include "machine.h"
#include "opcodes.h"

#define DEBUG 0

static uint16_t swap16( uint16_t v ) { return ((v>>8)&0xFF)|((v<<8)&0xFF00); }

#ifdef VM_16BIT
static uint16_t swapCELL( uint16_t v ) { return ((v>>8)&0xFF)|((v<<8)&0xFF00); }
#else
static cell_t swapCELL( cell_t v ) { return ((v>>24)&0xFF)|((v>>8)&0xFF00)|((v<<8)&0xFF0000)|((v<<24)&0xFF000000); }
#endif

static void putWord_NativeOrder_AlignmentSafe( machine_t* machine, cell_t r_address, cell_t value ) {
	uint8_t* ptr;
	uint16_t* ptr2;
	uint16_t word = value;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (uint16_t*)ptr;
	memmove( ptr2, &word, sizeof(word) );
}
static void putCell_NativeOrder_AlignmentSafe( machine_t* machine, cell_t r_address, cell_t value ) {
	uint8_t* ptr;
	cell_t* ptr2;
	cell_t word = value;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (cell_t*)ptr;
	memmove( ptr2, &word, sizeof(word) );
}
static uint16_t getWord_NativeOrder_AlignmentSafe( machine_t* machine, cell_t r_address ) {
	uint8_t* ptr;
	uint16_t* ptr2;
	uint16_t value;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (uint16_t*)ptr;
	memmove( &value, ptr2, sizeof(uint16_t) );
	return value;
}
static cell_t getCell_NativeOrder_AlignmentSafe( machine_t* machine, cell_t r_address ) {
	uint8_t* ptr;
	cell_t* ptr2;
	cell_t value;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (cell_t*)ptr;
	memmove( &value, ptr2, sizeof(cell_t) );
	return value;
}

static void putWord_Swap_AlignmentSafe( machine_t* machine, cell_t r_address, cell_t value ) {
	putWord_NativeOrder_AlignmentSafe( machine, r_address, swap16( value ) );
}
static void putCell_Swap_AlignmentSafe( machine_t* machine, cell_t r_address, cell_t value ) {
	putCell_NativeOrder_AlignmentSafe( machine, r_address, swapCELL( value ) );
}
static uint16_t getWord_Swap_AlignmentSafe( machine_t* machine, cell_t r_address ) {
	return swap16( getWord_NativeOrder_AlignmentSafe( machine, r_address ) );
}
static cell_t getCell_Swap_AlignmentSafe( machine_t* machine, cell_t r_address ) {
	return swapCELL( getCell_NativeOrder_AlignmentSafe( machine, r_address ) );
}

static void putWord_NativeOrder_NoAlignment( machine_t* machine, cell_t r_address, cell_t value ) {
	uint8_t* ptr;
	uint16_t* ptr2;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (uint16_t*)ptr;
	ptr2[0] = value;
}
static void putCell_NativeOrder_NoAlignment( machine_t* machine, cell_t r_address, cell_t value ) {
	uint8_t* ptr;
	cell_t* ptr2;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (cell_t*)ptr;
	ptr2[0] = value;
}
static uint16_t getWord_NativeOrder_NoAlignment( machine_t* machine, cell_t r_address ) {
	uint8_t* ptr;
	uint16_t* ptr2;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (uint16_t*)ptr;
	return ptr2[0];
}
static cell_t getCell_NativeOrder_NoAlignment( machine_t* machine, cell_t r_address ) {
	uint8_t* ptr;
	cell_t* ptr2;
	ptr = (uint8_t*)(machine->memory);
	ptr = ptr + r_address;
	ptr2 = (cell_t*)ptr;
	return ptr2[0];
}

static void putWord_Swap_NoAlignment( machine_t* machine, cell_t r_address, cell_t value ) {
	putWord_NativeOrder_NoAlignment( machine, r_address, swap16( value ) );
}
static void putCell_Swap_NoAlignment( machine_t* machine, cell_t r_address, cell_t value ) {
	putCell_NativeOrder_NoAlignment( machine, r_address, swapCELL( value ) );
}
static uint16_t getWord_Swap_NoAlignment( machine_t* machine, cell_t r_address ) {
	return swap16( getWord_NativeOrder_NoAlignment( machine, r_address ) );
}
static cell_t getCell_Swap_NoAlignment( machine_t* machine, cell_t r_address ) {
	return swapCELL( getCell_NativeOrder_NoAlignment( machine, r_address ) );
}

void machine_init( machine_t* machine ) {
	(void)platform_init();
	ioInit();
	ioRegister( &io_file );
	ioRegister( &io_dmesg );
	machine->DP = 0;
	machine->RP = 0;
	machine->LP = 0;	
	atexit( platform_term );
}

void machine_set_endian( machine_t* machine, machine_endian_t which, int unaligned_workaround ) {
	cell_t value = HEADER_ID;
	uint8_t* p = (uint8_t*)&value;
	machine_endian_t me = (p[3] == (HEADER_ID & 255)) ? ENDIAN_BIG : ENDIAN_LITTLE;

	if ( DEBUG ) {
		platform_print_term("Machine is ");
		platform_print_term( me == ENDIAN_BIG ? "Big" : "Little" );
		platform_println_term(" endian" );

		switch(which){
		case ENDIAN_BIG: platform_println_term("\trequest was for big endian"); break;
		case ENDIAN_LITTLE: platform_println_term("\trequest was for little endian"); break;
		case ENDIAN_NATIVE: platform_println_term("\trequest was for native endian"); break;
		case ENDIAN_SWAP: platform_println_term("\trequest was for swapped-native endian"); break;
		default: platform_println_term("\trequest was for unknown endian"); break;
		}
	}

	if ( which == ENDIAN_NATIVE ) which = me;
	else if ( which == ENDIAN_SWAP ) {
		which = ( me == ENDIAN_BIG ) ? ENDIAN_LITTLE : ENDIAN_BIG;
	}

	if ( unaligned_workaround ) {	/* for now, anything with alignment restrictions uses these slow words */
		if ( me == which ) {
			if ( DEBUG ) platform_println_term("Using native order, alignment safe");
			machine->getWord = getWord_NativeOrder_AlignmentSafe;
			machine->putWord = putWord_NativeOrder_AlignmentSafe;
			machine->getCell = getCell_NativeOrder_AlignmentSafe;
			machine->putCell = putCell_NativeOrder_AlignmentSafe;
		} else {
			if ( DEBUG ) platform_println_term("Using swapped-native order, alignment safe");
			machine->getWord = getWord_Swap_AlignmentSafe;
			machine->putWord = putWord_Swap_AlignmentSafe;
			machine->getCell = getCell_Swap_AlignmentSafe;
			machine->putCell = putCell_Swap_AlignmentSafe;
		}
	} else {
		if ( me == which ) {
			if ( DEBUG ) platform_println_term("Using native order, ignore alignment");
			machine->getWord = getWord_NativeOrder_NoAlignment;
			machine->putWord = putWord_NativeOrder_NoAlignment;
			machine->getCell = getCell_NativeOrder_NoAlignment;
			machine->putCell = putCell_NativeOrder_NoAlignment;
		} else {
			if ( DEBUG ) platform_println_term("Using swapped-native order, ignore alignment");
			machine->getWord = getWord_Swap_NoAlignment;
			machine->putWord = putWord_Swap_NoAlignment;
			machine->getCell = getCell_Swap_NoAlignment;
			machine->putCell = putCell_Swap_NoAlignment;
		}
	}

	machine->swapCell = swapCELL;
}

#define ATHROW( condition, todo, throw_code )	if (condition) {\
													todo \
													DP++; \
													datastack[ DP-1 ] = throw_code; \
													IP=GET_CELL( machine, a_throw );\
													if ( IP == 0 ) { \
														platform_println_term("Urk - no throw handler");\
														exit(0); /* FIXME */ \
													}\
													break; \
												}
void machine_execute( machine_t* machine, cell_t a_throw, int run_mode ) {
	int instruction_counter = 0;
	cell_t tmp;
	cell_t tmp2;
	cell_t tmp3;
	cell_t tmp4;

	cell_t* datastack = machine->datastack;
	cell_t* returnstack = machine->returnstack;
#define DP machine->DP
#define RP machine->RP
#define LP machine->LP
#define IP machine->IP

	while ( ( run_mode <= 0 ) || ( run_mode > instruction_counter ) ) {
		unsigned char opcode;
		instruction_counter++;
		opcode = GET_BYTE( machine, IP ); IP++;

		switch( opcode ) {
		/* debug */
		case opDEBUG:
			platform_println_term("DEBUG opcode invoked - no action");
			break;
		/* threading */
		case opCONTEXT_SWITCH:					/* new old -- */
			/* warning, if runmode = 0 we came from the bootstrap and you cannot multithread there */
			{
				uint32_t prev = datastack[ DP-1 ];
				uint32_t next = datastack[ DP-2 ];
				DP-=2;
				if ( prev == 0 ) {
					/* first boot start task */
					IP = GET_CELL( machine, next+0 );
					DP = GET_CELL( machine, next+4 );
					RP = GET_CELL( machine, next+8 );
					LP = GET_CELL( machine, next+12 );
					WRITE_CELL( machine, A_DATASTACK, GET_CELL( machine, next+16 ) );
					WRITE_CELL( machine, A_RETURNSTACK, GET_CELL( machine, next+20 ) );
		
					machine->datastack = machine->memory + ( GET_CELL( machine, A_DATASTACK ) / CELL_SIZE );
					machine->returnstack = machine->memory + ( GET_CELL( machine, A_RETURNSTACK ) / CELL_SIZE );
					/* todo these should be #defines */
					datastack = machine->datastack;
					returnstack = machine->returnstack;
				} else if ( prev == next ) {
					/* nothin to do */
				} else {
					WRITE_CELL( machine, prev+0, IP );
					WRITE_CELL( machine, prev+4, DP );
					WRITE_CELL( machine, prev+8, RP );
					WRITE_CELL( machine, prev+12, LP );
					WRITE_CELL( machine, prev+16, GET_CELL( machine, A_DATASTACK ) );
					WRITE_CELL( machine, prev+20, GET_CELL( machine, A_RETURNSTACK ) );
					IP = GET_CELL( machine, next+0 );
					DP = GET_CELL( machine, next+4 );
					RP = GET_CELL( machine, next+8 );
					LP = GET_CELL( machine, next+12 );
					WRITE_CELL( machine, A_DATASTACK, GET_CELL( machine, next+16 ) );
					WRITE_CELL( machine, A_RETURNSTACK, GET_CELL( machine, next+20 ) );
					machine->datastack = machine->memory + ( GET_CELL( machine, A_DATASTACK ) / CELL_SIZE );
					machine->returnstack = machine->memory + ( GET_CELL( machine, A_RETURNSTACK ) / CELL_SIZE );
					/* todo these should be #defines */
					datastack = machine->datastack;
					returnstack = machine->returnstack;
				}
			}	
			break;
		/* device access. Note addresses are 2 cells! */
		case opREL2ABS:
			{
				uint64_t address;
				uint8_t* ptr = (uint8_t*)(machine->memory);
				ATHROW( DP<1, ;, -4 );
				address = datastack[ DP-1 ];
				DP--;
				address = address + (uint64_t)ptr;
#ifdef VM_16BIT
#error todo  fix overflow of address on 64bit host and 16bit vm
				DP++; datastack[ DP -1 ] = ( address & 65535 );
				DP++; datastack[ DP -1 ] = ( address >> 16 ) & 65535;
#else
				DP++; datastack[ DP -1 ] = address & CELL_MASK;
				DP++; datastack[ DP -1 ] = (address>>CELL_BITS) & CELL_MASK;
#endif
			}
			break;
		case opD8FETCH:
			ATHROW( DP<2, ;, -4 );
			{
				uint64_t address;
				uint8_t* ptr = NULL;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				DP--;
				ptr = (uint8_t*)address;
				datastack[DP-1] = ptr[0];
			}
			break;
		case opD16FETCH:
			ATHROW( DP<2, ;, -4 );
			{
				uint64_t address;
				uint16_t* ptr = NULL;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				DP--;
				ptr = (uint16_t*)address;
				datastack[DP-1] = ptr[0];
			}
			break;
		case opD32FETCH:
#ifdef VM_16BIT
			ATHROW( DP<2, ;, -4 );
			{
				uint64_t address;
				uint32_t* ptr = NULL;
				uint32_t v;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				ptr = (uint32_t*)address;
				v = ptr[0];
				datastack[DP-2] = ( v & CELL_MASK );
				v>>=CELL_BITS;
				datastack[DP-1] = ( v & CELL_MASK );
			}
#else
			ATHROW( DP<2, ;, -4 );
			{
				uint64_t address;
				uint32_t* ptr = NULL;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				DP--;
				ptr = (uint32_t*)address;
				datastack[DP-1] = ptr[0];
			}
#endif
			break;
		case opD8STORE:
			ATHROW( DP<3, ;, -4 );
			{
				uint64_t address;
				uint8_t* ptr = NULL;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				ptr = (uint8_t*)address;
				DP-=2;
				ptr[0] = ( datastack[DP-1] & 255 );
				DP--;
			}
			break;
		case opD16STORE:
			ATHROW( DP<3, ;, -4 );
			{
				uint64_t address;
				uint16_t* ptr = NULL;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				ptr = (uint16_t*)address;
				DP-=2;
				ptr[0] = ( datastack[DP-1] & 0xFFFF );
				DP--;
			}
			break;
		case opD32STORE:
#ifdef VM_16BIT
			ATHROW( DP<4, ;, -4 );
			{
				uint64_t address;
				uint32_t* ptr = NULL;
				uint32_t v;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				ptr = (uint32_t*)address;
				DP-=2;
				v = datastack[ DP-1 ];
				v <<=CELL_BITS;
				v |= datastack[ DP-2 ];
				DP-=2;
				ptr[0] = v;
			}
#else
			ATHROW( DP<3, ;, -4 );
			{
				uint64_t address;
				uint32_t* ptr = NULL;
				address =  datastack[DP-1];
				address <<= CELL_BITS;
				address |= datastack[DP-2];
				ptr = (uint32_t*)address;
				DP-=2;
				ptr[0] = datastack[DP-1];
				DP--;
			}
#endif
			break;
		/* literals */
		case opLITM1: DP++; datastack[DP-1] = -1; break;
		case opLIT0: DP++; datastack[DP-1] = 0; break;
		case opLIT1: DP++; datastack[DP-1] = 1; break;
		case opLIT2: DP++; datastack[DP-1] = 2; break;
		case opLIT3: DP++; datastack[DP-1] = 3; break;
		case opLIT4: DP++; datastack[DP-1] = 4; break;
		case opLIT5: DP++; datastack[DP-1] = 5; break;
		case opLIT6: DP++; datastack[DP-1] = 6; break;
		case opLIT7: DP++; datastack[DP-1] = 7; break;
		case opLIT8: DP++; datastack[DP-1] = 8; break;
		/* locals */
		case opLPFETCH:
			DP++;
			datastack[ DP-1 ] = LP;
			break;
		case opLPSTORE:
			LP = datastack[ DP-1 ];
			DP--;
			break;
		case opLFETCH:
			tmp = datastack[ DP-1 ];
			tmp += LP;
			datastack[ DP-1 ] = returnstack[ tmp ];
			break;
		case opLSTORE:
			tmp = datastack[ DP-1 ];
			tmp += LP;
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			returnstack[ tmp ] = tmp2;
			break;
		/* files */
		case opCREATE_FILE:
			ATHROW( DP<3, ;, -4 );
			tmp = datastack[ DP-1 ]; DP--;		
			tmp2 = datastack[ DP-1 ];			
			tmp3 = datastack[ DP-2 ];			
			{
				int fd;
				int ior = ioCreate( (const char*)ABS_PTR( machine, tmp3 ), tmp2, tmp, &fd );
				datastack[ DP-2 ] = (cell_t)fd;
				datastack[ DP-1 ] = (cell_t)ior;
			}
			break;
		case opOPEN_FILE:
			ATHROW( DP<3, ;, -4 );
			tmp = datastack[ DP-1 ]; DP--;		
			tmp2 = datastack[ DP-1 ];			
			tmp3 = datastack[ DP-2 ];			
			{
				int fd;
				int ior = ioOpen( (const char*)ABS_PTR( machine, tmp3 ), tmp2, tmp, &fd );
				datastack[ DP-2 ] = (cell_t)fd;
				datastack[ DP-1 ] = (cell_t)ior;
			}
			break;
		case opCLOSE_FILE:
			ATHROW( DP<1, ;, -4 );
			datastack[DP-1] = (cell_t)ioClose( (int)datastack[ DP-1 ] );
			break;
		case opREAD_FILE:
			ATHROW( DP<3, ;, -4 );
			tmp = datastack[ DP-1 ]; DP--;		
			tmp2 = datastack[ DP-1 ];			
			tmp3 = datastack[ DP-2 ];			
			{
				int i = ioRead( (int)tmp, ABS_PTR(machine,tmp3), tmp2 );
				if ( i < 0 ) {
					datastack[ DP-2 ] = 0;
					datastack[ DP-1 ] = (cell_t)i;
				} else {
					datastack[ DP-2 ] = (cell_t)i;
					datastack[ DP-1 ] = IOR_OK;		
				}
			}
			break;
		case opWRITE_FILE:
			ATHROW( DP<3, ;, -4 );
			tmp = datastack[ DP-1 ]; DP--;		
			tmp2 = datastack[ DP-1 ]; DP--;		
			tmp3 = datastack[ DP-1 ];			
			{
				datastack[ DP-1 ] = (cell_t)ioWrite( (int)tmp, ABS_PTR( machine, tmp3 ), tmp2 );
			}
			break;
		case opDELETE_FILE:
			tmp = datastack[ DP-1 ]; DP--;
			datastack[DP-1] = (cell_t)IOR_NOT_SUPPORTED;
			break;
		case opRENAME_FILE:
			tmp = datastack[DP-1]; DP--;		
			tmp2 = datastack[DP-1]; DP--;	
			tmp3 = datastack[DP-1]; DP--;
			datastack[DP-1] = (cell_t)IOR_NOT_SUPPORTED;
			break;
		case opREPOSITION_FILE:
			tmp = datastack[DP-1];
			{
				uint64_t p = datastack[DP-2] & CELL_MASK;
				p<<=CELL_BITS;
				p|=(datastack[DP-3] & CELL_MASK);
				DP-=2;
				datastack[DP-1] = (cell_t)ioSeek( (int)tmp, p );
			}
			break;
		case opRESIZE_FILE:
			DP-=2;
			datastack[DP-1] = (cell_t)IOR_NOT_SUPPORTED;
			break;
		case opFILE_POSITION:		
			{
				unsigned long long int length;
				ior_t ior = ioPosition( (int)datastack[ DP-1 ], &length );
				if ( ior != IOR_OK ) length = 0;
				DP+=2;
				/* TODO check length fits and raise error if not */
				datastack[ DP-3 ] = length & CELL_MASK;
				datastack[ DP-2 ] = ( length >> CELL_BITS ) & CELL_MASK;
				datastack[ DP-1 ] = (cell_t)ior;
			}
			break;
		case opFILE_SIZE:	
			{
				unsigned long long int length;
				ior_t ior = ioSize( (int)datastack[ DP-1 ], &length );
				if ( ior != IOR_OK ) length = 0;
				DP+=2;
				/* TODO check length fits and raise error if not */
				datastack[ DP-3 ] = length & CELL_MASK;
				datastack[ DP-2 ] = ( length >> CELL_BITS ) & CELL_MASK;
				datastack[ DP-1 ] = (cell_t)ior;
			}
			break;
		case opFILE_STATUS:
			datastack[ DP-2 ] = 0;
			datastack[ DP-1 ] = (cell_t)IOR_OK;
			break;
		case opFLUSH_FILE:
			datastack[DP-1] = (cell_t)IOR_NOT_SUPPORTED;
			break;
		/* internal magic */
		case opBYE:	
			platform_println_term("\n\nBYE!!!\n\n");
			return;
			break;
		case opIP:
			datastack[ DP ] = IP;
			DP++;
			break;
		case opRSPFETCH:
			datastack[ DP ] = RP;
			DP++;
			break;
		case opRSPSTORE:
			RP = datastack[ DP-1 ];
			DP--;
			break;
		case opSPFETCH:
			datastack[ DP ] = DP;
			DP++;
			break;
		case opSPSTORE:
			DP = datastack[ DP-1 ];
			break;
		/* calls, jumps etc */
		case opEXECUTE:
			ATHROW( DP<1, ;, -4 );
			returnstack[ RP ] = IP;
			RP++;
			IP = datastack[ DP-1 ];
			DP--;
			break;
		case opQBRANCH:
			tmp = datastack[ DP-1 ];
			DP--;
			if ( tmp == 0 ) {
				int i;
				tmp = GET_WORD( machine, IP );
				if ( tmp & 0x8000 ) tmp |= 0xFFFF0000;
				i = (int) tmp;	
				IP=IP+2+i;
			}
			else IP+=2;
			break;			
		case opBRANCH:
			{
				int i;
				tmp = GET_WORD( machine, IP );
				if ( tmp & 0x8000 ) tmp |= 0xFFFF0000;
				i = (int) tmp;	
				IP=IP+2+i;
			}
			break;
		case opSHORT_CALL:
			returnstack[ RP ] = IP+2;
			RP++;
			IP = GET_WORD( machine, IP );
			break;
		case opCALL:
			returnstack[ RP ] = IP+CELL_SIZE;
			RP++;
			IP = GET_CELL( machine, IP );
			break;
		case opJUMP:
			DP--;
			IP=datastack[DP];
			break;
		/* exit and ret are the same thing, it just helps the disassembler to 
		   know the difference between return from inside a word and at the
		   end of a word */
		case opEXIT:
		case opRET:
			if ( RP == 0 ) {
				if ( run_mode == 0 )
					return;			/* run a single word from boot strap interpreter */
				/* stack underflow */
				platform_println_term("return stack underflow");
				DP++;
				datastack[ DP-1 ] = -6;
				IP=GET_CELL( machine, a_throw );
			} else {
				RP--;
				IP=returnstack[ RP ];
			}
			break;
		/* stackrobatics */
		case opDEPTH:
			datastack[ DP ] = DP;
			DP++;
			break;
		case opNIP:
			ATHROW( DP<2, ;, -4 );
			datastack[ DP-2 ] = datastack[ DP-1 ];
			DP--;
			break;
		case opTUCK:	
			ATHROW( DP<2, ;, -4 );
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP++;
			datastack[ DP-3 ] = tmp;
			datastack[ DP-2 ] = tmp2;
			datastack[ DP-1 ] = tmp;
			break;
		case opROLL:
			ATHROW( DP<1, ;, -4 );
			tmp = datastack[ DP-1 ];
			DP--;
			if ( tmp ) {
				ATHROW( DP<tmp, ;, -4 );
				tmp2 = datastack[ DP-1-tmp ];
				memmove( datastack+DP-1-tmp, datastack+DP-tmp, tmp*CELL_SIZE );
				datastack[ DP-1 ] = tmp2;
			}
			break;
		case opQDUP:
			ATHROW( DP<1, ;, -4 );
			if ( datastack[DP-1] ) {
				datastack[ DP ] = datastack[ DP-1 ];
				DP++;
			}
			break;
		case opDUP:
			ATHROW( DP<1, ;, -4 );
			datastack[ DP ] = datastack[ DP-1 ];
			DP++;
			break;
		case op2DUP:
			ATHROW( DP<2, ;, -4 );
			DP+=2;
			datastack[ DP-2 ] = datastack[ DP-4 ];
			datastack[ DP-1 ] = datastack[ DP-3 ];
			break;
		case opDROP:
			ATHROW( DP<1, ;, -4 );
			DP--;
			break;
		case op2DROP:
			ATHROW( DP<2, ;, -4 );
			DP-=2;
			break;
		case opOVER:
			ATHROW( DP<2, ;, -4 );
			datastack[ DP ] = datastack[ DP - 2 ];
			DP++;
			break;
		case op2OVER: 	
			ATHROW( DP<4, ;, -4 );
			DP+=2;
			datastack[ DP-2 ] = datastack[ DP-6 ];
			datastack[ DP-1 ] = datastack[ DP-5 ];
			break;
		case opSWAP:
			ATHROW( DP<2, ;, -4 );
			tmp = datastack[ DP-2 ];
			datastack[ DP-2 ] = datastack[ DP-1 ];
			datastack[ DP-1 ] = tmp;
			break;
		case op2SWAP:	
			ATHROW( DP<4, ;, -4 );
			tmp = datastack[ DP-2 ];
			tmp2 = datastack[ DP-1 ];
			datastack[ DP-2 ] = datastack[ DP-4 ];
			datastack[ DP-1 ] = datastack[ DP-3 ];
			datastack[ DP-4 ] = tmp;
			datastack[ DP-3 ] = tmp2;
			break;
		case opPICK:
			ATHROW( DP<1, ;, -4 );
			tmp = datastack[ DP-1 ];
			ATHROW( DP<(tmp+2), ;, -4 );
			datastack[ DP-1 ] = datastack[ DP - tmp - 2 ];
			break;
		case opROT:
			ATHROW( DP<3, ;, -4 );
			tmp = datastack[ DP-3 ];
			datastack[ DP-3 ] = datastack[ DP-2 ];
			datastack[ DP-2 ] = datastack[ DP-1 ];
			datastack[ DP-1 ] = tmp;
			break;
		/* comparisons */
		case opU_GREATER_THAN:
			ATHROW( DP<2, ;, -4 );
			datastack[ DP-2 ] = datastack[ DP-2 ] > datastack[ DP-1 ] ? 1 : 0;
			DP--;
			break;
		case opU_LESS_THAN:
			ATHROW( DP<2, ;, -4 );
			datastack[ DP-2 ] = datastack[ DP-2 ] < datastack[ DP-1 ] ? 1 : 0;
			DP--;
			break;
		case opGREATER_THAN:
			ATHROW( DP<2, ;, -4 );
			{	
				s_cell_t a,b;
				b = datastack[ DP-1 ];
				DP--;
				a = datastack[ DP-1 ];
				datastack[ DP-1 ] = ( a > b ) ? 1 : 0;
			}
			break;
		case opDULESSTHAN:
			ATHROW( DP<4, ;, -4 );
			{
				uint64_t a,b;

				a = (s_cell_t)datastack[DP-3]; 
				a<<=CELL_BITS;
				a|= datastack[DP-4];

				b = (s_cell_t)datastack[DP-1]; 
				b<<=CELL_BITS;
				b|= datastack[DP-2];

				DP-=3;
	
				datastack[DP-1] = ( a < b ) ? 1 : 0 ;
			}
			break;
		case opDLESSTHAN:
			ATHROW( DP<4, ;, -4 );
			{
				int64_t a,b;

				a = (s_cell_t)datastack[DP-3]; 
				a<<=CELL_BITS;
				a|= datastack[DP-4];

				b = (s_cell_t)datastack[DP-1]; 
				b<<=CELL_BITS;
				b|= datastack[DP-2];

				DP-=3;
	
				datastack[DP-1] = ( a < b ) ? 1 : 0 ;
			}
			break;
		case opLESS_THAN:
			ATHROW( DP<2, ;, -4 );
			{
				s_cell_t a,b;
				b = datastack[ DP-1 ];
				DP--;
				a = datastack[ DP-1 ];
				datastack[ DP-1 ] = ( a < b ) ? 1 : 0;
			}
			break;
		case opEQUALS:	
			ATHROW( DP<2, ;, -4 );
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] == datastack[ DP ] ? 1 : 0;
			break;
		/* fetch/store */
		case opWFETCH:
			ATHROW( DP<1, ;, -4 );
			datastack[ DP-1 ] = GET_WORD( machine, datastack[ DP-1 ] );
			break;
		case opCFETCH:
			ATHROW( DP<1, ;, -4 );
			datastack[ DP-1 ] = GET_BYTE( machine, datastack[ DP-1 ] );
			break;
		case opFETCH:
			ATHROW( DP<1, ;, -4 );
			datastack[ DP-1 ] = GET_CELL( machine, datastack[ DP-1 ] );
			break;
		case opPLUSSTORE:
			ATHROW( DP<2, ;, -4 );
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			WRITE_CELL( machine, tmp, GET_CELL(machine, tmp) + tmp2 );
			break;
		case opWSTORE:
			ATHROW( DP<2, ;, -4 );
			tmp = datastack[ DP-1 ];
			WRITE_WORD( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		case opCSTORE:
			ATHROW( DP<2, ;, -4 );
			tmp = datastack[ DP-1 ];
			WRITE_BYTE( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		case opSTORE:
			ATHROW( DP<2, ;, -4 );
			tmp = datastack[ DP-1 ];
			WRITE_CELL( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		/* return stack fetch/store */
		case opRFETCH:
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			break;
		case op2RFETCH:
			datastack[ DP ] = returnstack[ RP-2 ];
			DP++;
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			break;
		case opTOR:
			ATHROW( DP<1, ;, -4 );
			DP--;
			returnstack[ RP ] = datastack[ DP ];
			RP++;
			break;
		case op2TOR:
			ATHROW( DP<2, ;, -4 );
			returnstack[ RP ] = datastack[ DP-2 ];
			RP++;
			returnstack[ RP ] = datastack[ DP-1 ];
			RP++;
			DP-=2;
			break;
		case opRFROM:
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			RP--;
			break;
		case op2RFROM:
			datastack[ DP ] = returnstack[ RP-2 ];
			DP++;
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			RP-=2;
			break;
		/* memory */
		case opICOMPARE:
			tmp = datastack[ DP-4 ];
			tmp2 = datastack[ DP-3 ];
			tmp3 = datastack[ DP-2 ];
			tmp4 = datastack[ DP-1 ];
			DP-=3;
			datastack[ DP-1 ] = cmp( (const char*)ABS_PTR( machine, tmp ), tmp2, (const char*)ABS_PTR( machine, tmp3 ), tmp4, 0 );
			break;
		case opCOMPARE:
			tmp = datastack[ DP-4 ];
			tmp2 = datastack[ DP-3 ];
			tmp3 = datastack[ DP-2 ];
			tmp4 = datastack[ DP-1 ];
			DP-=3;
			datastack[ DP-1 ] = cmp( (const char*)ABS_PTR( machine, tmp ), tmp2, (const char*)ABS_PTR( machine, tmp3 ), tmp4, 1 );
			break;
		case opMOVE:
			tmp = datastack[ DP-3 ];
			tmp2 = datastack[ DP-2 ];
			tmp3 = datastack[ DP-1 ];
			DP-=3;
		    if ( tmp3 > 0 )
				memmove( ABS_PTR( machine, tmp2 ), ABS_PTR( machine, tmp ), tmp3 );
			break;
		/* simple math */
		case opINC:
			datastack[DP-1] = datastack[DP-1]+1;
			break;
		case opDEC:
			datastack[DP-1] = datastack[DP-1]-1;
			break;
		case opMULT:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] * datastack[ DP ];
			break;
		case opPLUS:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] + datastack[ DP ];
			break;
		case opMINUS:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] - datastack[ DP ];
			break;
		case opONEPLUS:
			datastack[ DP-1 ]++;
			break;
		case opONEMINUS:
			datastack[ DP-1 ]--;
			break;
		/* math */
		case opMULT2:
			tmp2 = datastack[ DP-1 ];
			tmp3 = datastack[ DP-2 ];
			{
				union {
					int32_t i;
					uint32_t u;
				} v, u;
				int64_t V, U;
				v.u = tmp2;
				u.u = tmp3;
				V = v.i;
				U = u.i;
				V*=U;
				tmp3 = V & CELL_MASK;
				V>>=CELL_BITS;
				tmp2 = V & CELL_MASK;
			}
			datastack[ DP-1 ] = tmp2;
			datastack[ DP-2 ] = tmp3;
			break;
		case opDMINUS:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			tmp3 = datastack[ DP-1 ];
			tmp4 = datastack[ DP-2 ];
			{
				uint64_t v, w;
				v = tmp; v<<=CELL_BITS; v|=tmp2;
				w = tmp3; w<<=CELL_BITS; w|=tmp4;
				w-=v;
				tmp4 = w & CELL_MASK;
				w>>=CELL_BITS;
				tmp3 = w & CELL_MASK;
			}
			datastack[ DP-1 ] = tmp3;
			datastack[ DP-2 ] = tmp4;
			break;
		case opADD2:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			tmp3 = datastack[ DP-1 ];
			tmp4 = datastack[ DP-2 ];
			{
				uint64_t v, w;
				v = tmp; v<<=CELL_BITS; v|=tmp2;
				w = tmp3; w<<=CELL_BITS; w|=tmp4;
				w+=v;
				tmp4 = w & CELL_MASK;
				w>>=CELL_BITS;
				tmp3 = w & CELL_MASK;
			}
			datastack[ DP-1 ] = tmp3;
			datastack[ DP-2 ] = tmp4;
			break;
		case opUMULT2:
			tmp2 = datastack[ DP-1 ];
			tmp3 = datastack[ DP-2 ];
			{
				cell_t v = tmp2;
				cell_t u = tmp3;
				uint64_t V = v;
				uint64_t U = u;
				V*=U;
				tmp3 = V & CELL_MASK;
				V>>=CELL_BITS;
				tmp2 = V & CELL_MASK;
			}
			datastack[ DP-1 ] = tmp2;
			datastack[ DP-2 ] = tmp3;
			break;
		case opUMULT:
			tmp = datastack[ DP-1 ];		
			DP--;
			tmp2 = datastack[ DP-1 ];
			tmp3 = datastack[ DP-2 ];
			{
				uint64_t v = tmp2; v<<=CELL_BITS; v|=tmp3;
				v*=tmp;
				tmp3 = v & CELL_MASK;
				v>>=CELL_BITS;
				tmp2 = v & CELL_MASK;
			}
			datastack[ DP-1 ] = tmp2;
			datastack[ DP-2 ] = tmp3;
			break;
		case opSM_SLASH_REM:
			{
				int32_t n = (int32_t)datastack[ DP - 1 ];
				int32_t a, b;
				int64_t v = datastack[ DP-2 ];
				v<<=CELL_BITS;
				v|=datastack[ DP-3 ];
				a = (int32_t)(v / n);
				b = (int32_t)(v % n);
				DP--;
				datastack[ DP-2 ] = (cell_t)b;
				datastack[ DP-1 ] = (cell_t)a;
			}
			break;
		case opUM_SLASH_MOD:
			tmp = datastack[ DP-1 ];		
			DP--;
			{
				uint64_t v = datastack[ DP-1 ];
				v<<=CELL_BITS;
				v|=datastack[ DP-2 ];

				tmp2 = v / tmp;
				tmp3 = v % tmp;

				datastack[ DP-2 ] = tmp3;
				datastack[ DP-1 ] = tmp2;
			}
			break;
		/* io */
		case opEKEY:
			{
				int rc = platform_read_term();
				DP++;
				datastack[DP-1] = rc;
			}
			break;
		case opEMIT:
			{
				unsigned char c;
				tmp = datastack[DP-1];
				DP--;
				c = tmp & 255;
				platform_write_term( c );
			}
			break;
		/* logic */
		case opLSHIFT:
			tmp = datastack[DP-1]; DP--;
			datastack[ DP-1 ] = datastack[DP-1] << tmp;
			break;
		case opRSHIFT:
			tmp = datastack[DP-1]; DP--;
			datastack[ DP-1 ] = datastack[DP-1] >> tmp;
			break;
		case opINVERT:
			{
				cell_t v = 1;
				tmp = datastack[ DP-1 ];
				tmp2 = 0;
				int i;
				for ( i = 0; i < CELL_BITS; i++ ) {
					if ( ( tmp & v ) == 0 ) tmp2|=v;
					v<<=1;
				}
				datastack[ DP-1 ] = tmp2;
			}
			break;
		case opZEROEQ:
			datastack[ DP-1 ] = datastack[ DP-1 ] ? 0 : 1;
			break;
		case opXOR:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] ^ datastack[ DP ];
			break;
		case opOR:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] | datastack[ DP ];
			break;
		case opAND:
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] & datastack[ DP ];
			break;
		/* others */
		case opDOCSTR:
			DP++;
			datastack[ DP-1 ] = IP;
			IP = IP + 1 + GET_BYTE( machine, IP );
			break;
		case opDOLIT:
			datastack[ DP ] = GET_CELL( machine, IP );
			DP++;
			IP+=CELL_SIZE;
			break;
		case opDOLIT_U8:
			datastack[ DP ] = GET_BYTE( machine, IP );
			DP++;
			IP+=1;
			break;
		case opDOLIT_U16:
			datastack[ DP ] = GET_WORD( machine, IP );
			DP++;
			IP+=2;
			break;
		case opQTHROW:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			ATHROW( tmp, ;, tmp2 );
			break;
		case opNONE:
			break;
		default:
			ATHROW( 1, ;, -9 );
			break;
		}
	}		
}

