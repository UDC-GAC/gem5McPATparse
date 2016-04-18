// set of libraries needed

#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <fstream>
#include <vector>
#include <math.h>
#include "colors.h"
#include "isa.h"
#include "copy.h"
#include "rapidxml.hpp"
#include "rapidxml_print.hpp"

using namespace rapidxml;
using namespace std;

#ifndef VERSION
#define VERSION "0.1"
#endif

#ifndef xml_temp
#define xml_temp "template.xml"
#endif

#ifndef MAX(X,Y)
#define MAX(X,Y) X>Y ? X : Y
#endif

#define MAX_NUM 1000
#define MAX_LINE 1000


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

FILE *config_fptr, *stats_fptr;

// declaration
void usage(int i);
int handle_options(int argc, char **argv);
