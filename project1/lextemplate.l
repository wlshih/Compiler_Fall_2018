%{
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
char temp[MAX_LINE_LENGTH];

typedef struct _ID_COUNT {
    char id[MAX_ID_LENGTH];
    int freq;
} ID_COUNT;
ID_COUNT cnt[MAX_ID_NUM];
int n = 0;
%}

float_num           ([-+]?[0]|[1-9][0-9]*)\.[0-9]+
scientific          [-+]?[0-9]*\.?[0-9]+[Ee][-+]?[0-9]+
integer	            [-+]?[0]|[1-9][0-9]*
identifier          [a-zA-Z][a-zA-Z0-9]*
string_literal      ["](\\.|[^"\\\n])*["]

c_style_comment     ("/*"([^*]|[*]+[^*/])*[*]+"/")
cpp_style_comment   ("//"[^\r\n]*)
pragma              #"pragma "("source "|"token "|"statistic ")("on"|"off")

%x C_STYLE_COMMENT CPP_STYLE_COMMENT

%%
"," {tokenString("delim", ",");}
";" {tokenString("delim", ";");}
"(" {tokenString("delim", "(");}
")" {tokenString("delim", ")");}
"[" {tokenString("delim", "[");}
"]" {tokenString("delim", "]");}
"{" {tokenString("delim", "{");}
"}" {tokenString("delim", "}");}

"+" {token("+");}
"-" {token("-");}
"*" {token("*");}
"/" {token("/");}
"%" {token("%");}
"=" {token("=");}
"<" {token("<");}
"<=" {token("<=");}
">=" {token(">=");}
">" {token(">");}
"==" {token("==");}
"!=" {token("!=");}
"&&" {token("&&");}
"||" {token("||");}
"!" {token("!");}

"while" {tokenString("KW", "while");}
"do" {tokenString("KW", "do");}
"if" {tokenString("KW", "if");}
"else" {tokenString("KW", "else");}
"true" {tokenString("KW", "true");}
"false" {tokenString("KW", "false");}
"for" {tokenString("KW", "for");}
"int" {tokenString("KW", "int");}
"print" {tokenString("KW", "print");}
"const" {tokenString("KW", "const");}
"read" {tokenString("KW", "read");}
"boolean" {tokenString("KW", "boolean");}
"bool" {tokenString("KW", "bool");}
"void" {tokenString("KW", "void");}
"float" {tokenString("KW", "float");}
"double" {tokenString("KW", "double");}
"string" {tokenString("KW", "string");}
"continue" {tokenString("KW", "continue");}
"break" {tokenString("KW", "break");}
"return" {tokenString("KW", "return");}

{float_num} {tokenString("float", yytext);}
{scientific} {tokenString("scientific", yytext);}
{integer} {tokenString("integer", yytext);}

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
}


{string_literal} {
    int i;
    for (i=0; i<yyleng-2; i++) {
        temp[i] = yytext[i+1];
    }
    tokenString("string", temp);
    memset(temp, '\0', yyleng);
}

"//" {
    LIST;
    BEGIN CPP_STYLE_COMMENT;
    //printf("<cpp_comment>\n");
}
<CPP_STYLE_COMMENT>. {LIST;}
<CPP_STYLE_COMMENT>\n {
    //LIST; //canceled because it will be listed again after changing state
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

{pragma} {
    LIST;
    int p_switch = (yytext[yyleng-1] == 'n') ? 1 : 0;
    if (yytext[10] == 'u') { //source
        Opt_Source = p_switch;
    }
    else if (yytext[10] == 'k') { //token
        Opt_Token = p_switch;
    }
    else { //statistic
        Opt_Statistic = p_switch;
    }
    //printf("<pragma: %s>\n", yytext);
}


\n {
    LIST;
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
