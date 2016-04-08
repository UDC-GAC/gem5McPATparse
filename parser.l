%option yylineno noyywrap
%{
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

%}
digit   	    [0-9]
letter              [a-zA-Z]
eq                  "="
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
{digit}+            { yylval.t_int = atoi(yytext); return NUM; }
{letter}+           { yylval.t_str = strdup(yytext); return STR; }
{eq}                { return EQ; }
%%
