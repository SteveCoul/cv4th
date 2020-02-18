
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#include "common.h"
#include "machine.h"
#include "opcode.h"

static int			input;
static machine_t*	machine;

#define SIZE_DATA_STACK					1024
#define SIZE_RETURN_STACK				1024
#define SIZE_FORTH						256*1024
#define SIZE_INPUT_BUFFER				256
#define SIZE_PICTURED_NUMERIC			64
#define SIZE_ORDER						10

#define	A_HERE							0
#define A_LIST_OF_WORDLISTS				4
/* wid-link ptr for forth-wordlist 		8	*/
#define A_FORTH_WORDLIST				12
/* wid-link ptr for internals 			16	*/
#define A_INTERNALS_WORDLIST			20
/* wid-link ptr for locals 				24	*/
#define A_LOCALS_WORDLIST				28
#define A_QUIT							32
#define A_BASE							36
#define A_STATE							40
#define A_TIB							44
#define A_HASH_TIB						48
#define A_TOIN							52	
#define A_CURRENT						56
#define A_ORDER							60
#define A_PICTURED_NUMERIC				A_ORDER + ( SIZE_ORDER * 4 )
#define A_INPUT_BUFFER					A_PICTURED_NUMERIC + SIZE_PICTURED_NUMERIC
#define START_HERE						A_INPUT_BUFFER+SIZE_INPUT_BUFFER

#define HERE 							GET_CELL( machine, A_HERE )
#define FORTH_WORDLIST					GET_CELL( machine, A_FORTH_WORDLIST )
#define INTERNALS_WORDLIST				GET_CELL( machine, A_INTERNALS_WORDLIST )
#define LOCALS_WORDLIST					GET_CELL( machine, A_LOCALS_WORDLIST )
#define HASH_TIB						GET_CELL( machine, A_HASH_TIB )
#define TOIN							GET_CELL( machine, A_TOIN )
#define STATE							GET_CELL( machine, A_STATE )

#define COMMA( value )					{ WRITE_CELL( machine, HERE, value ); WRITE_CELL( machine, A_HERE, HERE + 4 ); }
#define W_COMMA( value )				{ WRITE_WORD( machine, HERE, value ); WRITE_CELL( machine, A_HERE, HERE + 2 ); }
#define C_COMMA( value )				{ WRITE_BYTE( machine, HERE, value ); WRITE_CELL( machine, A_HERE, HERE + 1 ); }
#define S_COMMA( text )					C_COMMA( strlen(text) ); { unsigned int i; for ( i = 0; text[i] != 0; i++ ) C_COMMA( text[i] ); }

#define LAY_HEADER( type, name )		COMMA( GET_CELL( machine, GET_CELL( machine, A_CURRENT ) ) ); \
										C_COMMA( type ); 											  \
										WRITE_CELL( machine, GET_CELL( machine, A_CURRENT ), HERE - 5 ); 	\
										S_COMMA( name )

#define TO_XT( r_address )				r_address + GET_BYTE( machine, r_address+5 ) + 6
#define TO_NAME( r_address )			r_address + 5

#define VARIABLE( r_address, name )	LAY_HEADER( opNONE, name ); C_COMMA( opDOLIT ); COMMA( r_address ); C_COMMA( opRET )
#define OPWORD( opcode, name ) LAY_HEADER( opcode, name ); C_COMMA( opcode ); C_COMMA( opRET )
#define CONSTANT( name, value ) LAY_HEADER( opNONE, name ); C_COMMA( opDOLIT ); COMMA( value ); C_COMMA( opRET )
#define OPCONSTANT( name ) LAY_HEADER( opNONE, #name ); C_COMMA( opDOLIT ); COMMA( name ); C_COMMA( opRET );

#define INTERNALS_DEFINITIONS			WRITE_CELL( machine, A_CURRENT, A_INTERNALS_WORDLIST );
#define FORTH_DEFINITIONS				WRITE_CELL( machine, A_CURRENT, A_FORTH_WORDLIST );

uint32_t find( const char* name ) {
	uint32_t i = 0;	
	uint32_t wids[ SIZE_ORDER + 1 ];
	wids[0] = LOCALS_WORDLIST;
	for ( i = 0; i < SIZE_ORDER; i++ ) {
		wids[i+1] = GET_CELL( machine, A_ORDER + (i*4) );
	}
	
	for ( i = 0; i < SIZE_ORDER+1; i++ ) {
		uint32_t p = wids[i];
		while ( p != 0 ) {
			uint32_t s = TO_NAME( p );
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
		(void)read( input, &c, 1 );
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
	machine->datastack = malloc( SIZE_DATA_STACK/4 );
	machine->returnstack = malloc( SIZE_RETURN_STACK/4 );

	machine_set_endian( machine, endian );

	memset( machine->memory, 0, SIZE_FORTH );

	/** init user vars */
	WRITE_CELL( machine, A_HERE, START_HERE );
	WRITE_CELL( machine, A_FORTH_WORDLIST-4, 0 );
	WRITE_CELL( machine, A_FORTH_WORDLIST, 0 );
	WRITE_CELL( machine, A_INTERNALS_WORDLIST-4, A_FORTH_WORDLIST );
	WRITE_CELL( machine, A_INTERNALS_WORDLIST, 0 );
	WRITE_CELL( machine, A_LOCALS_WORDLIST-4, A_INTERNALS_WORDLIST );
	WRITE_CELL( machine, A_LOCALS_WORDLIST, 0 );
	WRITE_CELL( machine, A_LIST_OF_WORDLISTS, A_LOCALS_WORDLIST );
	WRITE_CELL( machine, A_QUIT, 0 );
	WRITE_CELL( machine, A_BASE, 10 );
	WRITE_CELL( machine, A_STATE, 0 );
	WRITE_CELL( machine, A_TIB, A_INPUT_BUFFER );
	WRITE_CELL( machine, A_HASH_TIB, 0 );
	WRITE_CELL( machine, A_TOIN, 0 );
	WRITE_CELL( machine, A_CURRENT, A_FORTH_WORDLIST );
	WRITE_CELL( machine, A_ORDER, A_INTERNALS_WORDLIST );
	WRITE_CELL( machine, A_ORDER +4, A_FORTH_WORDLIST );

	CONSTANT( "INTERNALS", A_INTERNALS_WORDLIST );		
	CONSTANT( "forth-wordlist", A_FORTH_WORDLIST );		// this one is actually a forth word

	INTERNALS_DEFINITIONS
	VARIABLE( A_LIST_OF_WORDLISTS, "A_LIST_OF_WORDLISTS" );
	CONSTANT( "locals-wordlist", A_LOCALS_WORDLIST );	

	FORTH_DEFINITIONS
	LAY_HEADER( opNONE, "here" );	// in forth code here is not a variable
	C_COMMA( opDOLIT );
	COMMA( A_HERE );
	C_COMMA( opFETCH );
	C_COMMA( opRET );

	VARIABLE( A_STATE, "state" );
	VARIABLE( A_TIB, "tib" );
	VARIABLE( A_HASH_TIB, "#tib" );
	VARIABLE( A_TOIN, ">in" );
	VARIABLE( A_BASE, "base" );
	CONSTANT( "r/o", O_RDONLY );
	CONSTANT( "w/o", O_WRONLY );
	CONSTANT( "r/w", O_RDWR );

	INTERNALS_DEFINITIONS
	CONSTANT( "SIZE_DATA_STACK", SIZE_DATA_STACK );
	CONSTANT( "SIZE_RETURN_STACK", SIZE_RETURN_STACK );
	CONSTANT( "SIZE_FORTH", SIZE_FORTH );
	CONSTANT( "SIZE_INPUT_BUFFER", SIZE_INPUT_BUFFER );
	CONSTANT( "SIZE_PICTURED_NUMERIC", SIZE_PICTURED_NUMERIC );
	CONSTANT( "SIZE_ORDER", SIZE_ORDER );
	CONSTANT( "A_HERE", A_HERE );
	CONSTANT( "A_QUIT", A_QUIT );
	CONSTANT( "A_CURRENT", A_CURRENT );
	CONSTANT( "A_ORDER", A_ORDER );
	CONSTANT( "A_PICTURED_NUMERIC", A_PICTURED_NUMERIC );
	CONSTANT( "A_INPUT_BUFFER", A_INPUT_BUFFER );

	/** Forth definitions that map to a single opcode */
	FORTH_DEFINITIONS
	OPWORD( opOPEN_FILE, "open-file" );
	OPWORD( opCLOSE_FILE, "close-file" );
	OPWORD( opCREATE_FILE, "create-file" );
	OPWORD( opREAD_FILE, "read-file" );
	OPWORD( opWRITE_FILE, "write-file" );
	OPWORD( opDELETE_FILE, "delete-file" );
	OPWORD( opFILE_POSITION, "file-position" );
	OPWORD( opFILE_SIZE, "file-size" );
	OPWORD( opFILE_STATUS, "file-status" );
	OPWORD( opFLUSH_FILE, "flush-file" );
	OPWORD( opRESIZE_FILE, "resize-file" );
	OPWORD( opRENAME_FILE, "rename-file" );
	OPWORD( opREPOSITION_FILE, "reposition-file" );
	OPWORD( opU_GREATER_THAN, "u>" );
	OPWORD( opU_LESS_THAN, "u<" );
	OPWORD( opNIP, "nip" );
	OPWORD( opROT, "rot" );
	OPWORD( opTUCK, "tuck" );
	OPWORD( opROLL, "roll" );
	OPWORD( op2DUP, "2dup" );
	OPWORD( op2DROP, "2drop" );
	OPWORD( op2OVER, "2over" );
	OPWORD( op2SWAP, "2swap" );
	OPWORD( opMOVE, "move" );
	OPWORD( opDEPTH, "depth" );
	OPWORD( opOVER, "over" );
	OPWORD( opDUP, "dup" );
	OPWORD( opPICK, "pick" );
	OPWORD( opFETCH, "@" );
	OPWORD( opEQUALS, "=" );
	OPWORD( opSTORE, "!" );
	OPWORD( opNOT, "not" );
	OPWORD( opOR, "or" );
	OPWORD( opAND, "and" );
	OPWORD( opCSTORE, "c!" );
	OPWORD( opCFETCH, "c@" );
	OPWORD( opDROP, "drop" );
	OPWORD( opEMIT, "emit" );
	OPWORD( opMULT, "*" );
	OPWORD( opMINUS, "-" );
	OPWORD( opGREATER_THAN, ">" );
	OPWORD( opLESS_THAN, "<" );
	OPWORD( opPLUS, "+" );
	OPWORD( opPLUSSTORE, "+!" );
	OPWORD( opSWAP, "swap" );
	OPWORD( opUM_SLASH_MOD, "um/mod" );
	// DO NOT embed opcode for execute or we can't run it from the bootstrap interpreter ( I think? maybe try one day )
	LAY_HEADER( opNONE, "execute" );
	C_COMMA( opEXECUTE ); C_COMMA( opRET );
	// Do not make the r> >r r@ words here because compiling the opcode behavior as above doesn't work if you ' execute etc.

	INTERNALS_DEFINITIONS
	OPWORD( opBYE, "bye" );
	OPWORD( opRSPFETCH, "rsp@" );
	OPWORD( opRSPSTORE, "rsp!" );
	OPWORD( opSPFETCH, "sp@" );
	OPWORD( opSPSTORE, "sp!" );
	OPWORD( opWFETCH, "w@" );
	OPWORD( opWSTORE, "w!" );

	/* only the ones I need to save space */
	OPCONSTANT( opNONE );
	OPCONSTANT( opADD2 );
	OPCONSTANT( opUMULT );
	OPCONSTANT( opIN );
	OPCONSTANT( opFETCH );
	OPCONSTANT( opCALL );
	OPCONSTANT( opSHORT_CALL );
 	OPCONSTANT( opCOMPARE );
    OPCONSTANT( opRET );
	OPCONSTANT( opJUMP_EQ_ZERO );
	OPCONSTANT( opJUMP );
	OPCONSTANT( opJUMPD );
	OPCONSTANT( opDOLIT );
    OPCONSTANT( opDUP );
	OPCONSTANT( opLPFETCH );
	OPCONSTANT( opLPSTORE );
	OPCONSTANT( opRSPSTORE );
	OPCONSTANT( opLFETCH );
	OPCONSTANT( opLSTORE );
    OPCONSTANT( opSWAP );
    OPCONSTANT( opRFROM );
    OPCONSTANT( opTOR );
    OPCONSTANT( opROT );
    OPCONSTANT( opRFETCH );
	OPCONSTANT( opIMMEDIATE );

	FORTH_DEFINITIONS
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
				machine_execute( machine, GET_CELL( machine, A_QUIT ) );
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
					LAY_HEADER( opNONE, tmp_word );
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
					WRITE_CELL( machine, A_STATE, 0 );
					C_COMMA( opRET );
					if ( word_colon == 0 ) 		{ word_colon = find(":"); if ( word_colon ) printf("now have :\n"); }
					if ( word_semicolon == 0 )  { word_semicolon = find(";"); if ( word_semicolon ) printf("now have ;\n" ); }
					goto rescan;
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
						C_COMMA( opDOLIT );
						COMMA( v );
					} else {
						machine->datastack[ machine->DP ] = v;
						machine->DP++;
					}				
				} else {
					uint32_t xt = TO_XT( v );
					uint8_t* header = ((uint8_t*)(machine->memory))+v;

					if ( ( STATE == 0 ) || ( header[4] == opIMMEDIATE ) ) {
						machine_execute( machine, xt );
					} else if ( header[4] == opNONE ) {
						if ( xt < 65536 ) {
							C_COMMA( opSHORT_CALL );
							W_COMMA( xt );
						} else {
							C_COMMA( opCALL );
							COMMA( xt );
						}
					} else {
						C_COMMA( header[4] );
					}
				}
			}
		}
	}

	return 0;
}
