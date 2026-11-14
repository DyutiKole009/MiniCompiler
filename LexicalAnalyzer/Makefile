CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -O2
TARGET = lexer
SOURCE = lexer.c

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(SOURCE) -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

# Run the lexer on a C source file:
# make run FILE=test_cases/valid.c
run-file: $(TARGET)
	./$(TARGET) $(FILE)

clean:
	rm -f $(TARGET) *.o
