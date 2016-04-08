# gem5ToMcPAT
[IN DEVELOPMENT] An attempt to adapt gem5 output to McPAT input. This version is implemented in Bison, Flex and C/C++. It also uses the library RapidXML for C++. Based on Fernando Endo's notes [^1], this parser extracts the parameters and statistics from the output of gem5, 'config.ini' and 'stats.txt', and fills the equivalent fields in a XML based on 'template.xml'.

## Installation
To install this version:

    make install

## Running the parser
To run the parser and generate 'output.xml':

    make run

It is also possible to run as (all these options are mandatory):

    ./gem5ToMcPAT -x <template_file> -c <config_file> -s <stats_file> -o <output_file>
    ./gem5ToMcPAT --xmltempalte <template_file> --config <config_file> --stats <stats_file> --output <output_file>

In order to get help from the program:

    ./gem5ToMcPAT -h

## Software needed
It has been tested in a Linux distribution with `gcc version 5.2.1`, `bison version 3.0.2`, `flex 2.5.39` and `make 4.0`

# Limitations
This first version is focused on the compatibility of the output of memory system and core in gem5 with the input of McPAT. Thus, other components such as PCIe will be ignored by the moment.

# References
[^1]: Fernando Akira Endo. Génération dynamique de code pour l’optimisation énergétique. Architectures Matérielles [cs.AR]. Université Grenoble Alpes, 2015. Français. <NNT : 2015GREAM044>. <tel-01285964> (Appendix A)