

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <unistd.h>

#include "common.h"
#include "io.h"
#include "io_file.h"
#include "machine.h"
#include "opcode.h"

static uint16_t swap16( uint16_t v ) { return ((v>>8)&0xFF)|((v<<8)&0xFF00); }
static uint32_t swap32( uint32_t v ) { return ((v>>24)&0xFF)|((v>>8)&0xFF00)|((v<<8)&0xFF0000)|((v<<24)&0xFF000000); }
static uint16_t noswap16( uint16_t v ) { return v; }
static uint32_t noswap32( uint32_t v ) { return v; }

void machine_init( machine_t* machine ) {
	ioInit();
	ioRegister( &io_file );
	machine->DP = 0;
	machine->RP = 0;
	machine->LP = 0;
}

void machine_set_endian( machine_t* machine, machine_endian_t which ) {
	uint32_t value = 0x11223344;
	uint8_t* p = (uint8_t*)&value;
	machine_endian_t me = (p[0] == 0x11) ? ENDIAN_BIG : ENDIAN_LITTLE;
	if ( ( me == which ) || ( which == ENDIAN_NATIVE ) ) {
		machine->swap16 = noswap16;
		machine->swap32 = noswap32;
	} else {
		machine->swap16 = swap16;
		machine->swap32 = swap32;
	}
}

void machine_execute( machine_t* machine, uint32_t xt ) {

	uint32_t tmp;
	uint32_t tmp2;
	uint32_t tmp3;
	uint32_t tmp4;

	uint32_t IP=xt;
	uint32_t* datastack = machine->datastack;
	uint32_t* returnstack = machine->returnstack;
#define DP machine->DP
#define RP machine->RP
#define LP machine->LP

	for (;;) {
		unsigned char opcode;

		opcode = GET_BYTE( machine, IP ); IP++;

		switch( opcode ) {
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
		case opDELETE_FILE:
			tmp = datastack[ DP-1 ]; DP--;
			datastack[DP-1] = (uint32_t)ioDelete( ABS_PTR(machine,datastack[DP-1]), tmp );
			break;
		case opRENAME_FILE:
			tmp = datastack[DP-1]; DP--;		// tmp = newlen
			tmp2 = datastack[DP-1]; DP--;		// tmp2 = newname
			tmp3 = datastack[DP-1]; DP--;		// tmp3 = len
			datastack[DP-1] = (uint32_t)ioRename( ABS_PTR(machine,datastack[DP-1]), tmp3, ABS_PTR(machine,tmp2), tmp );
			break;
		case opREPOSITION_FILE:
			/* assuming 31bit file length */
			{
				int i = ioReposition( (int)datastack[ DP-1 ], (int)datastack[ DP-3 ] );
				DP-=2;
				datastack[ DP-1 ] = (uint32_t)i;
			}
			break;
		case opRESIZE_FILE:
			/* assuming 31bit file length */
			{
				int i = ioResize( (int)datastack[ DP-1 ], (int)datastack[ DP-3 ] );
				DP-=2;
				datastack[ DP-1 ] = (uint32_t)i;
			}
			break;
		case opFILE_POSITION:		/* note, I'm not doing 64bit, never having files that big */
			{
				int i = ioPosition( (int)datastack[DP-1] );
				if ( i < 0 ) {
					datastack[ DP-1 ] = 0; 
					DP++; datastack[ DP-1 ] = 0;
					DP++; datastack[ DP-1 ] = (uint32_t)i;
				} else {
					datastack[ DP-1 ] = (uint32_t)i;
					DP++; datastack[ DP-1 ] = 0;
					DP++; datastack[ DP-1 ] = 0;
				}
			}
			break;
		case opFILE_SIZE:		/* note, I'm not doing 64bit, never having files that big */
			{
				int i = ioSize( (int)datastack[DP-1] );
				if ( i < 0 ) {
					datastack[ DP-1 ] = 0; 
					DP++; datastack[ DP-1 ] = 0;
					DP++; datastack[ DP-1 ] = (uint32_t)i;
				} else {
					datastack[ DP-1 ] = (uint32_t)i;
					DP++; datastack[ DP-1 ] = 0;
					DP++; datastack[ DP-1 ] = 0;
				}
			}
			break;
		case opFILE_STATUS:
			// cant really think of anything atm. I want to report.
			datastack[ DP-2 ] = 0;
			datastack[ DP-1 ] = 0;
			break;
		case opWRITE_FILE:
			tmp = datastack[ DP-1 ]; DP--;		// tmp is 'file-id'
			tmp2 = datastack[ DP-1 ]; DP--;		// tmp2 is length
			tmp3 = datastack[ DP-1 ];			// tmp3 is pointer
			{
				int i = ioWrite( (int)tmp, ABS_PTR( machine, tmp3 ), tmp2 );
				if ( i < 0 ) datastack[ DP-1 ] = (uint32_t) i;
				else		 datastack[ DP-1 ] = 0;
			}
			break;
		case opREAD_FILE:
			tmp = datastack[ DP-1 ]; DP--;		// tmp is 'file-id'
			tmp2 = datastack[ DP-1 ];			// tmp2 is length
			tmp3 = datastack[ DP-2 ];			// tmp3 is pointer
			{
				int i = ioRead( (int)tmp, ABS_PTR(machine,tmp3), tmp2 );
				if ( i < 0 ) {
					datastack[ DP-2 ] = 0;				// bytes read
					datastack[ DP-1 ] = (uint32_t)i;
				} else {
					datastack[ DP-2 ] = (uint32_t)i;
					datastack[ DP-1 ] = 0;		
				}
			}
			break;
		case opOPEN_FILE:
			tmp = datastack[ DP-1 ]; DP--;		// tmp is 'fam'
			tmp2 = datastack[ DP-1 ];			// tmp2 is length of name
			tmp3 = datastack[ DP-2 ];			// tmp3 is name pointer
			{
				int i = ioOpen( ABS_PTR( machine, tmp3 ), tmp2, tmp );
				if ( i < 0 ) {
					datastack[ DP-2 ] = 0;
					datastack[ DP-1 ] = (uint32_t)i;
				} else {
					datastack[ DP-2 ] = (uint32_t)i;
					datastack[ DP-1 ] = 0;
				}
			}
			break;
		case opCREATE_FILE:
			tmp = datastack[ DP-1 ]; DP--;		// tmp is 'fam'
			tmp2 = datastack[ DP-1 ];			// tmp2 is length of name
			tmp3 = datastack[ DP-2 ];			// tmp3 is name pointer
			{
				int i = ioCreate( ABS_PTR( machine, tmp3 ), tmp2, tmp );
				if ( i < 0 ) {
					datastack[ DP-2 ] = 0;
					datastack[ DP-1 ] = (uint32_t)i;
				} else {
					datastack[ DP-2 ] = (uint32_t)i;
					datastack[ DP-1 ] = 0;
				}
			}
			break;
		case opFLUSH_FILE:
			datastack[DP-1] = (uint32_t)ioFlush( (int)datastack[ DP-1 ] );
			break;
		case opCLOSE_FILE:
			datastack[DP-1] = (uint32_t)ioClose( (int)datastack[ DP-1 ] );
			break;
		/* internal magic */
		case opNONE:
			printf("Bang\n"); 
			exit(0);
			break;			
		case opBYE:
			exit(0);
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
			returnstack[ RP ] = IP;
			RP++;
			IP = datastack[ DP-1 ];
			DP--;
			break;
		case opJUMP_EQ:
			tmp = datastack[ DP-1 ] == datastack[ DP-2 ];
			DP-=2;
			if ( tmp ) IP = GET_CELL( machine, IP );
			else IP+=4;
			break;			
		case opJUMP_EQ_ZERO:
			tmp = datastack[ DP-1 ];
			DP--;
			if ( tmp == 0 ) IP = GET_CELL( machine, IP );
			else IP+=4;
			break;			
		case opJUMPD:
			IP=datastack[DP-1];
			DP--;
			break;
		case opJUMP:
			IP=GET_CELL( machine, IP );
			break;
		case opSHORT_CALL:
			returnstack[ RP ] = IP+2;
			RP++;
			IP = GET_WORD( machine, IP );
			break;
		case opCALL:
			returnstack[ RP ] = IP+4;
			RP++;
			IP = GET_CELL( machine, IP );
			break;
		case opRET:
			if ( RP == 0 ) {
				return;
			}
			RP--;
			IP=returnstack[ RP ];
			break;
		/* stackrobatics */
		case opDEPTH:
			datastack[ DP ] = DP;
			DP++;
			break;
		case opNIP:
			datastack[ DP-2 ] = datastack[ DP-1 ];
			DP--;
			break;
		case opTUCK:	
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP++;
			datastack[ DP-3 ] = tmp;
			datastack[ DP-2 ] = tmp2;
			datastack[ DP-1 ] = tmp;
			break;
		case opROLL:
			tmp = datastack[ DP-1 ];
			DP--;
			if ( tmp ) {
				tmp2 = datastack[ DP-1-tmp ];
				memmove( datastack+DP-1-tmp, datastack+DP-tmp, tmp*4 );
				datastack[ DP-1 ] = tmp2;
			}
			break;
		case opDUP:
			datastack[ DP ] = datastack[ DP-1 ];
			DP++;
			break;
		case op2DUP:
			DP+=2;
			datastack[ DP-2 ] = datastack[ DP-4 ];
			datastack[ DP-1 ] = datastack[ DP-3 ];
			break;
		case opDROP:
			DP--;
			break;
		case op2DROP:
			DP-=2;
			break;
		case opOVER:
			datastack[ DP ] = datastack[ DP - 2 ];
			DP++;
			break;
		case op2OVER: 	
			DP+=2;
			datastack[ DP-2 ] = datastack[ DP-6 ];
			datastack[ DP-1 ] = datastack[ DP-5 ];
			break;
		case opSWAP:
			tmp = datastack[ DP-2 ];
			datastack[ DP-2 ] = datastack[ DP-1 ];
			datastack[ DP-1 ] = tmp;
			break;
		case op2SWAP:	
			tmp = datastack[ DP-2 ];
			tmp2 = datastack[ DP-1 ];
			datastack[ DP-2 ] = datastack[ DP-4 ];
			datastack[ DP-1 ] = datastack[ DP-3 ];
			datastack[ DP-4 ] = tmp;
			datastack[ DP-3 ] = tmp2;
			break;
		case opPICK:
			datastack[ DP-1 ] = datastack[ DP - datastack[ DP - 1 ] - 2 ];
			break;
		case opROT:
			tmp = datastack[ DP-3 ];
			datastack[ DP-3 ] = datastack[ DP-2 ];
			datastack[ DP-2 ] = datastack[ DP-1 ];
			datastack[ DP-1 ] = tmp;
			break;
		/* comparisons */
		case opU_GREATER_THAN:
			datastack[ DP-2 ] = datastack[ DP-2 ] > datastack[ DP-1 ] ? 1 : 0;
			DP--;
			break;
		case opU_LESS_THAN:
			datastack[ DP-2 ] = datastack[ DP-2 ] < datastack[ DP-1 ] ? 1 : 0;
			DP--;
			break;
		case opGREATER_THAN:
			{
				int b = datastack[ DP-1 ];
				DP--;
				int a = datastack[ DP-1 ];
				datastack[ DP-1 ] = ( a > b ) ? 1 : 0;
			}
			break;
		case opLESS_THAN:
			{
				int b = datastack[ DP-1 ];
				DP--;
				int a = datastack[ DP-1 ];
				datastack[ DP-1 ] = ( a < b ) ? 1 : 0;
			}
			break;
		case opEQUALS:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] == datastack[ DP ] ? 1 : 0;
			break;
		/* fetch/store */
		case opWFETCH:
			datastack[ DP-1 ] = GET_WORD( machine, datastack[ DP-1 ] );
			break;
		case opCFETCH:
			datastack[ DP-1 ] = GET_BYTE( machine, datastack[ DP-1 ] );
			break;
		case opFETCH:
			datastack[ DP-1 ] = GET_CELL( machine, datastack[ DP-1 ] );
			break;
		case opPLUSSTORE:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			WRITE_CELL( machine, tmp, GET_CELL(machine, tmp) + tmp2 );
			break;
		case opWSTORE:
			tmp = datastack[ DP-1 ];
			WRITE_WORD( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		case opCSTORE:
			tmp = datastack[ DP-1 ];
			WRITE_BYTE( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		case opSTORE:
			tmp = datastack[ DP-1 ];
			WRITE_CELL( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		/* return stack fetch/store */
		case opRFETCH:
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			break;
		case opTOR:
			DP--;
			returnstack[ RP ] = datastack[ DP ];
			RP++;
			break;
		case opRFROM:
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			RP--;
			break;
		/* memory */
		case opCOMPARE:
			tmp = datastack[ DP-3 ];
			tmp2 = datastack[ DP-2 ];
			tmp3 = datastack[ DP-1 ];
			DP-=2;
			datastack[ DP-1 ] = cmp( ABS_PTR( machine, tmp ), ABS_PTR( machine, tmp2 ), tmp3 );
			break;
		case opMOVE:
			tmp = datastack[ DP-3 ];
			tmp2 = datastack[ DP-2 ];
			tmp3 = datastack[ DP-1 ];
			DP-=3;
		    if ( tmp3 > 0 )
				memmove( ABS_PTR( machine, tmp2 ), ABS_PTR( machine, tmp ), tmp3 );
			break;
		/* math */
		case opADD2:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			tmp3 = datastack[ DP-1 ];
			tmp4 = datastack[ DP-2 ];
			{
				uint64_t v = tmp; v<<=32; v|=tmp2;
				uint64_t w = tmp3; w<<=32; w|=tmp4;
				w+=v;
				tmp4 = w & 0xFFFFFFFF;
				w>>=32;
				tmp3 = w & 0xFFFFFFFF;
			}
			datastack[ DP-1 ] = tmp3;
			datastack[ DP-2 ] = tmp4;
			break;
		case opUMULT:
			tmp = datastack[ DP-1 ];		
			DP--;
			tmp2 = datastack[ DP-1 ];
			tmp3 = datastack[ DP-2 ];
			{
				uint64_t v = tmp2; v<<=32; v|=tmp3;
				v*=tmp;
				tmp3 = v & 0xFFFFFFFF;
				v>>=32;
				tmp2 = v & 0xFFFFFFFF;
			}
			datastack[ DP-1 ] = tmp2;
			datastack[ DP-2 ] = tmp3;
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
		case opUM_SLASH_MOD:
			tmp = datastack[ DP-1 ];		// divisor
			DP--;
			{
				uint64_t v = datastack[ DP-1 ];
				v<<=32;
				v|=datastack[ DP-2 ];

				tmp2 = v / tmp;
				tmp3 = v % tmp;

				datastack[ DP-2 ] = tmp3;
				datastack[ DP-1 ] = tmp2;
			}
			break;
		/* io */
		case opIN:
			datastack[ DP ] = getchar();
			DP++;
			break;
		case opEMIT:
			putchar( datastack[DP-1] );
			DP--;
			break;
		/* logic */
		case opNOT:
			datastack[ DP-1 ] = datastack[ DP-1 ] ? 0 : 1;
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
		case opDOLIT:
			datastack[ DP ] = GET_CELL( machine, IP );
			DP++;
			IP+=4;
			break;
		default:
			printf("Illegal opcode [%x]\n", opcode );
			exit(0);
			break;
		}
	}		
}

