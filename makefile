# This makefile allows to compile and run the parser

COMP=g++
XMLTEMPLATE=tempalte.xml
OUTPUT=out.xml
BIN=gem5ToMcPAT
FLAGS=-lfl -ly -w
PARS=parser

all: compile

compile: $(PARS).l $(PARS).y
	flex $(PARS).l
	bison -o $(PARS).tab.c $(PARS).y -yd
	$(COMP) -o $(BIN) lex.yy.c $(PARS).tab.c $(FLAGS)

run:
	echo "Running parser..."
	./$(BIN) -x $(XMLTEMPLATE) -c $(CONF) -s $(STATS) -o $(OUTPUT)

clean:
	rm *.yy.c *.tab.c *.out *.tab.h
