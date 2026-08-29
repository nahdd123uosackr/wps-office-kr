#!/bin/bash
# wps-office-disable-mime-detection.sh
# Disables WPS Office's startup MIME type detection that overrides system associations
# This prevents WPS from creating ~/.local/share/mime/packages/Override.xml

# Create the config directory if it doesn't exist
CONFIG_DIR="$HOME/.config/Kingsoft"
CONFIG_FILE="$CONFIG_DIR/Office.conf"

mkdir -p "$CONFIG_DIR"

# Disable file association detection at startup
if [ -f "$CONFIG_FILE" ]; then
    # Check if the setting already exists
    if ! grep -q "do_not_detect_file_association_while_startup" "$CONFIG_FILE"; then
        # Add to [common] section or create it
        if grep -q "^\[common\]" "$CONFIG_FILE"; then
            sed -i '/^\[common\]/a do_not_detect_file_association_while_startup=true' "$CONFIG_FILE"
        else
            echo -e "\n[common]\ndo_not_detect_file_association_while_startup=true" >> "$CONFIG_FILE"
        fi
    fi
else
    # Create new config file with the setting
    cat > "$CONFIG_FILE" << 'EOF'
[common]
do_not_detect_file_association_while_startup=true
EOF
fi

# Remove any existing Override.xml that may have been created
OVERRIDE_FILE="$HOME/.local/share/mime/packages/Override.xml"
if [ -f "$OVERRIDE_FILE" ]; then
    rm -f "$OVERRIDE_FILE"
    # Update MIME database
    if command -v update-mime-database >/dev/null 2>&1; then
        update-mime-database "$HOME/.local/share/mime" >/dev/null 2>&1 || true
    fi
fi

# Also update system MIME database if we have permissions
if [ -w "/usr/share/mime" ] && command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database /usr/share/mime >/dev/null 2>&1 || true
fi

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

exit 0