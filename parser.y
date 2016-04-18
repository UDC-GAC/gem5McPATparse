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
#include "isa.h"
#include "lib/copy.h"
#include "lib/rapidxml.hpp"

using namespace rapidxml;
using namespace std;

#ifndef VERSION
#define VERSION "0.0.9"
#endif

#ifndef xml_temp
#define xml_temp "template.xml"
#endif

#ifndef MAX(X,Y)
#define MAX(X,Y) X>Y ? X : Y
#endif

#define MAX_NUM 1000
#define MAX_LINE 1000

int ERROR = 0;

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
    int pipeline_depth[2] = {INT_EXE, FP_EXE};
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
    int lat_IntDiv = 20; //TODO
    int lat_IntMult = 3; //TODO
};

struct t_mcpat_stats {
    /* core statistics */
    int total_instructions = 0;
    int branch_instructions = 0;
    int branch_mispredictions = 0;
    int load_instructions = 0;
    int store_instructions = 0;
    int committed_int_instructions = 0;
    int committed_fp_instructions = 0;
    double pipeline_duty_cycle = 0.0;
    int total_cycles = 0;
    int idle_cycles = 0;
    int busy_cycles = 0;
    int ROB_reads = 0;
    int ROB_writes = 0;
    int rename_reads = 0;
    int rename_writes = 0;
    int fp_rename_reads = 0;
    int fp_rename_writes = 0;
    int inst_window_reads = 0;
    int inst_window_writes = 0;
    int inst_window_wakeup_accesses = 0;

    int fp_inst_window_reads = 0;
    int fp_inst_window_writes = 0;
    int fp_inst_window_wakeup_accesses = 0;
    int int_regfile_reads = 0;
    int int_regfile_writes = 0;
    int float_regfile_reads = 0;
    int float_regfile_writes = 0;
    int function_calls = 0;
    /* formulas */
    int ialu_accesses = 0;
    int fpu_accesses = 0;
    int mul_accesses = 0;
    int cdb_alu_accesses = 0;
    int cdb_mul_accesses = 0;
    int cdb_fpu_accesses = 0;
    /* btb stats */
    int btb_read_accesses = 0;
    int btb_write_accesses = 0;
    /* tlb L1 */
    int dtlb_total_accesses = 0;
    int dtlb_total_misses = 0;
    int itlb_total_accesses = 0;
    int itlb_total_misses = 0;
    /* l1 cache */
    int l1_read_accesses = 0;
    int l1_write_accesses = 0;
    int l1_read_misses = 0;
    int l1_write_misses = 0;
    /* l2 cache */
    int l2_read_accesses = 0;
    int l2_write_accesses = 0;
    int l2_read_misses = 0;
    int l2_write_misses = 0;

    /* aux: default values */
    int IntDiv = 0; //todo
    int IntMult = 0; //todo
    int overall_access[3] = {0};
    int overall_misses[3] = {0};
    int WriteReq_access[3] = {0};
    int WriteReq_hits[2] = {0}; // i1/d1
    int WriteReq_misses[3] = {0};
    int Writeback_accesses[3] = {0};
    int Writeback_misses = 0; // l2
};

struct t_error {
    int n_stat = 0;
    int stat_l[MAX_NUM] = {0};
    char *stat[MAX_NUM];

    int n_config = 0;
    int config_l[MAX_NUM] = {0};
    char *config[MAX_NUM];
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
%token EQ WS NL
%token X86 SYSCLK MEM_MODE			
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
%token <t_int> NUM
%token <t_double> FLOAT
%token <t_str> STR
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
	|	line error { /* do nothing */ }
;

config:
                X86 { mcpat_param->isa_x86 = 1; }
        |	MEM_MODE EQ STR { printf("MEM_TYPE: %s\n", $3); }
        |	SYSCLK EQ NUM { mcpat_param->clock_rate = $3; }
	|	FETCHW EQ NUM { mcpat_param->fetch_width = $3; }
	|	DECODEW EQ NUM {
	               mcpat_param->decode_width = $3;
		       mcpat_param->issue_width = $3; }
        |	ISSUEW EQ NUM { mcpat_param->peak_issue_width = $3; }
        |	COMMITW EQ NUM { mcpat_param->commit_width = $3; }
        |	BASE EQ NUM { mcpat_param->base_stages += $3; mcpat_param->nbase++; }
	|	MAXBASE EQ NUM {
	               mcpat_param->max_base = MAX(mcpat_param->max_base, $3);
		       mcpat_param->nmax_base++; }
        |	BUFFERS EQ NUM { mcpat_param->instruction_buffer_size = $3; }
	|	NIQENTRIES EQ NUM {
	               if ($3 % 2==0){
			   mcpat_param->instruction_window_size = $3/2;
			   mcpat_param->fp_instruction_window_size = $3/2;
		       } else { yyerror("numIQEntries must be odd\n"); } }
        |	NROBENTRIES EQ NUM { mcpat_param->ROB_size = $3;  }
        |	NINTREGS EQ NUM { mcpat_param->phy_Regs_IRF_size = $3;  }
        |	NFREGS EQ NUM { mcpat_param->phy_Regs_FRF_size = $3; }
        |	SQENTRIES EQ NUM { mcpat_param->store_buffer_size = $3;  }	
        |	LQENTRIES EQ NUM { mcpat_param->load_buffer_size = $3; }
        |	RASSIZE EQ NUM { mcpat_param->RAS_size = $3; }
        |	LHISTB EQ NUM { mcpat_param->load_predictor[0] = $3; }
        |	LCTRB EQ NUM { mcpat_param->load_predictor[1] = $3; }
	|	LPREDSIZE EQ NUM {
	               mcpat_param->load_predictor[2] = $3;
		       if (mcpat_param->load_predictor[0]==0) {
			   mcpat_param->load_predictor[0] = (int) floor(log2((double) $3));
		       } }
        |	GPREDSIZE EQ NUM { mcpat_param->global_predictor[0] = $3; }
        |	GCTRB EQ NUM { mcpat_param->global_predictor[1] = $3; }
        |	CPREDSIZE EQ NUM { mcpat_param->predictor_chooser[0] = $3; }
        |	CCTRB EQ NUM { mcpat_param->predictor_chooser[1] = $3; }
        |	BTBE EQ NUM { mcpat_param->BTB_config = $3; }
        |	TLBD EQ NUM { mcpat_param->number_entries_dtlb = $3; }
	|	TLBI EQ NUM { mcpat_param->number_entries_itlb = $3; }
	|	DL1SIZE EQ NUM { mcpat_param->dcache_config[0] = $3; }
	|	DL1BSIZE EQ NUM { mcpat_param->dcache_config[1] = $3; }		
	|	DL1ASSOC EQ NUM {
	                mcpat_param->dcache_config[2] = $3;
			mcpat_param->dcache_config[3] = 1;
			mcpat_param->dcache_config[5] = 32;
			mcpat_param->dcache_config[6] = 1;}
	|	D1MSHRS EQ NUM {
	                mcpat_param->dcache_buffer_sizes[0] = $3;
			mcpat_param->dcache_buffer_sizes[1] = $3;
			mcpat_param->dcache_buffer_sizes[2] = $3; }
	|	WBDL1 EQ NUM { mcpat_param->icache_buffer_sizes[3] = $3; }
	|	HLDL1 EQ NUM { mcpat_param->dhit_lat = $3; }		
	|	RLDL1 EQ NUM { mcpat_param->dresp_lat = $3; }		
	|	IL1SIZE EQ NUM { mcpat_param->icache_config[0] = $3; }
	|	IL1BSIZE EQ NUM { mcpat_param->icache_config[1] = $3; }		
	|	IL1ASSOC EQ NUM {
	                mcpat_param->icache_config[2] = $3;
			mcpat_param->icache_config[3] = 1;
			mcpat_param->icache_config[5] = 32;
			mcpat_param->icache_config[6] = 1;}
	|	I1MSHRS EQ NUM {
	                mcpat_param->icache_buffer_sizes[0] = $3;
			mcpat_param->icache_buffer_sizes[1] = $3;
			mcpat_param->icache_buffer_sizes[2] = $3;
			mcpat_param->icache_buffer_sizes[3] = 0;}
	|	HLIL1 EQ NUM { mcpat_param->ihit_lat = $3; }		
	|	RLIL1 EQ NUM { mcpat_param->iresp_lat = $3; }	
	|	L2SIZE EQ NUM { mcpat_param->L2_config[0] = $3; }
	|	L2BSIZE EQ NUM { mcpat_param->L2_config[1] = $3; }		
	|	L2ASSOC EQ NUM {
	                mcpat_param->L2_config[2] = $3;
			mcpat_param->L2_config[3] = 1;
			mcpat_param->L2_config[5] = 32;
			mcpat_param->L2_config[6] = 1;}
	|	L2MSHRS EQ NUM {
	                mcpat_param->L2_buffer_sizes[0] = $3;
			mcpat_param->L2_buffer_sizes[1] = $3;
			mcpat_param->L2_buffer_sizes[2] = $3; }
	|	WBL2 EQ NUM { mcpat_param->L2_buffer_sizes[3] = $3; }
	|	HLL2 EQ NUM { mcpat_param->l2hit_lat = $3; }		
	|	RLL2 EQ NUM { mcpat_param->l2resp_lat = $3; }		
		
stats:		DECODINSTS WS NUM { mcpat_stats->total_instructions = $3; }
	|	BRANCHPRED WS NUM { mcpat_stats->branch_instructions = $3; }
	|	BRANCHERR WS NUM { mcpat_stats->branch_mispredictions = $3; }
	|	IEWLOAD WS NUM { mcpat_stats->load_instructions = $3; }
	|	IEWSTORE WS NUM { mcpat_stats->store_instructions = $3; }
	|	CINT WS NUM { mcpat_stats->committed_int_instructions = $3; }
	|	CFP WS NUM { mcpat_stats->committed_fp_instructions = $3; }
	|	IPC WS FLOAT { mcpat_stats->pipeline_duty_cycle = $3; }
	|	NCYCLES WS NUM { mcpat_stats->total_cycles = $3; }
	|	ICYCLES WS NUM { mcpat_stats->idle_cycles = $3; }
	|	ROBREADS WS NUM { mcpat_stats->ROB_reads = $3; }			       
	|	ROBWRITES WS NUM { mcpat_stats->ROB_writes = $3; }
	|	RE_INT_LKUP WS NUM { mcpat_stats->rename_reads = $3; }
	|	RE_INT_OP WS NUM { mcpat_stats->rename_writes = $3; }
	|	RE_FP_LKUP WS NUM { mcpat_stats->fp_rename_reads = $3; }
	|	RE_FP_OP WS NUM { mcpat_stats->fp_rename_writes = $3; }
	|	IQ_INT_R WS NUM { mcpat_stats->inst_window_reads = $3; }
	|	IQ_INT_W WS NUM { mcpat_stats->inst_window_writes = $3; }
	|	IQ_INT_WA WS NUM { mcpat_stats->inst_window_wakeup_accesses = $3; }
	|       IQ_FP_QR WS NUM { mcpat_stats->fp_inst_window_reads = $3; }
	|	IQ_FP_QW WS NUM { mcpat_stats->fp_inst_window_writes = $3; }
	|	IQ_FP_QWA WS NUM { mcpat_stats->fp_inst_window_wakeup_accesses = $3; }
	|	INT_RG_R WS NUM { mcpat_stats->int_regfile_reads = $3; }
        |	INT_RG_W WS NUM { mcpat_stats->int_regfile_writes = $3; }
	|	FP_RG_R WS NUM { mcpat_stats->float_regfile_reads = $3; }
	|	FP_RG_W WS NUM { mcpat_stats->float_regfile_writes = $3; }
	|	COMCALLS WS NUM { mcpat_stats->function_calls = $3; }
	|	INTDIV WS NUM { mcpat_stats->IntDiv *= $3; }
        |	INTMULT WS NUM { mcpat_stats->IntMult *= $3; }
	|	INT_ALU_ACC WS NUM { mcpat_stats->ialu_accesses = $3; }
	|	FP_ALU_ACC WS NUM {
	                 mcpat_stats->fpu_accesses = $3;
			 mcpat_stats->cdb_fpu_accesses = $3; }
	|       BTBLKUP WS NUM { mcpat_stats->btb_read_accesses = $3; }
	|	BTBUP WS NUM { mcpat_stats->btb_write_accesses = $3; }
	|	DTB_MISS WS NUM { mcpat_stats->dtlb_total_misses = $3; }
	|	DTB_ACC WS NUM { mcpat_stats->dtlb_total_accesses = $3; }
	|	ITB_MISS WS NUM { mcpat_stats->itlb_total_misses = $3; }
	|	ITB_ACC WS NUM { mcpat_stats->itlb_total_accesses = $3; }
	|	D1_ACC WS NUM { mcpat_stats->overall_access[0] = $3; }
	|	D1_MISS WS NUM { mcpat_stats->overall_misses[0] = $3; }
	|	D1_WRACC WS NUM { mcpat_stats->WriteReq_access[0] = $3; }
	|	D1_WRMISS WS NUM { mcpat_stats->WriteReq_misses[0] = $3; }
	|	D1_WRHITS WS NUM { mcpat_stats->WriteReq_hits[0] = $3; }
	|	D1_WRBACK WS NUM { mcpat_stats->Writeback_accesses[0] = $3; }
	|	I1_ACC WS NUM { mcpat_stats->overall_access[1] = $3; }
	|	I1_MISS WS NUM { mcpat_stats->overall_misses[1] = $3; }
	|	I1_WRACC WS NUM { mcpat_stats->WriteReq_access[1] = $3; }
	|	I1_WRMISS WS NUM { mcpat_stats->WriteReq_misses[1] = $3; }
	|	I1_WRHITS WS NUM { mcpat_stats->WriteReq_hits[1] = $3; }
	|	I1_WRBACK WS NUM { mcpat_stats->Writeback_accesses[1] = $3; }
	|	L2_ACC WS NUM { mcpat_stats->overall_access[2] = $3; }
	|	L2_MISS WS NUM { mcpat_stats->overall_misses[2] = $3; }
	|	L2_WRACC WS NUM { mcpat_stats->WriteReq_access[2] = $3; }
	|	L2_WRMISS WS NUM { mcpat_stats->WriteReq_misses[2] = $3; }
	|	L2_WRBACK WS NUM { mcpat_stats->Writeback_accesses[2] = $3; }
	|	L2_WRBMISS WS NUM { mcpat_stats->Writeback_misses = $3; }		
	;

%%

// this function has C++ style
void xmlParser()
{
    char *error_msg = "Error in template structure! Quitting";
    // copying template
    copy("template.xml", "out.xml");
    // if no errors then
    cout << "Parsing template..." << endl;
    xml_document<> doc;
    xml_node<> * root_node;
    // Read the xml file into a vector
    ifstream theTemplate (xml_temp);
    vector<char> buffer((istreambuf_iterator<char>(theTemplate)), istreambuf_iterator<char>());
    buffer.push_back('\0');
    // Parse the buffer using the xml file parsing library into doc
    doc.parse<0>(&buffer[0]);
    // Find our root node
    root_node = doc.first_node("component");
    if ((strcmp(root_node->first_attribute("id")->value(), "root"))&&
	(strcmp(root_node->first_attribute("name")->value(), "root")) {
	cout << error_msg << endl;
	unlink("out.xml");
	exit(-1);
    }
    // system node
    sys_node = root_node->first_node("component");
    if ((strcmp(root_node->first_attribute("id")->value(), "system"))&&
	(strcmp(root_node->first_attribute("name")->value(), "system")) {
	cout << error_msg << endl;
	unlink("out.xml");
	exit(-1);
    }
    /* SYSTEM PARAMS AND STATS */
    
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
	        "gem5ToMcPAT v%s 2016\n"
		"Usage:  gem5ToMcPAT [OPTIONS]\n"
		"Launch parser gem5ToMcPAT\n"
		"Options:\n"
		"  -x <file>, --xmltemplate=<file>: XML template\n"
		"  -c <file>, --config=<file>: config.ini file (not JSON!)\n"
		"  -s <file>, --stats=<file>: statistics file\n"
		"  -o <file>, --output=<output>: XML output\n"
		"  -h, --help: displays this message\n\n",
	VERSION);
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
    int i;
    mcpat_param = (struct t_mcpat_params *) malloc(sizeof(struct t_mcpat_params));
    mcpat_stats = (struct t_mcpat_stats *) malloc(sizeof(struct t_mcpat_stats));

    error_list = (struct t_error *) malloc(sizeof(struct t_error));
    for (i=0; i < MAX_NUM; i++) {
	error_list->stat[i] = (char *) malloc(MAX_LINE*sizeof(char));
    }
    for (i=0; i < MAX_NUM; i++) {
	error_list->config[i] = (char *) malloc(MAX_LINE*sizeof(char));
    }
}

/* function to report errors */
void yyerror(const char *s, ...)
{
    // error
    ERROR = 1;
    printf("%d: error: %s\n", yylineno, s);
    if (yyin == config_fptr) {
	error_list->config[error_list->n_config] = strdup(s);
	error_list->config_l[error_list->n_config++] = yylineno;
        
    } else if (yyin == stats_fptr) {
	error_list->stat[error_list->n_stat] = strdup(s);
	error_list->stat_l[error_list->n_stat++] = yylineno;
    }
}

void display_errors()
{
    int i;

    if ((error_list->n_config == 0)&&
	(error_list->n_stat == 0)) {
	printf("Parsing was successful!\n");
	return;
    } 


    printf("Errors in config.ini: %d\n", error_list->n_config);
    for(i=0; i < error_list->n_config; i++) {
	printf("%d: %s\n", error_list->config_l[i], error_list->config[i]);
    }

    printf("Errors in stats: %d\n", error_list->n_stat);
    for(i=0; i < error_list->n_stat; i++) {
	printf("%d: %s\n", error_list->stat_l[i], error_list->stat[i]);
    }
}

/////////////////////////////////
// main function		      
int main(int argc, char *argv[])
{
    // no arguments
    if (argc == 1) {
	usage(0);
    }
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

    // initializing all the structures needed
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
    
    // fill template.xml if no errors
    // otherwise it makes no sense
    if (!ERROR)
	xmlParser();

    display_errors();
    
    exit(0);
}
