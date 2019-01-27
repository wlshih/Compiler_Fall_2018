#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LEVEL_SIZE_MAX 100 // symbol table
#define ENTRY_NUM_MAX 100
#define NAME_SIZE_MAX 32 // identifiers
#define STR_BUF_MAX 60
#define LIST_SIZE_MAX 10 // parameters, array nums

extern int Opt_Symbol;
extern int current_level;
extern int funct_def;
extern int funct_call;
extern int arr_init_cnt;
extern int loop;
//extern char* decl_kind;
extern char* decl_type;
extern char* rtrn_type;
extern int isreturn;
extern int name_decl_linenum; // from lex
extern int debug;

typedef struct _SYMBOL_TABLE SYMBOL_TABLE;
typedef struct _TABLE_ENTRY TABLE_ENTRY;
typedef struct _NODE NODE;
typedef struct _LIST LIST;
//typedef _TYPE TYPE;
//typedef _ATTRIBUTE ATTRIBUTE;

struct _SYMBOL_TABLE {
    //int current_level;
    int* size; //[level]
    //int capacity;
    TABLE_ENTRY** entry; // [level][entry]
};

struct _TABLE_ENTRY {
    char name[NAME_SIZE_MAX];
    char kind[STR_BUF_MAX];
    char level[STR_BUF_MAX];
    char type[STR_BUF_MAX];
    char attr[STR_BUF_MAX];
    // char const_val[STR_BUF_MAX];
    // char parameter[LIST_SIZE_MAX][STR_BUF_MAX];
    // int par_cnt;
    int isdefined;
};

SYMBOL_TABLE table;

struct _LIST {
    int size;
    char* name[LIST_SIZE_MAX];
    char* type[LIST_SIZE_MAX]; // array of pointers to a string(type)
};

LIST par_list;

struct _NODE {
    char* name;
    char* type;
    int value;
    double dvalue;
    char* svalue; // string value
    //LIST* par_list;
    // int dim;
    // int* arr_num;
    int opr;
    NODE* opd1;
    NODE* opd2;
};

void symbol_table_init();
void pop_symbol_table();
void push_symbol_table();
//void push_table_entry(TABLE_ENTRY* e);
void dump_symbol_table();

void insert_table_entry(char* name, char* kind, NODE* n);
void build_const_attr(char* const_val, NODE* n);
void build_funct_attr(char* attr);

//TABLE_ENTRY* new_entry(char* name);
//void build_var(TABLE_ENTRY* e);
//void build_const(TABLE_ENTRY* e, NODE* n);

NODE* new_node();
NODE* new_expr_node(int opr, NODE* opd1, NODE* opd2);

LIST* new_list();
void par_list_init();
void insert_list(LIST* list, char* name, char* type);
void clean_list(LIST* list);

void array(int num, NODE* n);
int isarray(char* type);
int arr_ref(char* name, int dim, NODE* ref);

int isconst(char* name);
char* get_attr(char* name);

char* var_type(char* name);
char* funct_type(char* name);
char* const_type(char* name);
char* expr_type(int opr, char* t1, char* t2);
void assign_type_check(NODE* d, NODE* s);
void par_type_check(char* name, LIST* list);
void init_type_check(char* type);

void type_coercion(char* t1, char* t2, int assign);


int err_redecl(char* name);
int err_funct_undef();
int err_arr_init(char* name);
int err_undecl(char* name, char* kind);
int err_invalid_ref(char* type);
int err_invalid_opd(int opr);
int err_incomp_type();
int err_incomp_arg_type(int argc);
int err_const_assign(char* name);
int err_cond_type(char* type);
int err_jump_stmt();
int err_rtrn_type(char* type);
int err_rtrn_last();

void dump_err_msg(char* msg);

/*
    function return -> the last statement has to be return
    array type coercion
*/