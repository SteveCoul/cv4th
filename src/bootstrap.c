
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#include "common.h"
#include "io.h"
#include "machine.h"
#include "opcode.h"

static int			input;
static machine_t*	machine;

#define HERE 							GET_CELL( machine, A_HERE )
#define FORTH_WORDLIST					GET_CELL( machine, A_FORTH_WORDLIST )
#define INTERNALS_WORDLIST				GET_CELL( machine, A_INTERNALS_WORDLIST )
#define LOCALS_WORDLIST					GET_CELL( machine, A_LOCALS_WORDLIST )
#define EXT_WORDLIST					GET_CELL( machine, A_EXT_WORDLIST )
#define HASH_TIB						GET_CELL( machine, A_HASH_TIB )
#define TOIN							GET_CELL( machine, A_TOIN )
#define STATE							GET_CELL( machine, A_STATE )

static void comma( cell_t value ) { WRITE_CELL( machine, HERE, value ); WRITE_CELL( machine, A_HERE, HERE + CELL_SIZE ); }
static void w_comma( uint16_t value ) { WRITE_WORD( machine, HERE, value ); WRITE_CELL( machine, A_HERE, HERE + 2 ); }
static void c_comma( uint8_t value ) { WRITE_BYTE( machine, HERE, value ); WRITE_CELL( machine, A_HERE, HERE + 1 ); }

static void s_comma( const char* text ) {
    unsigned int i; 
	c_comma( (uint8_t)strlen( text ) );
    for ( i = 0; text[i] != 0; i++ ) 
		c_comma( (uint8_t)text[i] );
}

/* ****************** */

static cell_t lay_header_no_link( uint8_t type, const char* name ) {
	cell_t rc = HERE;
	comma( 0 );
/*	comma( 0x12345678 );	IF I WANT MORE HEAD SPACE */
	c_comma( type );
	s_comma( name );
	return rc;
}

static cell_t link_to_flag( cell_t link ) {
	link = link + CELL_SIZE;
/*	link = link + CELL_SIZE;	IF I WANT MORE HEAD SPACE */
	return link;
}

static cell_t to_name( cell_t link ) { return link_to_flag( link ) + 1; }

static cell_t to_xt( cell_t link, uint8_t* pflag ) { 
	if ( pflag ) pflag[0] = GET_BYTE( machine, link_to_flag( link ) );
	link = to_name( link );
	link = link + 1 + GET_BYTE( machine, link );
	return link;
}

/* ****************** */

static void link_header( cell_t where ) {
	WRITE_CELL( machine, where, GET_CELL( machine, GET_CELL( machine, A_CURRENT ) ) );
	WRITE_CELL( machine, GET_CELL( machine, A_CURRENT), where );
}

static void lay_header( uint8_t type, const char* name ) {
	link_header( lay_header_no_link( type, name ) );
}

static void variable( cell_t address, const char* name ) {
	lay_header( opNONE, name );
	c_comma( opDOLIT ); comma( address ); c_comma( opRET );
}

static void opword( uint8_t opcode, const char* name ) {
	lay_header( opcode, name );
	c_comma( opcode );
	c_comma( opRET );
}

static void literal( uint32_t v ) {
	if ( v == -1 ) {
		c_comma( opLITM1 );
	} else if ( v == 0 ) {
		c_comma( opLIT0 );
	} else if ( v == 1 ) {
		c_comma( opLIT1 );
	} else if ( v == 2 ) {
		c_comma( opLIT2 );
	} else if ( v == 3 ) {
		c_comma( opLIT3 );
	} else if ( v == 4 ) {
		c_comma( opLIT4 );
	} else if ( v == 5 ) {
		c_comma( opLIT5 );
	} else if ( v == 6 ) {
		c_comma( opLIT6 );
	} else if ( v == 7 ) {
		c_comma( opLIT7 );
	} else if ( v == 8 ) {
		c_comma( opLIT8 );
	} else if ( ( v < 256 ) && ( v >= 0 ) ) {
		c_comma( opDOLIT_U8 );
		c_comma( v );
	} else if ( ( v < 65536 ) && ( v>= 0 ) ) {
		c_comma( opDOLIT_U16 );
		w_comma( v );
	} else {
		c_comma( opDOLIT );
		comma( v );
	}
}

static void constant( const char* name, cell_t value ) {
	lay_header( opNONE, name );
	literal( value );
	c_comma( opRET );
}

#define opconstant( name ) constant( #name, name )

//#define opconst_db( name ) {}
#define opconst_db( name ) constant( #name, name )

static void internals_definitions( void ) {	WRITE_CELL( machine, A_CURRENT, A_INTERNALS_WORDLIST ); }
static void forth_definitions( void ) {	WRITE_CELL( machine, A_CURRENT, A_FORTH_WORDLIST ); }
static void ext_definitions( void ) { WRITE_CELL( machine, A_CURRENT, A_EXT_WORDLIST ); }

uint32_t find( const char* name ) {
	uint32_t i = 0;	
	uint32_t wids[ SIZE_ORDER + 1 ];
	wids[0] = LOCALS_WORDLIST;
	for ( i = 0; i < SIZE_ORDER; i++ ) {
		wids[i+1] = GET_CELL( machine, A_ORDER + (i*CELL_SIZE) );
	}
	
	for ( i = 0; i < SIZE_ORDER+1; i++ ) {
		uint32_t p = wids[i];
		while ( p != 0 ) {
			uint32_t s = to_name( p );
			if ( GET_BYTE( machine, s ) == strlen(name) ) {
				if ( cmp( name, strlen(name), ABS_PTR( machine, s+1 ), strlen(name), 0 ) == 0 ) {
					return p;
				}
			}
			p = GET_CELL( machine, p );
		}
	}
	return 0;
}

int refill( void ) {
	if ( input == STDIN_FILENO ) {
		if (GET_CELL( machine, A_STATE )==0) printf("\n");

		printf("BS [%c] ", STATE ? 'c' : 'i' );
		printf("%d [ ", machine->DP );
		for ( int i = 0; i < machine->DP; i++ ) printf("%d ", machine->datastack[i] );
		printf("] > " ); fflush( stdout );
	} else {
		unsigned int mx;
		unsigned int h = lseek( input, 0, SEEK_CUR );
		mx = lseek( input, 0, SEEK_END );
		lseek( input, h, SEEK_SET );
		if ( mx == h ) {
			close( input );
			input = STDIN_FILENO;
			return 0;
		}
	}

	WRITE_CELL( machine, A_HASH_TIB, 0 );
	for (;;) {
		char c;
		if ( read( input, &c, 1 ) != 1 ) {
			if ( input == STDIN_FILENO ) continue;
			break;
		}
		if ( c != '\r' ) {
			if ( input == STDIN_FILENO ) {
				if ( write( input, &c, 1 ))
					;
			}
			if ( c == '\n' ) break;
			WRITE_BYTE( machine, A_INPUT_BUFFER + GET_CELL( machine, A_HASH_TIB ), c );
			WRITE_CELL( machine, A_HASH_TIB, (GET_CELL( machine, A_HASH_TIB )) + 1 );
			/* TODO dont overflow buffer */
			if ( HASH_TIB == SIZE_INPUT_BUFFER ) {
				fprintf( stderr, "overflow in input buffer\n" );
				exit(0);
			}
		}
	}
	WRITE_CELL( machine, A_TOIN, 0 );
	return 1;
}

static void align() {
	for (;;) {
		cell_t a = GET_CELL( machine, A_HERE );
		if ( (a%CELL_SIZE)==0 ) break;
		WRITE_CELL( machine, A_HERE, a+1 );
	}
}

int main( int argc, char** argv ) {
	int					bye = 0;
	machine_endian_t	endian = ENDIAN_NATIVE;
	uint32_t			word_colon = 0;
	uint32_t			word_semicolon = 0;
	uint32_t			word_fslash = 0;
	uint32_t			word_opensq = 0;
	uint32_t			word_closesq = 0;
	const char*			include_file = NULL;
	const char*			post_action = NULL;
	cell_t 				current_word = 0;
	int					i;
	int					alignment_workaround = 0;
	cell_t				dictionary_size = 32*1024;
	cell_t				dstack_size = 128;
	cell_t				rstack_size = 128;
	cell_t				temp;

	for ( i = 1; i < argc; i++ ) {
		if ( ( strcmp( argv[i], "-h" ) == 0 ) || ( strcmp( argv[i], "-help" ) == 0 ) ) {
			printf("%s <args>\n", argv[0] );
			printf("-h -help		This text\n" );
			printf("-f <name>		File to include on boot\n" );
			printf("-p <string>		Text to run on start but after include\n" );
			printf("-be				Select big endian\n");
			printf("-le				Select little endian\n");
			printf("-a				Enable alignment capable fetch and store\n");
			printf("-ds <num>		Initial dictionary size in K (default 32)\n");
			printf("				Default endian is host native\n");
			exit(0);
		}

		if ( strcmp( argv[i], "-f" ) == 0 ) {
			include_file = argv[i+1]; i++;
		} else if ( strcmp( argv[i], "-p" ) == 0 ) {		
			post_action = argv[ i+1 ]; i++;
		} else if ( strcmp( argv[i], "-be" ) == 0 ) {
			endian = ENDIAN_BIG;
		} else if ( strcmp( argv[i], "-le" ) == 0 ) { 
			endian = ENDIAN_LITTLE;
		} else if ( strcmp( argv[i], "-a" ) == 0 ) {
			alignment_workaround = 1;
		} else if ( strcmp( argv[i], "-ds" ) == 0 ) {
			dictionary_size = atoi( argv[i+1] ) * 1024; i++;
		} else {
			printf("invalid switch %s\n", argv[i] );
			exit(0);
		}
	}

	machine = (machine_t*)malloc( sizeof(machine_t) );

	machine_init( machine );
	machine->memory = malloc( dictionary_size );

	machine_set_endian( machine, endian, alignment_workaround );

	memset( machine->memory, 0, dictionary_size );

	/** init vars */
	WRITE_CELL( machine, A_HEADER, HEADER_ID );
	WRITE_CELL( machine, A_HERE, START_HERE );
	WRITE_CELL( machine, A_DICTIONARY_SIZE, dictionary_size );
	WRITE_CELL( machine, A_DATASTACK, 0 );
	WRITE_CELL( machine, A_SIZE_DATASTACK, dstack_size );
	WRITE_CELL( machine, A_RETURNSTACK, 0 );
	WRITE_CELL( machine, A_SIZE_RETURNSTACK, rstack_size );
	WRITE_CELL( machine, A_FORTH_WORDLIST-CELL_SIZE, 0 );
	WRITE_CELL( machine, A_FORTH_WORDLIST, 0 );
	WRITE_CELL( machine, A_INTERNALS_WORDLIST-CELL_SIZE, A_FORTH_WORDLIST );
	WRITE_CELL( machine, A_INTERNALS_WORDLIST, 0 );
	WRITE_CELL( machine, A_LOCALS_WORDLIST-CELL_SIZE, A_INTERNALS_WORDLIST );
	WRITE_CELL( machine, A_LOCALS_WORDLIST, 0 );
	WRITE_CELL( machine, A_EXT_WORDLIST-CELL_SIZE, A_LOCALS_WORDLIST );
	WRITE_CELL( machine, A_EXT_WORDLIST, 0 );
	WRITE_CELL( machine, A_LIST_OF_WORDLISTS, A_EXT_WORDLIST );
	WRITE_CELL( machine, A_QUIT, 0 );
	WRITE_CELL( machine, A_SETUP, 0 );
	WRITE_CELL( machine, A_BASE, 10 );
	WRITE_CELL( machine, A_STATE, 0 );
	WRITE_CELL( machine, A_TIB, A_INPUT_BUFFER );
	WRITE_CELL( machine, A_HASH_TIB, 0 );
	WRITE_CELL( machine, A_TOIN, 0 );
	WRITE_CELL( machine, A_CURRENT, A_FORTH_WORDLIST );
	WRITE_CELL( machine, A_THROW, 0 );
	WRITE_CELL( machine, A_ORDER, A_INTERNALS_WORDLIST );		// bootstrap has a search order of internals-ext-forth
	WRITE_CELL( machine, A_ORDER+CELL_SIZE, A_EXT_WORDLIST );
	WRITE_CELL( machine, A_ORDER +CELL_SIZE+CELL_SIZE, A_FORTH_WORDLIST );

	constant( "INTERNALS", A_INTERNALS_WORDLIST );		
	constant( "ext-wordlist", A_EXT_WORDLIST );
	constant( "forth-wordlist", A_FORTH_WORDLIST );		// this one is actually a forth word

	internals_definitions();
	variable( A_LIST_OF_WORDLISTS, "A_LIST_OF_WORDLISTS" );
	constant( "locals-wordlist", A_LOCALS_WORDLIST );	
	constant( "context-size", CONTEXT_SIZE );

	forth_definitions();
	lay_header( opNONE, "here" );	// in forth code here is not a variable
	c_comma( opDOLIT );
	comma( A_HERE );
	c_comma( opFETCH );
	c_comma( opRET );

	variable( A_STATE, "state" );
	variable( A_TIB, "tib" );
	variable( A_HASH_TIB, "#tib" );
	variable( A_TOIN, ">in" );
	variable( A_BASE, "base" );
	constant( "r/o", IO_RDONLY );
	constant( "w/o", IO_WRONLY );
	constant( "r/w", IO_RDWR );

	internals_definitions();
	constant( "A_DATASTACK", A_DATASTACK );
	constant( "A_SIZE_DATASTACK", A_SIZE_DATASTACK );
	constant( "A_RETURNSTACK", A_RETURNSTACK );
	constant( "A_SIZE_RETURNSTACK", A_SIZE_RETURNSTACK );
	constant( "A_DICTIONARY_SIZE", A_DICTIONARY_SIZE );
	constant( "/INPUT_BUFFER", SIZE_INPUT_BUFFER );
	constant( "/PICTURED_NUMERIC", SIZE_PICTURED_NUMERIC );
	constant( "/ORDER", SIZE_ORDER );
	constant( "A_HERE", A_HERE );
	constant( "A_QUIT", A_QUIT );
	constant( "A_SETUP", A_SETUP );
	constant( "A_CURRENT", A_CURRENT );
	constant( "A_THROW", A_THROW );
	constant( "A_ORDER", A_ORDER );
	constant( "A_PICTURED_NUMERIC", A_PICTURED_NUMERIC );
	constant( "A_INPUT_BUFFER", A_INPUT_BUFFER );

	/** Forth definitions that map to a single opcode */
	forth_definitions();
	opword( opINC, "1+" );
	opword( opDEC, "1-" );
	opword( opOPEN_FILE, "open-file" );
	opword( opCLOSE_FILE, "close-file" );
	opword( opCREATE_FILE, "create-file" );
	opword( opREAD_FILE, "read-file" );
	opword( opWRITE_FILE, "write-file" );
	opword( opDELETE_FILE, "delete-file" );
	opword( opFILE_POSITION, "file-position" );
	opword( opFILE_SIZE, "file-size" );
	opword( opFILE_STATUS, "file-status" );
	opword( opFLUSH_FILE, "flush-file" );
	opword( opRESIZE_FILE, "resize-file" );
	opword( opRENAME_FILE, "rename-file" );
	opword( opREPOSITION_FILE, "reposition-file" );
	opword( opU_GREATER_THAN, "u>" );
	opword( opU_LESS_THAN, "u<" );
	opword( opNIP, "nip" );
	opword( opADD2, "d+" );
	opword( opDLESSTHAN, "d<" );
	opword( opDULESSTHAN, "du<" );
	opword( opLSHIFT, "lshift" );
	opword( opRSHIFT, "rshift" );
	opword( opROT, "rot" );
	opword( opTUCK, "tuck" );
	opword( opROLL, "roll" );
	opword( op2DUP, "2dup" );
	opword( opQDUP, "?dup" );
	opword( op2DROP, "2drop" );
	opword( op2OVER, "2over" );
	opword( op2SWAP, "2swap" );
	opword( opMOVE, "move" );
	opword( opDEPTH, "depth" );
	opword( opOVER, "over" );
	opword( opDUP, "dup" );
	opword( opPICK, "pick" );
    opword( opDMINUS, "d-" );
	opword( opEXECUTE, "execute" );
	opword( opFETCH, "@" );
	opword( opEQUALS, "=" );
	opword( opSTORE, "!" );
	opword( opZEROEQ, "0=" );
	opword( opOR, "or" );
	opword( opAND, "and" );
	opword( opXOR, "xor" );
	opword( opCSTORE, "c!" );
	opword( opCOMPARE, "compare" );
	opword( opCFETCH, "c@" );
	opword( opDROP, "drop" );
	opword( opEMIT, "emit" );
	opword( opMULT, "*" );
	opword( opMULT2, "m*" );
	opword( opUMULT2, "um*" );
	opword( opMINUS, "-" );
	opword( opGREATER_THAN, ">" );
	opword( opLESS_THAN, "<" );
	opword( opPLUS, "+" );
	opword( opPLUSSTORE, "+!" );
	opword( opSWAP, "swap" );
	opword( opUM_SLASH_MOD, "um/mod" );
	opword( opSM_SLASH_REM, "sm/rem" );
    opword( opINVERT, "invert" );
	ext_definitions();
	opword( opD8FETCH, "d8@" );
	opword( opD16FETCH, "d16@" );
	opword( opD32FETCH, "d32@" );
	opword( opD8STORE, "d8!" );
	opword( opD16STORE, "d16!" );
	opword( opD32STORE, "d32!" );
	opword( opREL2ABS, "rel>abs" );

	forth_definitions();
	lay_header( opNONE, "cells" );
	if ( CELL_SIZE == 4 ) {
		c_comma( opLIT4 ); c_comma( opMULT ); c_comma( opRET );
	} else if ( CELL_SIZE == 2 ) {
		c_comma( opLIT2 ); c_comma( opMULT ); c_comma( opRET );
	} else {	
		printf("bug - only 16 and 32bit builds allowed\n");
		exit(0);
	}

	// Do not make the r> >r r@ words here because compiling the opcode behavior as above doesn't work if you ' execute etc.
	// ditto 2r> 2>r 2r@

	internals_definitions();
	opword( opRSPFETCH, "rsp@" );
	opword( opRSPSTORE, "rsp!" );
	opword( opSPFETCH, "sp@" );
	opword( opSPSTORE, "sp!" );
	opword( opWFETCH, "w@" );
	opword( opWSTORE, "w!" );
	ext_definitions();
	opword( opBYE, "bye" );

	internals_definitions();
	opconstant( opNONE );
	opconst_db( opD8FETCH );
	opconst_db( opD16FETCH );
	opconst_db( opD32FETCH );
	opconst_db( opD8STORE );
	opconst_db( opD16STORE );
	opconst_db( opD32STORE );
	opconst_db( op2DROP );
	opconst_db( op2DUP );
	opconst_db( op2OVER );
	opconst_db( op2SWAP );
	opconstant( op2TOR );
	opconstant( op2RFROM );
	opconstant( op2RFETCH );
	opconst_db( opADD2 );
	opconst_db( opAND );
	opconstant( opBRANCH );
	opconst_db( opBYE );
	opconstant( opCALL );
	opconst_db( opCFETCH );
	opconst_db( opCLOSE_FILE );
	opconstant( opCONTEXT_SWITCH );
	opconst_db( opCOMPARE );
	opconst_db( opCREATE_FILE );
	opconst_db( opCSTORE );
 	opconst_db( opDEC );
	opconst_db( opDELETE_FILE );
	opconst_db( opDEPTH );
	opconst_db( opDLESSTHAN );
	opconstant( opDOCSTR );
	opconstant( opDOLIT );
	opconstant( opDOLIT_U8 );
	opconstant( opDOLIT_U16 );
	opconst_db( opDROP );
	opconst_db( opDULESSTHAN );
	opconstant( opDUP );
	opconstant( opEKEY );
	opconst_db( opEMIT );
	opconst_db( opEQUALS );
	opconst_db( opEXECUTE );
	opconstant( opFETCH );
	opconst_db( opFILE_POSITION );
	opconst_db( opFILE_SIZE );
	opconst_db( opFILE_STATUS );
	opconst_db( opFLUSH_FILE );
	opconst_db( opGREATER_THAN );
	opconstant( opICOMPARE );
	opconst_db( opINVERT );
	opconst_db( opIP );
	opconstant( opINC );
	opconst_db( opLESS_THAN );
	opconstant( opLITM1 );
	opconstant( opLIT0 );
	opconstant( opLIT1 );
	opconstant( opLIT2 );
	opconstant( opLIT3 );
	opconstant( opLIT4 );
	opconstant( opLIT5 );
	opconstant( opLIT6 );
	opconstant( opLIT7 );
	opconstant( opLIT8 );
	opconstant( opLPFETCH );
	opconstant( opLPSTORE );
	opconstant( opLFETCH );
	opconst_db( opLSHIFT );
	opconstant( opLSTORE );
	opconst_db( opMINUS );
	opconst_db( opMOVE );
	opconst_db( opMULT );
	opconst_db( opMULT2 );
	opconst_db( opNIP );
	opconst_db( opONEMINUS );
	opconst_db( opONEPLUS );
	opconst_db( opOPEN_FILE );
	opconst_db( opOR );
	opconst_db( opOVER );
	opconst_db( opPICK );
	opconst_db( opPLUS );
	opconst_db( opPLUSSTORE );
	opconstant( opQBRANCH );
	opconst_db( opQDUP );
	opconstant( opQTHROW );
	opconst_db( opREAD_FILE );
	opconst_db( opRENAME_FILE );
	opconst_db( opREPOSITION_FILE );
	opconst_db( opRESIZE_FILE );
	opconstant( opRET );
	opconstant( opRFETCH );
	opconstant( opRFROM );
	opconstant( opROT );
	opconst_db( opROLL );
	opconst_db( opRSHIFT );
	opconstant( opRSPFETCH );
	opconstant( opRSPSTORE );
	opconstant( opSHORT_CALL );
	opconst_db( opSPFETCH );
	opconst_db( opSPSTORE );
	opconst_db( opSTORE );
	opconstant( opSWAP );
	opconstant( opTOR );
	opconst_db( opTUCK );
	opconst_db( opU_GREATER_THAN );
	opconst_db( opU_LESS_THAN );
	opconstant( opUMULT );
	opconst_db( opUMULT2 );
	opconst_db( opUM_SLASH_MOD );
	opconst_db( opWFETCH );
	opconst_db( opWRITE_FILE );
	opconst_db( opWSTORE );
	opconst_db( opXOR );
	opconst_db( opZEROEQ );
	opconstant( opIMMEDIATE );

	/* setup our stacks */
	lay_header( opNONE, "initial-stacks" );
	c_comma( opRET );
	{
		printf("setup stacks. here was %x\n", GET_CELL( machine, A_HERE ) );
		align();	/* stacks are aligned in the image because I used native fetch on them
					   so alignment is critical on some targets */
		temp = GET_CELL( machine, A_HERE );
		if ( ( temp + ((dstack_size+rstack_size)*CELL_SIZE) ) >= dictionary_size ) {
			printf("\n\nCannot bootstrap, not enough dictionary space for stacks\n\n");
			exit(1);
		}
		printf("datastack will be at %x\n", temp );
		WRITE_CELL( machine, A_DATASTACK, temp );
		WRITE_CELL( machine, A_HERE, GET_CELL( machine, A_HERE ) + ( dstack_size * CELL_SIZE ) );
		temp = GET_CELL( machine, A_HERE );
		printf("returnstack will be at %x\n", temp );
		WRITE_CELL( machine, A_RETURNSTACK, temp );
		WRITE_CELL( machine, A_HERE, GET_CELL( machine, A_HERE ) + ( rstack_size * CELL_SIZE ) );
		machine->datastack = machine->memory + ( GET_CELL( machine, A_DATASTACK ) / CELL_SIZE );
		machine->returnstack = machine->memory + ( GET_CELL( machine, A_RETURNSTACK ) / CELL_SIZE );
		printf( "dstack %p, rstack %p\n", (void*)(machine->datastack), (void*)(machine->returnstack) );
	}

	forth_definitions();

	/**
 	 */
	if ( include_file )
		input = open( include_file, O_RDONLY );
	else	
		input = STDIN_FILENO;
	while (bye == 0 ) {
		int next_word_is_colon_name;
aborted:
		if ( ! refill() ) {
			if ( post_action ) {
				int i;
				WRITE_CELL( machine, A_HASH_TIB, 0 );
				for ( i = 0; i < strlen(post_action ); i++ ) {
					WRITE_BYTE( machine, A_INPUT_BUFFER + GET_CELL( machine, A_HASH_TIB ), post_action[i] );
					WRITE_CELL( machine, A_HASH_TIB, (GET_CELL( machine, A_HASH_TIB )) + 1 );
				}
				WRITE_CELL( machine, A_TOIN, 0 );
				printf("\nPostaction\n");
				bye = 1;	/* I'm going to assume the postaction will bye */
			} else if ( GET_CELL( machine, A_QUIT ) == 0 ) {
				/* just drop into bootstrap interpreter */
				printf("\nNo bootstrap vector set\n");
			} else {
				/* TODO report any exception? */
				for (;;) {
					printf("\nBoot via vector\n");
					machine->IP = GET_CELL( machine, A_SETUP );
					if ( machine->IP ) {
						printf("setup\n");
						machine_execute( machine, A_THROW, 0 );	
					}
					printf("\nquit\n");
					machine->IP = GET_CELL( machine, A_QUIT );
					/* reset stacks? */
					machine_execute( machine, A_THROW, 0 );	/* run until complete */
				}
				exit(0);
			}
		}

		next_word_is_colon_name = 0;
		while ( TOIN != HASH_TIB ) {
			uint8_t* p;
rescan:
			p = ((uint8_t*)(machine->memory)) + A_INPUT_BUFFER + TOIN;

			while ( ( isspace( p[0] ) && ( TOIN != HASH_TIB ) ) ) {
				WRITE_CELL( machine, A_TOIN, GET_CELL( machine, A_TOIN)+1 );
				p++;
			}

			if ( TOIN != HASH_TIB ) {
				char tmp_word[ SIZE_INPUT_BUFFER ];
				unsigned int i = 0;
				while ( !isspace( p[i] ) && ( (TOIN + i ) < HASH_TIB ) ) {
					i++;
				}

				memmove( tmp_word, p, i );
				tmp_word[i] = 0;

				if ( ( TOIN + i ) < HASH_TIB ) i++;		// trash trailing delimiter just like forth 'word' implementation

				WRITE_CELL( machine, A_TOIN, (GET_CELL( machine, A_TOIN )) + i );

				if ( next_word_is_colon_name ) {
					current_word = lay_header_no_link( opNONE, tmp_word );
					WRITE_CELL( machine, A_STATE, 1 );
					next_word_is_colon_name = 0;
					goto rescan;
				}
				// If we are executing ":" and we haven't yet defined both colon and semicolon in forth
				// we'll do a native version which is pretty dumb 
				if ( ( strcmp( tmp_word, ":" ) == 0 ) && ( ( word_colon == 0 ) || ( word_semicolon == 0 ) ) ) {
					next_word_is_colon_name = 1;
					goto rescan;
				}

				// If we are executing ";" and have not yet defined both colon and semicolon in forth
				// we'll do a naive version and then scan to see if we've got the two forth words yet.
				if ( ( strcmp( tmp_word, ";" ) == 0 ) && ( ( word_colon == 0 ) || ( word_semicolon == 0 ) ) ) {
					// relink to wordlist to make visible
					WRITE_CELL( machine, A_STATE, 0 );
					c_comma( opRET );
					link_header( current_word );
					if ( word_colon == 0 ) 		{ word_colon = find(":"); if ( word_colon ) printf("now have :\n"); }
					if ( word_semicolon == 0 )  { word_semicolon = find(";"); if ( word_semicolon ) printf("now have ;\n" ); }
					goto rescan;
				}

				if ( word_opensq == 0 ) {
					if ( strcmp( tmp_word, "[" ) == 0 ) {
						word_opensq = find( "[" );
						if ( word_opensq == 0 ) {
							WRITE_CELL( machine, A_STATE, 0 );
							goto rescan;
						}
					}
				}

				if ( word_closesq == 0 ) {
					if ( strcmp( tmp_word, "]" ) == 0 ) {
						word_closesq = find( "]" );
						if ( word_closesq == 0 ) {
							WRITE_CELL( machine, A_STATE, 1 );
							goto rescan;
						}
					}
				}

				if ( word_fslash == 0 ) {
					if ( strcmp( tmp_word, "\\" ) == 0 ) {
						word_fslash = find("\\");
						if ( word_fslash == 0 ) {
							WRITE_CELL( machine, A_TOIN, HASH_TIB );
							goto rescan;
						} 
					}
				}

				uint32_t v;

				v = find( tmp_word );
				if ( v == 0 ) {
					{
						unsigned int j;
						for ( j = tmp_word[0] == '-' ? 1 : 0; tmp_word[j] != '\0'; j++ ) {
							if ( ! ( ( tmp_word[j] >= '0' ) && ( tmp_word[j] <= '9' ) ) ) {
								printf("\n'%s' not found (bootstrap interpreter)\n", tmp_word );
								WRITE_CELL( machine, A_STATE, 0 ); 
								if ( input != STDIN_FILENO ) {
									close( input );
									input = STDIN_FILENO;
								}
								goto aborted;
							}
						}
					}

					if ( tmp_word[0] == '-' ) v = 0- atoi( tmp_word+1 );
					else v = atoi( tmp_word );
					if ( STATE == 1 ) {
						literal( v );
					} else {
						machine->datastack[ machine->DP ] = v;
						machine->DP++;
					}				
				} else {
					uint8_t flag;
					uint32_t xt = to_xt( v, &flag );

					if ( ( STATE == 0 ) || ( flag == opIMMEDIATE ) ) {
						machine->IP = xt;
						machine_execute( machine, A_THROW, 0 );	/* run until we are done */
						/* TODO report any exception? */
					} else if ( flag == opNONE ) {
						if ( xt < 65536 ) {
							c_comma( opSHORT_CALL );
							w_comma( xt );
						} else {
							c_comma( opCALL );
							comma( xt );
						}
					} else {
						c_comma( flag );
					}
				}
			}
		}
	}

	return 0;
}

