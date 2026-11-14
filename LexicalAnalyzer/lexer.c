#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "tokens.h"
#include <stdlib.h>

#define MAX_ID_LEN    31
#define MAX_NUM_LEN   20

/*--------------------------
        DFA States
---------------------------*/

#define START_STATE        0
#define ID_STATE           1
#define NUM_STATE          2
#define FLOAT_STATE        3
#define STRING_STATE       4

#define PLUS_STATE         5
#define MINUS_STATE        6
#define MUL_STATE          7
#define DIV_STATE          8
#define MOD_STATE          9

#define ASSIGN_STATE       10
#define LT_STATE           11
#define GT_STATE           12
#define NOT_STATE          13

#define AND_STATE          14
#define OR_STATE           15
#define XOR_STATE          16
#define BITNOT_STATE       17

#define LPAREN_STATE       18
#define RPAREN_STATE       19
#define LBRACE_STATE       20
#define RBRACE_STATE       21
#define SEMICOLON_STATE    22

#define ERROR_STATE        100

/*--------------------------
    Global Variables
---------------------------*/

FILE *yyin;

char yytext[256];
int yyleng = 0;
int yylineno = 1;

/*--------------------------
    Helper Functions
---------------------------*/

char getNextChar()
{
    return fgetc(yyin);
}

void retract()
{
    fseek(yyin,-1,SEEK_CUR);
}

int isKeyword(char *str)
{
    if(strcmp(str,"int")==0)
        return INT_TOK;

    if(strcmp(str,"float")==0)
        return FLOAT_TOK;

    if(strcmp(str,"char")==0)
        return CHAR_TOK;

    if(strcmp(str,"if")==0)
        return IF_TOK;

    if(strcmp(str,"else")==0)
        return ELSE_TOK;

    if(strcmp(str,"for")==0)
        return FOR_TOK;

    if(strcmp(str,"while")==0)
        return WHILE_TOK;
    
    if(strcmp(str,"do")==0)
        return DO_TOK;

    return IDENTIFIER_TOK;
}

int spellingError(char *str)
{
    char *keywords[] =
    {
        "int","float","char","for",
        "do","while","if","else"
    };

    int i,j,diff;

    for(i=0;i<8;i++)
    {
        diff=0;

        int l1=strlen(str);
        int l2=strlen(keywords[i]);

        if(abs(l1-l2)>1)
            continue;

        int min=l1<l2?l1:l2;

        for(j=0;j<min;j++)
        {
            if(str[j]!=keywords[i][j])
                diff++;
        }

        diff+=abs(l1-l2);

        if(diff==1)
            return 1;
    }

    return 0;
}

/*--------------------------
        yylex()
---------------------------*/

int yylex()
{
    int state = START_STATE;

    char c;
    int i = 0;

    while(1)
    {
        switch(state)
        {

        /*=====================================
                q0 : START STATE
        =====================================*/

        case START_STATE:

            c = getNextChar();

            if(c==EOF)
            {
                strcpy(yytext,"EOF");
                yyleng=3;
                return EOF_TOK;
            }

            yytext[0]='\0';
            yyleng=0;
            i=0;

            switch(c)
            {
                case ' ':
                case '\t':
                case '\r':

                    state = START_STATE;
                    break;

                case '\n':

                    yylineno++;
                    state = START_STATE;
                    break;

                case '+':

                    yytext[i++] = c;
                    state = PLUS_STATE;
                    break;

                case '-':

                    yytext[i++] = c;
                    state = MINUS_STATE;
                    break;

                case '*':

                    yytext[i++] = c;
                    state = MUL_STATE;
                    break;

                case '/':

                    yytext[i++] = c;
                    state = DIV_STATE;
                    break;

                case '%':

                    yytext[i++] = c;
                    state = MOD_STATE;
                    break;

                case '=':

                    yytext[i++] = c;
                    state = ASSIGN_STATE;
                    break;

                case '<':

                    yytext[i++] = c;
                    state = LT_STATE;
                    break;

                case '>':

                    yytext[i++] = c;
                    state = GT_STATE;
                    break;

                case '!':

                    yytext[i++] = c;
                    state = NOT_STATE;
                    break;

                case '&':

                    yytext[i++] = c;
                    state = AND_STATE;
                    break;

                case '|':

                    yytext[i++] = c;
                    state = OR_STATE;
                    break;

                case '^':

                    yytext[i++] = c;
                    state = XOR_STATE;
                    break;

                case '~':

                    yytext[i++] = c;
                    state = BITNOT_STATE;
                    break;

                case '(':

                    yytext[i++] = c;
                    state = LPAREN_STATE;
                    break;

                case ')':

                    yytext[i++] = c;
                    state = RPAREN_STATE;
                    break;

                case '{':

                    yytext[i++] = c;
                    state = LBRACE_STATE;
                    break;

                case '}':

                    yytext[i++] = c;
                    state = RBRACE_STATE;
                    break;

                case ';':

                    yytext[i++] = c;
                    state = SEMICOLON_STATE;
                    break;

                case '"':

                    yytext[i++] = c;
                    state = STRING_STATE;
                    break;

                default:

                    if(isalpha(c) || c=='_')
                    {
                        yytext[i++] = c;
                        state = ID_STATE;
                    }
                    else if(isdigit(c))
                    {
                        yytext[i++] = c;
                        state = NUM_STATE;
                    }
                    else
                    {
                        printf("Lexical Error at line %d : Illegal Character '%c'\n",
                                yylineno,c);

                        state = START_STATE;
                    }

                    break;
            }

            break;
        /*=====================================
                q1 : IDENTIFIER STATE
        =====================================*/

        case ID_STATE:

            c = getNextChar();

            switch(c)
            {
                case '_':

                    if(i >= MAX_ID_LEN)
                    {
                        printf("Lexical Error at line %d : Identifier too long\n",
                            yylineno);

                        while(1)
                        {
                            c = getNextChar();

                            if(!(isalnum(c) || c=='_'))
                            {
                                retract();
                                break;
                            }
                        }

                        state = START_STATE;
                        break;
                    }

                    yytext[i++] = c;
                    break;

                default:

                    if(isalnum(c))
                    {
                        if(i >= MAX_ID_LEN)
                        {
                            printf("Lexical Error at line %d : Identifier too long\n",
                                yylineno);

                            while(1)
                            {
                                c = getNextChar();

                                if(!(isalnum(c) || c=='_'))
                                {
                                    retract();
                                    break;
                                }
                            }

                            state = START_STATE;
                            break;
                        }

                        yytext[i++] = c;
                    }
                    else
                    {
                        retract();

                        yytext[i] = '\0';
                        yyleng = i;

                        int tok = isKeyword(yytext);

                        if(tok != IDENTIFIER_TOK)
                            return tok;

                        if(spellingError(yytext))
                        {
                            printf("Lexical Error at line %d : Possible spelling mistake \"%s\"\n",
                                yylineno,
                                yytext);

                            state = START_STATE;
                            break;
                        }

                        return IDENTIFIER_TOK;
                    }

                    break;
            }

            break;

        /*=====================================
                q2 : NUMBER STATE
        =====================================*/

        case NUM_STATE:

            c = getNextChar();

            switch(c)
            {
                case '.':

                    yytext[i++] = c;
                    state = FLOAT_STATE;
                    break;

                default:

                    if(isdigit(c))
                    {
                        if(i >= MAX_NUM_LEN)
                        {
                            printf("Lexical Error at line %d : Numeric constant too long\n",
                                yylineno);

                            while(1)
                            {
                                c = getNextChar();

                                if(!isdigit(c))
                                {
                                    retract();
                                    break;
                                }
                            }

                            state = START_STATE;
                            break;
                        }

                        yytext[i++] = c;
                    }

                    else if(isalpha(c) || c=='_')
                    {
                        yytext[i++] = c;

                        while(1)
                        {
                            c = getNextChar();

                            if(isalnum(c) || c=='_')
                                yytext[i++] = c;
                            else
                            {
                                retract();
                                break;
                            }
                        }

                        yytext[i]='\0';

                        printf("Lexical Error at line %d : Invalid Identifier \"%s\"\n",
                            yylineno,
                            yytext);

                        state = START_STATE;
                    }

                    /* Invalid character inside numeric constant */

                    else if(!isspace(c) &&
                            c!=';' &&
                            c!=',' &&
                            c!=')' &&
                            c!='(' &&
                            c!='{' &&
                            c!='}' &&
                            c!='+' &&
                            c!='-' &&
                            c!='*' &&
                            c!='/' &&
                            c!='%' &&
                            c!='=' &&
                            c!='<' &&
                            c!='>')
                    {
                        yytext[i++] = c;

                        while(1)
                        {
                            c = getNextChar();

                            if(isalnum(c) ||
                            (!isspace(c) &&
                                c!=';' &&
                                c!=',' &&
                                c!=')' &&
                                c!='(' &&
                                c!='{' &&
                                c!='}' &&
                                c!='+' &&
                                c!='-' &&
                                c!='*' &&
                                c!='/' &&
                                c!='%' &&
                                c!='=' &&
                                c!='<' &&
                                c!='>'))
                            {
                                yytext[i++] = c;
                            }
                            else
                            {
                                retract();
                                break;
                            }
                        }

                        yytext[i]='\0';

                        printf("Lexical Error at line %d : Invalid Numeric Constant \"%s\"\n",
                            yylineno,
                            yytext);

                        state = START_STATE;
                    }

                    else
                    {
                        retract();

                        yytext[i]='\0';
                        yyleng=i;

                        return INTEGER_TOK;
                    }

                    break;
            }

            break;
        /*=====================================
                q3 : FLOAT STATE
        =====================================*/

        case FLOAT_STATE:

            c=getNextChar();

            if(!isdigit(c))
            {
                printf("Lexical Error at line %d : Invalid Floating Constant\n",
                    yylineno);

                state=START_STATE;
                break;
            }

            yytext[i++]=c;

            while(1)
            {
                c=getNextChar();

                if(isdigit(c))
                {
                    if(i >= MAX_NUM_LEN)
                    {
                        printf("Lexical Error at line %d : Floating constant too long\n",
                            yylineno);

                        while(1)
                        {
                            c = getNextChar();

                            if(!isdigit(c))
                            {
                                retract();
                                break;
                            }
                        }

                        state = START_STATE;
                        break;
                    }

                    yytext[i++]=c;
                }
                else
                {
                    retract();
                    break;
                }
            }

            yytext[i]='\0';
            yyleng=i;

            return FLOAT_CONST_TOK;


        /*=====================================
                q4 : STRING STATE
        =====================================*/

        case STRING_STATE:

            c = getNextChar();

            if(c == EOF)
            {
                printf("Lexical Error at line %d : Unterminated String\n",
                    yylineno);

                state = START_STATE;
                break;
            }

            if(c == '\n')
            {
                printf("Lexical Error at line %d : Unterminated String\n",
                    yylineno);

                yylineno++;
                state = START_STATE;
                break;
            }

            yytext[i++] = c;

            if(c == '"')
            {
                yytext[i] = '\0';
                yyleng = i;

                return STRING_TOK;
            }

            break;


        /*=====================================
                q5 : '+' STATE
        =====================================*/

        case PLUS_STATE:

            c = getNextChar();

            if(c == '+')
            {
                strcpy(yytext,"++");
                yyleng = 2;
                return INC_TOK;
            }

            if(c == '=')
            {
                strcpy(yytext,"+=");
                yyleng = 2;
                return ADD_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"+");
            yyleng = 1;

            return PLUS_TOK;

        /*=====================================
                q6 : '-' STATE
        =====================================*/

        case MINUS_STATE:

            c = getNextChar();

            if(c == '-')
            {
                strcpy(yytext,"--");
                yyleng = 2;
                return DEC_TOK;
            }

            if(c == '=')
            {
                strcpy(yytext,"-=");
                yyleng = 2;
                return SUB_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"-");
            yyleng = 1;

            return MINUS_TOK;


        /*=====================================
                q7 : '*' STATE
        =====================================*/

        case MUL_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,"*=");
                yyleng = 2;
                return MUL_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"*");
            yyleng = 1;

            return MUL_TOK;

                    /*=====================================
                q8 : '/' STATE
        =====================================*/

        case DIV_STATE:

            c = getNextChar();

            switch(c)
            {
                case '=':

                    strcpy(yytext,"/=");
                    yyleng = 2;
                    return DIV_ASSIGN_TOK;

                case '/':

                    /* Skip single-line comment */

                    while((c = getNextChar()) != EOF && c != '\n');

                    if(c == '\n')
                        yylineno++;

                    state = START_STATE;
                    break;

                case '*':

                {
                    /* Skip multi-line comment */

                    char prev = 0;

                    while((c = getNextChar()) != EOF)
                    {
                        if(c == '\n')
                            yylineno++;

                        if(prev == '*' && c == '/')
                            break;

                        prev = c;
                    }

                    if(c == EOF)
                        printf("Lexical Error at line %d : Unterminated Comment\n",
                               yylineno);

                    state = START_STATE;
                    break;
                }

                default:

                    retract();

                    strcpy(yytext,"/");
                    yyleng = 1;

                    return DIV_TOK;
            }

            break;


        /*=====================================
                q9 : '%' STATE
        =====================================*/

        case MOD_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,"%=");
                yyleng = 2;

                return MOD_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"%");
            yyleng = 1;

            return MOD_TOK;


        /*=====================================
                q10 : '=' STATE
        =====================================*/

        case ASSIGN_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,"==");
                yyleng = 2;

                return EQ_TOK;
            }

            retract();

            strcpy(yytext,"=");
            yyleng = 1;

            return ASSIGN_TOK;


        /*=====================================
                q11 : '<' STATE
        =====================================*/

        case LT_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,"<=");
                yyleng = 2;

                return LE_TOK;
            }

            retract();

            strcpy(yytext,"<");
            yyleng = 1;

            return LT_TOK;


        /*=====================================
                q12 : '>' STATE
        =====================================*/

        case GT_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,">=");
                yyleng = 2;

                return GE_TOK;
            }

            retract();

            strcpy(yytext,">");
            yyleng = 1;

            return GT_TOK;

                    /*=====================================
                q13 : '!' STATE
        =====================================*/

        case NOT_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,"!=");
                yyleng = 2;
                return NE_TOK;
            }

            retract();

            strcpy(yytext,"!");
            yyleng = 1;
            return NOT_TOK;


        /*=====================================
                q14 : '&' STATE
        =====================================*/

        case AND_STATE:

            c = getNextChar();

            if(c == '&')
            {
                strcpy(yytext,"&&");
                yyleng = 2;
                return AND_TOK;
            }

            if(c == '=')
            {
                strcpy(yytext,"&=");
                yyleng = 2;
                return AND_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"&");
            yyleng = 1;
            return BITAND_TOK;


        /*=====================================
                q15 : '|' STATE
        =====================================*/

        case OR_STATE:

            c = getNextChar();

            if(c == '|')
            {
                strcpy(yytext,"||");
                yyleng = 2;
                return OR_TOK;
            }

            if(c == '=')
            {
                strcpy(yytext,"|=");
                yyleng = 2;
                return OR_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"|");
            yyleng = 1;
            return BITOR_TOK;


        /*=====================================
                q16 : '^' STATE
        =====================================*/

        case XOR_STATE:

            c = getNextChar();

            if(c == '=')
            {
                strcpy(yytext,"^=");
                yyleng = 2;
                return XOR_ASSIGN_TOK;
            }

            retract();

            strcpy(yytext,"^");
            yyleng = 1;
            return XOR_TOK;


        /*=====================================
                q17 : '~' STATE
        =====================================*/

        case BITNOT_STATE:

            strcpy(yytext,"~");
            yyleng = 1;
            return BITNOT_TOK;


        /*=====================================
                q18 : '(' STATE
        =====================================*/

        case LPAREN_STATE:

            strcpy(yytext,"(");
            yyleng = 1;
            return LPAREN_TOK;


        /*=====================================
                q19 : ')' STATE
        =====================================*/

        case RPAREN_STATE:

            strcpy(yytext,")");
            yyleng = 1;
            return RPAREN_TOK;


        /*=====================================
                q20 : '{' STATE
        =====================================*/

        case LBRACE_STATE:

            strcpy(yytext,"{");
            yyleng = 1;
            return LBRACE_TOK;


        /*=====================================
                q21 : '}' STATE
        =====================================*/

        case RBRACE_STATE:

            strcpy(yytext,"}");
            yyleng = 1;
            return RBRACE_TOK;


        /*=====================================
                q22 : ';' STATE
        =====================================*/

        case SEMICOLON_STATE:

            strcpy(yytext,";");
            yyleng = 1;
            return SEMICOLON_TOK;

        }   /* end switch */

    }   /* end while */

}   /* end yylex() */


/*=====================================
            MAIN FUNCTION
=====================================*/

int main(int argc, char *argv[])
{
    int token;

    if(argc != 2)
    {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1],"r");

    if(yyin == NULL)
    {
        printf("Cannot open input file.\n");
        return 1;
    }

    printf("\n%-20s %-10s %-10s\n",
           "Lexeme",
           "Token",
           "Length");

    printf("---------------------------------------------\n");

    while((token = yylex()) != EOF_TOK)
    {
        printf("%-20s %-10d %-10d\n",
               yytext,
               token,
               yyleng);
    }

    fclose(yyin);

    return 0;
}
