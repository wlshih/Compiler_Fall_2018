%{
#include "y.tab.h"
#define LIST                { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define token(t)            { LIST; if (Opt_Token) printf("<%s>\n", #t); }
#define tokenString(t, s)   { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
#define MAX_ID_NUM 257
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic = 1;
int linenum = 1;
char buf[MAX_LINE_LENGTH];
char str_buf[MAX_LINE_LENGTH];

typedef struct _ID_COUNT {
    char id[MAX_ID_LENGTH];
    int freq;
} ID_COUNT;
ID_COUNT cnt[MAX_ID_NUM];
int n = 0;
%}

float_num           [0-9]+\.[0-9]+
scientific          [0-9]*\.?[0-9]+[Ee][-+]?[0-9]+
integer	            [0]|[1-9][0-9]*
identifier          [a-zA-Z][a-zA-Z0-9]*
string_literal      ["](\\.|[^"\\\n])*["]

c_style_comment     ("/*"([^*]|[*]+[^*/])*[*]+"/")
cpp_style_comment   ("//"[^\r\n]*)
pragma              #"pragma "("source "|"token "|"statistic ")("on"|"off")

%x C_STYLE_COMMENT
%x CPP_STYLE_COMMENT
%x PRAGMA_SOURCE
%x PRAGMA_TOKEN
%x PRAGMA_STATISTIC
%x PRAGMA_END
%x STRING

%%
"," {tokenString("delim", ","); return COMMA;}
";" {tokenString("delim", ";"); return SEMICOLON;}
"(" {tokenString("delim", "("); return L_PARENTHESIS;}
")" {tokenString("delim", ")"); return R_PARENTHESIS;}
"[" {tokenString("delim", "["); return L_BRACKET;}
"]" {tokenString("delim", "]"); return R_BRACKET;}
"{" {tokenString("delim", "{"); return L_BRACE;}
"}" {tokenString("delim", "}"); return R_BRACE;}

"+" {token("+"); return ADD;}
"-" {token("-"); return SUB;}
"*" {token("*"); return MUL;}
"/" {token("/"); return DIV;}
"%" {token("%"); return MOD;}
"=" {token("="); return ASSIGN;}
"<" {token("<"); return LT;}
"<=" {token("<="); return LE;}
">=" {token(">="); return GE;}
">" {token(">"); return GT;}
"==" {token("=="); return EQ;}
"!=" {token("!="); return NE;}
"&&" {token("&&"); return AND;}
"||" {token("||"); return OR;}
"!" {token("!"); return NOT;}

"while" {tokenString("KW", "while"); return KW_WHILE;}
"do" {tokenString("KW", "do"); return KW_DO;}
"if" {tokenString("KW", "if"); return KW_IF;}
"else" {tokenString("KW", "else"); return KW_ELSE;}
"true" {tokenString("KW", "true"); return KW_TRUE;}
"false" {tokenString("KW", "false"); return KW_FALSE;}
"for" {tokenString("KW", "for"); return KW_FOR;}
"int" {tokenString("KW", "int"); return KW_INT;}
"print" {tokenString("KW", "print"); return KW_PRINT;}
"const" {tokenString("KW", "const"); return KW_CONST;}
"read" {tokenString("KW", "read"); return KW_READ;}
"boolean" {tokenString("KW", "boolean"); return KW_BOOLEAN;}
"bool" {tokenString("KW", "bool"); return KW_BOOL;}
"void" {tokenString("KW", "void"); return KW_VOID;}
"float" {tokenString("KW", "float"); return KW_FLOAT;}
"double" {tokenString("KW", "double"); return KW_DOUBLE;}
"string" {tokenString("KW", "string"); return KW_STRING;}
"continue" {tokenString("KW", "continue"); return KW_CONTINUE;}
"break" {tokenString("KW", "break"); return KW_BREAK;}
"return" {tokenString("KW", "return"); return KW_RETURN;}

{float_num} {tokenString("float", yytext); return FLOAT_NUM;}
{scientific} {tokenString("scientific", yytext); return SCIENTIFIC;}
{integer} {tokenString("integer", yytext); return INTEGER;}

{identifier} {
    int i;
    int id_match = 0;
    for (i=0; i<n; i++) {
        if (strcmp(cnt[i].id, yytext) == 0) {
            cnt[i].freq++;
            id_match = 1;
            break;
        }
        else continue;
    }
    if (!id_match) {
        strncpy(cnt[n].id, yytext, MAX_ID_LENGTH);
        cnt[n].freq++;
        n++;
    }
    tokenString("id", yytext);
    return ID;
}

"\"" {
    LIST;
    BEGIN STRING;
}
<STRING>"\\"("\""|"\\") {
    LIST;
    //printf("<%c>\n", yytext[1]);
    strncat(str_buf, yytext+1, 1);
}
<STRING>"\"" {
    tokenString("string", str_buf);
    str_buf[0] = '\0';
    BEGIN INITIAL;
    return STRING_TOKEN;
}
<STRING>. {
    LIST;
    strncat(str_buf, yytext, sizeof(str_buf)-strlen(str_buf)-1);
}
<STRING>\n {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

"//" {
    LIST;
    BEGIN CPP_STYLE_COMMENT;
    //printf("<cpp_comment>\n");
}
<CPP_STYLE_COMMENT>. {LIST;}
<CPP_STYLE_COMMENT>\n {
    LIST;
    //printf("<newline>\n");
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
    BEGIN INITIAL;
}

"/*" {
    LIST;
    BEGIN C_STYLE_COMMENT;
    //printf("<c_comment>\n");
}
<C_STYLE_COMMENT>. {LIST;}
<C_STYLE_COMMENT>\n {
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}
<C_STYLE_COMMENT>"*/" {
    LIST;
    BEGIN INITIAL;
}

"#pragma"[\t ]+"source"[\t ]+ {
    LIST;
    BEGIN PRAGMA_SOURCE;
}
"#pragma"[\t ]+"token"[\t ]+ {
    LIST;
    BEGIN PRAGMA_TOKEN;
}
"#pragma"[\t ]+"statistic"[\t ]+ {
    LIST;
    BEGIN PRAGMA_STATISTIC;
}

<PRAGMA_SOURCE>"on"[\t\r ]* {
    LIST;
    Opt_Source = 1;
    //printf("<pragma_source: on>\n");
    BEGIN PRAGMA_END;
}
<PRAGMA_SOURCE>"off"[\t\r ]* {
    LIST;
    Opt_Source = 0;
    //printf("<pragma_source: off>\n");
    BEGIN PRAGMA_END;
}
<PRAGMA_SOURCE>. {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<PRAGMA_TOKEN>"on"[\t\r ]* {
    LIST;
    Opt_Token = 1;
    //printf("<pragma_token: on>\n");
    BEGIN PRAGMA_END;
}
<PRAGMA_TOKEN>"off"[\t\r ]* {
    LIST;
    Opt_Token = 0;
    //printf("<pragma_token: off>\n");
    BEGIN PRAGMA_END;
}
<PRAGMA_TOKEN>. {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<PRAGMA_STATISTIC>"on"[\t\r ]* {
    LIST;
    Opt_Statistic = 1;
    //printf("<pragma_statistic: on>\n");
    BEGIN PRAGMA_END;
}
<PRAGMA_STATISTIC>"off"[\t\r ]* {
    LIST;
    Opt_Statistic = 0;
    //printf("<pragma_statistic: off>\n");
    BEGIN PRAGMA_END;
}
<PRAGMA_STATISTIC>. {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<PRAGMA_END>"/*" {
    LIST;
    BEGIN C_STYLE_COMMENT;
    //printf("<c_comment>\n");
}
<PRAGMA_END>"//" {
    LIST;
    BEGIN CPP_STYLE_COMMENT;
    //printf("<cpp_comment>\n");
}
<PRAGMA_END>[\n] {
    LIST;
    //printf("<newline>\n");
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
    BEGIN INITIAL;
}
<PRAGMA_END>. {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

\n {
    LIST;
    //printf("<newline>\n");
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

[ \t\r] {LIST;}


. { // Unrecognized character
    // temp = yytext[0];
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

%%
/*
int main( int argc, char **argv )
{
    if (argc >= 2)
    {
        yyin = fopen( argv[1], "r" );
        if ( NULL == yyin ) {
            fprintf( stderr, "Cannot open: %s\n", argv[1] );
            exit(-1);
        }
    }
    else
    {
        yyin = stdin;
    }
    yylex();

    if (Opt_Statistic)
    {
        // Print frequency table
        printf("frequencies of identifiers:\n");
        int i;
        for (i=0; i<n; i++) {
            printf("%-12s %d\n", cnt[i].id, cnt[i].freq);
        }
    }
    
    exit(0);
}
*/