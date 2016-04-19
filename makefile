# This makefile allows to compile and run the parser

COMP=g++
XMLTEMPLATE=template.xml
OUTPUT=out.xml
CONF=config.ini
STATS=stats.txt
BIN=gem5ToMcPAT
FLAGS=-lfl -ly -std=c++11
PARS=parser

all: compile

compile: $(PARS).l $(PARS).y
	flex $(PARS).l
	bison -o $(PARS).tab.c $(PARS).y -yd
	$(COMP) -o $(BIN) lex.yy.c $(PARS).tab.c $(FLAGS)

run:
	./$(BIN) -x $(XMLTEMPLATE) -c $(CONF) -s $(STATS) -o $(OUTPUT)

clean:
	rm *.yy.c *.tab.c *.out *.tab.h stack.hh $(OUTPUT) $(BIN)
