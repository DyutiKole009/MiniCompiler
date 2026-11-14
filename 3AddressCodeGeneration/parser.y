
%code requires {
    #include <stdio.h>

    typedef struct {
        char *place;
        char *type;
    } Expr;

    typedef struct {
        char *start;
        char *exit;
    } Loop;
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Quadruple structure */

typedef struct {
    char label[20];
    char op[20];
    char arg1[256];
    char arg2[256];
    char result[256];
} Quad;

/* Symbol table structure */

typedef struct {
    char name[50];
    char type[20];
} Symbol;

#define MAX_QUADS 500
#define MAX_SYMBOLS 100

/* Global variables */

Quad quad[MAX_QUADS];
int qcount = 0;

int tempCount = 0;
int labelCount = 0;

Symbol symtab[MAX_SYMBOLS];
int symCount = 0;

char *currentType = NULL;

FILE *out;

/* Generate temporary variable */

char *newTemp(void) {
    char *temp = malloc(30);
    sprintf(temp, "T%d", ++tempCount);
    return temp;
}

/* Generate label */

char *newLabel(void) {
    char *label = malloc(30);
    sprintf(label, "L%d", labelCount++);
    return label;
}

/* Generate quadruple */

void emit(char *op, char *arg1,
          char *arg2, char *result) {

    if (qcount >= MAX_QUADS) {
        fprintf(stderr, "Quadruple table full\n");
        exit(1);
    }

    sprintf(quad[qcount].label, "%02d", qcount);

    snprintf(quad[qcount].op, 20, "%s", op);
    snprintf(quad[qcount].arg1, 256, "%s",
             arg1 ? arg1 : "");
    snprintf(quad[qcount].arg2, 256, "%s",
             arg2 ? arg2 : "");
    snprintf(quad[qcount].result, 256, "%s",
             result ? result : "");

    qcount++;
}

/* Print three-address code */

void printCode(FILE *fp) {

    for (int i = 0; i < qcount; i++) {

        Quad q = quad[i];

        fprintf(fp, "%s ", q.label);

        if (strcmp(q.op, "uminus") == 0) {
            fprintf(fp, "%s = - %s\n",
                    q.result, q.arg1);
        }

        else if (strcmp(q.op, "=") == 0) {
            fprintf(fp, "%s = %s\n",
                    q.result, q.arg1);
        }

        else if (strcmp(q.op, "label") == 0) {
            fprintf(fp, "%s:\n", q.result);
        }

        else if (strcmp(q.op, "goto") == 0) {
            fprintf(fp, "goto %s\n", q.result);
        }

        else if (strcmp(q.op, "ifFalse") == 0) {
            fprintf(fp, "ifFalse (%s) goto %s\n",
                    q.arg1, q.result);
        }

        else {
            fprintf(fp, "%s = %s %s %s\n",
                    q.result, q.arg1,
                    q.op, q.arg2);
        }
    }

    fprintf(fp, "%02d\n", qcount);
}

/* Insert variable into symbol table */

void declareVariable(char *name, char *type) {

    for (int i = 0; i < symCount; i++) {

        if (strcmp(symtab[i].name, name) == 0) {
            fprintf(stderr,
                    "Error: Variable %s already declared\n",
                    name);
            exit(1);
        }
    }

    if (symCount >= MAX_SYMBOLS) {
        fprintf(stderr, "Symbol table full\n");
        exit(1);
    }

    strcpy(symtab[symCount].name, name);
    strcpy(symtab[symCount].type, type);

    symCount++;
}

/* Retrieve variable type */

char *getType(char *name) {

    for (int i = 0; i < symCount; i++) {

        if (strcmp(symtab[i].name, name) == 0) {
            return symtab[i].type;
        }
    }

    fprintf(stderr,
            "Error: Variable %s not declared\n", name);

    exit(1);
    return NULL;
}

void yyerror(const char *s);
int yylex(void);

%}

/* Semantic values */

%union {
    char *str;
    Expr expr;
    Loop loop;
}

/* Tokens */

%token <str> ID NUMBER FLOATNUM

%token INT FLOAT IF ELSE WHILE

%token LE GE EQ NE

/* Non-terminal types */

%type <str> type id_list
%type <str> if_prefix else_prefix while_start

%type <loop> while_prefix

%type <expr> expr condition

/* Operator precedence */

%left '+' '-'
%left '*' '/'
%right UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

program:
    declarations statements
    {
        printf("\nThree Address Code:\n\n");

        printCode(stdout);

        out = fopen("output.txt", "w");

        if (out == NULL) {
            perror("output.txt");
            exit(1);
        }

        printCode(out);
        fclose(out);

        printf("\nOutput saved in output.txt\n");
    }
    ;

declarations:
      declarations declaration
    |
    ;

declaration:
    type id_list ';'
    ;

type:
      INT
      {
          currentType = "int";
          $$ = "int";
      }

    | FLOAT
      {
          currentType = "float";
          $$ = "float";
      }
    ;

id_list:
      ID
      {
          declareVariable($1, currentType);
          $$ = $1;
      }

    | id_list ',' ID
      {
          declareVariable($3, currentType);
          $$ = $3;
      }
    ;

statements:
      statements statement
    |
    ;

statement:

    /* Assignment statement */

      ID '=' expr ';'
      {
          char *varType = getType($1);

          if (strcmp(varType, $3.type) != 0) {
              yyerror("Type mismatch in assignment");
              exit(1);
          }

          emit("=", $3.place, "", $1);
      }

    /* If statement */

    | if_prefix statement %prec LOWER_THAN_ELSE
      {
          emit("label", "", "", $1);
      }

    /* If-else statement */

    | else_prefix statement
      {
          emit("label", "", "", $1);
      }

    /* While statement */

    | while_prefix statement
      {
          emit("goto", "", "", $1.start);
          emit("label", "", "", $1.exit);
      }

    /* Compound statement */

    | '{' statements '}'
    ;

if_prefix:
    IF '(' condition ')'
    {
        $$ = newLabel();
        emit("ifFalse", $3.place, "", $$);
    }
    ;

else_prefix:
    if_prefix statement ELSE
    {
        $$ = newLabel();

        emit("goto", "", "", $$);
        emit("label", "", "", $1);
    }
    ;

while_start:
    WHILE
    {
        $$ = newLabel();
        emit("label", "", "", $$);
    }
    ;

while_prefix:
    while_start '(' condition ')'
    {
        $$.start = $1;
        $$.exit = newLabel();

        emit("ifFalse", $3.place, "", $$.exit);
    }
    ;

/* Arithmetic expressions */

expr:

      expr '+' expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Incompatible operand types");
              exit(1);
          }

          $$.place = newTemp();
          $$.type = $1.type;

          emit("+", $1.place, $3.place, $$.place);
      }

    | expr '-' expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Incompatible operand types");
              exit(1);
          }

          $$.place = newTemp();
          $$.type = $1.type;

          emit("-", $1.place, $3.place, $$.place);
      }

    | expr '*' expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Incompatible operand types");
              exit(1);
          }

          $$.place = newTemp();
          $$.type = $1.type;

          emit("*", $1.place, $3.place, $$.place);
      }

    | expr '/' expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Incompatible operand types");
              exit(1);
          }

          $$.place = newTemp();
          $$.type = $1.type;

          emit("/", $1.place, $3.place, $$.place);
      }

    /* Unary minus */

    | '-' expr %prec UMINUS
      {
          $$.place = newTemp();
          $$.type = $2.type;

          emit("uminus", $2.place, "", $$.place);
      }

    /* Parentheses */

    | '(' expr ')'
      {
          $$ = $2;
      }

    /* Identifier */

    | ID
      {
          $$.place = $1;
          $$.type = getType($1);
      }

    /* Integer constant */

    | NUMBER
      {
          $$.place = $1;
          $$.type = "int";
      }

    /* Float constant */

    | FLOATNUM
      {
          $$.place = $1;
          $$.type = "float";
      }
    ;

/* Relational conditions */

condition:

      expr '<' expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Type mismatch in condition");
              exit(1);
          }

          $$.place = malloc(512);
          sprintf($$.place, "%s < %s",
                  $1.place, $3.place);
          $$.type = "bool";
      }

    | expr '>' expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Type mismatch in condition");
              exit(1);
          }

          $$.place = malloc(512);
          sprintf($$.place, "%s > %s",
                  $1.place, $3.place);
          $$.type = "bool";
      }

    | expr LE expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Type mismatch in condition");
              exit(1);
          }

          $$.place = malloc(512);
          sprintf($$.place, "%s <= %s",
                  $1.place, $3.place);
          $$.type = "bool";
      }

    | expr GE expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Type mismatch in condition");
              exit(1);
          }

          $$.place = malloc(512);
          sprintf($$.place, "%s >= %s",
                  $1.place, $3.place);
          $$.type = "bool";
      }

    | expr EQ expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Type mismatch in condition");
              exit(1);
          }

          $$.place = malloc(512);
          sprintf($$.place, "%s == %s",
                  $1.place, $3.place);
          $$.type = "bool";
      }

    | expr NE expr
      {
          if (strcmp($1.type, $3.type) != 0) {
              yyerror("Type mismatch in condition");
              exit(1);
          }

          $$.place = malloc(512);
          sprintf($$.place, "%s != %s",
                  $1.place, $3.place);
          $$.type = "bool";
      }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

extern FILE *yyin;

int main(int argc, char *argv[]) {

    if (argc != 2) {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");

    if (yyin == NULL) {
        perror("Error opening input file");
        return 1;
    }

    printf("Reading input file: %s\n", argv[1]);

    yyparse();

    fclose(yyin);

    return 0;
}
