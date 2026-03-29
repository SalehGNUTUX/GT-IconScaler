#!/bin/bash

echo "Choose the version to install:"
echo "1. CLI"
echo "2. GUI"
echo "3. Both"

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo "You 선택한 CLI version."
        ;;  
    2)
        echo "You 선택한 GUI version."
        ;;  
    3)
        echo "You 선택한 Both versions."
        ;;  
    *)
        echo "Invalid choice! Please select 1, 2, or 3."
        ;;  
esac