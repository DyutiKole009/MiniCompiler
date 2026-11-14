%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

static char *duplicate_string(void)
{
    return strdup(yytext);
}
%}

%option yylineno
%option noyywrap

%x MULTI_COMMENT

DIGIT       [0-9]
LETTER      [a-zA-Z_]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT})*
INTEGER     {DIGIT}+
REAL        {DIGIT}+"."{DIGIT}+
CHARACTER   \'([^\'\\]|\\.)\'
STRING      \"([^\"\\]|\\.)*\"

%%


"int"       return INT;
"float"     return FLOAT;
"char"      return CHAR;
"void"      return VOID;

"if"        return IF;
"else"      return ELSE;
"while"     return WHILE;
"do"        return DO;
"for"       return FOR;
"break"     return BREAK;
"continue"  return CONTINUE;
"return"    return RETURN;
"main"      return MAIN;




"=="        return EQ;
"!="        return NE;
"<="        return LE;
">="        return GE;

"&&"        return AND;
"||"        return OR;

"++"        return INC;
"--"        return DEC;

"+="        return ADDASSIGN;
"-="        return SUBASSIGN;




"="         return ASSIGN;

"<"         return LT;
">"         return GT;

"+"         return PLUS;
"-"         return MINUS;
"*"         return MUL;
"/"         return DIV;
"%"         return MOD;

"!"         return NOT;

"&"         return AMP;




"("         return LPAREN;
")"         return RPAREN;

"["         return LBRACKET;
"]"         return RBRACKET;

"{"         return LBRACE;
"}"         return RBRACE;

";"         return SEMICOLON;
","         return COMMA;




{REAL} {
    yylval.str = duplicate_string();
    return FLOAT_CONST;
}

{INTEGER} {
    yylval.str = duplicate_string();
    return INT_CONST;
}

{CHARACTER} {
    yylval.str = duplicate_string();
    return CHAR_CONST;
}

{STRING} {
    yylval.str = duplicate_string();
    return STRING_CONST;
}




{IDENTIFIER} {
    yylval.str = duplicate_string();
    return ID;
}




[ \t\r\n]+ {
    /* skip whitespace */
}




"//".* {
    /* skip single-line comment */
}




"/*" {
    BEGIN(MULTI_COMMENT);
}

<MULTI_COMMENT>"*/" {
    BEGIN(INITIAL);
}

<MULTI_COMMENT>. {
    /* ignore characters inside comment */
}

<MULTI_COMMENT>\n {
    /* ignore newline inside comment */
}



. {
    return yytext[0];
}

%%