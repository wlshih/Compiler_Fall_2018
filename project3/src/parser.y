%{
#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>


extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];

int current_level;
char* decl_type;

int yylex();
int yyerror( char *msg );

%}

%union {
  int val;
  int op;
  double dval;
  char* str;
  struct _NODE* node;
}

%token <str> ID
%token <val> INT_CONST
%token <dval> FLOAT_CONST
%token <dval> SCIENTIFIC
%token <str> STR_CONST

%token <op> LE_OP
%token <op> NE_OP
%token <op> GE_OP
%token <op> EQ_OP
%token <op> AND_OP
%token <op> OR_OP

%token <str> READ
%token <str> PRINT
%token <str> BOOLEAN
%token <str> WHILE
%token <str> DO
%token <str> IF
%token <str> ELSE
%token <val> TRUE
%token <val> FALSE
%token <str> FOR
%token <str> INT
%token <str> BOOL
%token <str> VOID
%token <str> FLOAT
%token <str> DOUBLE
%token <str> STRING
%token <str> CONTINUE
%token <str> BREAK
%token <str> RETURN
%token <str> CONST

%token <str> L_PAREN
%token <str> R_PAREN
%token <str> COMMA
%token <str> SEMICOLON
%token <str> ML_BRACE
%token <str> MR_BRACE
%token <str> L_BRACE
%token <str> R_BRACE
%token <op> ADD_OP
%token <op> SUB_OP
%token <op> MUL_OP
%token <op> DIV_OP
%token <op> MOD_OP
%token <op> ASSIGN_OP
%token <op> LT_OP
%token <op> GT_OP
%token <op> NOT_OP
/*
%type <type> scalar_type
%type <type> funct_def
%type <type> funct_decl
%type <type> parameter_list
%type <type> var_decl
*/
%type <str> scalar_type
%type <node> parameter_list
%type <node> array_decl
%type <node> dim
%type <node> literal_const

/*  Program 
    Function 
    Array 
    Const 
    IF 
    ELSE 
    RETURN 
    FOR 
    WHILE
*/
%start program
%%

program : decl_list funct_def decl_and_def_list { dump_symbol_table(); }
        ;

decl_list : decl_list var_decl
          | decl_list const_decl
          | decl_list funct_decl
          |
          ;


decl_and_def_list : decl_and_def_list var_decl
                  | decl_and_def_list const_decl
                  | decl_and_def_list funct_decl
                  | decl_and_def_list funct_def
                  | 
                  ;
/**/
funct_def : scalar_type ID L_PAREN R_PAREN compound_statement
            {
                decl_type = strdup($1);
                insert_table_entry($2, "function", NULL);
            }
          | scalar_type ID L_PAREN parameter_list R_PAREN  compound_statement
            {
                decl_type = strdup($1);
                insert_table_entry($2, "function", NULL);
                free($4);
            }
          | VOID ID L_PAREN R_PAREN compound_statement
            {
                decl_type = strdup($1);
                insert_table_entry($2, "function", NULL);
            }
          | VOID ID L_PAREN parameter_list R_PAREN compound_statement
            {
                decl_type = strdup($1);
                insert_table_entry($2, "function", NULL);
                free($4);
            }
          ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
             {
                 decl_type = strdup($1);
                 insert_table_entry($2, "function", NULL);
             }
           | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
             {
                 decl_type = strdup($1);
                 insert_table_entry($2, "function", NULL);
             }
           | VOID ID L_PAREN R_PAREN SEMICOLON
             {
                 decl_type = strdup($1);
                 insert_table_entry($2, "function", NULL);
             }
           | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
             {
                 decl_type = strdup($1);
                 insert_table_entry($2, "function", NULL);
             }
           ;

parameter_list : parameter_list COMMA scalar_type ID
                 {
                     insert_list(&par_list, $4, $3);
                 }
               | parameter_list COMMA scalar_type array_decl
                 {
                     insert_list(&par_list, $4->name, $4->type);
                 }
               | scalar_type array_decl
                 {
                     insert_list(&par_list, $2->name, $2->type);
                 }
               | scalar_type ID
                 {
                     insert_list(&par_list, $2, $1);
                 }
               ;
/*ok*/
var_decl : scalar_type identifier_list SEMICOLON { free(decl_type); }
         ;

identifier_list : identifier_list COMMA ID
                  {
                      insert_table_entry($3, "variable", NULL);
                  }
                | identifier_list COMMA ID ASSIGN_OP logical_expression
                  {
                      insert_table_entry($3, "variable", NULL);
                  }
                | identifier_list COMMA array_decl ASSIGN_OP initial_array
                  {
                      insert_table_entry($3->name, "variable", $3);
                      free($3);
                  }
                | identifier_list COMMA array_decl
                  {
                      insert_table_entry($3->name, "variable", $3);
                      free($3);
                  }
                | array_decl ASSIGN_OP initial_array
                  {
                      insert_table_entry($1->name, "variable", $1);
                      free($1);
                  }
                | array_decl
                  {
                      insert_table_entry($1->name, "variable", $1);
                      free($1);
                  }
                | ID ASSIGN_OP logical_expression
                  {
                      insert_table_entry($1, "variable", NULL);
                  }
                | ID
                  {
                      insert_table_entry($1, "variable", NULL);
                  }
                ;

initial_array : L_BRACE literal_list R_BRACE
              ;

literal_list : literal_list COMMA logical_expression
             | logical_expression
             | 
             ;
/*ok*/
const_decl : CONST scalar_type const_list SEMICOLON { free(decl_type); }
           ;

const_list : const_list COMMA ID ASSIGN_OP literal_const
             {
                 insert_table_entry($3, "constant", $5);
                 free($5);
             }
           | ID ASSIGN_OP literal_const
             {
                 insert_table_entry($1, "constant", $3);
                 free($3);
             }
           ;
/************what's the problem************/
array_decl : ID dim
             {
                //printf("************%s %s*************\n", $2->type, $1);
                $$ = new_node();
                $$->type = strdup($2->type);
                $$->name = strdup($1);
                //printf("************%s %s*************\n", $$->type, $$->name);
             }
/************?????????????????*************/
dim : dim ML_BRACE INT_CONST MR_BRACE
      {
          
          array($3, $1->type);
          //printf("\n-----------------%s--------------\n\n", $$->type);
      }
    | ML_BRACE INT_CONST MR_BRACE
      {
          $$ = new_node();
          $$->type = strndup(decl_type, STR_BUF_MAX);
          array($2, $$->type);
          //printf("\n-----------------%s--------------\n\n", $$->type);
      }
    ;

compound_statement : L_BRACE
                     push_level
                     var_const_stmt_list R_BRACE
                     pop_level
                   ;

var_const_stmt_list : var_const_stmt_list statement 
                    | var_const_stmt_list var_decl
                    | var_const_stmt_list const_decl
                    |
                    ;

statement : compound_statement
          | simple_statement
          | conditional_statement
          | while_statement
          | for_statement
          | function_invoke_statement
          | jump_statement
          ;     

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON
                 | PRINT logical_expression SEMICOLON
                 | READ variable_reference SEMICOLON
                 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN L_BRACE 
                        push_level
                        var_const_stmt_list R_BRACE
                        pop_level
                      | IF L_PAREN logical_expression R_PAREN L_BRACE
                        push_level
                        var_const_stmt_list R_BRACE
                        ELSE L_BRACE var_const_stmt_list R_BRACE
                        pop_level
                      ;

while_statement : WHILE L_PAREN logical_expression R_PAREN L_BRACE 
                  push_level
                  var_const_stmt_list R_BRACE
                  pop_level
                | DO L_BRACE
                  push_level
                  var_const_stmt_list
                  R_BRACE
                  pop_level
                  WHILE L_PAREN logical_expression R_PAREN SEMICOLON
                ;

for_statement : FOR L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN L_BRACE
                push_level
                var_const_stmt_list R_BRACE
                pop_level
              ;

push_level : { push_symbol_table(); }
           ;

pop_level : { pop_symbol_table();} 
          ;

initial_expression_list : initial_expression
                        |
                        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | initial_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression

control_expression_list : control_expression
                        |
                        ;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | control_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression
                   ;

increment_expression_list : increment_expression 
                          |
                          ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression
                     | increment_expression COMMA logical_expression
                     | logical_expression
                     | variable_reference ASSIGN_OP logical_expression
                     ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
                          | ID L_PAREN R_PAREN SEMICOLON
                          ;

jump_statement : CONTINUE SEMICOLON
               | BREAK SEMICOLON
               | RETURN logical_expression SEMICOLON
               ;

variable_reference : array_list
                   | ID
                   ;


logical_expression : logical_expression OR_OP logical_term
                   | logical_term
                   ;

logical_term : logical_term AND_OP logical_factor
             | logical_factor
             ;

logical_factor : NOT_OP logical_factor
               | relation_expression
               ;

relation_expression : relation_expression relation_operator arithmetic_expression
                    | arithmetic_expression
                    ;

relation_operator : LT_OP
                  | LE_OP
                  | EQ_OP
                  | GE_OP
                  | GT_OP
                  | NE_OP
                  ;

arithmetic_expression : arithmetic_expression ADD_OP term
                      | arithmetic_expression SUB_OP term
                      | term
                      ;

term : term MUL_OP factor
     | term DIV_OP factor
     | term MOD_OP factor
     | factor
     ;

factor : SUB_OP factor
       | literal_const
       | variable_reference
       | L_PAREN logical_expression R_PAREN
       | ID L_PAREN logical_expression_list R_PAREN
       | ID L_PAREN R_PAREN
       ;

logical_expression_list : logical_expression_list COMMA logical_expression
                        | logical_expression
                        ;

array_list : ID dimension
           ;

dimension : dimension ML_BRACE logical_expression MR_BRACE         
          | ML_BRACE logical_expression MR_BRACE
          ;



scalar_type : INT { decl_type = strdup("int"); }
            | DOUBLE { decl_type = strdup("double"); }
            | STRING { decl_type = strdup("string"); }
            | BOOL { decl_type = strdup("bool"); }
            | FLOAT { decl_type = strdup("float"); }
            ;
 
literal_const : INT_CONST { $$ = new_node(); $$->value = $1; }
              | FLOAT_CONST { $$ = new_node(); $$->dvalue = $1; }
              | SCIENTIFIC { $$ = new_node(); $$->dvalue = $1; }
              | STR_CONST { $$ = new_node(); $$->svalue = $1; }
              | TRUE { $$ = new_node(); $$->value = 1; }
              | FALSE { $$ = new_node(); $$->value = 0; }
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
    //  fprintf( stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext );
}


