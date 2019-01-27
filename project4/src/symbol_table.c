#include "symbol_table.h"
#include "y.tab.h"
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
            table.entry[i][j].isdefined = 0;
        }
    }

    current_level = 0;
    funct_def = 0;
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
        table.entry[current_level][j].isdefined = 0;
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
        // printf("%-5d", table.entry[current_level][j].isdefined);
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
    
    int i;
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
    table.entry[current_level][j].isdefined = funct_def;
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
    // new->dim = 0;
    // new->arr_num = NULL;
    new->opr = 0;
    new->opd1 = NULL;
    new->opd2 = NULL;

    return new;
}

// NODE* node_dup(NODE* n) {
//     NODE* dest = (NODE*)malloc(sizeof(NODE));
//     if(n->name) dest->name = strdup(n->name);
//     if(n->type) dest->type = strdup(n->type);
//     dest->value = n->value;
//     dest->dvalue = n->dvalue;
//     if(n->svalue) dest->svalue = strdup(n->svalue);
//     dest->opr = n->opr;
//     if(n->opd1) dest->opd1 = 
// }
// super dirty code
// do not free operands
NODE* new_expr_node(int opr, NODE* opd1, NODE* opd2) {
    NODE* new = new_node(); // new->type = NULL
    new->opr = opr;
    new->opd1 = opd1;
    new->opd2 = opd2;

    // check if undeclared
    if(opd1 != NULL && opd2 != NULL) {
        if(opd1->type == NULL || opd2->type == NULL) {
            return new;
        }
    }
    else if(opd1 != NULL) {
        if(opd1->type == NULL) {
            return new;
        }
    }

    if(opd2 == NULL) {
        new->type = expr_type(opr, opd1->type, "(null)");
    }
    else {
        new->type = expr_type(opr, opd1->type, opd2->type);
    }
    
    // printf("***%s***\n", new->type);
    // if(opd2) printf("%d, %s, %s\n", opr, opd1->type, opd2->type);
    // else printf("%d, %s\n", opr, opd1->type);
    return new;
}

LIST* new_list() {
    LIST* new = (LIST*)malloc(sizeof(LIST));
    memset(new->type, 0, sizeof(new->type));
    memset(new->name, 0, sizeof(new->name));
    new->size = 0;

    return new;
}

// pointers in the list, not arrays
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

void array(int num, NODE* n) {
    char buf[STR_BUF_MAX];
    sprintf(buf, "%d", num);
    strncat(n->type, "[", STR_BUF_MAX);
    strncat(n->type, buf, STR_BUF_MAX);
    strncat(n->type, "]", STR_BUF_MAX);
    //printf("[len: %d num: %c]\n", i, type[i+1]);
    // n->dim += 1;
    // n->arr_num[n->dim-1] = num;
    // printf("(%d, %d)\n", n->dim, n->arr_num[n->dim-1]);
}

int isarray(char* type) {
    return (strchr(type, '[') == NULL) ? 0 : 1;
}
// get array type, reduce to reference type
int arr_ref(char* name, int dim, NODE* ref) { // ref has been malloced, dim > 0 => reference dim
    char* type;
    ref->name = strdup(name);
    type = var_type(name);
    if(type == NULL) { // undeclared
        err_undecl(name, "variable");
        return -1;
    }
    
    // extract type elements
    int i;
    int dim_cnt = 0; // declare dim
    char* buf;
    char scalar_type[STR_BUF_MAX];
    int dimension[LIST_SIZE_MAX];
    strncpy(scalar_type, type, STR_BUF_MAX);

    buf = strtok(scalar_type, "[]");
    while(buf != NULL) {
        buf = strtok(NULL, "[]");
        if(buf) {
            dimension[dim_cnt] = atoi(buf);
            dim_cnt++;
        }
    }

    // reference type
    ref->type = strdup(scalar_type);
    buf = (char*)malloc(STR_BUF_MAX*sizeof(char));
    for(i=dim; i<dim_cnt; i++) {
        sprintf(buf, "[%d]", dimension[i]);
        strncat(ref->type, buf, STR_BUF_MAX);
        // printf("/%s/\n", ref->type);
    }
    if((dim - dim_cnt) > 0) { // invalid access
        // err
        dump_err_msg("invalid access(1)");
        return -1;
    }
    else if((dim - dim_cnt) < 0) { // array access
        if(!funct_call) {
            dump_err_msg("invalid access(2)");
        }
        return 1;
    }
    else
        return 0;
}

int isconst(char* name) {
    int i, j;
    for(i=current_level; i>=0; i--) { // start from smallest scope
        for(j=0; j<table.size[i]; j++) {
            if(strcmp(table.entry[i][j].name, name) == 0) { // name is found
                if(strcmp(table.entry[i][j].kind, "constant") == 0) return 1;
                else return 0;
            }
        }
    }
    return 0; // name not found
}

char* get_attr(char* name) {
    char* attr;
    int i, j;
    for(i=current_level; i>=0; i--) { // start from smallest scope
        for(j=0; j<table.size[i]; j++) {
            if(strcmp(table.entry[i][j].name, name) == 0) { // name is found
                attr = strdup(table.entry[i][j].attr);
                return attr;
            }
        }
    }
    return NULL;    
}

// find var from symbol table
char* var_type(char* name) {
    char* type;
    int i, j;
    for(i=current_level; i>=0; i--) { // start from smallest scope
        for(j=0; j<table.size[i]; j++) {
            if(strcmp(table.entry[i][j].name, name) == 0 && strcmp(table.entry[i][j].kind, "function") != 0) { // variable is found
                type = strdup(table.entry[i][j].type);
                return type;
            }
        }
    }
    return NULL;
}

char* funct_type(char* name) {
    char* type;
    int j;
    for(j=0; j<table.size[0]; j++) { // function must be in global scope
        if(strcmp(table.entry[0][j].name, name) == 0 && strcmp(table.entry[0][j].kind, "function") == 0) { // function is found
            type = strdup(table.entry[0][j].type);
            return type;
        }
    }
    return NULL;
}

char* const_type(char* name) {
    char* type;
    int i, j;
    for(i=current_level; i>=0; i--) { // start from smallest scope
        for(j=0; j<table.size[i]; j++) {
            if(strcmp(table.entry[i][j].name, name) == 0 && strcmp(table.entry[i][j].kind, "constant") == 0) { // constant is found
                type = strdup(table.entry[i][j].type);
                return type;
            }
        }
    }
    return NULL;
}

char* expr_type(int opr, char* t1, char* t2) {
    char* type;
    // type checking, set new->type
    if(strcmp(t2, "(null)") == 0) { // unary expression
        if(strcmp(t1, "(undefined)") == 0) {
            type = strdup("(undefined)");
        }
        else if(strcmp(t1, "string") == 0) {
            err_invalid_opd(opr);
            type = strdup("(undefined)");
        }
        else if(opr == SUB_OP && strcmp(t1, "bool") != 0) {
            type = strdup(t1);
        }
        else if(opr == NOT_OP && strcmp(t1, "bool") == 0) {
            type = strdup("bool");
        }
        else {
            err_invalid_opd(opr);
            type = strdup("(undefined)");
        }
    }
    else { // t1 & t2 != (null)
        if(strcmp(t1, "(undefined)") == 0 || strcmp(t2, "(undefined)") == 0) {
            type = strdup("(undefined)");
        }
        else if(strcmp(t1, "string") == 0 || strcmp(t2, "string") == 0) {
            err_invalid_opd(opr);
            type = strdup("(undefined)");
        }
        else {
            switch(opr) {
                case ADD_OP: // int, float, double -> same
                case SUB_OP:
                case MUL_OP:
                case DIV_OP:
                    if(strcmp(t1, "bool") == 0 || strcmp(t2, "bool") == 0) { // arithmetic bool
                        err_invalid_opd(opr);
                        type = strdup("(undefined)");
                    }
                    else {
                        type_coercion(t1, t2, 0);
                        type = strdup(t1);
                    }
                    break;
                case MOD_OP: // int -> int
                    if(strcmp(t1, "int") == 0 && strcmp(t2, "int") == 0) {
                        type = strdup("int");
                    }
                    else {
                        type = strdup("(undefined)");
                        err_invalid_opd(opr);
                    }
                    break;
                case GT_OP: // int, float, double -> bool
                case GE_OP:
                case LE_OP:
                case LT_OP:
                case EQ_OP:
                case NE_OP:
                    if(strcmp(t1, "bool") == 0 || strcmp(t2, "bool") == 0) { // relational bool
                        type = strdup("(undefined)");
                        err_invalid_opd(opr);
                    }
                    else {
                        type = strdup("bool");
                    }
                    break;
                case AND_OP: // bool -> bool
                case OR_OP:
                    if(strcmp(t1, "bool") == 0 && strcmp(t2, "bool") == 0) {
                        type = strdup("bool");
                    }
                    else {
                        type = strdup("(undefined)");
                        err_invalid_opd(opr);
                    }
                    break;
                default:
                    fprintf(stderr, "error: operator(%d)\n", opr);
            }
        }
    }
    return type;
}

void assign_type_check(NODE* d, NODE* s) {
    // check if undeclared
    if(d->type == NULL || s->type == NULL) {
        return; // don't care
    }
    // type check
    if(isconst(d->name)) { 
         err_const_assign(d->name);
         return;
    }
    if(isarray(d->type) || isarray(s->type)) {
        err_incomp_type();
        return;
    }
    if(strcmp(d->type, s->type) == 0) {
        return; // same type, safe
    }
    if(strcmp(d->type, "(undefined)") == 0 || strcmp(s->type, "(undefined)") == 0);
    else if(strcmp(d->type, "str") == 0 || strcmp(s->type, "str") == 0 || strcmp(d->type, "bool") == 0 || strcmp(s->type, "bool") == 0) {
        err_incomp_type();
    }
    else {
        // printf("(%s, %s)", d->type, s->type);
        type_coercion(d->type, s->type, 1);
        // printf("-->(%s, %s)\n", d->type, s->type);
    }
    return;
}
// *parameter type coercion*(done!!!!)
void par_type_check(char* fname, LIST* arg) { // function name
    char* ftype;
    char* ptype;
    char* buf;
    char* pscal_t;
    char* ascal_t;
    int pscal_len;
    int ascal_len;
    int par_cnt = 0;
    ftype = funct_type(fname);
    if(ftype != NULL) {
        // get declared parameter types
        ptype = get_attr(fname);
        buf = strtok(ptype, ",");
        while(buf != NULL) {
            par_cnt++;//printf("***\n%s\n", buf);
            // type checking
            if(arg->type[par_cnt-1] != NULL && strcmp(buf, arg->type[par_cnt-1]) != 0) {
                // parameter coersion
                pscal_len = strcspn(buf, "[");//printf("%d\n", pscal_len);
                ascal_len = strcspn(arg->type[par_cnt-1], "[");//printf("%d\n", ascal_len);
                pscal_t = strndup(buf, pscal_len);
                ascal_t = strndup(arg->type[par_cnt-1], ascal_len);
                if(strcmp(pscal_t, "double") == 0 && (strcmp(ascal_t, "float") == 0 || strcmp(ascal_t, "int") == 0));
                else if(strcmp(pscal_t, "float") == 0 && strcmp(ascal_t, "int") == 0);
                else {
                    err_incomp_arg_type(par_cnt);
                }
            }
            buf = strtok(NULL, ",");
        }
        if(arg->size < par_cnt) {//printf("%d%d\n", arg->size, par_cnt);
            dump_err_msg("too few arguments for the function.");
        }
        else if(arg->size > par_cnt) {
            dump_err_msg("too many arguments for the function.");
        }
    }
    else { 
        err_undecl(fname, "function");
    }
    return;
}

void init_type_check(char* type) {
    decl_type;
    if(strcmp(type, decl_type) == 0) {
        return;
    }
    else if((strcmp(type, "int") == 0 || strcmp(type, "float") == 0 || strcmp(type, "double") == 0) &&
            strcmp(decl_type, "int") == 0 || strcmp(decl_type, "float") == 0 || strcmp(decl_type, "double") == 0) {
        type_coercion(decl_type, type, 1);
    }
    else {
        err_incomp_type();
    }
}

// only when + - * / = , not passing args
void type_coercion(char* t1, char* t2, int assign) { // assignment or not
    char type[3][STR_BUF_MAX] = {"int", "float", "double"};
    int i;
    int flag[2] = {-1, -1};

    if(strcmp(t1, t2) == 0) return; // same type

    for(i=0; i<3; i++) {
        if(strcmp(t1, type[i]) == 0) {
            flag[0] = i;
        }
        else if(strcmp(t2, type[i]) == 0) {
            flag[1] = i;
        }
    }//printf("before coercion*************%s, %s\n", t1, t2);
    if(flag[0] < 0 || flag[1] < 0) {
        // err
        fprintf(stderr, "error: type coercion\n");
    }
    else if(flag[0] > flag[1]) {
        free(t2);//printf("1->%s\n", t2);
        t2 = strdup(t1);
    }
    else if(!assign){ // flag[0] < flag[1]
        free(t1);//printf("2->%s\n", t1);
        t1 = strdup(t2);
    }
    else { // assignment
        err_incomp_type();
    }
    return;
}
// void type_coercion(char* t1, char* t2, int assign) { // assignment or not
//     char type[3][STR_BUF_MAX] = {"double", "float", "int"};
//     int i;
//     int flag = 0;

//     if(strcmp(t1, t2) == 0) return; // same type

//     for(i=0; i<3; i++) {
//         if(strcmp(t1, type[i]) == 0) {
//             flag = 1;
//             break;
//         }
//         else if(strcmp(t2, type[i]) == 0) {
//             flag = 1;
//             break;
//         }
//     }
//     if(flag == 0) {
//         fprintf(stderr, "error: type coercion\n");
//     }
//     else if(flag == 1) {
//         free(t2);
//         t2 = strdup(t1);
//     }
//     else { // flag == 2
//         free(t1);
//         t1 = strdup(t2);
//     }
//     return;
// }

//----------------------------------errors-----------------------------------//

int err_redecl(char* name) {
    int j;
    int size = table.size[current_level];
    for(j=0; j<size; j++) {
        if(strcmp(table.entry[current_level][j].name, name) == 0) {
            if(funct_def && table.entry[current_level][j].isdefined == 0) { // funct_def after declared
                table.entry[current_level][j].isdefined = 1;
                return 1; // not error, but do not add in symbol table
            }
            char err_msg[STR_BUF_MAX];
            if(funct_def) {
                strncpy(err_msg, "function ", STR_BUF_MAX);
                strncat(err_msg, name, NAME_SIZE_MAX);
                strncat(err_msg, " redefined.", STR_BUF_MAX-NAME_SIZE_MAX-9);
            }
            else {
                strncpy(err_msg, "variable ", STR_BUF_MAX);
                strncat(err_msg, name, NAME_SIZE_MAX);
                strncat(err_msg, " redeclared.", STR_BUF_MAX-NAME_SIZE_MAX-9);
            }
            dump_err_msg(err_msg);
            return -1; // return error
        }
    }
    return 0; // no error
}

int err_funct_undef() {
    int error = 0;
    int j;
    int size = table.size[current_level];
    for(j=0; j<size; j++) { // function undefined
        if(strcmp(table.entry[current_level][j].kind, "function") == 0 && table.entry[current_level][j].isdefined == 0) {
            char err_msg[STR_BUF_MAX];
            strncpy(err_msg, "function ", STR_BUF_MAX);
            strncat(err_msg, table.entry[current_level][j].name, NAME_SIZE_MAX);
            strncat(err_msg, " undefined.", STR_BUF_MAX-NAME_SIZE_MAX-9);
            dump_err_msg(err_msg);
            error = -1;
        }
    }
    return error;
}

int err_arr_init(char* name) {//printf("%d\n", arr_init_cnt);
    if(arr_init_cnt < 0) {
        char err_msg[STR_BUF_MAX];
        strncpy(err_msg, "excess element in array initializer of ", STR_BUF_MAX);
        strncat(err_msg, name, NAME_SIZE_MAX);
        strncat(err_msg, ".", STR_BUF_MAX);
        dump_err_msg(err_msg);
        return -1;
    }
    return 0;    
}

int err_undecl(char* name, char* kind) {
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, kind, STR_BUF_MAX);
    strncat(err_msg, " ", STR_BUF_MAX);
    strncat(err_msg, name, NAME_SIZE_MAX);
    strncat(err_msg, " undeclared.", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

int err_invalid_ref(char* type) { // reference array type
    if(type == NULL) return -1;
    if(isarray(type)) {
        char err_msg[STR_BUF_MAX];
        strncpy(err_msg, "invalid reference type ", STR_BUF_MAX);
        strncat(err_msg, type, STR_BUF_MAX);
        strncat(err_msg, ".", STR_BUF_MAX);
        dump_err_msg(err_msg);
        return -1;
    }
    return 0;
}

int err_invalid_opd(int opr) {
    char err_msg[STR_BUF_MAX];
    char* operator;
    switch(opr) {
        case ADD_OP: operator = strdup("+"); break;
        case SUB_OP: operator = strdup("-"); break;
        case MUL_OP: operator = strdup("*"); break;
        case DIV_OP: operator = strdup("/"); break;
        case MOD_OP: operator = strdup("%"); break;
        case GT_OP: operator = strdup(">"); break;
        case GE_OP: operator = strdup(">="); break;
        case LE_OP: operator = strdup("<+"); break;
        case LT_OP: operator = strdup("<"); break;
        case EQ_OP: operator = strdup("=="); break;
        case NE_OP: operator = strdup("!="); break;
        case AND_OP: operator = strdup("&&"); break;
        case OR_OP: operator = strdup("||"); break;
        case NOT_OP: operator = strdup("!"); break;
    }
    strncpy(err_msg, "invalid operands to operator '", STR_BUF_MAX);
    strcat(err_msg, operator);
    strcat(err_msg, "'.");
    dump_err_msg(err_msg);
    return -1;
}

int err_incomp_type() {
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, "incompatible type for assignment.", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

int err_incomp_arg_type(int argc) {
    char err_msg[STR_BUF_MAX];
    char num[STR_BUF_MAX];
    sprintf(num, "%d", argc);
    strncpy(err_msg, "incompatible type for argument ", STR_BUF_MAX);
    strncat(err_msg, num, STR_BUF_MAX);
    strncat(err_msg, ".", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

int err_const_assign(char* name) {
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, "assignment of constant variable ", STR_BUF_MAX);
    strncat(err_msg, name, STR_BUF_MAX);
    strncat(err_msg, ".", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

int err_cond_type(char* type) {
    if(strcmp(type, "bool") == 0) return 0;
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, "invalid type for the condition expression.", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

int err_jump_stmt() {
    if(loop) return 0;
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, "jump statement not within loop.", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

int err_rtrn_type(char* type) {
    if(strcmp(type, rtrn_type) == 0) return 0;
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, "incompatible return type ", STR_BUF_MAX);
    strncat(err_msg, type, STR_BUF_MAX);
    strncat(err_msg, "." ,STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;    
}

int err_rtrn_last() {
    if(isreturn) return 0;
    char err_msg[STR_BUF_MAX];
    strncpy(err_msg, "the last statement is not a return statement.", STR_BUF_MAX);
    dump_err_msg(err_msg);
    return -1;
}

void dump_err_msg(char* msg) {
    fprintf(stderr, "##########Error at Line #%d: %s##########\n", name_decl_linenum, msg);
}