%{
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */

int yylex();
%}

%token COMMA
%token SEMICOLON
%token L_PARENTHESIS
%token R_PARENTHESIS
%token L_BRACKET
%token R_BRACKET
%token L_BRACE
%token R_BRACE
%right ASSIGN

%left OR
%left AND
%right NOT
%left GT GE LE LT EQ NE
%left ADD SUB
%left MUL DIV MOD
%nonassoc NEGATIVE /* supply precedence */

%token ID

%token KW_INT
%token KW_BOOL
%token KW_BOOLEAN
%token KW_VOID
%token KW_FLOAT
%token KW_DOUBLE
%token KW_STRING
%token KW_CONST
%token KW_WHILE
%token KW_DO
%token KW_IF
%token KW_ELSE
%token KW_TRUE
%token KW_FALSE
%token KW_FOR
%token KW_PRINT
%token KW_READ
%token KW_CONTINUE
%token KW_BREAK
%token KW_RETURN

%token INTEGER
%token FLOAT_NUM
%token SCIENTIFIC

%token STRING_TOKEN

%start program

%%
/* Program units */
program : declaration_list funct_def decl_and_def_list
        | funct_def decl_and_def_list
        ;

decl_and_def_list : decl_and_def_list funct_def
                  | decl_and_def_list declaration
                  |
                  ;

declaration_list : declaration_list declaration
                 | declaration
                 ;

declaration : const_decl
            | var_decl
            | funct_decl
            ;



/* Functions */
funct_decl : type ID L_PARENTHESIS formal_arg_list R_PARENTHESIS SEMICOLON
           | KW_VOID ID L_PARENTHESIS formal_arg_list R_PARENTHESIS SEMICOLON
           | type ID L_PARENTHESIS R_PARENTHESIS SEMICOLON
           | KW_VOID ID L_PARENTHESIS R_PARENTHESIS SEMICOLON
           ;

funct_def : type ID L_PARENTHESIS formal_arg_list R_PARENTHESIS compound_statement
          | KW_VOID ID L_PARENTHESIS formal_arg_list R_PARENTHESIS compound_statement
          | type ID L_PARENTHESIS R_PARENTHESIS compound_statement
          | KW_VOID ID L_PARENTHESIS R_PARENTHESIS compound_statement
          ;

formal_arg_list : formal_arg_list COMMA formal_argument
                | formal_argument
                ;

formal_argument : type var_and_arr_ref
                ;

/* Data types and declaration */
const_decl : KW_CONST type const_list SEMICOLON
          ;

var_decl : type identifier_list SEMICOLON
         ;

type : KW_INT
     | KW_DOUBLE
     | KW_FLOAT
     | KW_STRING
     | KW_BOOL
     ;

identifier_list : identifier_list COMMA identifier
                | identifier
                ;

const_list : const_list COMMA ID ASSIGN literal_const
           | ID ASSIGN literal_const

identifier : ID
           | ID ASSIGN expression
           | ID array_subscript
           | ID array_subscript ASSIGN array_initial
           ;
/* array[n]*/
array_subscript : array_subscript L_BRACKET expression R_BRACKET
                 | L_BRACKET expression R_BRACKET
                 ;

array_initial : L_BRACE expression_list R_BRACE
              | L_BRACE R_BRACE
              ;

expression_list : expression_list COMMA expression
                | expression
                ;

/* Statements */
statement : simple_statement
          | conditional_statement
          | while_statement
          | for_statement
          | jump_statement
          ;

simple_statement : var_and_arr_ref ASSIGN expression SEMICOLON
                 | KW_READ var_and_arr_ref SEMICOLON
                 | KW_PRINT expression SEMICOLON
                 | funct_invocation SEMICOLON
                 ;

conditional_statement : KW_IF L_PARENTHESIS expression R_PARENTHESIS compound_statement KW_ELSE compound_statement
                      | KW_IF L_PARENTHESIS expression R_PARENTHESIS compound_statement
                      ;

while_statement : KW_WHILE L_PARENTHESIS expression R_PARENTHESIS compound_statement
                | KW_DO compound_statement KW_WHILE L_PARENTHESIS expression R_PARENTHESIS SEMICOLON
                ;

for_statement : KW_FOR L_PARENTHESIS for_expression SEMICOLON for_expression SEMICOLON for_expression R_PARENTHESIS compound_statement
              ;

jump_statement : KW_RETURN expression SEMICOLON
               | KW_BREAK SEMICOLON
               | KW_CONTINUE SEMICOLON
               ;

funct_invocation : ID L_PARENTHESIS R_PARENTHESIS /* f(a,b) */
                 | ID L_PARENTHESIS expression_list R_PARENTHESIS
                 ;

compound_statement : L_BRACE stmt_and_decl_list R_BRACE
                   | L_BRACE R_BRACE
                   ;

stmt_and_decl_list : stmt_and_decl_list statement
                   | stmt_and_decl_list declaration
                   | statement
                   | declaration
                   ;

var_and_arr_ref : ID
                | ID array_subscript
                ;

for_expression:
              | expression
              | var_and_arr_ref ASSIGN expression
              ;

expression : SUB expression %prec NEGATIVE
           | expression ADD expression
           | expression SUB expression
           | expression MUL expression
           | expression DIV expression
           | expression MOD expression
           | expression AND expression
           | expression OR expression
           | expression GT expression
           | expression GE expression
           | expression LE expression
           | expression LT expression
           | expression EQ expression
           | expression NE expression
           | L_PARENTHESIS expression R_PARENTHESIS
           | var_and_arr_ref
           | literal_const
           | funct_invocation
           ;


literal_const : INTEGER
              | FLOAT_NUM
              | SCIENTIFIC
              | boolean_val
              | STRING_TOKEN
              ;

boolean_val : KW_TRUE
            | KW_FALSE
            ;

%%

int yyerror( char *msg )
{
  fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
    fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
    fprintf( stderr, "|\n" );
    fprintf( stderr, "| Unmatched token: %s\n", yytext );
  fprintf( stderr, "|--------------------------------------------------------------------------\n" );
  exit(-1);
}

int main( int argc, char **argv )
{
    if( argc != 2 ) {
        fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
        exit(0);
    }

    FILE *fp = fopen( argv[1], "r" );
    
    if( fp == NULL )  {
        fprintf( stdout, "Open  file  error\n" );
        exit(-1);
    }
    
    yyin = fp;
    yyparse();

    fprintf( stdout, "\n" );
    fprintf( stdout, "|--------------------------------|\n" );
    fprintf( stdout, "|  There is no syntactic error!  |\n" );
    fprintf( stdout, "|--------------------------------|\n" );
    exit(0);
}
