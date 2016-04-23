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
 *          Juan Quintela
 */
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

void usage(int i)
{
	printf(
		"Usage:  gem5ToMcPAT [OPTIONS]\n"
		"Launch parser gem5ToMcPAT\n"
		"Options:\n"
		"  -x <file>, --xmltemplate=<file>: XML template\n"
		"  -c <file>, --config=<file>: config.ini file (not JSON!)\n"
		"  -s <file>, --stats=<file>: statistics file\n"
		"  -o <file>, --output=<output>: XML output\n"
		"  -h, --help: displays this message\n\n");
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
	
	if (!strcmp(option.name, "xmltemplate")) {
	    strcpy(xml_file, arg);
	}
	
	if (!strcmp(option.name, "output")) {
	    strcpy(out_file, arg);
	}
}

int handle_options(int argc, char **argv)
{
	while (1) {
		int c;
		int flags = 0;
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
		case 'x': strcpy(xml_file, optarg); break;
	        case 'o': strcpy(out_file, optarg); break;
		case '?':
		case 'h':
			usage(0);
			break;

		default:
			printf ("?? getopt returned character code 0%o ??\n", c);
			usage(-1);
		}
	}

	if (stats_fptr==NULL) {
	    if (!check_file(stats_file, &stats_fptr)) {
		printf("'%s': invalid file\n", stats_file);
		fclose(stats_fptr);
		usage(-3);
	    }
	}

	if (config_fptr==NULL) {
	    if (!check_file(conf_file, &config_fptr)) {
		printf("'%s': invalid file\n", conf_file);
		fclose(config_fptr);
		usage(-3);
	    }
	}
	
	return 0;
}
