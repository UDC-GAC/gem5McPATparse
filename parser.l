%option yylineno noyywrap nodefault stack
%{
#include "parser.tab.h"

int PREV_STATE = -1;

%}					
%x CLK
%x ISA

%x DTLB
%x ITLB

%x DL1
%x DL1TAGS
%x IL1
%x IL1TAGS

%x L2
%x L2TAGS

%x VALUE
						
digit   	    [0-9]
letter              [a-zA-Z]
eq                  "="
ignore              [a-zA-Z0-9 \-\/\[\]\.\_\:]+					
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
%%

    /* CLOCK */
<INITIAL>"[system.clk_domain]\n" {
        printf("clk domain:(%s)\n", yytext);
	BEGIN(CLK);
}

<CLK>"clock" {
        printf("SYS CLK\n");
        BEGIN(VALUE);
        return SYSCLK;
}

    /* ISA type */

<INITIAL>"[system.cpu.isa]\n" {
        printf("type found\n");
        BEGIN(ISA);
}

<ISA>"type=X86ISA" {
        BEGIN(INITIAL);
        return X86;
}

    /* core parameters */
    /* FETCHWIDTH */
<INITIAL>{fetchWidth} {
        printf("FETCH WIDTH\n");
        BEGIN(VALUE);
        return FETCHW;        
}

    /* DECODEWIDTH */
<INITIAL>{decodeWidth} {
        printf("DECODE WIDTH\n");
        BEGIN(VALUE);
        return DECODEW;        
}

    /* ISSUEWIDTH */
<INITIAL>{issueWidth} {
        printf("ISSUE WIDTH\n");
        BEGIN(VALUE);
        return ISSUEW;        
}

    /* COMMITWIDTH */
<INITIAL>{commitWidth} {
        printf("COMMIT WIDTH\n");
        BEGIN(VALUE);
        return COMMITW;        
}

    /* fetchBufferSize */
<INITIAL>{fetchBufferSize} {
        printf("fetch buffer size\n");
        BEGIN(VALUE);
        return BUFFERS;        
}

    /* numIQEntries */
<INITIAL>{numIQEntries} {
        printf("numIQEntries\n");
        BEGIN(VALUE);
        return NIQENTRIES;        
}

    /* numROBEntries */
<INITIAL>{numROBEntries} {
        printf("NUMROBENTRIES\n");
        BEGIN(VALUE);
        return NROBENTRIES;        
}

    /* numPhysIntRegs */
<INITIAL>{numPhysIntRegs} {
        printf("numPhysIntRegs\n");
        BEGIN(VALUE);
        return NINTREGS;        
}

    /* numPhysFloatRegs */
<INITIAL>{numPhysFloatRegs} {
        printf("numPhysFloatRegs\n");
        BEGIN(VALUE);
        return NFREGS;        
}

    /* SQEntries */
<INITIAL>{SQEntries} {
        printf("SQEntries\n");
        BEGIN(VALUE);
        return SQENTRIES;        
}
    /* LQEntries */
<INITIAL>{LQEntries} {
        printf("LQEntries\n");
        BEGIN(VALUE);
        return LQENTRIES;        
}
    /* RASSize */
<INITIAL>{RASSize} {
        printf("RASSIZE\n");
        BEGIN(VALUE);
        return RASSIZE;        
}

    /* BRANCH PREDICTOR */
<INITIAL>{lHistBits} {
        printf("lHistBits\n");
        BEGIN(VALUE);
        return LHISTB;       
}

<INITIAL>{lCtrBits} {
        printf("lCtrBits\n");
        BEGIN(VALUE);
        return LCTRB;       
}

<INITIAL>{lPredictorSize} {
        printf("lPredictorSize\n");
        BEGIN(VALUE);
        return LPREDSIZE;       
}

<INITIAL>{gPredictorSize} {
        printf("gPredictorSize\n");
        BEGIN(VALUE);
        return GPREDSIZE;       
}

<INITIAL>{gCtrBits} {
        printf("gCtrBits\n");
        BEGIN(VALUE);
        return GCTRB;       
}

<INITIAL>{cPredictorSize} {
        printf("cPredictorSize\n");
        BEGIN(VALUE);
        return CPREDSIZE;       
}

<INITIAL>{cCtrBits} {
        printf("cCtrBits\n");
        BEGIN(VALUE);
        return CCTRB;       
}

    /* BRANCH PREDICTOR BUFFER */

<INITIAL>{BTBEntries} {
        printf("BTBEntries\n");
        BEGIN(VALUE);
        return BTBE;       
}

    /* CACHE PARAMETERS */
    /* tlb */

<INITIAL>"[system.cpu.dtb]" {
        printf("BEGIN TLB\n");
        BEGIN(DTLB);
}

<INITIAL>"[system.cpu.itb]" {
        printf("BEGIN TLB\n");
        BEGIN(ITLB);
}

<DTLB>"size" {
        printf("size Dtlb\n");
        BEGIN(VALUE);
        return TLBD;       
}

<ITLB>"size" {
        printf("size Itlb\n");
        BEGIN(VALUE);
        return TLBI;       
}

    /* DATA CACHE L1 */
<INITIAL>"[system.cpu.dcache]" {
        BEGIN(DL1);
}

<DL1>"size" {
        printf("size DL1\n");
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return DL1SIZE;
}

<DL1>"assoc" {
        printf("size DL1\n");
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return DL1ASSOC;
}

<DL1>"mshrs" {
        printf("mshrs\n");
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return D1MSHRS;
}

<DL1>"hit_latency" {
        printf("response_latency\n");
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return HLDL1;
}

<DL1>"response_latency" {
        printf("response_latency\n");
        PREV_STATE = DL1;
        BEGIN(VALUE);
        return RLDL1;
}

<DL1>"write_buffers" {
        printf("size DL1\n");
        BEGIN(VALUE);
        return WBDL1;
}

<INITIAL>"[system.cpu.dcache.tags]" {
        BEGIN(DL1TAGS);
}

<DL1TAGS>"block_size" {
        printf("\n");
        BEGIN(VALUE);
        return DL1BSIZE;
}

    /* INST CACHE L1 */
<INITIAL>"[system.cpu.icache]" {
        BEGIN(IL1);
}

<IL1>"size" {
        printf("size IL1\n");
        BEGIN(VALUE);
        return IL1SIZE;
}

<IL1>"assoc" {
        printf("size IL1\n");
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return IL1ASSOC;
}

<IL1>"mshrs" {
        printf("mshrs\n");
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return I1MSHRS;
}

<IL1>"hit_latency" {
        printf("response_latency\n");
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return HLIL1;
}

<IL1>"response_latency" {
        printf("response_latency\n");
        PREV_STATE = IL1;
        BEGIN(VALUE);
        return RLIL1;
}

<INITIAL>"[system.cpu.icache.tags]" {
        BEGIN(IL1TAGS);
}

<IL1TAGS>"block_size" {
        printf("block size\n");
        BEGIN(VALUE);
        return IL1BSIZE;
}

    /* CACHE L2 */

<INITIAL>"[system.l2]" {
        BEGIN(L2);
}

<L2>"size" {
        printf("size L2\n");
        PREV_STATE = L2;
        BEGIN(VALUE);
        return L2SIZE;
}

<L2>"assoc" {
        printf("size L2\n");
        PREV_STATE = L2;
        BEGIN(VALUE);
        return L2ASSOC;
}

<L2>"mshrs" {
        printf("mshrs\n");
        PREV_STATE = L2;
        BEGIN(VALUE);
        return L2MSHRS;
}

<L2>"hit_latency" {
        printf("response_latency\n");
        PREV_STATE = L2;
        BEGIN(VALUE);
        return HLL2;
}

<L2>"response_latency" {
        printf("response_latency\n");
        PREV_STATE = L2;
        BEGIN(VALUE);
        return RLL2;
}

<L2>"write_buffers" {
        printf("size DL2\n");
        BEGIN(VALUE);
        return WBL2;
}

<INITIAL>"[system.l2.tags]" {
        BEGIN(L2TAGS);
}

<L2TAGS>"block_size" {
        printf("block size\n");
        BEGIN(VALUE);
        return L2BSIZE;
}

    /* CALCULATING BASE PARAMETERS (SEE APPENDIX A) */

<INITIAL>{f2DecodeDelay} {
        printf("f2DecodeDelay\n");
        BEGIN(VALUE);
        return BASE;        
}

<INITIAL>{d2RenameDelay} {
        printf("d2RenameDelay\n");
        BEGIN(VALUE);
        return BASE;        
}

<INITIAL>{r2IEWDelay} {
        printf("r2IEWDelay\n");
        BEGIN(VALUE);
        return BASE;
}

<INITIAL>{i2CommitDelay} {
        printf("i2CommitDelay\n");
        BEGIN(VALUE);
        return BASE;       
}

<INITIAL>{c2DecodeDelay} {
        printf("c2DecodeDelay\n");
        BEGIN(VALUE);
        return MAXBASE;       
}

<INITIAL>{c2FetchDelay} {
        printf("c2FetchDelay\n");
        BEGIN(VALUE);
        return MAXBASE;       
}

<INITIAL>{c2IEWDelay} {
        printf("c2IEWDelay\n");
        BEGIN(VALUE);
        return MAXBASE;       
}

<INITIAL>{c2RenameDelay} {
        printf("c2RenameDelay\n");
        BEGIN(VALUE);
        return MAXBASE;       
}

    /* OBTAINING VALUES DESIRED */

<VALUE>{eq} {
        printf("eq:(%s)\n", yytext);
        return EQ;
}

<VALUE>{letter}+ {
    printf("value(%s)\n",yytext);
    yylval.t_str = yytext;
    if (PREV_STATE!=-1) {
       BEGIN(PREV_STATE);
       PREV_STATE = -1;
    } else {
       BEGIN(INITIAL);
    }
    return STR;
}

<VALUE>{digit}+ {
    printf("value(%s)\n", yytext);
    yylval.t_int = atoi(yytext);
    if (PREV_STATE!=-1) {
       BEGIN(PREV_STATE);
       PREV_STATE = -1;
    } else {
       BEGIN(INITIAL);
    }
    return NUM;
}

    /* WHEN NOTHING ELSE MATCHES */
<*>{ignore}|{eq}|"\n"            { printf("ignore:(%s)\n", yytext); }
<*>.                                { printf("error: %s\n", yytext); }
%%

/** Some comments:
 * PREV_STATE allows to return to the previous state
 **/
