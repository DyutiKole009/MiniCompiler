CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -O2
TARGET = parser
SOURCE = main.c

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) *.o
