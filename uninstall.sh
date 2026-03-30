#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Messages in English
WELCOME_EN="This script will remove all installed icons, desktop entries, binaries, and update the icon cache and desktop database."
CONFIRM_EN="Do you want to proceed with the uninstallation? (y/n): "
SUCCESS_EN="Uninstallation completed successfully."
ERROR_EN="An error occurred during uninstallation."

# Messages in Arabic
WELCOME_AR="سيقوم هذا البرنامج النصي بإزالة جميع الرموز المثبتة، ومدخلات سطح المكتب، والملفات الثنائية، وتحديث ذاكرة التخزين المؤقت للرموز وقاعدة بيانات سطح المكتب."
CONFIRM_AR="هل تريد المتابعة مع الإلغاء؟ (نعم/لا): "
SUCCESS_AR="اكتمل إلغاء التثبيت بنجاح."
ERROR_AR="حدث خطأ أثناء إلغاء التثبيت."

# Function to remove icons, desktop entries, and binaries
uninstall() {
    # Add commands to remove icons and desktop entries here
    # Example:
    # rm -rf ~/.local/share/icons/*
    # rm -rf ~/.local/share/applications/*
    
    # Example command to update icon cache and desktop database
    # update-icon-caches ~/.local/share/icons
    # update-desktop-database ~/.local/share/applications
    
    echo -e "${GREEN}${SUCCESS_EN}${NC}"
    echo -e "${GREEN}${SUCCESS_AR}${NC}"
}

# Welcome Message
echo -e "${WELCOME_EN}"
echo -e "${WELCOME_AR}"

# User Confirmation
read -p "$(echo -e ${CONFIRM_EN})$(echo -e ${CONFIRM_AR})" -n 1 -r
echo    # New line
if [[ $REPLY =~ ^[Yy]$ || $REPLY =~ ^[نن]$ ]]; then
    uninstall
else
    echo -e "${RED}Uninstallation cancelled.${NC}"
fi
