# makefile for parser
# lex lex.l
# yacc -v -d yacc.y
# gcc -o parser lex.yy.c y.tab.c
LEX = lex
LEXFN = lex.l
YACC = yacc
YACCFN = yacc.y
CC = gcc
LIBS = -lfl -ll -ly
FLAGS = -v -d
RM = rm -f
SCANNERSN = lex.yy.c
PARSERSN = y.tab.c
PARSERN = parser

.PHONY:all clean

all: parser

parser: yacc lex
	$(CC) -o $(PARSERN) $(SCANNERSN) $(PARSERSN) $(LIBS)

yacc: 
	$(YACC) $(FLAGS) $(YACCFN)

lex:
	$(LEX) $(LEXFN)


clean:
	$(RM) $(PARSERN) $(PARSERSN) $(SCANNERSN) y.tab.h y.output

