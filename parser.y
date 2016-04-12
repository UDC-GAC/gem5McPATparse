%error-verbose
%{
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <math.h>
#include "lib/rapidxml.hpp"

using namespace rapidxml;
using namespace std;

#ifndef xml_temp
#define xml_temp "template.xml"
#endif

#ifndef MAX(X,Y)
#define MAX(X,Y) X>Y ? X : Y
#endif

#define MAX_NUM 1000

extern FILE *yyin;
extern int yylineno;

FILE *config_fptr, *stats_fptr;

struct t_mcpat_params {
    /* for x86 architectures */
    int isa_x86 = 0;
    /* core parameters */
    int clock_rate;
    int fetch_width;
    int decode_width;
    int issue_width;
    int peak_issue_width;
    int commit_width;
    int instruction_buffer_size;
    int instruction_window_size;
    int fp_instruction_window_size;
    int ROB_size;
    int phy_Regs_IRF_size;
    int phy_Regs_FRF_size;
    int store_buffer_size;
    int load_buffer_size;
    int RAS_size;
    /* to calculate base */
    int nbase = 0;
    int base_stages = 0;
    int nmax_base = 0;
    int max_base = 0;
    int pipeline_depth[2];
    /* branch predictor */
    int load_predictor[3] = {0};
    int global_predictor[2];
    int predictor_chooser[2];
    /* branch predictor buffer */
    int BTB_config;
    /* cache parameters: TLB and caches */
    int number_entries_dtlb;
    int number_entries_itlb;
    /* cache l1 */
    int dcache_config[7];
    int icache_config[7];
    int dcache_buffer_sizes[4];
    int icache_buffer_sizes[4];

    int dhit_lat;
    int dresp_lat;
    int ihit_lat;
    int iresp_lat;
    
    /* cache l2 */
    int L2_config[7];
    int L2_buffer_sizes[4];
    int l2_clockrate;
    
    int l2hit_lat;
    int l2resp_lat;

    /* ALUs latencies */
    int lat_IntDiv; //TODO
    int lat_IntMult; //TODO
};

struct t_mcpat_stats {
    /* core statistics */
    int total_instructions;
    int branch_instructions;
    int branch_mispredictions;
    int load_instructions;
    int store_instructions;
    int committed_int_instructions;
    int committed_fp_instructions;
    double pipeline_duty_cycle;
    int total_cycles;
    int idle_cycles;
    int busy_cycles;
    int ROB_reads;
    int ROB_writes;
    int rename_reads;
    int rename_writes;
    int fp_rename_reads;
    int fp_rename_writes;
    int inst_window_reads;
    int inst_window_writes;
    int inst_window_wakeup_accesses;

    int fp_inst_window_reads;
    int fp_inst_window_writes;
    int fp_inst_window_wakeup_accesses;
    int int_regfile_reads;
    int int_regfile_writes;
    int float_regfile_reads;
    int float_regfile_writes;
    int function_calls;
    /* formulas */
    int ialu_accesses;
    int fpu_accesses;
    int mul_accesses;
    int cdb_alu_accesses;
    int cdb_mul_accesses;
    int cdb_fpu_accesses;
    /* btb stats */
    int btb_read_accesses;
    int btb_write_accesses;
    /* tlb L1 */
    int dtlb_total_accesses;
    int dtlb_total_misses;
    int itlb_total_accesses;
    int itlb_total_misses;
    /* l1 cache */
    int l1_read_accesses;
    int l1_write_accesses;
    int l1_read_misses;
    int l1_write_misses;
    /* l2 cache */
    int l2_read_accesses;
    int l2_write_accesses;
    int l2_read_misses;
    int l2_write_misses;

    /* aux: default values */
    int IntDiv = 20; //todo
    int IntMult = 3; //todo
    int overall_access[3] = {0};
    int overall_misses[3] = {0};
    int WriteReq_access[3] = {0};
    int WriteReq_hits[2] = {0}; // i1/d1
    int WriteReq_misses[3] = {0};
    int Writeback_accesses[3] = {0};
    int Writeback_misses = 0; // l2
};

struct t_error {
    int n_stat;
    int err_stat[MAX_NUM];

    int n_config;
    int err_config[MAX_NUM];
};

struct t_mcpat_params *mcpat_param;
struct t_mcpat_stats *mcpat_stats;
struct t_error *error_list;

int yylex(void);
void yyerror(const char *s, ...);
void yyrestart(FILE *yyin);
%}
%union {
    int t_int;
    double t_double;
    char * t_str;
}
    /* TOKENS PARAMS */			
%token EQ WS
%token X86 SYSCLK			
%token FETCHW DECODEW ISSUEW COMMITW BASE MAXBASE BUFFERS NIQENTRIES NROBENTRIES NINTREGS NFREGS SQENTRIES LQENTRIES RASSIZE
%token LHISTB LCTRB LPREDSIZE GPREDSIZE GCTRB CPREDSIZE	CCTRB
%token BTBE
%token TLBD TLBI
%token IL1SIZE IL1ASSOC I1MSHRS HLIL1 RLIL1 IL1BSIZE
%token DL1SIZE DL1ASSOC D1MSHRS HLDL1 RLDL1 WBDL1 DL1BSIZE
%token L2SIZE L2ASSOC L2MSHRS HLL2 RLL2 WBL2 L2BSIZE
    /* TOKENS STATS */
%token DECODINSTS BRANCHPRED BRANCHERR IEWLOAD IEWSTORE	CINT CFP IPC NCYCLES ICYCLES ROBREADS ROBWRITES	RE_INT_LKUP RE_INT_OP RE_FP_LKUP RE_FP_OP IQ_INT_R IQ_INT_W IQ_INT_WA IQ_FP_QR IQ_FP_QW IQ_FP_QWA INT_RG_R INT_RG_W FP_RG_R FP_RG_W COMCALLS INTDIV INTMULT INT_ALU_ACC FP_ALU_ACC
%token BTBLKUP BTBUP
%token DTB_MISS DTB_ACC	ITB_MISS ITB_ACC
%token D1_ACC D1_MISS D1_WRACC D1_WRBACK D1_WRMISS D1_WRHITS
%token I1_ACC I1_MISS I1_WRACC I1_WRBACK I1_WRMISS I1_WRHITS
%token L2_ACC L2_MISS L2_WRACC L2_WRMISS L2_WRBACK L2_WRBMISS	     				
%token	<t_int> NUM
%token	<t_double> FLOAT
// tokens types etc
%start S 			
%%
// rules
S : line { printf("finished parsing!\n\n"); }
  ;

/* left recursion better than right recursion: due to stack reasons */
line : /* empty */ 
	|	line config
	|	line stats
;

config:
                X86 { mcpat_param->isa_x86 = 1; }       
        |	SYSCLK EQ NUM { printf("clk=%d\n",$3); mcpat_param->clock_rate = $3; }
	|	FETCHW EQ NUM { printf("FW=%d\n",$3); mcpat_param->fetch_width = $3; }
	|	DECODEW EQ NUM { printf("FW=%d\n",$3); mcpat_param->decode_width = $3; mcpat_param->issue_width = $3; }
        |	ISSUEW EQ NUM { printf("IW=%d\n", $3); mcpat_param->peak_issue_width = $3; }
        |	COMMITW EQ NUM { printf("CW=%d\n", $3); mcpat_param->commit_width = $3; }
        |	BASE EQ NUM { printf("BASE=%d\n", $3); mcpat_param->base_stages += $3; mcpat_param->nbase++; }
	|	MAXBASE EQ NUM { printf("maxBASE=%d\n", $3); mcpat_param->max_base = MAX(mcpat_param->max_base, $3); mcpat_param->nmax_base++; }
        |	BUFFERS EQ NUM { printf("BUFFERSIZE=%d\n", $3); mcpat_param->instruction_buffer_size = $3; }
	|	NIQENTRIES EQ NUM { printf("NIQENTRIES=%d\n", $3); if ($3 % 2==0){ mcpat_param->instruction_window_size = $3/2; mcpat_param->fp_instruction_window_size = $3/2; } else { yyerror("numIQEntries must be odd\n"); } }
        |	NROBENTRIES EQ NUM { printf("NROBENTRIES=%d\n", $3); mcpat_param->ROB_size = $3;  }
        |	NINTREGS EQ NUM { printf("NINTREGS=%d\n", $3); mcpat_param->phy_Regs_IRF_size = $3;  }
        |	NFREGS EQ NUM { printf("NFREGS=%d\n", $3); mcpat_param->phy_Regs_FRF_size = $3; }
        |	SQENTRIES EQ NUM { printf("SQENTRIES=%d\n", $3); mcpat_param->store_buffer_size = $3;  }	
        |	LQENTRIES EQ NUM { printf("IQENTRIES=%d\n", $3); mcpat_param->load_buffer_size = $3; }
        |	RASSIZE EQ NUM { printf("RASSIZE=%d\n", $3); mcpat_param->RAS_size = $3; }
        |	LHISTB EQ NUM { printf("LHISTB=%d\n", $3); mcpat_param->load_predictor[0] = $3; }
        |	LCTRB EQ NUM { printf("LCTRB=%d\n", $3); mcpat_param->load_predictor[1] = $3; }
|	LPREDSIZE EQ NUM { printf("LPREDSIZE=%d\n", $3); mcpat_param->load_predictor[2] = $3; if (mcpat_param->load_predictor[0]==0) {mcpat_param->load_predictor[0] = (int) floor(log2((double) $3)); } }
        |	GPREDSIZE EQ NUM { printf("GPREDSIZE=%d\n", $3); mcpat_param->global_predictor[0] = $3; }
        |	GCTRB EQ NUM { printf("GCTRB=%d\n", $3); mcpat_param->global_predictor[1] = $3; }
        |	CPREDSIZE EQ NUM { printf("CPREDSIZE=%d\n", $3); mcpat_param->predictor_chooser[0] = $3; }
        |	CCTRB EQ NUM { printf("CCTRB=%d\n", $3); mcpat_param->predictor_chooser[1] = $3; }
        |	BTBE EQ NUM { printf("BTBE=%d\n", $3); mcpat_param->BTB_config = $3; }
        |	TLBD EQ NUM { printf("TLBD=%d\n", $3); mcpat_param->number_entries_dtlb = $3; }
	|	TLBI EQ NUM { printf("TLBI=%d\n", $3); mcpat_param->number_entries_itlb = $3; }
	|	DL1SIZE EQ NUM { printf("DL1SIZE=%d\n", $3); mcpat_param->dcache_config[0] = $3; }
	|	DL1BSIZE EQ NUM { printf("DL1BSIZE=%d\n", $3); mcpat_param->dcache_config[1] = $3; }		
	|	DL1ASSOC EQ NUM { printf("DL1ASSOC=%d\n", $3); mcpat_param->dcache_config[2] = $3; mcpat_param->dcache_config[3] = 1; mcpat_param->dcache_config[5] = 32; mcpat_param->dcache_config[6] = 1;}
	|	D1MSHRS EQ NUM { printf("D1MSHRS=%d\n", $3); mcpat_param->dcache_buffer_sizes[0] = $3; mcpat_param->dcache_buffer_sizes[1] = $3; mcpat_param->dcache_buffer_sizes[2] = $3; }
	|	WBDL1 EQ NUM { printf("WBDL1=%d\n", $3); mcpat_param->icache_buffer_sizes[3] = $3; }
	|	HLDL1 EQ NUM { printf("HLDL1=%d\n", $3); mcpat_param->dhit_lat = $3; }		
	|	RLDL1 EQ NUM { printf("RLDL1=%d\n", $3); mcpat_param->dresp_lat = $3; }		
	|	IL1SIZE EQ NUM { printf("IL1SIZE=%d\n", $3); mcpat_param->icache_config[0] = $3; }
	|	IL1BSIZE EQ NUM { printf("IL1BSIZE=%d\n", $3); mcpat_param->icache_config[1] = $3; }		
	|	IL1ASSOC EQ NUM { printf("IL1ASSOC=%d\n", $3); mcpat_param->icache_config[2] = $3; mcpat_param->icache_config[3] = 1; mcpat_param->icache_config[5] = 32; mcpat_param->icache_config[6] = 1;}
	|	I1MSHRS EQ NUM { printf("I1MSHRS=%d\n", $3); mcpat_param->icache_buffer_sizes[0] = $3; mcpat_param->icache_buffer_sizes[1] = $3; mcpat_param->icache_buffer_sizes[2] = $3; mcpat_param->icache_buffer_sizes[3] = 0;}
	|	HLIL1 EQ NUM { printf("HLIL1=%d\n", $3); mcpat_param->ihit_lat = $3; }		
	|	RLIL1 EQ NUM { printf("RLIL1=%d\n", $3); mcpat_param->iresp_lat = $3; }	
	|	L2SIZE EQ NUM { printf("L2SIZE=%d\n", $3); mcpat_param->L2_config[0] = $3; }
	|	L2BSIZE EQ NUM { printf("L2BSIZE=%d\n", $3); mcpat_param->L2_config[1] = $3; }		
	|	L2ASSOC EQ NUM { printf("L2ASSOC=%d\n", $3); mcpat_param->L2_config[2] = $3; mcpat_param->L2_config[3] = 1; mcpat_param->L2_config[5] = 32; mcpat_param->L2_config[6] = 1;}
	|	L2MSHRS EQ NUM { printf("L2MSHRS=%d\n", $3); mcpat_param->L2_buffer_sizes[0] = $3; mcpat_param->L2_buffer_sizes[1] = $3; mcpat_param->L2_buffer_sizes[2] = $3; }
	|	WBL2 EQ NUM { printf("WBL2=%d\n", $3); mcpat_param->L2_buffer_sizes[3] = $3; }
	|	HLL2 EQ NUM { printf("HLL2=%d\n", $3); mcpat_param->l2hit_lat = $3; }		
	|	RLL2 EQ NUM { printf("RLL2=%d\n", $3); mcpat_param->l2resp_lat = $3; }		
	|	error { printf("error you\n"); }
		
stats:		DECODINSTS WS NUM { printf("DECODED INSTRUCTIONS: %d\n",$3); mcpat_stats->total_instructions = $3; }
	|	BRANCHPRED WS NUM { printf("BRANCH: %d\n",$3); mcpat_stats->branch_instructions = $3; }
	|	BRANCHERR WS NUM { printf("BRANCHERR: %d\n",$3); mcpat_stats->branch_mispredictions = $3; }
	|	IEWLOAD WS NUM { printf("IEWLOAD: %d\n",$3); mcpat_stats->load_instructions = $3; }
	|	IEWSTORE WS NUM { printf("IEWSTORE: %d\n",$3); mcpat_stats->store_instructions = $3; }
	|	CINT WS NUM { printf("CINT: %d\n",$3); mcpat_stats->committed_int_instructions = $3; }
	|	CFP WS NUM { printf("CFP: %d\n",$3); mcpat_stats->committed_fp_instructions = $3; }
	|	IPC WS FLOAT { printf("IPC: %f\n",$3); mcpat_stats->pipeline_duty_cycle = $3; }
	|	NCYCLES WS NUM { printf("NCYCLES: %d\n",$3); mcpat_stats->total_cycles = $3; }
	|	ICYCLES WS NUM { printf("ICYCLES: %d\n",$3); mcpat_stats->idle_cycles = $3; }
	|	ROBREADS WS NUM { printf("ROBREADS: %d\n",$3); mcpat_stats->ROB_reads = $3; }			       
	|	ROBWRITES WS NUM { printf("ROBWRITES: %d\n",$3); mcpat_stats->ROB_writes = $3; }
	|	RE_INT_LKUP WS NUM { printf("RE_INT_LKUP: %d\n",$3); mcpat_stats->rename_reads = $3; }
	|	RE_INT_OP WS NUM { printf("RE_INT_OP: %d\n",$3); mcpat_stats->rename_writes = $3; }
	|	RE_FP_LKUP WS NUM { printf("RE_FP_LKUP: %d\n",$3); mcpat_stats->fp_rename_reads = $3; }
	|	RE_FP_OP WS NUM { printf("RE_FP_OP: %d\n",$3); mcpat_stats->fp_rename_writes = $3; }
	|	IQ_INT_R WS NUM { printf("IQ_INT_R: %d\n",$3); mcpat_stats->inst_window_reads = $3; }
	|	IQ_INT_W WS NUM { printf("IQ_INT_W: %d\n",$3); mcpat_stats->inst_window_writes = $3; }
	|	IQ_INT_WA WS NUM { printf("IQ_INT_WA: %d\n",$3); mcpat_stats->inst_window_wakeup_accesses = $3; }				|	IQ_FP_QR WS NUM { printf("IQ_FP_QR: %d\n",$3); mcpat_stats->fp_inst_window_reads = $3; }
	|	IQ_FP_QW WS NUM { printf("IQ_FP_QW: %d\n",$3); mcpat_stats->fp_inst_window_writes = $3; }
	|	IQ_FP_QWA WS NUM { printf("IQ_FP_QWA: %d\n",$3); mcpat_stats->fp_inst_window_wakeup_accesses = $3; }
	|	INT_RG_R WS NUM { printf("INT_RG_R: %d\n",$3); mcpat_stats->int_regfile_reads = $3; }
        |	INT_RG_W WS NUM { printf("INT_RG_W: %d\n",$3); mcpat_stats->int_regfile_writes = $3; }
	|	FP_RG_R WS NUM { printf("FP_RG_R: %d\n",$3); mcpat_stats->float_regfile_reads = $3; }
	|	FP_RG_W WS NUM { printf("FP_RG_W: %d\n",$3); mcpat_stats->float_regfile_writes = $3; }
	|	COMCALLS WS NUM { printf("COMCALLS: %d\n",$3); mcpat_stats->function_calls = $3; }
	|	INTDIV WS NUM { printf("INTDIV: %d\n",$3); mcpat_stats->IntDiv *= $3; }
        |	INTMULT WS NUM { printf("INTMULT: %d\n",$3); mcpat_stats->IntMult *= $3; }
	|	INT_ALU_ACC WS NUM { printf("INT_ALU_ACC: %d\n",$3); mcpat_stats->ialu_accesses = $3; }
	|	FP_ALU_ACC WS NUM { printf("FP_ALU_ACC: %d\n",$3); mcpat_stats->fpu_accesses = $3; mcpat_stats->cdb_fpu_accesses = $3; }       |	BTBLKUP WS NUM { printf("BTBLKUP: %d\n",$3); mcpat_stats->btb_read_accesses = $3; }
	|	BTBUP WS NUM { printf("BTBUP: %d\n",$3); mcpat_stats->btb_write_accesses = $3; }
	|	DTB_MISS WS NUM { printf("DTB_MISS: %d\n",$3); mcpat_stats->dtlb_total_misses = $3; }
	|	DTB_ACC WS NUM { printf("DTB_ACC: %d\n",$3); mcpat_stats->dtlb_total_accesses = $3; }
	|	ITB_MISS WS NUM { printf("ITB_MISS: %d\n",$3); mcpat_stats->itlb_total_misses = $3; }
	|	ITB_ACC WS NUM { printf("ITB_ACC: %d\n",$3); mcpat_stats->itlb_total_accesses = $3; }
	|	D1_ACC WS NUM { printf("D1_ACC: %d\n",$3); mcpat_stats->overall_access[0] = $3; }
	|	D1_MISS WS NUM { printf("D1_MISS: %d\n",$3); mcpat_stats->overall_misses[0] = $3; }
	|	D1_WRACC WS NUM { printf("D1_WRACC: %d\n",$3); mcpat_stats->WriteReq_access[0] = $3; }
	|	D1_WRMISS WS NUM { printf("D1_WRMISS: %d\n",$3); mcpat_stats->WriteReq_misses[0] = $3; }
	|	D1_WRHITS WS NUM { printf("D1_WRHITS: %d\n",$3); mcpat_stats->WriteReq_hits[0] = $3; }
	|	D1_WRBACK WS NUM { printf("D1_WRBACK: %d\n",$3); mcpat_stats->Writeback_accesses[0] = $3; }
	|	I1_ACC WS NUM { printf("I1_ACC: %d\n",$3); mcpat_stats->overall_access[1] = $3; }
	|	I1_MISS WS NUM { printf("I1_MISS: %d\n",$3); mcpat_stats->overall_misses[1] = $3; }
	|	I1_WRACC WS NUM { printf("I1_WRACC: %d\n",$3); mcpat_stats->WriteReq_access[1] = $3; }
	|	I1_WRMISS WS NUM { printf("I1_WRMISS: %d\n",$3); mcpat_stats->WriteReq_misses[1] = $3; }
	|	I1_WRHITS WS NUM { printf("I1_WRHITS: %d\n",$3); mcpat_stats->WriteReq_hits[1] = $3; }
	|	I1_WRBACK WS NUM { printf("I1_WRBACK: %d\n",$3); mcpat_stats->Writeback_accesses[1] = $3; }
	|	L2_ACC WS NUM { printf("L2_ACC: %d\n",$3); mcpat_stats->overall_access[2] = $3; }
	|	L2_MISS WS NUM { printf("L2_MISS: %d\n",$3); mcpat_stats->overall_misses[2] = $3; }
	|	L2_WRACC WS NUM { printf("L2_WRACC: %d\n",$3); mcpat_stats->WriteReq_access[2] = $3; }
	|	L2_WRMISS WS NUM { printf("L2_WRMISS: %d\n",$3); mcpat_stats->WriteReq_misses[2] = $3; }
	|	L2_WRBACK WS NUM { printf("L2_WRBACK: %d\n",$3); mcpat_stats->Writeback_accesses[2] = $3; }
	|	L2_WRBMISS WS NUM { printf("L2_WRBMISS: %d\n",$3); mcpat_stats->Writeback_misses = $3; }		
	;

%%
// example code for RapidXML API

void xmlParser()
{
    /* cout << "Parsing my beer journal..." << endl; */
    /* xml_document<> doc; */
    /* xml_node<> * root_node; */
    /* // Read the xml file into a vector */
    /* ifstream theFile ("beerJournal.xml"); */
    /* vector<char> buffer((istreambuf_iterator<char>(theFile)), istreambuf_iterator<char>()); */
    /* buffer.push_back('\0'); */
    /* // Parse the buffer using the xml file parsing library into doc  */
    /* doc.parse<0>(&buffer[0]); */
    /* // Find our root node */
    /* root_node = doc.first_node("MyBeerJournal"); */
    /* // Iterate over the brewerys */
    /* for (xml_node<> * brewery_node = root_node->first_node("Brewery"); brewery_node; brewery_node = brewery_node->next_sibling()) */
    /* 	{ */
    /* 	    printf("I have visited %s in %s. ",  */
    /* 		   brewery_node->first_attribute("name")->value(), */
    /* 		   brewery_node->first_attribute("location")->value()); */
    /*         // Interate over the beers */
    /* 	    for(xml_node<> * beer_node = brewery_node->first_node("Beer"); beer_node; beer_node = beer_node->next_sibling()) */
    /* 		{ */
    /* 		    printf("On %s, I tried their %s which is a %s. ",  */
    /* 			   beer_node->first_attribute("dateSampled")->value(), */
    /* 			   beer_node->first_attribute("name")->value(),  */
    /* 			   beer_node->first_attribute("description")->value()); */
    /* 		    printf("I gave it the following review: %s", beer_node->value()); */
    /* 		} */
    /* 	    cout << endl; */
    /* 	} */
}

static struct option long_options[] = {
	{ .name = "xmltemplate",
	  .has_arg = required_argument,
	  .flag = NULL,
	  .val = 0},
	{ .name = "config",
	  .has_arg = required_argument,
	  .flag = NULL,
	  .val = 0},
	{ .name = "stats",
	  .has_arg = required_argument,
	  .flag = NULL,
	  .val = 0},
	{ .name = "output",
	  .has_arg = required_argument,
	  .flag = NULL,
	  .val = 0},
	{0, 0, 0, 0}
};

static void usage(int i)
{
	printf(
		"Usage:  gem5ToMcPAT [OPTIONS]\n"
		"Launch parser gem5ToMcPAT\n"
		"Options:\n"
		"  -x <file>, --xmltemplate=<file>: XML template\n"
		"  -c <file>, --config=<file>: config.ini file (not JSON!)\n"
		"  -s <file>, --stats=<file>: statistics file\n"
		"  -o <file>, --output=<output>: XML output\n"
		"  -h, --help: displays this message\n\n"
	);
	exit(i);
}

static int check_file(char *arg, FILE **f)
{
    *f = fopen(arg, "r");
    
    return (*f!=NULL);
}

static void handle_long_options(struct option option, char *arg)
{
	if (!strcmp(option.name, "help"))
		usage(0);

	if (!strcmp(option.name, "config")) {
	        if (!check_file(arg, &config_fptr)) {
			printf("'%s': invalid file\n", arg);
			fclose(config_fptr);
			usage(-3);
		}
	}
	if (!strcmp(option.name, "stats")) {
	        if (!check_file(arg, &stats_fptr)) {
			printf("'%s': invalid file\n", arg);
			fclose(stats_fptr);
			usage(-3);
		}
	}
}

static int handle_options(int argc, char **argv)
{
	while (1) {
		int c;
		int option_index = 0;

		c = getopt_long (argc, argv, "x:c:s:o:",
				 long_options, &option_index);
		if (c == -1)
			break;

		switch (c) {
		case 0:
			handle_long_options(long_options[option_index],
				optarg);
			break;

		case 'c':
                        if (!check_file(optarg, &config_fptr)) {
				printf("'%s': invalid file\n", optarg);
				fclose(config_fptr);
				usage(-3);
			}
			break;

		case 's':
         		if (!check_file(optarg, &stats_fptr)) {
				printf("'%s': invalid file\n", optarg);
				fclose(stats_fptr);
				usage(-3);
			}
		break;
		case 'x':
	        case 'o': break;
		case '?':
		case 'h':
			usage(0);
			break;

		default:
			printf ("?? getopt returned character code 0%o ??\n", c);
			usage(-1);
		}
	}
	return 0;
}

void init_structs()
{
    mcpat_param = (struct t_mcpat_params *) malloc(sizeof(struct t_mcpat_params));
    mcpat_stats = (struct t_mcpat_stats *) malloc(sizeof(struct t_mcpat_stats));

    error_list = (struct t_error *) malloc(sizeof(struct t_error));
}

void display_errors()
{

}

/////////////////////////////////
// main function		      
int main(int argc, char *argv[])
{
    // check options
    int result = handle_options(argc, argv);
    
    if (result != 0)
	exit(result);
    
    if (argc - optind != 0) {
	printf ("Extra arguments\n\n");
	while (optind < argc)
	    printf ("'%s' ", argv[optind++]);
	printf ("\n");
	usage(-2);
    }

    init_structs();
    
    // parse config.ini
    yyin = config_fptr;
    yyparse();
    fclose(yyin);
    
    // to clean yyin
    yyrestart(yyin);
    yyin = stats_fptr;
    yyparse();
    fclose(yyin);

    //check_stats();
    
    // fill template.xml
    //fill_xml();

    // display_errors();
    
    exit(0);
}

/* function to report errors */
void yyerror(const char *s, ...)
{
    printf("%d: error: %s\n", yylineno, s);
}
