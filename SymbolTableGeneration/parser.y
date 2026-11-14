%code requires {

typedef enum
{
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_CHAR,
    TYPE_VOID,
    TYPE_STRING,
    TYPE_ERROR
} BaseType;

typedef struct TypeInfo
{
    BaseType base_type;
    int pointer_level;
    int is_array;
    int array_size;
} TypeInfo;

}

%{
#include "parser.tab.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern int yylineno;
extern char *yytext;
extern FILE *yyin;

void yyerror(const char *s);

#define MAX_SCOPE_STACK 100

typedef struct Symbol
{
    char name[64];
    char data_type[32];

    int scope_level;
    int scope_id;

    char scope_name[64];

    int line_number;
    int size;

    char category[20];

    TypeInfo type;

    struct Symbol *next;

} Symbol;

Symbol *symbol_table = NULL;

int current_scope_level = 0;
int current_scope_id = 0;

char scope_stack[MAX_SCOPE_STACK][64];
int scope_id_stack[MAX_SCOPE_STACK];

int scope_top = 0;

int next_scope_id = 1;

char current_decl_type[32];

char current_function_name[64];

TypeInfo current_function_return_type;

int has_main = 0;


/* ============================================================
   TYPE HELPER FUNCTIONS
   ============================================================ */

TypeInfo make_type(BaseType base)
{
    TypeInfo t;

    t.base_type = base;
    t.pointer_level = 0;
    t.is_array = 0;
    t.array_size = 0;

    return t;
}


TypeInfo make_error_type(void)
{
    return make_type(TYPE_ERROR);
}


const char *base_type_name(BaseType type)
{
    switch (type)
    {
        case TYPE_INT:
            return "int";

        case TYPE_FLOAT:
            return "float";

        case TYPE_CHAR:
            return "char";

        case TYPE_VOID:
            return "void";

        case TYPE_STRING:
            return "string";

        default:
            return "error";
    }
}


void type_to_string(TypeInfo type, char *buffer, size_t size)
{
    int i;

    snprintf(
        buffer,
        size,
        "%s",
        base_type_name(type.base_type)
    );

    for (i = 0; i < type.pointer_level; i++)
    {
        strncat(buffer, "*", size - strlen(buffer) - 1);
    }

    if (type.is_array)
    {
        char temp[32];

        snprintf(
            temp,
            sizeof(temp),
            "[%d]",
            type.array_size
        );

        strncat(
            buffer,
            temp,
            size - strlen(buffer) - 1
        );
    }
}


int same_type(TypeInfo a, TypeInfo b)
{
    if (a.base_type == TYPE_ERROR ||
        b.base_type == TYPE_ERROR)
    {
        return 0;
    }

    return
        a.base_type == b.base_type &&
        a.pointer_level == b.pointer_level &&
        a.is_array == b.is_array;
}


int same_value_type(TypeInfo a, TypeInfo b)
{
    if (a.base_type == TYPE_ERROR ||
        b.base_type == TYPE_ERROR)
    {
        return 0;
    }

    return
        a.base_type == b.base_type &&
        a.pointer_level == b.pointer_level;
}


int is_numeric(TypeInfo type)
{
    return
        type.pointer_level == 0 &&
        !type.is_array &&
        (
            type.base_type == TYPE_INT ||
            type.base_type == TYPE_FLOAT ||
            type.base_type == TYPE_CHAR
        );
}


int is_integer(TypeInfo type)
{
    return
        type.pointer_level == 0 &&
        !type.is_array &&
        type.base_type == TYPE_INT;
}


void report_type_error(const char *message)
{
    fprintf(
        stderr,
        "[TYPE ERROR] Line %d: %s\n",
        yylineno,
        message
    );
}


void report_assignment_error(
    const char *variable,
    TypeInfo lhs,
    TypeInfo rhs)
{
    char lhs_name[64];
    char rhs_name[64];

    type_to_string(lhs, lhs_name, sizeof(lhs_name));
    type_to_string(rhs, rhs_name, sizeof(rhs_name));

    fprintf(
        stderr,
        "[TYPE ERROR] Line %d: cannot assign %s to '%s' of type %s.\n",
        yylineno,
        rhs_name,
        variable,
        lhs_name
    );
}


/* ============================================================
   GET SIZE OF DATA TYPE
   ============================================================ */

int get_type_size(const char *type)
{
    if (strcmp(type, "int") == 0)
        return sizeof(int);

    if (strcmp(type, "float") == 0)
        return sizeof(float);

    if (strcmp(type, "char") == 0)
        return sizeof(char);

    if (strcmp(type, "void") == 0)
        return 0;

    return 0;
}


/* ============================================================
   GET CURRENT SCOPE NAME
   ============================================================ */

const char *get_current_scope_name(void)
{
    return scope_stack[scope_top];
}


/* ============================================================
   CHECK DECLARATION IN CURRENT SCOPE
   ============================================================ */

int is_declared_in_current_scope(const char *name)
{
    Symbol *node = symbol_table;

    while (node != NULL)
    {
        if (node->scope_id == current_scope_id &&
            strcmp(node->name, name) == 0)
        {
            return 1;
        }

        node = node->next;
    }

    return 0;
}


/* ============================================================
   FIND VISIBLE SYMBOL
   ============================================================ */

Symbol *find_visible_symbol(const char *name)
{
    int level;

    for (level = scope_top; level >= 0; level--)
    {
        int search_scope_id = scope_id_stack[level];

        Symbol *node = symbol_table;

        while (node != NULL)
        {
            if (node->scope_id == search_scope_id &&
                strcmp(node->name, name) == 0)
            {
                return node;
            }

            node = node->next;
        }
    }

    return NULL;
}


/* ============================================================
   INSERT SYMBOL
   ============================================================ */

void insert_symbol(
    const char *name,
    const char *type,
    const char *category,
    int line,
    int size,
    TypeInfo type_info)
{
    Symbol *new_symbol;

    if (is_declared_in_current_scope(name))
    {
        fprintf(
            stderr,
            "[ERROR] Line %d: '%s' already declared in scope '%s'.\n",
            line,
            name,
            get_current_scope_name()
        );

        return;
    }

    new_symbol = malloc(sizeof(Symbol));

    if (new_symbol == NULL)
    {
        fprintf(
            stderr,
            "[ERROR] Memory allocation failed.\n"
        );

        exit(1);
    }

    strncpy(
        new_symbol->name,
        name,
        sizeof(new_symbol->name) - 1
    );

    new_symbol->name[
        sizeof(new_symbol->name) - 1
    ] = '\0';

    strncpy(
        new_symbol->data_type,
        type,
        sizeof(new_symbol->data_type) - 1
    );

    new_symbol->data_type[
        sizeof(new_symbol->data_type) - 1
    ] = '\0';

    new_symbol->scope_level = current_scope_level;

    new_symbol->scope_id = current_scope_id;

    strncpy(
        new_symbol->scope_name,
        get_current_scope_name(),
        sizeof(new_symbol->scope_name) - 1
    );

    new_symbol->scope_name[
        sizeof(new_symbol->scope_name) - 1
    ] = '\0';

    new_symbol->line_number = line;

    new_symbol->size = size;

    strncpy(
        new_symbol->category,
        category,
        sizeof(new_symbol->category) - 1
    );

    new_symbol->category[
        sizeof(new_symbol->category) - 1
    ] = '\0';

    new_symbol->type = type_info;

    new_symbol->next = symbol_table;

    symbol_table = new_symbol;

    printf(
        "[INFO] Added %-15s Type=%-8s Scope=%-12s "
        "Level=%d ID=%d Line=%d Category=%s Size=%d\n",
        name,
        type,
        get_current_scope_name(),
        current_scope_level,
        current_scope_id,
        line,
        category,
        size
    );
}


/* ============================================================
   ENTER SCOPE
   ============================================================ */

void enter_scope(const char *scope_name)
{
    if (scope_top + 1 >= MAX_SCOPE_STACK)
    {
        fprintf(
            stderr,
            "[ERROR] Maximum scope depth exceeded.\n"
        );

        exit(1);
    }

    scope_top++;

    current_scope_level++;

    current_scope_id = next_scope_id++;

    scope_id_stack[scope_top] = current_scope_id;

    strncpy(
        scope_stack[scope_top],
        scope_name,
        sizeof(scope_stack[scope_top]) - 1
    );

    scope_stack[scope_top][
        sizeof(scope_stack[scope_top]) - 1
    ] = '\0';

    printf(
        "[SCOPE] Entering scope '%s' (level %d, ID %d)\n",
        scope_name,
        current_scope_level,
        current_scope_id
    );
}


/* ============================================================
   EXIT SCOPE
   ============================================================ */

void exit_scope(void)
{
    printf(
        "[SCOPE] Leaving scope '%s' (level %d, ID %d)\n",
        get_current_scope_name(),
        current_scope_level,
        current_scope_id
    );

    if (scope_top > 0)
    {
        scope_top--;

        current_scope_level--;

        current_scope_id =
            scope_id_stack[scope_top];
    }
}


/* ============================================================
   CHECK VARIABLE
   ============================================================ */

Symbol *check_variable(const char *name, int line)
{
    Symbol *symbol = find_visible_symbol(name);

    if (symbol == NULL)
    {
        fprintf(
            stderr,
            "[ERROR] Line %d: Variable '%s' used before declaration.\n",
            line,
            name
        );
    }

    return symbol;
}


/* ============================================================
   PRINT SYMBOL TABLE
   ============================================================ */

void print_symbol_table(void)
{
    Symbol *node = symbol_table;

    printf("\n");
    printf("SYMBOL TABLE\n");
    printf("\n");

    printf(
        "%-20s %-12s %-15s %-8s %-8s %-8s %-12s %-8s\n",
        "Name",
        "Type",
        "Scope",
        "Level",
        "ScopeID",
        "Line",
        "Category",
        "Size"
    );

    printf(
        "------------------------------------------------------------------------------------------------\n"
    );

    while (node != NULL)
    {
        char type_string[64];

        type_to_string(
            node->type,
            type_string,
            sizeof(type_string)
        );

        printf(
            "%-20s %-12s %-15s %-8d %-8d %-8d %-12s %-8d\n",
            node->name,
            type_string,
            node->scope_name,
            node->scope_level,
            node->scope_id,
            node->line_number,
            node->category,
            node->size
        );

        node = node->next;
    }

    printf("\n");
}


/* ============================================================
   FREE SYMBOL TABLE
   ============================================================ */

void free_symbol_table(void)
{
    Symbol *node = symbol_table;

    while (node != NULL)
    {
        Symbol *temp = node;

        node = node->next;

        free(temp);
    }

    symbol_table = NULL;
}

%}


/* ============================================================
   BISON DECLARATIONS
   ============================================================ */

%define parse.error verbose

%union
{
    char *str;
    TypeInfo type;
}


/* ---------- Tokens carrying strings ---------- */

%token <str> ID
%token <str> INT_CONST
%token <str> FLOAT_CONST
%token <str> CHAR_CONST
%token <str> STRING_CONST


/* ---------- Keywords ---------- */

%token INT
%token FLOAT
%token CHAR
%token VOID

%token IF
%token ELSE
%token WHILE
%token DO
%token FOR
%token BREAK
%token CONTINUE
%token RETURN
%token MAIN


/* ---------- Operators ---------- */

%token EQ
%token NE
%token LE
%token GE

%token LT
%token GT

%token AND
%token OR
%token NOT

%token INC
%token DEC

%token ADDASSIGN
%token SUBASSIGN

%token ASSIGN

%token PLUS
%token MINUS
%token MUL
%token DIV
%token MOD

%token AMP


/* ---------- Brackets ---------- */

%token LPAREN
%token RPAREN

%token LBRACKET
%token RBRACKET

%token LBRACE
%token RBRACE

%token SEMICOLON
%token COMMA


/* ---------- Non-terminal types ---------- */

%type <type> type_specifier
%type <type> expression
%type <type> assignment_expression
%type <type> logical_or_expression
%type <type> logical_and_expression
%type <type> equality_expression
%type <type> relational_expression
%type <type> additive_expression
%type <type> multiplicative_expression
%type <type> unary_expression
%type <type> postfix_expression
%type <type> primary_expression
%type <type> expression_opt


/* ---------- Precedence ---------- */

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%right ASSIGN ADDASSIGN SUBASSIGN

%left OR
%left AND

%left EQ NE

%left LT GT LE GE

%left PLUS MINUS

%left MUL DIV MOD

%right UMINUS UPLUS NOT DEREFERENCE

%nonassoc INC DEC


%%


/* ============================================================
   PROGRAM
   ============================================================ */

program
    : external_declarations
      {
          if (!has_main)
          {
              fprintf(
                  stderr,
                  "[WARNING] No 'main' function was found.\n"
              );
          }

          print_symbol_table();
      }
    ;


external_declarations
    : external_declarations external_declaration
    | external_declaration
    ;


external_declaration
    : declaration
    | function_definition
    | main_definition
    ;


/* ============================================================
   FUNCTION DEFINITION
   ============================================================ */

function_definition
    : type_specifier ID
      {
          strcpy(
              current_function_name,
              $2
          );

          current_function_return_type = $1;

          if (is_declared_in_current_scope($2))
          {
              fprintf(
                  stderr,
                  "[ERROR] Line %d: Function '%s' already declared.\n",
                  yylineno,
                  $2
              );
          }
          else
          {
              char function_type[64];

              type_to_string(
                  $1,
                  function_type,
                  sizeof(function_type)
              );

              insert_symbol(
                  $2,
                  function_type,
                  "Function",
                  yylineno,
                  0,
                  $1
              );
          }

          enter_scope($2);
      }
      LPAREN parameter_list_opt RPAREN
      function_body
      {
          exit_scope();

          printf(
              "[INFO] Function '%s' processed successfully.\n",
              current_function_name
          );
      }
    ;


/* ============================================================
   MAIN
   ============================================================ */

main_definition
    : type_specifier MAIN LPAREN RPAREN
      {
          if (has_main)
          {
              fprintf(
                  stderr,
                  "[ERROR] Line %d: Multiple main functions.\n",
                  yylineno
              );
          }
          else
          {
              has_main = 1;

              insert_symbol(
                  "main",
                  base_type_name($1.base_type),
                  "Function",
                  yylineno,
                  0,
                  $1
              );
          }

          current_function_return_type = $1;

          enter_scope("main");
      }
      function_body
      {
          exit_scope();

          printf(
              "[INFO] Main function processed successfully.\n"
          );
      }
    ;


/* ============================================================
   FUNCTION BODY
   ============================================================ */

function_body
    : LBRACE
      declaration_list
      statement_list
      RBRACE
    ;


/* ============================================================
   PARAMETERS
   ============================================================ */

parameter_list_opt
    : parameter_list
    | /* empty */
    ;


parameter_list
    : parameter_list COMMA parameter
    | parameter
    ;


parameter
    : type_specifier ID
      {
          char type_string[64];

          type_to_string(
              $1,
              type_string,
              sizeof(type_string)
          );

          insert_symbol(
              $2,
              type_string,
              "Parameter",
              yylineno,
              get_type_size(
                  base_type_name($1.base_type)
              ),
              $1
          );
      }

    | type_specifier ID LBRACKET RBRACKET
      {
          TypeInfo array_type = $1;

          array_type.is_array = 1;
          array_type.array_size = 0;

          insert_symbol(
              $2,
              base_type_name($1.base_type),
              "Parameter",
              yylineno,
              0,
              array_type
          );
      }
    ;


/* ============================================================
   TYPE SPECIFIER
   ============================================================ */

type_specifier
    : INT
      {
          $$ = make_type(TYPE_INT);

          strcpy(
              current_decl_type,
              "int"
          );
      }

    | FLOAT
      {
          $$ = make_type(TYPE_FLOAT);

          strcpy(
              current_decl_type,
              "float"
          );
      }

    | CHAR
      {
          $$ = make_type(TYPE_CHAR);

          strcpy(
              current_decl_type,
              "char"
          );
      }

    | VOID
      {
          $$ = make_type(TYPE_VOID);

          strcpy(
              current_decl_type,
              "void"
          );
      }
    ;


/* ============================================================
   DECLARATIONS
   ============================================================ */

declaration
    : type_specifier init_declarator_list SEMICOLON
    ;


init_declarator_list
    : init_declarator_list COMMA init_declarator
    | init_declarator
    ;


init_declarator
    : ID
      {
          TypeInfo t = make_type(
              $<type>0.base_type
          );

          /*
             Current declaration type is stored separately
             because the declaration may contain multiple IDs.
          */

          if (strcmp(current_decl_type, "int") == 0)
              t = make_type(TYPE_INT);

          else if (strcmp(current_decl_type, "float") == 0)
              t = make_type(TYPE_FLOAT);

          else if (strcmp(current_decl_type, "char") == 0)
              t = make_type(TYPE_CHAR);

          else
              t = make_type(TYPE_VOID);

          insert_symbol(
              $1,
              current_decl_type,
              "Variable",
              yylineno,
              get_type_size(current_decl_type),
              t
          );
      }

    | ID ASSIGN expression
      {
          TypeInfo lhs;

          if (strcmp(current_decl_type, "int") == 0)
              lhs = make_type(TYPE_INT);

          else if (strcmp(current_decl_type, "float") == 0)
              lhs = make_type(TYPE_FLOAT);

          else if (strcmp(current_decl_type, "char") == 0)
              lhs = make_type(TYPE_CHAR);

          else
              lhs = make_type(TYPE_VOID);

          if (!same_value_type(lhs, $3))
          {
              report_assignment_error(
                  $1,
                  lhs,
                  $3
              );
          }

          insert_symbol(
              $1,
              current_decl_type,
              "Variable",
              yylineno,
              get_type_size(current_decl_type),
              lhs
          );
      }

    | ID LBRACKET INT_CONST RBRACKET
      {
          TypeInfo array_type;

          int element_size =
              get_type_size(current_decl_type);

          int array_length =
              atoi($3);

          if (array_length <= 0)
          {
              fprintf(
                  stderr,
                  "[TYPE ERROR] Line %d: array '%s' must have a positive size.\n",
                  yylineno,
                  $1
              );

              array_length = 0;
          }

          if (strcmp(current_decl_type, "int") == 0)
              array_type = make_type(TYPE_INT);

          else if (strcmp(current_decl_type, "float") == 0)
              array_type = make_type(TYPE_FLOAT);

          else if (strcmp(current_decl_type, "char") == 0)
              array_type = make_type(TYPE_CHAR);

          else
              array_type = make_type(TYPE_VOID);

          array_type.is_array = 1;
          array_type.array_size = array_length;

          insert_symbol(
              $1,
              current_decl_type,
              "Array",
              yylineno,
              element_size * array_length,
              array_type
          );
      }
    ;


/* ============================================================
   DECLARATION / STATEMENT LIST
   ============================================================ */

declaration_list
    : declaration_list declaration
    | /* empty */
    ;


statement_list
    : statement_list statement
    | /* empty */
    ;


/* ============================================================
   COMPOUND STATEMENT
   ============================================================ */

compound_statement
    : LBRACE
      {
          enter_scope("block");
      }
      declaration_list
      statement_list
      RBRACE
      {
          exit_scope();
      }
    ;


/* ============================================================
   STATEMENTS
   ============================================================ */

statement
    : expression_statement
    | compound_statement
    | selection_statement
    | iteration_statement
    | jump_statement
    ;


expression_statement
    : expression_opt SEMICOLON
    ;


expression_opt
    : expression
      {
          $$ = $1;
      }

    | /* empty */
      {
          $$ = make_type(TYPE_VOID);
      }
    ;


/* ============================================================
   IF / ELSE
   ============================================================ */

selection_statement
    : IF LPAREN expression RPAREN statement
      %prec LOWER_THAN_ELSE
      {
          if ($3.base_type == TYPE_ERROR)
          {
              /* expression already generated an error */
          }
      }

    | IF LPAREN expression RPAREN statement ELSE statement
      {
          if ($3.base_type == TYPE_ERROR)
          {
              /* expression already generated an error */
          }
      }
    ;


/* ============================================================
   WHILE / DO / FOR
   ============================================================ */

iteration_statement
    : WHILE LPAREN expression RPAREN statement
      {
          if ($3.base_type == TYPE_ERROR)
          {
              /* expression already generated an error */
          }
      }

    | DO statement WHILE LPAREN expression RPAREN SEMICOLON
      {
          if ($5.base_type == TYPE_ERROR)
          {
              /* expression already generated an error */
          }
      }

    | FOR LPAREN expression_opt SEMICOLON
             expression_opt SEMICOLON
             expression_opt RPAREN
             statement
      {
          if ($5.base_type == TYPE_ERROR)
          {
              /* expression already generated an error */
          }
      }
    ;


/* ============================================================
   RETURN / BREAK / CONTINUE
   ============================================================ */

jump_statement
    : RETURN expression_opt SEMICOLON
      {
          if ($2.base_type != TYPE_VOID &&
              $2.base_type != TYPE_ERROR)
          {
              if (!same_value_type(
                      current_function_return_type,
                      $2))
              {
                  char expected[64];
                  char actual[64];

                  type_to_string(
                      current_function_return_type,
                      expected,
                      sizeof(expected)
                  );

                  type_to_string(
                      $2,
                      actual,
                      sizeof(actual)
                  );

                  fprintf(
                      stderr,
                      "[TYPE ERROR] Line %d: return type mismatch. "
                      "Expected %s but got %s.\n",
                      yylineno,
                      expected,
                      actual
                  );
              }
          }
      }

    | BREAK SEMICOLON

    | CONTINUE SEMICOLON
    ;


/* ============================================================
   EXPRESSION
   ============================================================ */

expression
    : assignment_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   ASSIGNMENT EXPRESSION
   ============================================================ */

assignment_expression
    : ID ASSIGN assignment_expression
      {
          Symbol *symbol =
              check_variable(
                  $1,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              if (!same_value_type(
                      symbol->type,
                      $3))
              {
                  report_assignment_error(
                      $1,
                      symbol->type,
                      $3
                  );
              }

              $$ = symbol->type;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | ID ADDASSIGN assignment_expression
      {
          Symbol *symbol =
              check_variable(
                  $1,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              if (!is_numeric(symbol->type) ||
                  !is_numeric($3))
              {
                  report_type_error(
                      "operands of '+=' must be numeric and of the same type"
                  );
              }
              else if (!same_value_type(
                           symbol->type,
                           $3))
              {
                  report_type_error(
                      "left and right side of '+=' must have the same type"
                  );
              }

              $$ = symbol->type;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | ID SUBASSIGN assignment_expression
      {
          Symbol *symbol =
              check_variable(
                  $1,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              if (!is_numeric(symbol->type) ||
                  !is_numeric($3))
              {
                  report_type_error(
                      "operands of '-=' must be numeric and of the same type"
                  );
              }
              else if (!same_value_type(
                           symbol->type,
                           $3))
              {
                  report_type_error(
                      "left and right side of '-=' must have the same type"
                  );
              }

              $$ = symbol->type;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | ID LBRACKET expression RBRACKET ASSIGN assignment_expression
      {
          Symbol *symbol =
              check_variable(
                  $1,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              if (!symbol->type.is_array)
              {
                  fprintf(
                      stderr,
                      "[TYPE ERROR] Line %d: '%s' is not an array.\n",
                      yylineno,
                      $1
                  );
              }

              if (!is_integer($3))
              {
                  report_type_error(
                      "array index must be of type int"
                  );
              }

              if (!same_value_type(
                      symbol->type,
                      $6))
              {
                  report_assignment_error(
                      $1,
                      symbol->type,
                      $6
                  );
              }

              $$ = symbol->type;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | logical_or_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   LOGICAL OR
   ============================================================ */

logical_or_expression
    : logical_or_expression OR logical_and_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '||' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | logical_and_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   LOGICAL AND
   ============================================================ */

logical_and_expression
    : logical_and_expression AND equality_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '&&' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | equality_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   EQUALITY
   ============================================================ */

equality_expression
    : equality_expression EQ relational_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '==' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | equality_expression NE relational_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '!=' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | relational_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   RELATIONAL
   ============================================================ */

relational_expression
    : relational_expression LT additive_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '<' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | relational_expression GT additive_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '>' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | relational_expression LE additive_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '<=' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | relational_expression GE additive_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '>=' must have the same type"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    | additive_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   ADDITIVE
   ============================================================ */

additive_expression
    : additive_expression PLUS multiplicative_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '+' must have the same type"
              );

              $$ = make_error_type();
          }
          else if (!is_numeric($1))
          {
              report_type_error(
                  "operands of '+' must be numeric"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $1;
          }
      }

    | additive_expression MINUS multiplicative_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '-' must have the same type"
              );

              $$ = make_error_type();
          }
          else if (!is_numeric($1))
          {
              report_type_error(
                  "operands of '-' must be numeric"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $1;
          }
      }

    | multiplicative_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   MULTIPLICATIVE
   ============================================================ */

multiplicative_expression
    : multiplicative_expression MUL unary_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '*' must have the same type"
              );

              $$ = make_error_type();
          }
          else if (!is_numeric($1))
          {
              report_type_error(
                  "operands of '*' must be numeric"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $1;
          }
      }

    | multiplicative_expression DIV unary_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '/' must have the same type"
              );

              $$ = make_error_type();
          }
          else if (!is_numeric($1))
          {
              report_type_error(
                  "operands of '/' must be numeric"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $1;
          }
      }

    | multiplicative_expression MOD unary_expression
      {
          if (!same_value_type($1, $3))
          {
              report_type_error(
                  "operands of '%' must have the same type"
              );

              $$ = make_error_type();
          }
          else if (!is_integer($1))
          {
              report_type_error(
                  "operands of '%' must be integers"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $1;
          }
      }

    | unary_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   UNARY
   ============================================================ */

unary_expression
    : MINUS unary_expression
      %prec UMINUS
      {
          if (!is_numeric($2))
          {
              report_type_error(
                  "unary '-' requires a numeric operand"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $2;
          }
      }

    | PLUS unary_expression
      %prec UPLUS
      {
          if (!is_numeric($2))
          {
              report_type_error(
                  "unary '+' requires a numeric operand"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $2;
          }
      }

    | NOT unary_expression
      %prec NOT
      {
          if (!is_numeric($2))
          {
              report_type_error(
                  "operator '!' requires a numeric operand"
              );
          }

          $$ = make_type(TYPE_INT);
      }

    /* Dereference */
    | MUL unary_expression
      %prec DEREFERENCE
      {
          if ($2.pointer_level <= 0)
          {
              report_type_error(
                  "cannot dereference an integer/non-pointer value"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $2;

              $$.pointer_level--;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    /* Address-of */
    | AMP unary_expression
      {
          if ($2.base_type == TYPE_ERROR)
          {
              $$ = make_error_type();
          }
          else if ($2.base_type == TYPE_VOID)
          {
              report_type_error(
                  "cannot take address of void expression"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = $2;

              $$.pointer_level++;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | INC ID
      {
          Symbol *symbol =
              check_variable(
                  $2,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              if (!is_numeric(symbol->type))
              {
                  report_type_error(
                      "increment operator requires a numeric variable"
                  );
              }

              $$ = symbol->type;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | DEC ID
      {
          Symbol *symbol =
              check_variable(
                  $2,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              if (!is_numeric(symbol->type))
              {
                  report_type_error(
                      "decrement operator requires a numeric variable"
                  );
              }

              $$ = symbol->type;
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }

    | postfix_expression
      {
          $$ = $1;
      }
    ;


/* ============================================================
   POSTFIX
   ============================================================ */

postfix_expression
    : primary_expression
      {
          $$ = $1;
      }

    | primary_expression INC
      {
          if (!is_numeric($1))
          {
              report_type_error(
                  "increment operator requires a numeric operand"
              );
          }

          $$ = $1;
        }

    | primary_expression DEC
      {
          if (!is_numeric($1))
          {
              report_type_error(
                  "decrement operator requires a numeric operand"
              );
          }

          $$ = $1;
        }
    ;


/* ============================================================
   PRIMARY EXPRESSIONS
   ============================================================ */

primary_expression
    : ID
      {
          Symbol *symbol =
              check_variable(
                  $1,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else
          {
              $$ = symbol->type;
          }
      }


    | ID LBRACKET expression RBRACKET
      {
          Symbol *symbol =
              check_variable(
                  $1,
                  yylineno
              );

          if (symbol == NULL)
          {
              $$ = make_error_type();
          }
          else if (!symbol->type.is_array)
          {
              fprintf(
                  stderr,
                  "[TYPE ERROR] Line %d: '%s' is not an array.\n",
                  yylineno,
                  $1
              );

              $$ = make_error_type();
          }
          else if (!is_integer($3))
          {
              report_type_error(
                  "array index must be of type int"
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = symbol->type;

              /*
                 Array element is not itself an array.
              */
              $$.is_array = 0;
              $$.array_size = 0;
          }
      }


    | ID LPAREN argument_list_opt RPAREN
      {
          Symbol *symbol =
              find_visible_symbol($1);

          if (symbol == NULL)
          {
              fprintf(
                  stderr,
                  "[ERROR] Line %d: Function '%s' not declared.\n",
                  yylineno,
                  $1
              );

              $$ = make_error_type();
          }
          else if (strcmp(
                       symbol->category,
                       "Function") != 0)
          {
              fprintf(
                  stderr,
                  "[TYPE ERROR] Line %d: '%s' is not a function.\n",
                  yylineno,
                  $1
              );

              $$ = make_error_type();
          }
          else
          {
              $$ = symbol->type;
          }
      }


    | INT_CONST
      {
          $$ = make_type(TYPE_INT);
      }


    | FLOAT_CONST
      {
          $$ = make_type(TYPE_FLOAT);
      }


    | CHAR_CONST
      {
          $$ = make_type(TYPE_CHAR);
      }


    | STRING_CONST
      {
          $$ = make_type(TYPE_STRING);
      }


    | LPAREN expression RPAREN
      {
          $$ = $2;
      }
    ;


/* ============================================================
   FUNCTION ARGUMENTS
   ============================================================ */

argument_list_opt
    : argument_list
    | /* empty */
    ;


argument_list
    : argument_list COMMA expression
    | expression
    ;


%%


/* ============================================================
   ERROR HANDLER
   ============================================================ */

void yyerror(const char *s)
{
    fprintf(
        stderr,
        "[SYNTAX ERROR] Line %d: %s near '%s'\n",
        yylineno,
        s,
        yytext != NULL ? yytext : "EOF"
    );
}


/* ============================================================
   MAIN
   ============================================================ */

int main(int argc, char **argv)
{
    printf(
        "[SYSTEM] Initializing Symbol Table + Type Checker Parser...\n"
    );

    strcpy(
        scope_stack[0],
        "GLOBAL"
    );

    scope_id_stack[0] = 0;

    current_scope_level = 0;

    current_scope_id = 0;

    scope_top = 0;

    next_scope_id = 1;

    if (argc > 1)
    {
        FILE *file = fopen(
            argv[1],
            "r"
        );

        if (file == NULL)
        {
            fprintf(
                stderr,
                "[ERROR] Could not open file: %s\n",
                argv[1]
            );

            return 1;
        }

        yyin = file;
    }

    if (yyparse() == 0)
    {
        printf(
            "\n[SUCCESS] Parsing completed successfully.\n"
        );
    }
    else
    {
        printf(
            "\n[FAILURE] Parsing failed.\n"
        );
    }

    if (yyin != NULL &&
        yyin != stdin)
    {
        fclose(yyin);
    }

    free_symbol_table();

    return 0;
}