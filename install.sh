#!/bin/bash

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo "خطأ: الدليل '$1' غير موجود." >&2
        exit 1
    fi
}

# Validate required directories
check_directory "./src"
check_directory "./bin"
check_directory "./lib"

# Validate requirements
REQUIRED_PACKAGES=("curl" "git" "make")
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! command -v $pkg &> /dev/null; then
        echo "خطأ: حزمة '$pkg' مطلوبة ولكنها غير مثبتة." >&2
        exit 1
    fi
done

# Main installation process

# Place your installation commands here, for example:
if ! make; then
    echo "خطأ: فشل في تنفيذ الأمر 'make'." >&2
    exit 1
fi

echo "تم التثبيت بنجاح!"