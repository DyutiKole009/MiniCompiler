
%{
#include "parser.tab.h"
#include <string.h>
%}

%%

"int"       { return INT; }
"float"     { return FLOAT; }

"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }

"<="        { return LE; }
">="        { return GE; }
"=="        { return EQ; }
"!="        { return NE; }

[0-9]+"."[0-9]+ {
    yylval.str = strdup(yytext);
    return FLOATNUM;
}

[0-9]+ {
    yylval.str = strdup(yytext);
    return NUMBER;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return ID;
}

[ \t\r\n]+     ;

"//".*         ;

.              { return yytext[0]; }

%%

int yywrap(void) {
    return 1;
}

