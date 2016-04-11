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
#endif

extern FILE *yyin;

FILE *config_fptr, *stats_fptr;

struct mcpat_struct {
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
    int pipeline_depthx;
    int pipeline_depthy;
    /* cache parameters */
};

struct mcpat_struct *mcpat_param;

int yylex(void);
void yyerror(char *s, ...);
void yyrestart(FILE *yyin);
%}
%union {
    int t_int;
    double t_double;
    char * t_str;
}
%token EQ NL SYSCLK FETCHW DECODEW ISSUEW COMMITW BASE MAXBASE BUFFERS NIQENTRIES NROBENTRIES NINTREGS NFREGS SQENTRIES LQENTRIES RASSIZE
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
        	SYSCLK EQ NUM { printf("clk=%d\n",$3); mcpat_param->clock_rate = $3; }
	|	FETCHW EQ NUM { printf("FW=%d\n",$3); mcpat_param->fetch_width = $3; }
	|	DECODEW EQ NUM { printf("FW=%d\n",$3); mcpat_param->decode_width = $3; mcpat_param->issue_width = $3; }
        |	ISSUEW EQ NUM { printf("IW=%d\n", $3); mcpat_param->peak_issue_width = $3; }
        |	COMMITW EQ NUM { printf("CW=%d\n", $3); mcpat_param->commit_width = $3; }
        |	BASE EQ NUM { printf("BASE=%d\n", $3); mcpat_param->base_stages += $3; mcpat_param->nbase++; }
        |	MAXBASE EQ NUM { printf("maxBASE=%d\n", $3); mcpat_param->base_stages += $3; mcpat_param->nmax_base++; }
        |	BUFFERS EQ NUM { printf("BUFFERSIZE=%d\n", $3); mcpat_param->instruction_buffer_size = $3; }
	|	NIQENTRIES EQ NUM { printf("NIQENTRIES=%d\n", $3); if ($3 % 2==0){ mcpat_param->instruction_window_size = $3/2; mcpat_param->fp_instruction_window_size = $3/2; } else { yyerror("numIQEntries must be odd\n"); } }
        |	NROBENTRIES EQ NUM { printf("NROBENTRIES=%d\n", $3); mcpat_param->ROB_size = $3;  }
        |	NINTREGS EQ NUM { printf("NINTREGS=%d\n", $3); mcpat_param->phy_Regs_IRF_size = $3;  }
        |	NFREGS EQ NUM { printf("NFREGS=%d\n", $3); mcpat_param->phy_Regs_FRF_size = $3; }
        |	SQENTRIES EQ NUM { printf("SQENTRIES=%d\n", $3); mcpat_param->store_buffer_size = $3;  }	
        |	LQENTRIES EQ NUM { printf("IQENTRIES=%d\n", $3); mcpat_param->load_buffer_size = $3; }
        |	RASSIZE EQ NUM { printf("RASSIZE=%d\n", $3); mcpat_param->RAS_size = $3; }
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
    mcpat_param = (struct mcpat_struct *) malloc(sizeof(struct mcpat_struct));
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
void yyerror(char *s, ...)
{
    printf("Error: %s\n", s);
}
