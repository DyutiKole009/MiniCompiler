#ifndef TOKENS_H
#define TOKENS_H

/*------------------------------
    Single Character Tokens
------------------------------*/

/* Arithmetic Operators */
#define PLUS_TOK        '+'
#define MINUS_TOK       '-'
#define MUL_TOK         '*'
#define DIV_TOK         '/'
#define MOD_TOK         '%'
#define SEMICOLON_TOK ';'

/* Assignment */
#define ASSIGN_TOK      '='

/* Relational */
#define LT_TOK          '<'
#define GT_TOK          '>'

/* Logical */
#define NOT_TOK         '!'

/* Bitwise */
#define BITAND_TOK      '&'
#define BITOR_TOK       '|'
#define XOR_TOK         '^'
#define BITNOT_TOK      '~'

/* Parentheses and Braces */
#define LPAREN_TOK      '('
#define RPAREN_TOK      ')'
#define LBRACE_TOK      '{'
#define RBRACE_TOK      '}'

/*------------------------------
    Multi-character Operators
------------------------------*/

/* Relational */
#define EQ_TOK          256     /* == */
#define NE_TOK          257     /* != */
#define LE_TOK          258     /* <= */
#define GE_TOK          259     /* >= */

/* Logical */
#define AND_TOK         260     /* && */
#define OR_TOK          261     /* || */

/* Assignment */
#define ADD_ASSIGN_TOK  262     /* += */
#define SUB_ASSIGN_TOK  263     /* -= */
#define MUL_ASSIGN_TOK  264     /* *= */
#define DIV_ASSIGN_TOK  265     /* /= */
#define MOD_ASSIGN_TOK  266     /* %= */

#define AND_ASSIGN_TOK  267     /* &= */
#define OR_ASSIGN_TOK   268     /* |= */
#define XOR_ASSIGN_TOK  269     /* ^= */
#define INC_TOK         270     /* ++ */
#define DEC_TOK         271     /* -- */

/*------------------------------
    Reserved Words
------------------------------*/

#define INT_TOK         300
#define FLOAT_TOK       301
#define CHAR_TOK        302

#define IF_TOK          303
#define ELSE_TOK        304
#define FOR_TOK         305
#define WHILE_TOK       306
#define DO_TOK          307

/*------------------------------
    Identifiers & Constants
------------------------------*/

#define IDENTIFIER_TOK  350
#define INTEGER_TOK     351
#define FLOAT_CONST_TOK 352
#define STRING_TOK      353

/*------------------------------
    End of File
------------------------------*/

#define EOF_TOK         400

#endif
