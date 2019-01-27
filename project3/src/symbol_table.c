#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void symbol_table_init() {
    int i, j;
    // allocate memory
    table.size = (int*)malloc(LEVEL_SIZE_MAX * sizeof(int));

    table.entry = (TABLE_ENTRY**)malloc(LEVEL_SIZE_MAX * sizeof(TABLE_ENTRY*));
    for(i=0; i<LEVEL_SIZE_MAX; i++) {
        table.entry[i] = (TABLE_ENTRY*)malloc(ENTRY_NUM_MAX * sizeof(TABLE_ENTRY));
    }
    // set memory
    memset(table.size, 0, sizeof(int) * LEVEL_SIZE_MAX);

    for(i=0; i<LEVEL_SIZE_MAX; i++) {
        for(j=0; j<ENTRY_NUM_MAX; j++) {
            memset(table.entry[i][j].name, 0, sizeof(table.entry[i][j].name));
            memset(table.entry[i][j].kind, 0, sizeof(table.entry[i][j].kind));
            memset(table.entry[i][j].level, 0, sizeof(table.entry[i][j].level));
            memset(table.entry[i][j].type, 0, sizeof(table.entry[i][j].type));
            memset(table.entry[i][j].attr, 0, sizeof(table.entry[i][j].attr));
            //table.entry[i][j].isdefined = 0;
        }
    }

    current_level = 0;
}

void pop_symbol_table() {
    int j;
    // dump symbol table
    if(Opt_Symbol) {
        dump_symbol_table();
    }
    for(j=0; j<ENTRY_NUM_MAX; j++) {
        memset(table.entry[current_level][j].name, 0, sizeof(table.entry[current_level][j].name));
        memset(table.entry[current_level][j].kind, 0, sizeof(table.entry[current_level][j].kind));
        memset(table.entry[current_level][j].level, 0, sizeof(table.entry[current_level][j].level));
        memset(table.entry[current_level][j].type, 0, sizeof(table.entry[current_level][j].type));
        memset(table.entry[current_level][j].attr, 0, sizeof(table.entry[current_level][j].attr));
        //table.entry[current_level][j].isdefined = 0;
    }
    table.size[current_level] = 0;
    current_level -= 1;
}

void push_symbol_table() {
    int i;
    current_level += 1;
    // insert parameter entries
    for(i=0; i<par_list.size; i++) {
    	decl_type = par_list.type[i];
        insert_table_entry(par_list.name[i], "parameter", NULL);
    }
}

void dump_symbol_table() {
    int j;
    if(!Opt_Symbol) {
        return;
    }
    printf("=======================================================================================\n");
    printf("%-33s%-11s%-12s%-19s%-24s\n", "Name", "Kind", "Level", "Type", "Attribute");
    printf("---------------------------------------------------------------------------------------\n");
    for(j=0; j<table.size[current_level]; j++) {
        printf("%-33s", table.entry[current_level][j].name);
        printf("%-11s", table.entry[current_level][j].kind);
        printf("%-12s", table.entry[current_level][j].level);
        printf("%-19s", table.entry[current_level][j].type);
        printf("%-24s", table.entry[current_level][j].attr);
        printf("\n");
    }
    printf("======================================================================================\n");
}
/*
void push_table_entry(TABLE_ENTRY* e) {
    int j = table.size[current_level];
    strncpy(table.entry[current_level][j].name, e->name, NAME_SIZE_MAX);
    strncpy(table.entry[current_level][j].kind, e->kind, STR_BUF_MAX);
    strncpy(table.entry[current_level][j].level, e->level, STR_BUF_MAX);
    strncpy(table.entry[current_level][j].type, e->type, STR_BUF_MAX);
    strncpy(table.entry[current_level][j].attr, e->attr, STR_BUF_MAX);
    table.size[current_level] += 1;
}
*/
// parameter insertions are called by push_symbol_table() automatically, with error detection
void insert_table_entry(char* name, char* kind, NODE* n) {
    // error detect
    if(err_redecl(name)) {
        return;
    }
    int j = table.size[current_level];
    char level[STR_BUF_MAX];
    char type[STR_BUF_MAX];
    char attr[STR_BUF_MAX];
    memset(level, 0, sizeof(level));
    memset(type, 0, sizeof(type));
    memset(attr, 0, sizeof(attr));
    // level
    sprintf(level, "%d", current_level);
    if(current_level == 0) {
        strncat(level, "(global)", STR_BUF_MAX);
    }
    else {
        strncat(level, "(local)", STR_BUF_MAX);
    }
    // type
    if(n == NULL || n->type == NULL) {
        strncpy(type, decl_type, STR_BUF_MAX);
    }
    else {
        strncpy(type, n->type, STR_BUF_MAX);
    }
    // attr
    if(strcmp(kind, "constant") == 0) {
        build_const_attr(attr, n);
    }
    else if(strcmp(kind, "function") == 0 && par_list.size != 0) {
        build_funct_attr(attr);
    }
    // insertion
    strncpy(table.entry[current_level][j].name, name, NAME_SIZE_MAX);
    strncpy(table.entry[current_level][j].kind, kind, STR_BUF_MAX);
    strncpy(table.entry[current_level][j].level, level, STR_BUF_MAX);
    strncpy(table.entry[current_level][j].type, type, STR_BUF_MAX);
    strncpy(table.entry[current_level][j].attr, attr, STR_BUF_MAX);
    table.size[current_level] += 1;
}


void build_const_attr(char* attr, NODE* n) {
    if(strcmp(decl_type, "int") == 0 || strcmp(decl_type, "bool") == 0) {
        sprintf(attr, "%d", n->value);
    }
    else if(strcmp(decl_type, "float") == 0 || strcmp(decl_type, "double") == 0) {
        sprintf(attr, "%g", n->dvalue);
    }
    else {
        strncpy(attr, n->svalue, STR_BUF_MAX);
    }
}

void build_funct_attr(char* attr) {
    int i;
    int size = par_list.size;
    strncat(attr, par_list.type[0], STR_BUF_MAX);
    for(i=1; i<size; i++) {
        strncat(attr, ",", STR_BUF_MAX);
        strncat(attr, par_list.type[i], STR_BUF_MAX);
    }
    clean_list(&par_list);
}


/*
TABLE_ENTRY* new_entry(char* name) {
    TABLE_ENTRY* new = (TABLE_ENTRY*)malloc(sizeof(TABLE_ENTRY));
    memset(new->name, 0, sizeof(new->name));
    memset(new->kind, 0, sizeof(new->kind));
    memset(new->level, 0, sizeof(new->level));
    memset(new->type, 0, sizeof(new->type));
    memset(new->attr, 0, sizeof(new->attr));
    new->isdefined = 1;
    // name
    strncpy(new->name, name, NAME_SIZE_MAX);
    // level
    new->level[0] = current_level + '0';
    if(current_level == 0) {
        strncat(new->level, "(global)", STR_BUF_MAX);
    }
    else {
        strncat(new->level, "(local)", STR_BUF_MAX);
    }
    // type
    strncpy(new->type, decl_type, STR_BUF_MAX);

    return new;
}

void build_var(TABLE_ENTRY* e) {
    // kind
    strncpy(e->kind, "variable", STR_BUF_MAX);
}

void build_const(TABLE_ENTRY* e, NODE* n) {
    // kind
    strncpy(e->kind, "constant", STR_BUF_MAX);
    // attribute
    if(strcmp(decl_type, "int") == 0 || strcmp(decl_type, "bool") == 0) {
        sprintf(e->attr, "%d", n->value);
    }
    else if(strcmp(decl_type, "float") == 0 || strcmp(decl_type, "double") == 0) {
        sprintf(e->attr, "%g", n->dvalue);
    }
    else {
        strncpy(e->attr, n->str, STR_BUF_MAX);
    }
}
*/
NODE* new_node() {
    NODE* new = (NODE*)malloc(sizeof(NODE));
    new->name = NULL;
    new->type = NULL;
    new->value = 0;
    new->dvalue = 0;
    new->svalue = NULL;
    //new->par_list = NULL;

    return new;
}
/*
LIST* new_list() {
    LIST* new = (LIST*)malloc(sizeof(LIST));
    memset(new->type, 0, sizeof(new->type));
    memset(new->name, 0, sizeof(new->name));
    new->size = 0;

    return new;
}
*/
void par_list_init() {
    int i;
    for(i=0; i<LIST_SIZE_MAX; i++) {
        par_list.name[i] = NULL;
        par_list.type[i] = NULL;
    }
    par_list.size = 0;
}
void insert_list(LIST* list, char* name, char* type) {
    int i = list->size;
    list->name[i] = strdup(name);
    list->type[i] = strdup(type);
    list->size += 1;
}
void clean_list(LIST* list) {
    int i;
    for(i=0; i<list->size; i++) {
        free(list->name[i]);
        free(list->type[i]);
    }
    list->size = 0;
}

void array(int num, char* type) {
    char buf[STR_BUF_MAX];
    sprintf(buf, "%d", num);
    strncat(type, "[", STR_BUF_MAX);
    strncat(type, buf, STR_BUF_MAX);
    strncat(type, "]", STR_BUF_MAX);
    //printf("[len: %d num: %c]\n", i, type[i+1]);
}

int err_redecl(char* name) {
    int j;
    int size = table.size[current_level];
    for(j=0; j<size; j++) {
        if(strcmp(table.entry[current_level][j].name, name) == 0) {
            char err_msg[STR_BUF_MAX];
            strncpy(err_msg, name, NAME_SIZE_MAX);
            strncat(err_msg, " redeclared.", STR_BUF_MAX-NAME_SIZE_MAX);
            fprintf(stderr, "##########Error at Line #%d: %s##########\n", name_decl_linenum, err_msg);

            return 1;
        }
    }
    return 0;
}