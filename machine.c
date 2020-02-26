
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "common.h"
#include "io.h"
#include "io_file.h"
#include "io_block.h"
#include "io_platform.h"
#include "machine.h"
#include "opcode.h"

static uint16_t swap16( uint16_t v ) { return ((v>>8)&0xFF)|((v<<8)&0xFF00); }
#ifdef VM_16BIT
static uint16_t swapCELL( uint16_t v ) { return ((v>>8)&0xFF)|((v<<8)&0xFF00); }
#else
static cell_t swapCELL( cell_t v ) { return ((v>>24)&0xFF)|((v>>8)&0xFF00)|((v<<8)&0xFF0000)|((v<<24)&0xFF000000); }
#endif
static uint16_t noswap16( uint16_t v ) { return v; }
static cell_t noswapCELL( cell_t v ) { return v; }

void machine_init( machine_t* machine ) {
	ioInit();
	ioRegister( &io_file );
	ioRegister( &io_block );
	machine->DP = 0;
	machine->RP = 0;
	machine->LP = 0;	
	(void)io_platform_init();
	atexit( io_platform_term );
}

void machine_set_endian( machine_t* machine, machine_endian_t which ) {
	cell_t value = HEADER_ID;
	uint8_t* p = (uint8_t*)&value;
	machine_endian_t me = (p[3] == (HEADER_ID & 255)) ? ENDIAN_BIG : ENDIAN_LITTLE;
	if ( ( me == which ) || ( which == ENDIAN_NATIVE ) ) {
		machine->swap16 = noswap16;
		machine->swapCELL = noswapCELL;
	} else {
		machine->swap16 = swap16;
		machine->swapCELL = swapCELL;
	}
}

#define ATHROW( condition, todo, throw_code )	if (condition) {\
													todo \
													DP++; \
													datastack[ DP-1 ] = throw_code; \
													IP=GET_CELL( machine, a_throw );\
													if ( IP == 0 ) { \
														printf("Urk - no throw handler\n");\
														exit(0); /* FIXME */ \
													}\
													break; \
												}
void machine_execute( machine_t* machine, cell_t xt, cell_t a_throw, int run_once ) {

	cell_t tmp;
	cell_t tmp2;
	cell_t tmp3;
	cell_t tmp4;

	cell_t IP=xt;
	cell_t* datastack = machine->datastack;
	cell_t* returnstack = machine->returnstack;
#define DP machine->DP
#define RP machine->RP
#define LP machine->LP

	for (;;) {
		unsigned char opcode;

		opcode = GET_BYTE( machine, IP ); IP++;

		switch( opcode ) {
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
				int ior = ioCreate( ABS_PTR( machine, tmp3 ), tmp2, tmp, &fd );
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
				int ior = ioOpen( ABS_PTR( machine, tmp3 ), tmp2, tmp, &fd );
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
				unsigned long int length;
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
				unsigned long int length;
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
			printf("\n\nBYE!!!\n\n");
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
		case opRET:
			if ( RP == 0 ) {
				if ( run_once )
					return;			/* run a single word from boot strap interpreter */
				/* stack underflow */
				printf("return stack underflow\n");
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
		case opTOR:
			ATHROW( DP<1, ;, -4 );
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
		case opICOMPARE:
			tmp = datastack[ DP-4 ];
			tmp2 = datastack[ DP-3 ];
			tmp3 = datastack[ DP-2 ];
			tmp4 = datastack[ DP-1 ];
			DP-=3;
			datastack[ DP-1 ] = cmp( ABS_PTR( machine, tmp ), tmp2, ABS_PTR( machine, tmp3 ), tmp4, 0 );
			break;
		case opCOMPARE:
			tmp = datastack[ DP-4 ];
			tmp2 = datastack[ DP-3 ];
			tmp3 = datastack[ DP-2 ];
			tmp4 = datastack[ DP-1 ];
			DP-=3;
			datastack[ DP-1 ] = cmp( ABS_PTR( machine, tmp ), tmp2, ABS_PTR( machine, tmp3 ), tmp4, 1 );
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
				unsigned char c[3];
				int ret = read( STDIN_FILENO, c, 3 );	
				/* I'm expecting either 1 byte or 3 ( 27 x y ) */
				if ( ret == 1 ) tmp = c[0];
				else tmp = ( c[1] << 8 ) | c[2];
				DP++;
				datastack[DP-1] = tmp;
			}
			break;
		case opEMIT:
			{
				unsigned char c;
				tmp = datastack[DP-1];
				DP--;
				c = ( tmp & 255 );
				if ( write( STDOUT_FILENO, &c, 1 ))
					;
			}
			break;
		/* logic */
		case opLSHIFT:
			datastack[ DP-1 ] = datastack[DP-1] << 1;
			break;
		case opRSHIFT:
			datastack[ DP-1 ] = datastack[DP-1] >> 1;
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
		case opQTHROW:
			tmp = datastack[ DP-1 ];
			tmp2 = datastack[ DP-2 ];
printf("\nopQTHROW %d %d\n", tmp, tmp2 );
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

