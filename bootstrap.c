
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#include "common.h"
#include "io.h"
#include "forth.h"
#include "machine.h"
#include "opcode.h"

static int			input;
static machine_t*	machine;

#define HERE 							GET_CELL( machine, A_HERE )
#define FORTH_WORDLIST					GET_CELL( machine, A_FORTH_WORDLIST )
#define INTERNALS_WORDLIST				GET_CELL( machine, A_INTERNALS_WORDLIST )
#define LOCALS_WORDLIST					GET_CELL( machine, A_LOCALS_WORDLIST )
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

static void lay_header( uint8_t type, const char* name ) {
	comma( GET_CELL( machine, GET_CELL( machine, A_CURRENT ) ) );
	c_comma( type );
	WRITE_CELL( machine, GET_CELL( machine, A_CURRENT ), HERE - CELL_SIZE - 1 );
	s_comma( name );
}

static cell_t to_xt( cell_t link ) { return link + GET_BYTE( machine, link+CELL_SIZE+1 ) + CELL_SIZE + 2; }
static cell_t to_name( cell_t link ) { return link + CELL_SIZE + 1; }

static void variable( cell_t address, const char* name ) {
	lay_header( opNONE, name );
	c_comma( opDOLIT ); comma( address ); c_comma( opRET );
}

static void opword( uint8_t opcode, const char* name ) {
	lay_header( opcode, name );
	c_comma( opcode );
	c_comma( opRET );
}

static void constant( const char* name, cell_t value ) {
	lay_header( opNONE, name );
	// TOO literal constants which have opcodes.
	if ( value < 256 ) {
		c_comma( opDOLIT_U8 );
		c_comma( value & 255 );
	} else {
		c_comma( opDOLIT );
		comma( value );
	}
	c_comma( opRET );
}

#define opconstant( name ) constant( #name, name )

//#define opconst_db( name ) {}
#define opconst_db( name ) constant( #name, name )

static void internals_definitions( void ) {	WRITE_CELL( machine, A_CURRENT, A_INTERNALS_WORDLIST ); }
static void forth_definitions( void ) {	WRITE_CELL( machine, A_CURRENT, A_FORTH_WORDLIST ); }

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
				if ( cmp( name, ABS_PTR( machine, s+1 ), strlen(name) ) == 0 ) {
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
		if ( read( input, &c, 1 ) != 1 ) break;
		if ( c != '\r' ) {
			if ( input != STDIN_FILENO ) {
				putchar( c );
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

int main( int argc, char** argv ) {

	machine_endian_t	endian = ENDIAN_NATIVE;
	uint32_t			word_colon = 0;
	uint32_t			word_semicolon = 0;
	uint32_t			word_fslash = 0;
	const char*			include_file = NULL;
	const char*			post_action = NULL;
	int					i;

	for ( i = 1; i < argc; i++ ) {
		if ( ( strcmp( argv[i], "-h" ) == 0 ) || ( strcmp( argv[i], "-help" ) == 0 ) ) {
			printf("%s <args>\n", argv[0] );
			printf("-h -help		This text\n" );
			printf("-f <name>		File to include on boot\n" );
			printf("-p <string>		Text to run on start but after include\n" );
			printf("-be				Select big endian\n");
			printf("-le				Select little endian\n");
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
		} else {
			printf("invalid switch %s\n", argv[i] );
			exit(0);
		}
	}

	machine = (machine_t*)malloc( sizeof(machine_t) );

	machine_init( machine );
	machine->memory = malloc( SIZE_FORTH );
	machine->datastack = malloc( SIZE_DATA_STACK );
	machine->returnstack = malloc( SIZE_RETURN_STACK );

	machine_set_endian( machine, endian );

	memset( machine->memory, 0, SIZE_FORTH );

	/** init vars */
	WRITE_CELL( machine, A_HERE, START_HERE );
	WRITE_CELL( machine, A_FORTH_WORDLIST-CELL_SIZE, 0 );
	WRITE_CELL( machine, A_FORTH_WORDLIST, 0 );
	WRITE_CELL( machine, A_INTERNALS_WORDLIST-CELL_SIZE, A_FORTH_WORDLIST );
	WRITE_CELL( machine, A_INTERNALS_WORDLIST, 0 );
	WRITE_CELL( machine, A_LOCALS_WORDLIST-CELL_SIZE, A_INTERNALS_WORDLIST );
	WRITE_CELL( machine, A_LOCALS_WORDLIST, 0 );
	WRITE_CELL( machine, A_LIST_OF_WORDLISTS, A_LOCALS_WORDLIST );
	WRITE_CELL( machine, A_QUIT, 0 );
	WRITE_CELL( machine, A_BASE, 10 );
	WRITE_CELL( machine, A_STATE, 0 );
	WRITE_CELL( machine, A_TIB, A_INPUT_BUFFER );
	WRITE_CELL( machine, A_HASH_TIB, 0 );
	WRITE_CELL( machine, A_TOIN, 0 );
	WRITE_CELL( machine, A_CURRENT, A_FORTH_WORDLIST );
	WRITE_CELL( machine, A_THROW, 0 );
	WRITE_CELL( machine, A_ORDER, A_INTERNALS_WORDLIST );
	WRITE_CELL( machine, A_ORDER +CELL_SIZE, A_FORTH_WORDLIST );

	constant( "INTERNALS", A_INTERNALS_WORDLIST );		
	constant( "forth-wordlist", A_FORTH_WORDLIST );		// this one is actually a forth word

	internals_definitions();
	variable( A_LIST_OF_WORDLISTS, "A_LIST_OF_WORDLISTS" );
	constant( "locals-wordlist", A_LOCALS_WORDLIST );	

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
	constant( "IMAGE_HEADER_ID", HEADER_ID );
	constant( "SIZE_DATA_STACK", SIZE_DATA_STACK );
	constant( "SIZE_RETURN_STACK", SIZE_RETURN_STACK );
	constant( "SIZE_FORTH", SIZE_FORTH );
	constant( "SIZE_INPUT_BUFFER", SIZE_INPUT_BUFFER );
	constant( "SIZE_PICTURED_NUMERIC", SIZE_PICTURED_NUMERIC );
	constant( "SIZE_ORDER", SIZE_ORDER );
	constant( "A_HERE", A_HERE );
	constant( "A_QUIT", A_QUIT );
	constant( "A_CURRENT", A_CURRENT );
	constant( "A_THROW", A_THROW );
	constant( "A_ORDER", A_ORDER );
	constant( "A_PICTURED_NUMERIC", A_PICTURED_NUMERIC );
	constant( "A_INPUT_BUFFER", A_INPUT_BUFFER );

	/** Forth definitions that map to a single opcode */
	forth_definitions();
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
	opword( opLSHIFT, "lshift" );
	opword( opRSHIFT, "rshift" );
	opword( opROT, "rot" );
	opword( opTUCK, "tuck" );
	opword( opROLL, "roll" );
	opword( op2DUP, "2dup" );
	opword( op2DROP, "2drop" );
	opword( op2OVER, "2over" );
	opword( op2SWAP, "2swap" );
	opword( opMOVE, "move" );
	opword( opDEPTH, "depth" );
	opword( opOVER, "over" );
	opword( opDUP, "dup" );
	opword( opPICK, "pick" );
    opword( opDMINUS, "d-" );
	opword( opFETCH, "@" );
	opword( opEQUALS, "=" );
	opword( opSTORE, "!" );
	opword( opZEROEQ, "0=" );
	opword( opOR, "or" );
	opword( opAND, "and" );
	opword( opXOR, "xor" );
	opword( opCSTORE, "c!" );
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

	lay_header( opNONE, "cells" );
	if ( CELL_SIZE == 4 ) {
		c_comma( opLIT4 ); c_comma( opMULT ); c_comma( opRET );
	} else if ( CELL_SIZE == 2 ) {
		c_comma( opLIT2 ); c_comma( opMULT ); c_comma( opRET );
	} else {	
		printf("bug - only 16 and 32bit builds allowed\n");
		exit(0);
	}

	// DO NOT embed opcode for execute or we can't run it from the bootstrap interpreter ( I think? maybe try one day )
	lay_header( opNONE, "execute" );
	c_comma( opEXECUTE ); c_comma( opRET );
	// Do not make the r> >r r@ words here because compiling the opcode behavior as above doesn't work if you ' execute etc.

	internals_definitions();
	opword( opRSPFETCH, "rsp@" );
	opword( opRSPSTORE, "rsp!" );
	opword( opSPFETCH, "sp@" );
	opword( opSPSTORE, "sp!" );
	opword( opWFETCH, "w@" );
	opword( opWSTORE, "w!" );
	opword( opBYE, "bye" );

	opconstant( opNONE );
	opconst_db( op2DROP );
	opconst_db( op2DUP );
	opconst_db( op2OVER );
	opconst_db( op2SWAP );
	opconst_db( opADD2 );
	opconst_db( opAND );
	opconstant( opBRANCH );
	opconst_db( opBYE );
	opconstant( opCALL );
	opconst_db( opCFETCH );
	opconst_db( opCLOSE_FILE );
	opconstant( opCOMPARE );
	opconst_db( opCREATE_FILE );
	opconst_db( opCSTORE );
	opconst_db( opDELETE_FILE );
	opconst_db( opDEPTH );
	opconst_db( opDLESSTHAN );
	opconstant( opDOLIT );
	opconstant( opDOLIT_U8 );
	opconst_db( opDROP );
	opconstant( opDUP );
	opconst_db( opEMIT );
	opconst_db( opEQUALS );
	opconst_db( opEXECUTE );
	opconstant( opFETCH );
	opconst_db( opFILE_POSITION );
	opconst_db( opFILE_SIZE );
	opconst_db( opFILE_STATUS );
	opconst_db( opFLUSH_FILE );
	opconst_db( opGREATER_THAN );
	opconst_db( opINVERT );
	opconst_db( opIP );
	opconstant( opIN );
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

	forth_definitions();
	/**
 	 */
	if ( include_file )
		input = open( include_file, O_RDONLY );
	else	
		input = STDIN_FILENO;
	for (;;) {
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
			} else if ( GET_CELL( machine, A_QUIT ) == 0 ) {
				/* just drop into bootstrap interpreter */
			} else {
				/* TODO report any exception? */
				for (;;)
					machine_execute( machine, GET_CELL( machine, A_QUIT ), A_THROW, 1 );
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
					lay_header( opNONE, tmp_word );
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
					if ( word_colon == 0 ) 		{ word_colon = find(":"); if ( word_colon ) printf("now have :\n"); }
					if ( word_semicolon == 0 )  { word_semicolon = find(";"); if ( word_semicolon ) printf("now have ;\n" ); }
					goto rescan;
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
						} else {
							c_comma( opDOLIT );
							comma( v );
						}
					} else {
						machine->datastack[ machine->DP ] = v;
						machine->DP++;
					}				
				} else {
					uint32_t xt = to_xt( v );
					uint8_t* header = ((uint8_t*)(machine->memory))+v;

					if ( ( STATE == 0 ) || ( header[ CELL_SIZE ] == opIMMEDIATE ) ) {
						machine_execute( machine, xt, A_THROW, 1 );
						/* TODO report any exception? */
					} else if ( header[CELL_SIZE] == opNONE ) {
						if ( xt < 65536 ) {
							c_comma( opSHORT_CALL );
							w_comma( xt );
						} else {
							c_comma( opCALL );
							comma( xt );
						}
					} else {
						c_comma( header[CELL_SIZE] );
					}
				}
			}
		}
	}

	return 0;
}

