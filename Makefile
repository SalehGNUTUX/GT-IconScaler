# Makefile for building and installing GT-IconScaler

# Define the compiler and flags
CC = gcc
CFLAGS = -Wall -Werror

# Define the targets
TARGET = gt_icon_scaler

# List of source files
SRCS = main.c utils.c icon_scaler.c

# Build the target
all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

# Install target
install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

# Clean target
clean:
	rm -f $(TARGET)