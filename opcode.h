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

	opBYE,

	opCALL,
	opCFETCH,
	opCLOSE_FILE,
	opCOMPARE,
	opCREATE_FILE,
	opCSTORE,

	opDELETE_FILE,
	opDEPTH,
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

	opIP,

	opJUMP,
	opJUMPD,
	opJUMP_EQ_ZERO,

	opIN,

	opLESS_THAN,
	opLPFETCH,
	opLPSTORE,
	opLFETCH,
	opLSTORE,

	opMINUS,
	opMOVE,
	opMULT,

	opNIP,
	opNOT,

	opONEMINUS,
	opONEPLUS,
	opOPEN_FILE,
	opOR,
	opOVER,

	opPICK,
	opPLUS,
	opPLUSSTORE,

	opREAD_FILE,
	opRENAME_FILE,
	opREPOSITION_FILE,
	opRESIZE_FILE,
	opRET,
	opRFETCH,
	opRFROM,
	opROT,
	opROLL,
	opRSPFETCH,
	opRSPSTORE,

	opSHORT_CALL,
	opSPFETCH,
	opSPSTORE,
	opSTORE,
	opSWAP,

	opTOR,
	opTUCK,

	opU_GREATER_THAN,
	opU_LESS_THAN,
	opUMULT,
	opUM_SLASH_MOD,

	opWFETCH,
	opWRITE_FILE,
	opWSTORE,
	opIMMEDIATE };

#endif


