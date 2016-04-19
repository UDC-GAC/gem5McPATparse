/*
 * Copyright (c) 2016 Universidade da Coruña
 * All rights reserved.
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
 */
%error-verbose
%{
#include "lib/utils.h"
#include "lib/handle_options.h"

int ERROR = 0;
int DETAILED = 0;

extern FILE *yyin;
extern int yylineno;
xml_document<> doc;

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
%token EQ WS NL BADTKN
%token X86 SYSCLK M_MODE			
%token FETCHW DECODEW ISSUEW COMMITW BASE MAXBASE BUFFERS
%token NIQENTRIES NROBENTRIES NINTREGS NFREGS SQENTRIES LQENTRIES RASSIZE
%token LHISTB LCTRB LPREDSIZE GPREDSIZE GCTRB CPREDSIZE	CCTRB
%token BTBE
%token TLBD TLBI
%token IL1SIZE IL1ASSOC I1MSHRS HLIL1 RLIL1 IL1BSIZE
%token DL1SIZE DL1ASSOC D1MSHRS HLDL1 RLDL1 WBDL1 DL1BSIZE
%token L2SIZE L2ASSOC L2MSHRS HLL2 RLL2 WBL2 L2BSIZE
%token MULTALU_LAT DIVALU_LAT			
    /* TOKENS STATS */
%token DECODINSTS BRANCHPRED BRANCHERR IEWLOAD IEWSTORE	CINT CFP IPC NCYCLES
%token ICYCLES ROBREADS ROBWRITES RE_INT_LKUP RE_INT_OP RE_FP_LKUP RE_FP_OP
%token IQ_INT_R IQ_INT_W IQ_INT_WA IQ_FP_QR IQ_FP_QW IQ_FP_QWA INT_RG_R INT_RG_W
%token FP_RG_R FP_RG_W COMCALLS INTDIV INTMULT INT_ALU_ACC FP_ALU_ACC
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
S : line { /* finish */ }
  ;

/* left recursion better than right recursion: due to stack reasons */
line : /* empty */ 
	|	line config
	|	line stats
	|	line error { /* do nothing */ }
;

config:
                X86 { mcpat_param->isa_x86 = 1; }
        |	M_MODE EQ STR { DETAILED = (!strcmp("detailed", $3));}
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
	|	MULTALU_LAT EQ NUM { mcpat_param->lat_IntMult = $3; }
	|	DIVALU_LAT EQ NUM { mcpat_param->lat_IntDiv = $3; }
		
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
	|	INTDIV WS NUM { mcpat_stats->IntDiv = $3; }
        |	INTMULT WS NUM { mcpat_stats->IntMult = $3; }
	|	INT_ALU_ACC WS NUM { mcpat_stats->ialu_accesses = $3; }
	|	FP_ALU_ACC WS NUM { mcpat_stats->fpu_accesses = $3;}
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

/* finds a concrete tag given the name of the tag (type) the value of
   the attribute name and then sets its value to value */
void findAndSetValue(xml_node<> *parent, char const *type, char const *name_value, char *value)
{
    int found = 0;
    for (xml_node<> *node = parent->first_node(type); node; node = node->next_sibling()) {
    	if (!strcmp(node->first_attribute("name")->value(), name_value)) {
	    if (!node->first_attribute("value")) {
		// is this good?
		cout << "Error: bad structure XML in " << name_value << endl;
		cout << "Quitting..." << endl;
		exit(-1);
	    }
	    // checked before if this attribute exists
	    node->remove_attribute(node->first_attribute("value"));
	    // creating again this attribute and allocating string value
	    char *value_name = doc.allocate_string(value);
	    xml_attribute<> *attr = doc.allocate_attribute("value", value_name);
    	    node->append_attribute(attr);
	    // found!
    	    found = 1;
    	}
    }
    
    if (!found) {
	// we could make a set of warnings in order to tell the user
	// that a requested param/stat has not been set
	cout << type << ": " << name_value << " not found!" << endl;
    }
}

void findAndSetIntValue(xml_node<> *parent, char const *type, char const *name_value, int value)
{
    char str[80];
    snprintf(str, 80, "%d", value);
    if (value <= 0) {
	cout << BLD YEL "Warning: " << type <<" " << parent->first_attribute("id")->value()
	     <<" '" << name_value << "' may have not been set!" RES << endl;
    }
    findAndSetValue(parent, type, name_value, str);
    
}

void findAndSetFloatValue(xml_node<> *parent, char const *type, char const *name_value, double value)
{
    char str[80];
    snprintf(str, 80, "%f", value);
    if (value <= 0.0) {
	cout << BLD YEL "Warning: " << type <<" " << parent->first_attribute("id")->value()
	     <<" '" << name_value << "' may have not been set!" RES << endl;
    }
    findAndSetValue(parent, type, name_value, str);
}

void checkNode(xml_node<> *node, char const *id, char const *value)
{
    char const *error_msg = "Error in template structure! Quitting\n";

    // no lazy comparison possible 
    if (node==0) {
	cout << "Node does not exist!" << endl;
	cout << error_msg << endl;
	unlink("out.xml");
	exit(0);
    }

    // if node is not null, i.e. exists
    if ((strcmp(node->first_attribute("id")->value(), id))&&
	(strcmp(node->first_attribute("name")->value(), value))) {
	cout << "Component " << id << " missing" << endl;
	cout << "Found: " << node->first_attribute("id")->value() << " "
	     << node->first_attribute("name")->value() << endl;
	cout << error_msg << endl;
	unlink("out.xml");
	exit(0);
    }	
}

/* xmlParser fills with the correct values the templates and prints in
   out.xml */
void xmlParser() throw()
{
    cout << "Parsing template..." << endl;
    // Read the xml file into a vector
    ifstream theTemplate ("out.xml");
    vector<char> buffer((istreambuf_iterator<char>(theTemplate)), istreambuf_iterator<char>());
    buffer.push_back('\0');
    // Parse the buffer using the xml file parsing library into doc
    doc.parse<0>(&buffer[0]);
    
    // Find our root node
    xml_node<> *root_node = doc.first_node("component");
    checkNode(root_node, "root", "root");
    
    // system node
    xml_node<> *sys_node = root_node->first_node("component");
    checkNode(sys_node, "system", "system");
    
    /* SYSTEM PARAMS AND STATS */
    findAndSetIntValue(sys_node, "param", "target_core_clockrate", mcpat_param->clock_rate);
    findAndSetIntValue(sys_node, "stat", "total_cycles", mcpat_stats->total_cycles);
    findAndSetIntValue(sys_node, "stat", "idle_cycles", mcpat_stats->idle_cycles);
    findAndSetIntValue(sys_node, "stat", "busy_cycles", mcpat_stats->total_cycles - mcpat_stats->idle_cycles);

    /* CORE PARAMS AND STATS */
    xml_node<> *core_node = sys_node->first_node("component");
    checkNode(core_node, "system.core0", "core0");
    findAndSetIntValue(core_node, "param", "clock_rate", mcpat_param->clock_rate);
    findAndSetIntValue(core_node, "param", "x86", mcpat_param->isa_x86);
    findAndSetIntValue(core_node, "param", "fetch_width", mcpat_param->fetch_width);
    findAndSetIntValue(core_node, "param", "decode_width", mcpat_param->decode_width);
    findAndSetIntValue(core_node, "param", "issue_width", mcpat_param->issue_width);
    findAndSetIntValue(core_node, "param", "peak_issue_width", mcpat_param->peak_issue_width);
    findAndSetIntValue(core_node, "param", "commit_width", mcpat_param->commit_width);
    if ((mcpat_param->nbase!=4)||(mcpat_param->nmax_base!=4))
	cout << BLD YEL "Warning: some parameters missing to set properly 'pipeline_depth'!" RES << endl;
    findAndSetValue(core_node, "param", "pipeline_depth", make_tuple(2, (INT_EXE +
									mcpat_param->base_stages +
								        mcpat_param->max_base),
								        (FP_EXE +
									mcpat_param->base_stages +
								        mcpat_param->max_base)));
    findAndSetIntValue(core_node, "param", "instruction_buffer_size", mcpat_param->instruction_buffer_size);
    findAndSetIntValue(core_node, "param", "instruction_window_size", mcpat_param->instruction_window_size);
    findAndSetIntValue(core_node, "param", "fp_instruction_window_size", mcpat_param->fp_instruction_window_size);
    findAndSetIntValue(core_node, "param", "ROB_size", mcpat_param->ROB_size);
    findAndSetIntValue(core_node, "param", "phy_Regs_IRF_size", mcpat_param->phy_Regs_IRF_size);
    findAndSetIntValue(core_node, "param", "phy_Regs_FRF_size", mcpat_param->phy_Regs_FRF_size);
    findAndSetIntValue(core_node, "param", "store_buffer_size", mcpat_param->store_buffer_size);
    findAndSetIntValue(core_node, "param", "load_buffer_size", mcpat_param->load_buffer_size);
    findAndSetIntValue(core_node, "param", "RAS_size", mcpat_param->RAS_size);

    findAndSetIntValue(core_node, "stat", "total_instructions", mcpat_stats->total_instructions);
    findAndSetIntValue(core_node, "stat", "branch_instructions", mcpat_stats->branch_instructions);
    findAndSetIntValue(core_node, "stat", "branch_mispredictions", mcpat_stats->branch_mispredictions);
    findAndSetIntValue(core_node, "stat", "load_instructions", mcpat_stats->load_instructions);
    findAndSetIntValue(core_node, "stat", "store_instructions", mcpat_stats->store_instructions - mcpat_stats->load_instructions);
    findAndSetIntValue(core_node, "stat", "committed_int_instructions", mcpat_stats->committed_int_instructions);
    findAndSetIntValue(core_node, "stat", "committed_fp_instructions", mcpat_stats->committed_fp_instructions);
    findAndSetFloatValue(core_node, "stat", "pipeline_duty_cycle", mcpat_stats->pipeline_duty_cycle);
    findAndSetIntValue(core_node, "stat", "total_cycles", mcpat_stats->total_cycles);
    findAndSetIntValue(core_node, "stat", "idle_cycles", mcpat_stats->idle_cycles);
    findAndSetIntValue(core_node, "stat", "busy_cycles", mcpat_stats->total_cycles - mcpat_stats->idle_cycles);
    findAndSetIntValue(core_node, "stat", "ROB_reads", mcpat_stats->ROB_reads);
    findAndSetIntValue(core_node, "stat", "ROB_writes", mcpat_stats->ROB_writes);
    findAndSetIntValue(core_node, "stat", "rename_reads", mcpat_stats->rename_reads);
    findAndSetIntValue(core_node, "stat", "rename_writes", mcpat_stats->rename_writes);
    findAndSetIntValue(core_node, "stat", "fp_rename_reads", mcpat_stats->fp_rename_reads);
    findAndSetIntValue(core_node, "stat", "fp_rename_writes", mcpat_stats->fp_rename_writes);
    findAndSetIntValue(core_node, "stat", "inst_window_reads", mcpat_stats->inst_window_reads);
    findAndSetIntValue(core_node, "stat", "inst_window_writes", mcpat_stats->inst_window_writes);
    findAndSetIntValue(core_node, "stat", "inst_window_wakeup_accesses", mcpat_stats->inst_window_wakeup_accesses);
    findAndSetIntValue(core_node, "stat", "fp_inst_window_reads", mcpat_stats->fp_inst_window_reads);
    findAndSetIntValue(core_node, "stat", "fp_inst_window_writes", mcpat_stats->fp_inst_window_writes);
    findAndSetIntValue(core_node, "stat", "fp_inst_window_wakeup_accesses", mcpat_stats->fp_inst_window_wakeup_accesses);
    findAndSetIntValue(core_node, "stat", "int_regfile_reads", mcpat_stats->int_regfile_reads);
    findAndSetIntValue(core_node, "stat", "int_regfile_writes", mcpat_stats->int_regfile_writes);
    findAndSetIntValue(core_node, "stat", "float_regfile_reads", mcpat_stats->float_regfile_reads);
    findAndSetIntValue(core_node, "stat", "function_calls", mcpat_stats->function_calls);
    mcpat_stats->mul_accesses = mcpat_stats->IntDiv*mcpat_param->lat_IntDiv +
	                        mcpat_stats->IntMult*mcpat_param->lat_IntMult;
    mcpat_stats->ialu_accesses -= mcpat_stats->mul_accesses;
    findAndSetIntValue(core_node, "stat", "ialu_accesses", mcpat_stats->ialu_accesses);
    findAndSetIntValue(core_node, "stat", "fpu_accesses", mcpat_stats->fpu_accesses);
    findAndSetIntValue(core_node, "stat", "mul_accesses", mcpat_stats->mul_accesses);
    // this is not the same as the Appendix says, but in some
    // templates the same values are used
    findAndSetIntValue(core_node, "stat", "cdb_alu_accesses", mcpat_stats->ialu_accesses);
    findAndSetIntValue(core_node, "stat", "cdb_mul_accesses", mcpat_stats->mul_accesses);    
    findAndSetIntValue(core_node, "stat", "cdb_fpu_accesses", mcpat_stats->fpu_accesses);    
    
    /* BRANCH PREDICTOR */
    xml_node<> *bp_node = core_node->first_node("component");
    checkNode(bp_node, "system.core0.predictor", "PBT");
    findAndSetValue(bp_node, "param", "load_predictor",
		    make_tuple(3, mcpat_param->load_predictor[0], mcpat_param->load_predictor[1],
			       mcpat_param->load_predictor[2]));
    findAndSetValue(bp_node, "param", "global_predictor",
		    make_tuple(2, mcpat_param->global_predictor[0], mcpat_param->global_predictor[1]));
    findAndSetValue(bp_node, "param", "predictor_chooser",
		    make_tuple(2, mcpat_param->predictor_chooser[0], mcpat_param->predictor_chooser[1]));

    /* ITLB */
    xml_node<> *itlb_node = bp_node->next_sibling();
    checkNode(itlb_node, "system.core0.itlb", "itlb");
    findAndSetIntValue(itlb_node, "param", "number_entries", mcpat_param->number_entries_itlb);
    findAndSetIntValue(itlb_node, "stat", "total_accesses", mcpat_stats->itlb_total_accesses);
    findAndSetIntValue(itlb_node, "stat", "total_misses", mcpat_stats->itlb_total_misses);
    
    /* ICACHE */
    xml_node<> *icache_node = itlb_node->next_sibling();
    checkNode(icache_node, "system.core0.icache", "icache");
    findAndSetValue(icache_node, "param", "icache_config", make_tuple(8,mcpat_param->icache_config[0],
								       mcpat_param->icache_config[1],
								       mcpat_param->icache_config[2],
								       1,mcpat_param->icache_config[4],
								      mcpat_param->icache_config[4], 32, 0));
    findAndSetValue(icache_node, "param", "buffer_sizes", make_tuple(4,mcpat_param->icache_buffer_sizes[0],
								     mcpat_param->icache_buffer_sizes[1],
								     mcpat_param->icache_buffer_sizes[2],0));
    
    /* DTLB */
    xml_node<> *dtlb_node = icache_node->next_sibling();
    checkNode(dtlb_node, "system.core0.dtlb", "dtlb");
    findAndSetIntValue(dtlb_node, "param", "number_entries", mcpat_param->number_entries_dtlb);
    findAndSetIntValue(dtlb_node, "stat", "total_accesses", mcpat_stats->dtlb_total_accesses);
    findAndSetIntValue(dtlb_node, "stat", "total_misses", mcpat_stats->dtlb_total_misses);
    
    /* DCACHE */
    xml_node<> *dcache_node = dtlb_node->next_sibling();
    checkNode(dcache_node, "system.core0.dcache", "dcache");
    findAndSetValue(dcache_node, "param", "dcache_config", make_tuple(8,mcpat_param->dcache_config[0],
								       mcpat_param->dcache_config[1],
								       mcpat_param->dcache_config[2],
								       1,mcpat_param->dcache_config[4],
								      mcpat_param->dcache_config[4], 32, 1));
    findAndSetValue(icache_node, "param", "buffer_sizes", make_tuple(4,mcpat_param->dcache_buffer_sizes[0],
								     mcpat_param->dcache_buffer_sizes[1],
								     mcpat_param->dcache_buffer_sizes[2],
								     mcpat_param->dcache_buffer_sizes[3]));
		    
    /* BTB: param tag in the middle that is why double next_sibling() */
    xml_node<> *btb_node = dcache_node->next_sibling()->next_sibling();
    checkNode(btb_node, "system.core0.BTB", "BTB");
    findAndSetValue(btb_node, "param", "BTB_config", make_tuple(6,mcpat_param->BTB_config,4,2,2,1,1));
		    
    /* L20 CACHE */
    xml_node<> *l2_node = core_node->next_sibling()->next_sibling()->next_sibling();
    checkNode(l2_node, "system.L20", "L20");
    findAndSetValue(l2_node, "param", "L2_config", make_tuple(8,mcpat_param->L2_config[0],
							      mcpat_param->L2_config[1],
							      mcpat_param->L2_config[2],
							      1,mcpat_param->L2_config[4],
							      mcpat_param->L2_config[4], 32, 1));
    findAndSetValue(l2_node, "param", "buffer_sizes", make_tuple(4,mcpat_param->L2_buffer_sizes[0],
								     mcpat_param->L2_buffer_sizes[1],
								     mcpat_param->L2_buffer_sizes[2],
								     mcpat_param->L2_buffer_sizes[3]));
    findAndSetIntValue(l2_node, "param", "clockrate", mcpat_param->clock_rate);
    findAndSetIntValue(l2_node, "stat", "read_accesses", mcpat_stats->overall_access[2]-mcpat_stats->WriteReq_access[2]);
    findAndSetIntValue(l2_node, "stat", "write_accesses", mcpat_stats->overall_access[2] +
		       mcpat_stats->Writeback_accesses[2] + mcpat_stats->WriteReq_access[2]);
    findAndSetIntValue(l2_node, "stat", "read_misses", mcpat_stats->overall_misses[2]-mcpat_stats->WriteReq_misses[2]);
    findAndSetIntValue(l2_node, "stat", "write_misses", mcpat_stats->overall_misses[2]-mcpat_stats->Writeback_misses +
		                                        mcpat_stats->WriteReq_misses[2]);


		    
    // finishing message
    cout << BLD "finish filling!" RES << endl;
    std::ofstream output;
    output.open ("out.xml");
    output << doc;
}

/* initializing */
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

/* when 'error' is found in the parser */
void yyerror(const char *s, ...)
{
    // activating error flag
    ERROR = 1;
    // showing user that there has been an error and then recording it
    printf("%d: error: %s\n", yylineno, s);
    if (yyin == config_fptr) {
	error_list->config[error_list->n_config] = strdup(s);
	error_list->config_l[error_list->n_config++] = yylineno;
        
    } else if (yyin == stats_fptr) {
	error_list->stat[error_list->n_stat] = strdup(s);
	error_list->stat_l[error_list->n_stat++] = yylineno;
    }
}

/* display recorded errors */
void display_errors()
{
    int i;

    if ((error_list->n_config == 0)&&
	(error_list->n_stat == 0)) {
	printf(GRN "Parsing was successful!\n" RES);
	return;
    } 

    printf(RED "Errors in config.ini: %d\n" RES, error_list->n_config);
    for(i=0; i < error_list->n_config; i++) {
	printf("%d: %s\n", error_list->config_l[i], error_list->config[i]);
    }

    printf(RED "Errors in stats: %d\n" RES, error_list->n_stat);
    for(i=0; i < error_list->n_stat; i++) {
	printf("%d: %s\n", error_list->stat_l[i], error_list->stat[i]);
    }
}

/////////////////////////////////
// main function		      
int main(int argc, char *argv[])
{
    printf(BLD "gem5ToMcPAT v%s 2016\n" RES, VERSION);
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

    // copying file
    copy("template.xml", "out.xml");
    
    // initializing all the structures needed
    init_structs();
    
    // parse config.ini
    yyin = config_fptr;
    yyparse();
    printf("[config.ini]: finished parsing!\n");
    fclose(yyin);
    
    // to clean yyin
    yyrestart(yyin);
    yyin = stats_fptr;
    yyparse();
    printf("[stats.txt]: finished parsing!\n");
    fclose(yyin);

    // in case the simulation is not detailed
    if (!DETAILED)
	printf(BLD YEL "Warning: simulation has not been done in detailed memory mode\n"
	       "Thus there is a lack of stats and some values will be set to zero\n" RES);
    
    // fill template.xml if no errors
    // otherwise it makes no sense
    if (!ERROR) xmlParser();
    else unlink("out.xml");

    display_errors();

    // quiting!
    exit(0);
}
