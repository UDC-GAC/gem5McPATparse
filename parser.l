%option yylineno noyywrap nodefault stack
%{
#include "parser.tab.h"

/* THIS WAY IS POSSIBLE TO RETURN TO PREVIOUS STATE */
int PREV_STATE = -1;

%}					
%x CLK			
%x ISA

%x LATENCY
			
%x DTLB
%x ITLB

%x DL1
%x DL1TAGS
%x IL1
%x IL1TAGS

%x L2
%x L2TAGS

%x MMEM

%x DELIM			
%x VALUE
						
digit   	    [0-9]
double              {digit}+"."{digit}+			
letter              [a-zA-Z]
str                 {letter}+			
ws                  [ ]			
eq                  "="
ignore              [a-zA-Z0-9\-\/\[\]\.\_\:\#\(\)\+\,\%\'\;]+					
fetchWidth          "fetchWidth"
decodeWidth         "decodeWidth"
issueWidth          "issueWidth"
commitWidth         "commitWidth"
fetchBufferSize     "fetchBufferSize"
numIQEntries        "numIQEntries"
numROBEntries       "numROBEntries"
numPhysIntRegs      "numPhysIntRegs"
numPhysFloatRegs    "numPhysFloatRegs"
SQEntries           "SQEntries"
LQEntries           "LQEntries"
RASSize             "RASSize"
f2DecodeDelay       "fetchToDecodeDelay"
d2RenameDelay       "decodeToRenameDelay"
r2IEWDelay          "renameToIEWDelay"
i2CommitDelay       "iewToCommitDelay"
c2DecodeDelay       "commitToDecodeDelay"
c2FetchDelay        "commitToFetchDelay"
c2IEWDelay          "commitToIEWDelay"
c2RenameDelay       "commitToRenameDelay"
lHistBits           "localHistoryBits"
lCtrBits            "localCtrBits" 
lPredictorSize      "localPredictorSize"
gPredictorSize      "globalPredictorSize"
gCtrBits            "globalCtrBits"
cPredictorSize      "choicePredictorSize"
cCtrBits            "choiceCtrBits"
BTBEntries          "BTBEntries"
CPU                 "system.cpu."
SYS                 "system."
SL2                 "system.l2."
DTB                 "system.cpu.dtb_walker_cache.tags."
ITB                 "system.cpu.itb_walker_cache.tags."
D1                  "system.cpu.dcache."
I1                  "system.cpu.icache."
%%			

    /* CLOCK */
<INITIAL>"[system.clk_domain]" {
	BEGIN(CLK);
}

<CLK>"clock" {
        BEGIN(VALUE);
        return SYSCLK;
}

    /* MEM MODE */
<INITIAL>"mem_mode" {
        BEGIN(VALUE);
        return M_MODE;
}

    /* ISA type */

<INITIAL>"[system.cpu.isa]\n" {
        BEGIN(ISA);
}

<ISA>"type=X86ISA" {
        BEGIN(INITIAL);
        return X86;
}

    /* core parameters */
    /* FETCHWIDTH */
<INITIAL>{fetchWidth} {
        BEGIN(VALUE);
        return FETCHW;        
}

    /* DECODEWIDTH */
<INITIAL>{decodeWidth} {
        BEGIN(VALUE);
        return DECODEW;        
}

    /* ISSUEWIDTH */
<INITIAL>{issueWidth} {
        BEGIN(VALUE);
        return ISSUEW;        
}

    /* COMMITWIDTH */
<INITIAL>{commitWidth} {
        BEGIN(VALUE);
        return COMMITW;        
}

    /* fetchBufferSize */
<INITIAL>{fetchBufferSize} {
        BEGIN(VALUE);
        return BUFFERS;        
}

    /* numIQEntries */
<INITIAL>{numIQEntries} {
        BEGIN(VALUE);
        return NIQENTRIES;        
}

    /* numROBEntries */
<INITIAL>{numROBEntries} {
        BEGIN(VALUE);
        return NROBENTRIES;        
}

    /* numPhysIntRegs */
<INITIAL>{numPhysIntRegs} {
        BEGIN(VALUE);
        return NINTREGS;        
}

    /* numPhysFloatRegs */
<INITIAL>{numPhysFloatRegs} {
        BEGIN(VALUE);
        return NFREGS;        
}

    /* SQEntries */
<INITIAL>{SQEntries} {
        BEGIN(VALUE);
        return SQENTRIES;        
}
    /* LQEntries */
<INITIAL>{LQEntries} {
        BEGIN(VALUE);
        return LQENTRIES;        
}
    /* RASSize */
<INITIAL>{RASSize} {
        BEGIN(VALUE);
        return RASSIZE;        
}

    /* BRANCH PREDICTOR */
<INITIAL>{lHistBits} {
        BEGIN(VALUE);
        return LHISTB;       
}

<INITIAL>{lCtrBits} {
        BEGIN(VALUE);
        return LCTRB;       
}

<INITIAL>{lPredictorSize} {
        BEGIN(VALUE);
        return LPREDSIZE;       
}

<INITIAL>{gPredictorSize} {
        BEGIN(VALUE);
        return GPREDSIZE;       
}

<INITIAL>{gCtrBits} {
        BEGIN(VALUE);
        return GCTRB;       
}

<INITIAL>{cPredictorSize} {
        BEGIN(VALUE);
        return CPREDSIZE;       
}

<INITIAL>{cCtrBits} {
        BEGIN(VALUE);
        return CCTRB;       
}

    /* BRANCH PREDICTOR BUFFER */

<INITIAL>{BTBEntries} {
        BEGIN(VALUE);
        return BTBE;       
}

    /* CACHE PARAMETERS */
    /* tlb */

<INITIAL>"[system.cpu.dtb]" {
        BEGIN(DTLB);
}

<INITIAL>"[system.cpu.itb]" {
        BEGIN(ITLB);
}

<DTLB>"size" {
        BEGIN(VALUE);
        return TLBD;       
}

<ITLB>"size" {
        BEGIN(VALUE);
        return TLBI;       
}

    /* DATA CACHE L1 */
<INITIAL>"[system.cpu.dcache]" {
        BEGIN(DL1);
}

<DL1>"size" {
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return DL1SIZE;
}

<DL1>"assoc" {
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return DL1ASSOC;
}

<DL1>"mshrs" {
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return D1MSHRS;
}

<DL1>"hit_latency" {
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return HLDL1;
}

<DL1>"response_latency" {
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return RLDL1;
}

<DL1>"write_buffers" {
        BEGIN(VALUE);
        return WBDL1;
}

<INITIAL>"[system.cpu.dcache.tags]" {
        BEGIN(DL1TAGS);
}

<DL1TAGS>"block_size" {
        BEGIN(VALUE);
        return DL1BSIZE;
}

    /* INST CACHE L1 */
<INITIAL>"[system.cpu.icache]" {
        BEGIN(IL1);
}

<IL1>"size" {
        BEGIN(VALUE);
        return IL1SIZE;
}

<IL1>"assoc" {
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return IL1ASSOC;
}

<IL1>"mshrs" {
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return I1MSHRS;
}

<IL1>"hit_latency" {
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return HLIL1;
}

<IL1>"response_latency" {
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return RLIL1;
}

<INITIAL>"[system.cpu.icache.tags]" {
        BEGIN(IL1TAGS);
}

<IL1TAGS>"block_size" {
        BEGIN(VALUE);
        return IL1BSIZE;
}

    /* CACHE L2 */

<INITIAL>"[system.l2]" {
        BEGIN(L2);
}

<L2>"size" {
        PREV_STATE = L2;
        BEGIN(VALUE);
        return L2SIZE;
}

<L2>"assoc" {
        PREV_STATE = L2;
        BEGIN(VALUE);
        return L2ASSOC;
}

<L2>"mshrs" {
        PREV_STATE = L2;
        BEGIN(VALUE);
        return L2MSHRS;
}

<L2>"hit_latency" {
        PREV_STATE = L2;
        BEGIN(VALUE);
        return HLL2;
}

<L2>"response_latency" {
        PREV_STATE = L2;
        BEGIN(VALUE);
        return RLL2;
}

<L2>"write_buffers" {
        BEGIN(VALUE);
        return WBL2;
}

<INITIAL>"[system.l2.tags]" {
        BEGIN(L2TAGS);
}

<L2TAGS>"block_size" {
        BEGIN(VALUE);
        return L2BSIZE;
}

    /* CALCULATING BASE PARAMETERS (SEE APPENDIX A) */

<INITIAL>{f2DecodeDelay} {
        BEGIN(VALUE);
        return BASE;        
}

<INITIAL>{d2RenameDelay} {
        BEGIN(VALUE);
        return BASE;        
}

<INITIAL>{r2IEWDelay} {
        BEGIN(VALUE);
        return BASE;
}

<INITIAL>{i2CommitDelay} {
        BEGIN(VALUE);
        return BASE;       
}

<INITIAL>{c2DecodeDelay} {
        BEGIN(VALUE);
        return MAXBASE;       
}

<INITIAL>{c2FetchDelay} {
        BEGIN(VALUE);
        return MAXBASE;       
}

<INITIAL>{c2IEWDelay} {
        BEGIN(VALUE);
        return MAXBASE;       
}

<INITIAL>{c2RenameDelay} {
        BEGIN(VALUE);
        return MAXBASE;       
}

    /* MAIN MEMORY PARAMS */
<INITIAL>"[system.mem_ctrls]" {
        BEGIN(MMEM);
}

<MMEM>"channels" {
        PREV_STATE = MMEM;
        BEGIN(VALUE);
        return MM_CHNLS;
}

<MMEM>"ranks_per_channel" {
        PREV_STATE = MMEM;
        BEGIN(VALUE);
        return MM_RANKS;
}

<MMEM>"write_buffer_size" {
        BEGIN(VALUE);
        return MM_BSIZE;
}


    /* ====== STATISTICS ====== */

<INITIAL>{CPU}"decode.DecodedInsts" {
    BEGIN(DELIM);
    return DECODINSTS;
}

<INITIAL>{CPU}"branchPred.condPredicted" {
    BEGIN(DELIM);
    return BRANCHPRED;
}

<INITIAL>{CPU}"branchPred.condIncorrect" {
    BEGIN(DELIM);
    return BRANCHERR;
}

<INITIAL>{CPU}"iew.iewExecLoadInsts" {
    BEGIN(DELIM);
    return IEWLOAD;
}

<INITIAL>{CPU}"iew.exec_refs" {
    BEGIN(DELIM);
    return IEWSTORE;
}

<INITIAL>{CPU}"commit.int_insts" {
    BEGIN(DELIM);
    return CINT;
}

<INITIAL>{CPU}"commit.fp_insts" {
    BEGIN(DELIM);
    return CFP;
}

<INITIAL>{CPU}"ipc_total" {
    BEGIN(DELIM);
    return IPC;
}

<INITIAL>{CPU}"numCycles" {
    BEGIN(DELIM);
    return NCYCLES;
}

<INITIAL>{CPU}"idleCycles" {
    BEGIN(DELIM);
    return ICYCLES;
}

<INITIAL>{CPU}"rob.rob_reads" {
    BEGIN(DELIM);
    return ROBREADS;
}

<INITIAL>{CPU}"rob.rob_writes" {
    BEGIN(DELIM);
    return ROBWRITES;
}

<INITIAL>{CPU}"rename.int_rename_lookups" {
    BEGIN(DELIM);
    return RE_INT_LKUP;
}

<INITIAL>{CPU}"rename.int_rename_operands" {
    BEGIN(DELIM);
    return RE_INT_OP;
}

<INITIAL>{CPU}"rename.fp_rename_lookups" {
    BEGIN(DELIM);
    return RE_FP_LKUP;
}

<INITIAL>{CPU}"rename.fp_rename_operands" {
    BEGIN(DELIM);
    return RE_FP_OP;
}

<INITIAL>{CPU}"iq.int_inst_queue_reads" {
    BEGIN(DELIM);
    return IQ_INT_R;
}

<INITIAL>{CPU}"iq.int_inst_queue_writes" {
    BEGIN(DELIM);
    return IQ_INT_W;
}

<INITIAL>{CPU}"iq.int_inst_queue_wakeup_accesses" {
    BEGIN(DELIM);
    return IQ_INT_WA;
}

<INITIAL>{CPU}"iq.fp_inst_queue_reads" {
    BEGIN(DELIM);
    return IQ_FP_QR;
}

<INITIAL>{CPU}"iq.fp_inst_queue_writes" {
    BEGIN(DELIM);
    return IQ_FP_QW;
}

<INITIAL>{CPU}"iq.fp_inst_queue_wakeup_accesses" {
    BEGIN(DELIM);
    return IQ_FP_QWA;
}

<INITIAL>{CPU}"int_regfile_reads" {
    BEGIN(DELIM);
    return INT_RG_R;
}

<INITIAL>{CPU}"int_regfile_writes" {
    BEGIN(DELIM);
    return INT_RG_W;
}

<INITIAL>{CPU}"fp_regfile_reads" {
    BEGIN(DELIM);
    return FP_RG_R;
}

<INITIAL>{CPU}"fp_regfile_writes" {
    BEGIN(DELIM);
    return FP_RG_W;
}

<INITIAL>{CPU}"commit.function_calls" {
    BEGIN(DELIM);
    return COMCALLS;
}

<INITIAL>{CPU}"iq.FU_type_0::IntDiv" {
    BEGIN(DELIM);
    return INTDIV;
}

<INITIAL>{CPU}"iq.FU_type_0::IntMult" {
    BEGIN(DELIM);
    return INTMULT;
}

<INITIAL>{CPU}"iq.int_alu_accesses" {
    BEGIN(DELIM);
    return INT_ALU_ACC;
}

<INITIAL>{CPU}"iq.fp_alu_accesses" {
    BEGIN(DELIM);
    return FP_ALU_ACC;
}

<INITIAL>"opClass=IntMult" {
    BEGIN(LATENCY);
    return MULTALU_LAT;
}

<INITIAL>"opClass=IntDiv" {
    BEGIN(LATENCY);
    return DIVALU_LAT;
}

<LATENCY>"opLat" {
    BEGIN(VALUE);
}

    /* BTB */
<INITIAL>{CPU}"branchPred.BTBLookups" {
    BEGIN(DELIM);
    return BTBLKUP;
}

<INITIAL>{CPU}"branchPred.BTBUpdates" {
    BEGIN(DELIM);
    return BTBUP;
}

    /* TLBs */
<INITIAL>{DTB}"replacements" {
    BEGIN(DELIM);
    return DTB_MISS;
}

<INITIAL>{DTB}"data_accesses" {
    BEGIN(DELIM);
    return DTB_ACC;
}

<INITIAL>{ITB}"replacements" {
    BEGIN(DELIM);
    return ITB_MISS;
}

<INITIAL>{ITB}"data_accesses" {
    BEGIN(DELIM);
    return ITB_ACC;
}

    /* L1 CACHES */
<INITIAL>{D1}"overall_accesses::total" {
    BEGIN(DELIM);
    return D1_ACC;
}

<INITIAL>{D1}"overall_misses::total" {
    BEGIN(DELIM);
    return D1_MISS;
}

<INITIAL>{D1}"WriteReq_accesses::total" {
    BEGIN(DELIM);
    return D1_WRACC;
}

<INITIAL>{D1}"writebacks::total" {
    BEGIN(DELIM);
    return D1_WRBACK;
}

<INITIAL>{D1}"WriteReq_misses::total" {
    BEGIN(DELIM);
    return D1_WRMISS;
}

<INITIAL>{D1}"WriteReq_hits::total" {
    BEGIN(DELIM);
    return D1_WRHITS;
}

    /* ICACHE */
<INITIAL>{I1}"overall_accesses::total" {
    BEGIN(DELIM);
    return I1_ACC;
}

<INITIAL>{I1}"overall_misses::total" {
    BEGIN(DELIM);
    return I1_MISS;
}

<INITIAL>{I1}"WriteReq_accesses::total" {
    BEGIN(DELIM);
    return I1_WRACC;
}

<INITIAL>{I1}"writebacks::total" {
    BEGIN(DELIM);
    return I1_WRBACK;
}

<INITIAL>{I1}"WriteReq_misses::total" {
    BEGIN(DELIM);
    return I1_WRMISS;
}

<INITIAL>{I1}"WriteReq_hits::total" {
    BEGIN(DELIM);
    return I1_WRHITS;
}

    /* L2 CACHE */
<INITIAL>{SL2}"overall_accesses::total" {
    BEGIN(DELIM);
    return L2_ACC;
}

<INITIAL>{SL2}"overall_misses::total" {
    BEGIN(DELIM);
    return L2_MISS;
}

<INITIAL>{SL2}"WriteReq_accesses::total" {
    BEGIN(DELIM);
    return L2_WRACC;
}

<INITIAL>{SL2}"WriteReq_misses::total" {
    BEGIN(DELIM);
    return L2_WRMISS;
}

<INITIAL>{SL2}"Writeback_accesses::total" {
    BEGIN(DELIM);
    return L2_WRBACK;
}

<INITIAL>{SL2}"Writeback_misses::total" {
    BEGIN(DELIM);
    return L2_WRBMISS;
}

   /* MAIN MEMORY */
<INITIAL>{SYS}"mem_ctrls.num_reads::total" {
    BEGIN(DELIM);
    return MM_NREADS;
}

<INITIAL>{SYS}"mem_ctrls.num_writes::total" {
    BEGIN(DELIM);
    return MM_NWRITES;
}


   /* OBTAINING VALUES DESIRED */

<VALUE>{eq} {
    return EQ;
}

<DELIM>{ws}+ {
    BEGIN(VALUE);
    return WS;
}

<VALUE>{letter}+ {
    yylval.t_str = strdup(yytext);
    if (PREV_STATE!=-1) {
       BEGIN(PREV_STATE);
       PREV_STATE = -1;
    } else {
       BEGIN(INITIAL);
    }
    return STR;
}

<VALUE>{digit}+ {
    yylval.t_int = atoi(yytext);
    if (PREV_STATE!=-1) {
       BEGIN(PREV_STATE);
       PREV_STATE = -1;
    } else {
       BEGIN(INITIAL);
    }
    return NUM;
}

<VALUE>{double} {
    yylval.t_double = atof(yytext);
    if (PREV_STATE!=-1) {
       BEGIN(PREV_STATE);
       PREV_STATE = -1;
    } else {
       BEGIN(INITIAL);
    }
    return FLOAT;
}

    /* WHEN NOTHING ELSE MATCHES */
<VALUE>{ignore}|{eq}|{ws}|"\n"|. {
    if (PREV_STATE!=-1) {
       BEGIN(PREV_STATE);
       PREV_STATE = -1;
    } else {
       BEGIN(INITIAL);
    }
    return BADTKN;
}

<*>{ignore}|{eq}|{ws}|"\n"|.           { /* DO NOTHING */ }
%%

/** Some comments:
 * PREV_STATE allows to return to the previous state. It is used when
 * a tag like [something] contains more than one parameter to catch
 **/
