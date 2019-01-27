%{
#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>


extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];

int current_level = 0;
int funct_def = 0;
int funct_call = 0;
int loop = 0;
int arr_init_cnt = 0;
char* decl_type;
char* rtrn_type;
int isreturn = 0;

int debug = 0;

int yylex();
int yyerror( char *msg );

%}

%union {
  int val;
  int op;
  double dval;
  char* str;
  struct _NODE* node;
  struct _LIST* list;
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

%type <node> logical_expression
%type <node> logical_term
%type <node> logical_factor
%type <node> relation_expression
%type <op> relation_operator
%type <node> arithmetic_expression
%type <node> term
%type <node> factor

%type <node> variable_reference
%type <node> array_list
%type <val> dimension

%type <list> logical_expression_list

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

program : decl_list funct_def decl_and_def_list
          {
              err_funct_undef();
              dump_symbol_table();
          }
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
/* return */
funct_def : scalar_type ID L_PAREN R_PAREN { rtrn_type = strdup($1); } compound_statement
            {
                funct_def = 1;debug++;
                decl_type = strdup($1);
                insert_table_entry($2, "function", NULL);
                funct_def = 0;
                err_rtrn_last();
            }
          | scalar_type ID L_PAREN parameter_list R_PAREN { rtrn_type = strdup($1); } compound_statement
            {
                funct_def = 1;debug++;
                decl_type = strdup($1);
                insert_table_entry($2, "function", NULL);
                funct_def = 0;
                free($4);
                err_rtrn_last();
            }
          | VOID ID L_PAREN R_PAREN { rtrn_type = strdup($1); } compound_statement
            {
                funct_def = 1;debug++;
                decl_type = strdup("void");
                insert_table_entry($2, "function", NULL);
                funct_def = 0;
            }
          | VOID ID L_PAREN parameter_list R_PAREN { rtrn_type = strdup($1); } compound_statement
            {
                funct_def = 1;debug++;
                decl_type = strdup("void");
                insert_table_entry($2, "function", NULL);
                funct_def = 0;
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
                      err_arr_init($3->name);
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
                      err_arr_init($1->name);
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
/* for array init */
literal_list : literal_list COMMA logical_expression { arr_init_cnt -= 1; init_type_check($3->type); }
             | logical_expression { arr_init_cnt -= 1; init_type_check($1->type); }
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

array_decl : ID dim
             {
                $$ = new_node();
                $$->type = strdup($2->type);
                $$->name = strdup($1);
             }

dim : dim ML_BRACE INT_CONST MR_BRACE
      {
          array($3, $1);
          arr_init_cnt *= $3;
      }
    | ML_BRACE INT_CONST MR_BRACE
      {
          $$ = new_node();
          $$->type = strndup(decl_type, STR_BUF_MAX);
          array($2, $$);
          arr_init_cnt = $2;
      }
    ;

compound_statement : L_BRACE
                     push_level
                     var_const_stmt_list R_BRACE
                     pop_level
                   ;

var_const_stmt_list : var_const_stmt_list statement 
                    | var_const_stmt_list var_decl { isreturn = 0; }
                    | var_const_stmt_list const_decl { isreturn = 0; }
                    |
                    ;

statement : compound_statement
          | simple_statement { isreturn = 0; }
          | conditional_statement { isreturn = 0; }
          | while_statement { isreturn = 0; }
          | for_statement { isreturn = 0; }
          | function_invoke_statement { isreturn = 0; }
          | jump_statement
          ;     

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON { assign_type_check($1, $3); }
                 | PRINT logical_expression SEMICOLON { err_invalid_ref($2->type); }
                 | READ variable_reference SEMICOLON { err_invalid_ref($2->type); }
                 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN L_BRACE
                        push_level
                        var_const_stmt_list R_BRACE
                        pop_level { err_cond_type($3->type); }
                      | IF L_PAREN logical_expression R_PAREN L_BRACE
                        push_level
                        var_const_stmt_list R_BRACE
                        ELSE L_BRACE var_const_stmt_list R_BRACE
                        pop_level { err_cond_type($3->type); }
                      ;

while_statement : WHILE { loop += 1; } L_PAREN logical_expression R_PAREN L_BRACE 
                  push_level
                  var_const_stmt_list R_BRACE
                  pop_level { loop -= 1; }
                | DO { loop += 1; } L_BRACE
                  push_level
                  var_const_stmt_list
                  R_BRACE
                  pop_level { loop -= 1; }
                  WHILE L_PAREN logical_expression R_PAREN SEMICOLON
                ;

for_statement : FOR { loop += 1; }L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN L_BRACE
                push_level
                var_const_stmt_list R_BRACE
                pop_level { loop -= 1; }
              ;

push_level : { push_symbol_table(); }
           ;

pop_level : { pop_symbol_table();} 
          ;

initial_expression_list : initial_expression
                        |
                        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression { assign_type_check($3, $5); }
                   | initial_expression COMMA logical_expression
                   | logical_expression { err_cond_type($1->type); }
                   | variable_reference ASSIGN_OP logical_expression { assign_type_check($1, $3); }

control_expression_list : control_expression
                        |
                        ;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression { assign_type_check($3, $5); }
                   | control_expression COMMA logical_expression
                   | logical_expression { err_cond_type($1->type); }
                   | variable_reference ASSIGN_OP logical_expression { assign_type_check($1, $3); }
                   ;

increment_expression_list : increment_expression 
                          |
                          ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression { assign_type_check($3, $5); }
                     | increment_expression COMMA logical_expression
                     | logical_expression { err_cond_type($1->type); }
                     | variable_reference ASSIGN_OP logical_expression { assign_type_check($1, $3); }
                     ;

function_invoke_statement : ID L_PAREN { funct_call = 1; } logical_expression_list R_PAREN SEMICOLON
                            { par_type_check($1, $4); funct_call = 0; }
                          | ID L_PAREN R_PAREN SEMICOLON { par_type_check($1, new_list()); }
                          ;

jump_statement : CONTINUE SEMICOLON { err_jump_stmt(); isreturn = 0; }
               | BREAK SEMICOLON { err_jump_stmt(); isreturn = 0; }
               | RETURN logical_expression SEMICOLON { err_rtrn_type($2->type); isreturn = 1; }
               ;
/**/
variable_reference : array_list
                     {
                         $$ = new_node();
                         $$->name = $1->name;
                         $$->type = $1->type;
                     }
                   | ID
                     {
                         $$ = new_node();
                         $$->name = $1;
                         $$->type = var_type($1);
                         if($$->type == NULL) err_undecl($1, "variable");
                     }
                   ;

/* type checking, functioin invocation */
logical_expression : logical_expression OR_OP logical_term { $$ = new_expr_node(OR_OP, $1, $3); }
                   | logical_term { $$ = $1; }
                   ;

logical_term : logical_term AND_OP logical_factor { $$ = new_expr_node(AND_OP, $1, $3); }
             | logical_factor { $$ = $1; }
             ;

logical_factor : NOT_OP logical_factor { $$ = new_expr_node(NOT_OP, $2, NULL); }
               | relation_expression { $$ = $1; }
               ;

relation_expression : relation_expression relation_operator arithmetic_expression { $$ = new_expr_node($2, $1, $3);}
                    | arithmetic_expression { $$ = $1; }
                    ;

relation_operator : LT_OP { $$ = LT_OP; }
                  | LE_OP { $$ = LE_OP; }
                  | EQ_OP { $$ = EQ_OP; }
                  | GE_OP { $$ = GE_OP; }
                  | GT_OP { $$ = GT_OP; }
                  | NE_OP { $$ = NE_OP; }
                  ;

arithmetic_expression : arithmetic_expression ADD_OP term { $$ = new_expr_node(ADD_OP, $1, $3); }
                      | arithmetic_expression SUB_OP term { $$ = new_expr_node(SUB_OP, $1, $3); }
                      | term { $$ = $1; }
                      ;

term : term MUL_OP factor { $$ = new_expr_node(MUL_OP, $1, $3); }
     | term DIV_OP factor { $$ = new_expr_node(DIV_OP, $1, $3); }
     | term MOD_OP factor { $$ = new_expr_node(MOD_OP, $1, $3); }
     | factor { $$ = $1; }
     ;

factor : SUB_OP factor { $$ = new_expr_node(SUB_OP, $2, NULL); }
       | literal_const { $$ = $1; }
       | variable_reference { $$ = $1; }
       | L_PAREN logical_expression R_PAREN { $$ = $2; }
       | ID L_PAREN { funct_call = 1; } logical_expression_list R_PAREN
         {
             $$ = new_node();
             $$->name = strdup($1);
             $$->type = funct_type($1);
             par_type_check($1, $4);
             funct_call = 0;
         }
       | ID L_PAREN R_PAREN
         {
            $$ = new_node();
            $$->name = strdup($1);
            $$->type = funct_type($1);
            par_type_check($1, new_list());
         }
       ;
/* for function arguments */
logical_expression_list : logical_expression_list COMMA logical_expression { insert_list($$, "", $3->type); }
                        | logical_expression { $$ = new_list(); insert_list($$, "", $1->type); }
                        ;

array_list : ID dimension
             {
                 $$ = new_node();
                 arr_ref($1, $2, $$);
             }
           ;

dimension : dimension ML_BRACE logical_expression MR_BRACE { $$ = $1 + 1; }     
          | ML_BRACE logical_expression MR_BRACE { $$ = 1; }
          ;



scalar_type : INT { decl_type = strdup("int"); }
            | DOUBLE { decl_type = strdup("double"); }
            | STRING { decl_type = strdup("string"); }
            | BOOL { decl_type = strdup("bool"); }
            | FLOAT { decl_type = strdup("float"); }
            ;
 
literal_const : INT_CONST { $$ = new_node(); $$->value = $1; $$->type = strdup("int"); }
              | FLOAT_CONST { $$ = new_node(); $$->dvalue = $1; $$->type = strdup("float"); }
              | SCIENTIFIC { $$ = new_node(); $$->dvalue = $1; $$->type = strdup("float"); }
              | STR_CONST { $$ = new_node(); $$->svalue = $1; $$->type = strdup("string"); }
              | TRUE { $$ = new_node(); $$->value = 1; $$->type = strdup("bool"); }
              | FALSE { $$ = new_node(); $$->value = 0; $$->type = strdup("bool"); }
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


