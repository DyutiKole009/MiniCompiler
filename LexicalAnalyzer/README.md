# Lexical Analyzer in C

A transition-diagram-based lexical analyzer implemented in C to recognize tokens from a complete C source program. The project demonstrates the fundamental concepts of lexical analysis, token classification, character-by-character scanning, and lexical error detection.

The implementation follows the ideas of the traditional Lex/Flex interface, including `yylex()`, `yytext`, `yyleng`, and `yylineno`.

## Objective

Design and implement a lexical analyzer using a transition diagram that reads a complete C program as input and identifies different categories of tokens while detecting common lexical errors.

## Features

### 1. Token Recognition

The lexical analyzer recognizes the following categories:

| Category | Tokens |
|---|---|
| Arithmetic Operators | `+`, `-`, `*`, `/`, `%` |
| Relational Operators | `<`, `>`, `<=`, `>=`, `==`, `!=` |
| Logical Operators | `&&`, `||`, `!` |
| Bitwise Operators | `&`, `|`, `^`, `~` |
| Assignment Operators | `=`, `+=`, `-=`, `*=`, `/=`, `%=` |
| Reserved Words | `int`, `float`, `char`, `for`, `do`, `while`, `if`, `else` |
| Identifiers | Variable and function identifiers |
| Integer Constants | Integer-valued constants |
| Parentheses | `(`, `)` |
| Curly Braces | `{`, `}` |

### 2. Lexical Error Detection

The analyzer aims to detect the following lexical errors:

- **Exceeding identifier length:** Identifiers longer than the permitted maximum length.
- **Exceeding numeric constant length:** Integer constants exceeding the permitted length.
- **Illegal characters:** Characters that do not belong to the supported lexical categories.
- **Unmatched strings:** String literals without a valid closing quotation mark.
- **Reserved-word spelling errors:** Inputs resembling reserved words but containing spelling mistakes.
- **Invalid characters in numeric constants:** For example, `12$34`.

### 3. Lexical Analyzer Interface

The implementation follows the concepts of the Lex/Flex interface:

| Component | Purpose |
|---|---|
| `yylex()` | Scans the input and identifies the next token. |
| `yytext` | Stores the currently recognized lexeme. |
| `yyleng` | Stores the length of the current lexeme. |
| `yylineno` | Tracks the current source-code line number. |

These concepts help organize token recognition and error reporting in a manner similar to conventional lexical analyzers.

## Transition Diagram

The lexical analyzer is designed around character-by-character state transitions.

The scanner identifies the starting character and follows the appropriate transition path to recognize identifiers, reserved words, numeric constants, operators, and delimiters.

Typical recognition paths include:

- Alphabetic character → Identifier / Reserved Word
- Digit → Integer Constant
- Operator character → Arithmetic / Relational / Logical / Bitwise / Assignment Operator
- Parenthesis or brace → Delimiter
- Unsupported character → Lexical Error

## Input and Output

**Input:** A complete C source program supplied to the lexical analyzer.

**Output:**
- Recognized token categories.
- Corresponding lexemes.
- Token lengths.
- Source line numbers.
- Lexical error messages, where applicable.

## Example

### Input

```c
int main() {
    int x = 10;
    int y = 20;
    if (x < y) {
        x += 5;
    }
    return x;
}
```

### Illustrative token output

```text
KEYWORD       int
IDENTIFIER    main
LPAREN        (
RPAREN        )
LBRACE        {
KEYWORD       int
IDENTIFIER    x
ASSIGN        =
INTEGER       10
SEMICOLON     ;
KEYWORD       int
IDENTIFIER    y
ASSIGN        =
INTEGER       20
SEMICOLON     ;
KEYWORD       if
LPAREN        (
IDENTIFIER    x
LESS_THAN     <
IDENTIFIER    y
RPAREN        )
LBRACE        {
IDENTIFIER    x
ADD_ASSIGN    +=
INTEGER       5
SEMICOLON     ;
RBRACE        }
RBRACE        }
```

*The output above illustrates the expected token classification; actual formatting depends on the implementation.*

## Technologies Used

- C Programming Language
- Finite State Machines
- Transition Diagrams
- Lexical Analysis
- Token Recognition
- File Handling

## Compilation and Execution

Using GCC:

```bash
gcc -Wall -Wextra -std=c11 lexer.c -o lexer
```

Run the analyzer:

```bash
./lexer
```

If the implementation accepts a source file as a command-line argument:

```bash
./lexer input.c
```

## Learning Outcomes

- Understanding the role of lexical analysis in compiler construction.
- Designing transition diagrams for token recognition.
- Implementing a finite-state-based scanner.
- Distinguishing reserved words, identifiers, constants, and operators.
- Maintaining lexeme length and source line information.
- Detecting and reporting lexical errors.

---

**Project:** Lexical Analyzer

**Domain:** Compiler Design | Lexical Analysis | Finite State Machines
