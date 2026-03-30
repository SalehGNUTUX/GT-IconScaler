#!/bin/bash

# GT-IconScaler Installation Script

# Update package list and install dependencies
sudo apt update

# Copy icons to the corresponding directories
sudo cp -r GT-IconScaler-CLI-ICON-icons/* /usr/share/icons/
sudo cp -r GT-IconScaler-GUI-ICON-icons/* /usr/share/icons/

# Make binaries executable and place them in /usr/local/bin/
sudo cp -r bin/* /usr/local/bin/
sudo chmod +x /usr/local/bin/*

# Setup desktop entry
cat <<EOF | sudo tee /usr/share/applications/gt-iconscaler.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=GT-IconScaler
Exec=gt-iconscaler
Icon=/usr/share/icons/gt-iconscaler-icon.png
Terminal=false
Categories=Utility;
EOF

echo "Installation complete!"