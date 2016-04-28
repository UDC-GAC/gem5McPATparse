/*
 * Copyright (c) 2016 Universidade da Coruña
 * All rights reserved. MIT Licence
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met: redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer;
 * redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution;
 * neither the name of the copyright holders nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Marcos Horro Varela
 *
 */

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
#include "xml/rapidxml.hpp"
#include "xml/rapidxml_print.hpp"

using namespace rapidxml;
using namespace std;

#ifndef VERSION
#define VERSION "0.1"
#endif

#ifndef MAX
#define MAX(X,Y) X>Y ? X : Y
#endif

#define MAX_NUM 1000
#define MAX_LINE 1000

struct t_mcpat_params {
    /* for x86 architectures */
    int isa_x86 = 0;
    /* core parameters */
    int clock_rate;
    int fetch_width = 4;
    int decode_width = 4;
    int issue_width = 4;
    int peak_issue_width = 6;
    int commit_width = 4;
    int instruction_buffer_size = 32;
    int instruction_window_size = 64;
    int fp_instruction_window_size = 64;
    int ROB_size = 128;
    int phy_Regs_IRF_size = 256;
    int phy_Regs_FRF_size = 256;
    int store_buffer_size = 96;
    int load_buffer_size = 48;
    int RAS_size = 64;
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
    
    int l2hit_lat;
    int l2resp_lat;

    /* cache l2 */
    int L3_config[7];
    int L3_buffer_sizes[4];
    
    int l3hit_lat;
    int l3resp_lat;

    /* ALUs latencies (default values) */
    int lat_IntDiv = 20;
    int lat_IntMult = 3;

    /* main memory */
    int memory_channels_per_mc = 1;
    int number_ranks = 2;
    int number_mcs = 1; // todo
    int block_size = 64;
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
    /* btb stats */
    int btb_read_accesses = 0;
    int btb_write_accesses = 0;
    /* tlb L1 */
    int dtlb_total_accesses = 0;
    int dtlb_total_misses = 0;
    int itlb_total_accesses = 0;
    int itlb_total_misses = 0;

    /* aux: default values */
    int IntDiv = 0; 
    int IntMult = 0;
    int overall_access[4] = {0};
    int overall_misses[4] = {0};
    int WriteReq_access[4] = {0};
    int WriteReq_hits[2] = {0}; // i1/d1
    int WriteReq_misses[4] = {0};
    int Writeback_accesses[4] = {0};
    int Writeback_misses = 0; // l2
    int Writeback_misses_l3 = 0; // l2

    /* main memory */
    int memory_reads = 0;
    int memory_writes = 0;
};

struct t_error {
    int n_stat = 0;
    int stat_l[MAX_NUM] = {0};
    char *stat[MAX_NUM];

    int n_config = 0;
    int config_l[MAX_NUM] = {0};
    char *config[MAX_NUM];
};

FILE *config_fptr = NULL;
FILE *stats_fptr = NULL;
char xml_file[80] = "template.xml";
char out_file[80] = "out.xml";
char conf_file[80] = "config.ini";
char stats_file[80] = "stats.txt";

// function headers
void usage(int i);
int handle_options(int argc, char **argv);
char *make_tuple(int n, int v[]);
void init_param(t_mcpat_params *p);

// simple function to create a tuple with n values
// like [value1],[value2],...,[valuen]
char *make_tuple(int n, ...)
{
    int i;
    char *aux = (char *) malloc(sizeof(char)*80);
    char str1[50], str2[50];
    
    va_list ap;
    va_start(ap, n);
    int v = va_arg(ap, int);
    snprintf(str1, 50, "%d", v);
    for (i=0; i < n-1; i++) {
	strcat(str1, ",");
	v = va_arg(ap, int);
	snprintf(str2, 50, "%d", v);
	strcat(str1, str2);
    }
    strcpy(aux, str1);

    return aux;
}

// due to C++11 it is needed to initialize like this
// the initialization is needed in case the execution
// does not provide the minimum params for McPAT
void init_param(t_mcpat_params *p)
{
    /* CORE PARAMS */
    p->fetch_width = 4;
    p->decode_width = 4;
    p->issue_width = 4;
    p->peak_issue_width = 6;
    p->commit_width = 4;
    p->instruction_buffer_size = 32;
    p->instruction_window_size = 64;
    p->fp_instruction_window_size = 64;
    p->ROB_size = 128;
    p->phy_Regs_IRF_size = 256;
    p->phy_Regs_FRF_size = 256;
    p->store_buffer_size = 96;
    p->load_buffer_size = 48;
    p->RAS_size = 64;
    /* BTB */
    p->BTB_config = 4096;
    /* PBT */
    p->load_predictor[0] = 10;
    p->load_predictor[1] = 3;
    p->load_predictor[2] = 1024;
    p->global_predictor[0] = 4096;
    p->global_predictor[1] = 2;
    p->predictor_chooser[0] = 4096;
    p->predictor_chooser[1] = 2;
}
