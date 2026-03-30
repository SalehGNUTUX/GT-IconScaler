#!/bin/bash

# setup.sh - System checks and directory setup script

# Function to check if a given command exists
test_command() {
    command -v "$1" &> /dev/null
    return $?
}

# System checks
echo "Performing system checks..."

# Check for required commands
REQUIRED_COMMANDS=(git gcc make)
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! test_command "$cmd"; then
        echo "Error: $cmd is not installed. Please install it before proceeding."
        exit 1
    fi
done

echo "All required commands are installed."

# Create necessary directories
DIRECTORIES=("bin" "src" "include" "lib")
for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "./$dir" ]; then
        echo "Creating directory: $dir"
        mkdir "$dir"
    else
        echo "Directory $dir already exists."
    fi
done

echo "Setup completed successfully!"