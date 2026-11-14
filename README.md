# MiniCompiler

A collection of compiler design and system programming assignments implemented in C, focusing on the fundamental phases and techniques involved in language processing.

This repository brings together four independent projects covering lexical analysis, parsing, symbol table management, and intermediate code generation.

## Repository Structure

```text
MiniCompiler/
│
├── 3AddressCodeGeneration/
│   └── README.md
│
├── LL1PredictiveParser/
│   └── README.md
│
├── LexicalAnalyzer/
│   └── README.md
│
├── SymbolTableGeneration/
│   └── README.md
│
└── README.md
```

## Projects

### 1. Three Address Code Generation

**Directory:** `3AddressCodeGeneration/`

Implements the generation of Three Address Code (TAC), an intermediate representation used in compiler design.

**Key concepts:**
- Intermediate code generation
- Syntax-directed translation
- Expression evaluation
- Temporary variable generation
- Representation of operations using three-address instructions

[Explore Three Address Code Generation](./3AddressCodeGeneration/)

### 2. LL(1) Predictive Parser

**Directory:** `LL1PredictiveParser/`

Implements a non-recursive, table-driven LL(1) predictive parser for a context-free grammar.

The grammar is transformed to eliminate left recursion and make it suitable for predictive parsing.

**Key concepts:**
- Context-Free Grammars (CFG)
- Left recursion elimination
- FIRST and FOLLOW concepts
- Predictive parsing table
- Stack-based parsing
- Syntax analysis

[Explore LL(1) Predictive Parser](./LL1PredictiveParser/)

### 3. Lexical Analyzer

**Directory:** `LexicalAnalyzer/`

Implements a lexical analyzer in C using transition-diagram-based recognition to identify tokens from a C source program.

**Token categories:**
- Arithmetic, relational, logical, bitwise, and assignment operators
- Reserved keywords
- Identifiers
- Integer constants
- Parentheses and curly braces

**Error detection requirements:**
- Identifier and numeric constant length overflow
- Illegal characters
- Unmatched strings
- Spelling errors in reserved keywords
- Invalid characters within numeric constants

The implementation follows the concepts of `yylex`, `yytext`, `yyleng`, and `yylineno`.

[Explore Lexical Analyzer](./LexicalAnalyzer/)

### 4. Symbol Table Generation

**Directory:** `SymbolTableGeneration/`

Explores symbol table generation and management, a fundamental component of a compiler's semantic analysis phase.

**Key concepts:**
- Symbol table construction
- Identifier information management
- Symbol lookup and insertion
- Scope and declaration handling, where implemented
- Semantic information management

[Explore Symbol Table Generation](./SymbolTableGeneration/)

## Technologies Used

- **Programming Language:** C
- **Compiler Tools:** Flex and Bison/Yacc, where applicable
- **Build Tools:** GCC, Make
- **Core Concepts:** Lexical Analysis, Syntax Analysis, Semantic Analysis, Intermediate Code Generation

## Getting Started

Clone the repository:

```bash
git clone https://github.com/DyutiKole009/MiniCompiler.git
cd MiniCompiler
```

Each project is maintained independently and contains its own source code, README, and build instructions where applicable.

Navigate to the required project directory and follow its individual README.

For projects containing a Makefile, build using:

```bash
make
```

Clean generated build files using:

```bash
make clean
```

## Learning Objectives

This repository demonstrates practical implementations of fundamental compiler-design concepts:

1. Understanding how source code is converted into tokens.
2. Recognizing grammatical structures through parsing techniques.
3. Managing identifiers and their associated information.
4. Generating intermediate representations of source programs.
5. Understanding the relationship between different phases of a compiler.

---

**Author:** Dyuti Kole  
**Repository:** [MiniCompiler](https://github.com/DyutiKole009/MiniCompiler)
