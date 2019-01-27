.PHONY:all clean

all:scanner

lex.yy.c:lextemplate.l
	lex lextemplate.l

scanner:lex.yy.c
	gcc -o scanner lex.yy.c -lfl

clean:
	-rm scanner lex.yy.c