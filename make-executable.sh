#!/bin/bash

# Quick script to make all necessary scripts executable
# Run this if you encounter permission errors

echo "Making all scripts executable..."

# Main scripts
chmod +x install.sh 2>/dev/null && echo "✓ install.sh"
chmod +x fix-permissions.sh 2>/dev/null && echo "✓ fix-permissions.sh"
chmod +x validate-fixes.sh 2>/dev/null && echo "✓ validate-fixes.sh"
chmod +x setup.sh 2>/dev/null && echo "✓ setup.sh"
chmod +x fix-java11-compatibility.sh 2>/dev/null && echo "✓ fix-java11-compatibility.sh"

# Scripts directory
if [ -d scripts ]; then
    find scripts -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
    echo "✓ All scripts in scripts/ directory"
fi

echo "Done! All scripts are now executable."
