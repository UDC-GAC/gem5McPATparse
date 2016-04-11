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
#include "lib/rapidxml.hpp"

using namespace rapidxml;
using namespace std;

#ifndef xml_temp
#define xml_temp "template.xml"
#endifç

#ifndef MAX(X,Y)
#define MAX(X,Y) X>Y ? X : Y
#endif

extern FILE *yyin;

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
    int load_predictor[3];
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
};

struct t_mcpat_stats {
};

struct t_mcpat_params *mcpat_param;
struct t_mcpat_stats *mcpat_stats;

int yylex(void);
 void yyerror(const char *s, ...);
void yyrestart(FILE *yyin);
%}
%union {
    int t_int;
    double t_double;
    char * t_str;
}
%token EQ X86 SYSCLK			
%token FETCHW DECODEW ISSUEW COMMITW BASE MAXBASE BUFFERS NIQENTRIES NROBENTRIES NINTREGS NFREGS SQENTRIES LQENTRIES RASSIZE
%token LHISTB LCTRB LPREDSIZE GPREDSIZE GCTRB CPREDSIZE	CCTRB
%token BTBE
%token TLBD TLBI
%token IL1SIZE IL1ASSOC I1MSHRS HLIL1 RLIL1 IL1BSIZE
%token DL1SIZE DL1ASSOC D1MSHRS HLDL1 RLDL1 WBDL1 DL1BSIZE
%token L2SIZE L2ASSOC L2MSHRS HLL2 RLL2 WBL2 L2BSIZE											
%token	<t_int> NUM
%token	<t_double> FLOAT
%token	<t_str> STR
// tokens types etc
%start S 			
%%
// rules
S : line { printf("finished parsing!\n"); }
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
        |	LPREDSIZE EQ NUM { printf("LPREDSIZE=%d\n", $3); mcpat_param->load_predictor[2] = $3; }
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
		
stats:		STR { /* DO NOTHING */}
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

    //check_params();
    
    // parse stats.txt
    //yyin = stats_fptr;
    //yyparse();
    //fclose(yyin);

    //check_stats();
    
    // fill template.xml
    //fill_xml();
    
    exit(0);
}

/* function to report errors */
void yyerror(const char *s, ...)
{
    printf("Error: %s\n", s);
}
