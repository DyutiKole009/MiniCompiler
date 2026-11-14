# Mini Compiler with Scoped Symbol Table and Type Checking

A Flex/Bison-based mini compiler front end written in C. It performs lexical analysis, parsing, scoped symbol-table management, type checking, and reports semantic/syntax errors.

## Features

- Lexical analysis using Flex.
- Grammar-based parsing using Bison.
- Symbol table implemented as a linked list.
- Scope tracking using a scope stack, scope levels, and unique scope IDs.
- Global, function, and nested block scopes.
- Duplicate declaration checks within the current scope.
- Lookup of visible identifiers from the innermost scope outward.
- Symbol metadata: identifier, data type, category, scope, declaration line, and size.
- Basic type checking for assignments, arithmetic/logical expressions, array indexing, and return statements.
- Support for scalar variables, arrays, function parameters, and function declarations.

## Repository structure

```text
SymbolTableGeneration/
├── lexer.l
├── parser.y
├── Makefile
├── README.md
├── .gitignore
```

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

This generates the Flex/Bison C sources and builds the executable named `compiler`.

## Run

```bash
./compiler esample.c
```

To provide input interactively:

```bash
./compiler
```

The parser prints symbol insertion and scope events, semantic/syntax diagnostics, and the final symbol table.

## Symbol table design

Each symbol-table entry stores:

| Field | Meaning |
|---|---|
| `name` | Identifier name |
| `data_type` | Base type string |
| `scope_level` | Nesting depth |
| `scope_id` | Unique ID for the declaring scope |
| `scope_name` | Global, function, or block scope label |
| `line_number` | Source line where the symbol was declared |
| `size` | Approximate storage size based on the implementation's type-size function |
| `category` | Variable, Array, Parameter, or Function |
| `type` | Structured type metadata, including base type and array information |

The symbol table is a singly linked list. New symbols are inserted at the head. A scope stack maintains the active scope. Lookup walks from the current scope toward enclosing scopes and returns the first matching declaration.

## Scope behaviour

- Global declarations are stored in the global scope.
- A function definition creates a function scope.
- A compound block creates a nested block scope.
- A declaration with the same name is rejected if that name already exists in the current scope.
- An inner scope may declare a name that also exists in an outer scope; lookup resolves the nearest visible declaration.

## Notes and limitations

- This project is a compiler front end with semantic checks and intermediate-code-related grammar/actions as implemented in `parser.y`; it does not generate native machine code.
- The `size` field uses the host compiler's `sizeof(int)`, `sizeof(float)`, and `sizeof(char)`, so it is an implementation-level estimate rather than a target-machine memory layout.
- The implementation's symbol-table and type-checking behaviour is defined by the supplied source files. Unsupported language features should not be assumed to work merely because they exist in full C.
- The example is intended to exercise global, function, and nested block scopes, along with symbol-table output.

## Clean generated files

```bash
make clean
```
