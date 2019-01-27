#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LEVEL_SIZE_MAX 100
#define ENTRY_NUM_MAX 100
#define NAME_SIZE_MAX 32
#define STR_BUF_MAX 50
#define LIST_SIZE_MAX 10

extern int Opt_Symbol;
extern int current_level;
//extern char* decl_kind;
extern char* decl_type;
extern int name_decl_linenum; // from lex

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
    //int isdefined;
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
};

void symbol_table_init();
void pop_symbol_table();
void push_symbol_table();
//void push_table_entry(TABLE_ENTRY* e);
void dump_symbol_table();

void insert_table_entry(char* name, char* kind, NODE* n);
void build_const_attr(char* attr, NODE* n);
void build_funct_attr(char* attr);

//TABLE_ENTRY* new_entry(char* name);
//void build_var(TABLE_ENTRY* e);
//void build_const(TABLE_ENTRY* e, NODE* n);

NODE* new_node();
//LIST* new_list();
void par_list_init();
void insert_list(LIST* list, char* name, char* type);
void clean_list(LIST* list);

void array(int num, char* type);

int err_redecl(char* name);