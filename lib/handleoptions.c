// this library allows to parse input arguments
// Thanks to Juan Quintela (Universidade da Coruña) http://www.madsgroup.org/staff/quintela/index.html

#include <errno.h>
#include <getopt.h>

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
		"  -c <file>, --config=<file>: config.ini file (not JSON)\n"
		"  -s <file>, --stats=<file>: statistics file\n"
		"  -o <file>, --output=<output>: XML result\n"
		"  -h, --help: displays this message\n\n"
	);
	exit(i);
}

static int check_file(char *

static int get_int(char *arg, int *value)
{
	char *end;
	*value = strtol(arg, &end, 10);

	return (end != NULL);
}

static void handle_long_options(struct option option, char *arg)
{
	if (!strcmp(option.name, "help"))
		usage(0);

	if (!strcmp(option.name, "xmltemplate")) {
		if (!get_int(arg, &num_producers)
		    || num_producers <= 0) {
			printf("'%s': no es un entero válido\n", arg);
			usage(-3);
		}
	}
	if (!strcmp(option.name, "consumers")) {
		if (!get_int(arg, &num_consumers)
		    || num_consumers <= 0) {
			printf("'%s': no es un entero válido\n", arg);
			usage(-3);
		}
	}
	if (!strcmp(option.name, "buffer_size")) {
		if (!get_int(arg, &buffer_size)
		    || buffer_size <= 0) {
			printf("'%s': no es un entero válido\n", arg);
			usage(-3);
		}
	}
	if (!strcmp(option.name, "iterations")) {
		if (!get_int(arg, &iterations)
		    || iterations <= 0) {
			printf("'%s': no es un entero válido\n", arg);
			usage(-3);
		}
	}
}

static int handle_options(int argc, char **argv)
{
	while (1) {
		int c;
		int option_index = 0;

		c = getopt_long (argc, argv, "hp:c:b:i:",
				 long_options, &option_index);
		if (c == -1)
			break;

		switch (c) {
		case 0:
			handle_long_options(long_options[option_index],
				optarg);
			break;

		case 'p':
			if (!get_int(optarg, &num_producers)
			    || num_producers <= 0) {
				printf("'%s': no es un entero válido\n",
				       optarg);
				usage(-3);
			}
			break;


		case 'c':
			if (!get_int(optarg, &num_consumers)
			    || num_consumers <= 0) {
				printf("'%s': no es un entero válido\n",
				       optarg);
				usage(-3);
			}
			break;

		case 'b':
			if (!get_int(optarg, &buffer_size)
			    || buffer_size <= 0) {
				printf("'%s': no es un entero válido\n",
				       optarg);
				usage(-3);
			}
			break;

		case 'i':
			if (!get_int(optarg, &iterations)
			    || iterations <= 0) {
				printf("'%s': no es un entero válido\n",
				       optarg);
				usage(-3);
			}
			break;


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
