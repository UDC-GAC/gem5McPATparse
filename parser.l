%option yylineno noyywrap
%{
#include "parser.tab.h"
%}

%x START
%x CLK
			
digit   	    [0-9]
letter              [a-zA-Z]
eq                  "="
ignore              [a-zA-Z0-9/_:[].]+			
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
%%
	BEGIN(START);

<START>"system.cpu_clk_domain" {
        /* printf("llego\n"); */
	BEGIN(CLK);
        return STR;
}

<CLK>"clock" {
        /* printf("SYS CLK\n"); */
        BEGIN(START);
        return SYSCLK;
}

<*>{digit}+            { /* printf("int:(%s)\n", yytext); */ yylval.t_int = atoi(yytext); return NUM; }
<*>{letter}+           { /* printf("letter:(%s)\n",yytext); */ yylval.t_str = strdup(yytext); return STR; }
<*>{eq}                { /* printf("eq:(%s)\n", yytext); */ return EQ; }
<*>{ignore}            { printf("ignore:(%s)\n", yytext); return IG; }
<*>"\n"                { /* printf("nl:(%s)\n", yytext); */ return NL; }
<*>.                   { /* printf(".:(%s)\n", yytext); */ }
%%
