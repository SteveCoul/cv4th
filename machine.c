

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
		case OPCODE_LPFETCH:
			DP++;
			datastack[ DP-1 ] = LP;
			break;
		case OPCODE_LPSTORE:
			LP = datastack[ DP-1 ];
			DP--;
			break;
		case OPCODE_LFETCH:
			tmp = datastack[ DP-1 ];
			tmp += LP;
			datastack[ DP-1 ] = returnstack[ tmp ];
			break;
		case OPCODE_LSTORE:
			tmp = datastack[ DP-1 ];
			tmp += LP;
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			returnstack[ tmp ] = tmp2;
			break;
		/* files */
		case OPCODE_DELETE_FILE:
			tmp = datastack[ DP-1 ]; DP--;
			datastack[DP-1] = (uint32_t)ioDelete( ABS_PTR(machine,datastack[DP-1]), tmp );
			break;
		case OPCODE_RENAME_FILE:
			tmp = datastack[DP-1]; DP--;		// tmp = newlen
			tmp2 = datastack[DP-1]; DP--;		// tmp2 = newname
			tmp3 = datastack[DP-1]; DP--;		// tmp3 = len
			datastack[DP-1] = (uint32_t)ioRename( ABS_PTR(machine,datastack[DP-1]), tmp3, ABS_PTR(machine,tmp2), tmp );
			break;
		case OPCODE_REPOSITION_FILE:
			/* assuming 31bit file length */
			{
				int i = ioReposition( (int)datastack[ DP-1 ], (int)datastack[ DP-3 ] );
				DP-=2;
				datastack[ DP-1 ] = (uint32_t)i;
			}
			break;
		case OPCODE_RESIZE_FILE:
			/* assuming 31bit file length */
			{
				int i = ioResize( (int)datastack[ DP-1 ], (int)datastack[ DP-3 ] );
				DP-=2;
				datastack[ DP-1 ] = (uint32_t)i;
			}
			break;
		case OPCODE_FILE_POSITION:		/* note, I'm not doing 64bit, never having files that big */
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
		case OPCODE_FILE_SIZE:		/* note, I'm not doing 64bit, never having files that big */
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
		case OPCODE_FILE_STATUS:
			// cant really think of anything atm. I want to report.
			datastack[ DP-2 ] = 0;
			datastack[ DP-1 ] = 0;
			break;
		case OPCODE_WRITE_FILE:
			tmp = datastack[ DP-1 ]; DP--;		// tmp is 'file-id'
			tmp2 = datastack[ DP-1 ]; DP--;		// tmp2 is length
			tmp3 = datastack[ DP-1 ];			// tmp3 is pointer
			{
				int i = ioWrite( (int)tmp, ABS_PTR( machine, tmp3 ), tmp2 );
				if ( i < 0 ) datastack[ DP-1 ] = (uint32_t) i;
				else		 datastack[ DP-1 ] = 0;
			}
			break;
		case OPCODE_READ_FILE:
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
		case OPCODE_OPEN_FILE:
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
		case OPCODE_CREATE_FILE:
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
		case OPCODE_FLUSH_FILE:
			datastack[DP-1] = (uint32_t)ioFlush( (int)datastack[ DP-1 ] );
			break;
		case OPCODE_CLOSE_FILE:
			datastack[DP-1] = (uint32_t)ioClose( (int)datastack[ DP-1 ] );
			break;
		/* internal magic */
		case OPCODE_NONE:
			printf("Bang\n"); 
			exit(0);
			break;			
		case OPCODE_BYE:
			exit(0);
			break;
		case OPCODE_IP:
			datastack[ DP ] = IP;
			DP++;
			break;
		case OPCODE_RSPFETCH:
			datastack[ DP ] = RP;
			DP++;
			break;
		case OPCODE_RSPSTORE:
			RP = datastack[ DP-1 ];
			DP--;
			break;
		case OPCODE_SPFETCH:
			datastack[ DP ] = DP;
			DP++;
			break;
		case OPCODE_SPSTORE:
			DP = datastack[ DP-1 ];
			break;
		/* calls, jumps etc */
		case OPCODE_EXECUTE:
			returnstack[ RP ] = IP;
			RP++;
			IP = datastack[ DP-1 ];
			DP--;
			break;
		case OPCODE_JUMP_EQ:
			tmp = datastack[ DP-1 ] == datastack[ DP-2 ];
			DP-=2;
			if ( tmp ) IP = GET_CELL( machine, IP );
			else IP+=4;
			break;			
		case OPCODE_JUMP_EQ_ZERO:
			tmp = datastack[ DP-1 ];
			DP--;
			if ( tmp == 0 ) IP = GET_CELL( machine, IP );
			else IP+=4;
			break;			
		case OPCODE_JUMPD:
			IP=datastack[DP-1];
			DP--;
			break;
		case OPCODE_JUMP:
			IP=GET_CELL( machine, IP );
			break;
		case OPCODE_SHORT_CALL:
			returnstack[ RP ] = IP+2;
			RP++;
			IP = GET_WORD( machine, IP );
			break;
		case OPCODE_CALL:
			returnstack[ RP ] = IP+4;
			RP++;
			IP = GET_CELL( machine, IP );
			break;
		case OPCODE_RET:
			if ( RP == 0 ) {
				return;
			}
			RP--;
			IP=returnstack[ RP ];
			break;
		/* stackrobatics */
		case OPCODE_DEPTH:
			datastack[ DP ] = DP;
			DP++;
			break;
		case OPCODE_NIP:
			datastack[ DP-2 ] = datastack[ DP-1 ];
			DP--;
			break;
		case OPCODE_TUCK:	
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP++;
			datastack[ DP-3 ] = tmp;
			datastack[ DP-2 ] = tmp2;
			datastack[ DP-1 ] = tmp;
			break;
		case OPCODE_ROLL:
			tmp = datastack[ DP-1 ];
			DP--;
			if ( tmp ) {
				tmp2 = datastack[ DP-1-tmp ];
				memmove( datastack+DP-1-tmp, datastack+DP-tmp, tmp*4 );
				datastack[ DP-1 ] = tmp2;
			}
			break;
		case OPCODE_DUP:
			datastack[ DP ] = datastack[ DP-1 ];
			DP++;
			break;
		case OPCODE_2DUP:
			DP+=2;
			datastack[ DP-2 ] = datastack[ DP-4 ];
			datastack[ DP-1 ] = datastack[ DP-3 ];
			break;
		case OPCODE_DROP:
			DP--;
			break;
		case OPCODE_2DROP:
			DP-=2;
			break;
		case OPCODE_OVER:
			datastack[ DP ] = datastack[ DP - 2 ];
			DP++;
			break;
		case OPCODE_2OVER: 	
			DP+=2;
			datastack[ DP-2 ] = datastack[ DP-6 ];
			datastack[ DP-1 ] = datastack[ DP-5 ];
			break;
		case OPCODE_SWAP:
			tmp = datastack[ DP-2 ];
			datastack[ DP-2 ] = datastack[ DP-1 ];
			datastack[ DP-1 ] = tmp;
			break;
		case OPCODE_2SWAP:	
			tmp = datastack[ DP-2 ];
			tmp2 = datastack[ DP-1 ];
			datastack[ DP-2 ] = datastack[ DP-4 ];
			datastack[ DP-1 ] = datastack[ DP-3 ];
			datastack[ DP-4 ] = tmp;
			datastack[ DP-3 ] = tmp2;
			break;
		case OPCODE_PICK:
			datastack[ DP-1 ] = datastack[ DP - datastack[ DP - 1 ] - 2 ];
			break;
		case OPCODE_ROT:
			tmp = datastack[ DP-3 ];
			datastack[ DP-3 ] = datastack[ DP-2 ];
			datastack[ DP-2 ] = datastack[ DP-1 ];
			datastack[ DP-1 ] = tmp;
			break;
		/* comparisons */
		case OPCODE_U_GREATER_THAN:
			datastack[ DP-2 ] = datastack[ DP-2 ] > datastack[ DP-1 ] ? 1 : 0;
			DP--;
			break;
		case OPCODE_U_LESS_THAN:
			datastack[ DP-2 ] = datastack[ DP-2 ] < datastack[ DP-1 ] ? 1 : 0;
			DP--;
			break;
		case OPCODE_GREATER_THAN:
			{
				int b = datastack[ DP-1 ];
				DP--;
				int a = datastack[ DP-1 ];
				datastack[ DP-1 ] = ( a > b ) ? 1 : 0;
			}
			break;
		case OPCODE_LESS_THAN:
			{
				int b = datastack[ DP-1 ];
				DP--;
				int a = datastack[ DP-1 ];
				datastack[ DP-1 ] = ( a < b ) ? 1 : 0;
			}
			break;
		case OPCODE_EQUALS:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] == datastack[ DP ] ? 1 : 0;
			break;
		/* fetch/store */
		case OPCODE_WFETCH:
			datastack[ DP-1 ] = GET_WORD( machine, datastack[ DP-1 ] );
			break;
		case OPCODE_CFETCH:
			datastack[ DP-1 ] = GET_BYTE( machine, datastack[ DP-1 ] );
			break;
		case OPCODE_FETCH:
			datastack[ DP-1 ] = GET_CELL( machine, datastack[ DP-1 ] );
			break;
		case OPCODE_PLUSSTORE:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
			DP-=2;
			WRITE_CELL( machine, tmp, GET_CELL(machine, tmp) + tmp2 );
			break;
		case OPCODE_WSTORE:
			tmp = datastack[ DP-1 ];
			WRITE_WORD( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		case OPCODE_CSTORE:
			tmp = datastack[ DP-1 ];
			WRITE_BYTE( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		case OPCODE_STORE:
			tmp = datastack[ DP-1 ];
			WRITE_CELL( machine, tmp, datastack[ DP-2 ] );
			DP-=2;
			break;
		/* return stack fetch/store */
		case OPCODE_RFETCH:
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			break;
		case OPCODE_TOR:
			DP--;
			returnstack[ RP ] = datastack[ DP ];
			RP++;
			break;
		case OPCODE_RFROM:
			datastack[ DP ] = returnstack[ RP-1 ];
			DP++;
			RP--;
			break;
		/* memory */
		case OPCODE_COMPARE:
			tmp = datastack[ DP-3 ];
			tmp2 = datastack[ DP-2 ];
			tmp3 = datastack[ DP-1 ];
			DP-=2;
			datastack[ DP-1 ] = cmp( ABS_PTR( machine, tmp ), ABS_PTR( machine, tmp2 ), tmp3 );
			break;
		case OPCODE_MOVE:
			tmp = datastack[ DP-3 ];
			tmp2 = datastack[ DP-2 ];
			tmp3 = datastack[ DP-1 ];
			DP-=3;
		    if ( tmp3 > 0 )
				memmove( ABS_PTR( machine, tmp2 ), ABS_PTR( machine, tmp ), tmp3 );
			break;
		/* math */
		case OPCODE_ADD2:
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
		case OPCODE_UMULT:
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
		case OPCODE_MULT:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] * datastack[ DP ];
			break;
		case OPCODE_PLUS:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] + datastack[ DP ];
			break;
		case OPCODE_MINUS:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] - datastack[ DP ];
			break;
		case OPCODE_ONEPLUS:
			datastack[ DP-1 ]++;
			break;
		case OPCODE_ONEMINUS:
			datastack[ DP-1 ]--;
			break;
		case OPCODE_UM_SLASH_MOD:
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
		case OPCODE_IN:
			datastack[ DP ] = getchar();
			DP++;
			break;
		case OPCODE_EMIT:
			putchar( datastack[DP-1] );
			DP--;
			break;
		/* logic */
		case OPCODE_NOT:
			datastack[ DP-1 ] = datastack[ DP-1 ] ? 0 : 1;
			break;
		case OPCODE_OR:	
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] | datastack[ DP ];
			break;
		case OPCODE_AND:
			DP--;
			datastack[ DP-1 ] = datastack[ DP-1 ] & datastack[ DP ];
			break;
		/* others */
		case OPCODE_DOLIT:
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


