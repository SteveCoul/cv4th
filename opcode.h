#ifndef __opcode_h__
#define __opcode_h__

enum {
	opNONE						= 0,

	op2DROP,
	op2DUP,
	op2OVER,
	op2SWAP,

	opADD2,
	opAND,

	opBRANCH,
	opBYE,

	opCALL,
	opCFETCH,
	opCLOSE_FILE,
	opCOMPARE,
	opCREATE_FILE,
	opCSTORE,

	opDELETE_FILE,
	opDEPTH,
    opDMINUS,
	opDOLIT,
	opDOLIT_U8,
	opDROP,
	opDUP,

	opEMIT,
	opEQUALS,
	opEXECUTE,

	opFETCH,
	opFILE_POSITION,
	opFILE_SIZE,
	opFILE_STATUS,
	opFLUSH_FILE,

	opGREATER_THAN,

	opINVERT,
	opIP,

	opIN,

	opLESS_THAN,
	opLITM1,
	opLIT0,
	opLIT1,
	opLIT2,
	opLIT3,
	opLIT4,
	opLIT5,
	opLIT6,
	opLIT7,
	opLIT8,
	opLPFETCH,
	opLPSTORE,
	opLFETCH,
    opLSHIFT,
	opLSTORE,

	opMINUS,
	opMOVE,
	opMULT,
	opMULT2,

	opNIP,

	opONEMINUS,
	opONEPLUS,
	opOPEN_FILE,
	opOR,
	opOVER,

	opPICK,
	opPLUS,
	opPLUSSTORE,

	opQBRANCH,
    opQTHROW,

	opREAD_FILE,
	opRENAME_FILE,
	opREPOSITION_FILE,
	opRESIZE_FILE,
	opRET,
	opRFETCH,
	opRFROM,
	opROT,
	opROLL,
	opRSHIFT,
	opRSPFETCH,
	opRSPSTORE,

	opSHORT_CALL,
 	opSM_SLASH_REM,
	opSPFETCH,
	opSPSTORE,
	opSTORE,
	opSWAP,

	opTOR,
	opTUCK,

	opU_GREATER_THAN,
	opU_LESS_THAN,
	opUMULT,
	opUMULT2,
	opUM_SLASH_MOD,

	opWFETCH,
	opWRITE_FILE,
	opWSTORE,

	opXOR,

	opZEROEQ,
	opIMMEDIATE };

#endif


