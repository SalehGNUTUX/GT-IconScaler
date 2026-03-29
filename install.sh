#!/bin/bash

# Script to install the GT-IconScaler

echo "Welcome to the GT-IconScaler Installation!"

echo "Please choose your installation option:"
echo "1. CLI Version"
echo "2. GUI Version"
echo "3. Both Versions"

read -p "Enter your choice (1/2/3): " choice

case $choice in
  1)
    echo "Installing CLI version..."
    # Command to install CLI version
  ;;  
  2)
    echo "Installing GUI version..."
    # Command to install GUI version
  ;;  
  3)
    echo "Installing both versions..."
    # Commands to install both versions
  ;;  
  *)
    echo "Invalid choice. Please run the script again."
    exit 1
  ;;

esac

echo "Installation complete!"