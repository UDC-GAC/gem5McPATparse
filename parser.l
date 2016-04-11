%option yylineno noyywrap nodefault stack
%{
#include "parser.tab.h"

%}					
%x CLK
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
numROBEntries       "numROBEntries"n
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
%%

    /* BEGIN CONDITIONS */

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
    BEGIN(INITIAL);
    return STR;
}

<VALUE>{digit}+ {
    printf("value(%s)\n", yytext);
    yylval.t_int = atoi(yytext);
    BEGIN(INITIAL);
    return NUM;
}

    /* WHEN NOTHING ELSE MATCHES */
<*>{ignore}|{eq}|"\n"            { printf("ignore:(%s)\n", yytext); }
<*>.                                { printf("error: %s\n", yytext); }
%%
