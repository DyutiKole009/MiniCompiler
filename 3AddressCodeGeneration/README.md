# Mini Compiler: Lexical Analysis, Parsing, Semantic Checks, and Intermediate Code Generation

A small compiler front end implemented in C to generate intermediate 3 Address Code using **Flex** and **GNU Bison (Yacc)**. It reads a source file, performs lexical analysis and grammar-based parsing, checks variable declarations and basic type consistency, and generates three-address code represented internally as quadruples.

## Features

- Lexical analysis with Flex (`lexer.l`).
- Grammar-based parsing with GNU Bison (`parser.y`).
- Supports `int` and `float` variable declarations.
- Supports assignments, arithmetic expressions (`+`, `-`, `*`, `/`), unary minus, and parentheses.
- Supports relational conditions (`<`, `>`, `<=`, `>=`, `==`, `!=`).
- Supports `if`, `if-else`, `while`, and compound statements using braces.
- Maintains a simple symbol table and checks for duplicate declarations and undeclared variables.
- Checks type consistency in arithmetic expressions, assignments, and relational conditions.
- Generates intermediate code using quadruples and prints the corresponding three-address code.
- Writes generated code to `output.txt` in the current working directory.

## Project structure

```text
Mini-Compiler/
├── lexer.l
├── parser.y
├── Makefile
├── README.md
├── .gitignore
```

Copy the supplied `lexer.l` and `parser.y` into this directory. The generated files (`lex.yy.c`, `parser.tab.c`, and `parser.tab.h`) are created during the build and should not be committed.

## Requirements

On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install build-essential flex bison
```

## Build

```bash
make
```

This generates the `compiler` executable.

## Run

```bash
./compiler sample.c
```

The compiler prints the three-address code to the terminal and writes the same output to `output.txt`.

To remove generated build files:

```bash
make clean
```

## Example input

```c
int a, b, c;
float x;

a = 10;
b = 20;
c = a + b * 2;

if (c > 30) {
    a = c - 5;
} else {
    a = c + 5;
}

while (a > 10) {
    a = a - 1;
}

x = 3.5;
```

## Implementation files

- `lexer.l`: token definitions and lexical rules.
- `parser.y`: grammar, semantic actions, symbol-table operations, type checks, quadruple generation, and the command-line entry point.

## License

Add a license if you intend to permit reuse or redistribution. Until then, no license is granted by this repository.
