#!/bin/bash
set -e

# Step 1: Build the app
echo "=== Building SimplePDF.app ==="
chmod +x build.sh
./build.sh

# Step 2: Prepare temporary packaging directory
echo "=== Preparing Packaging Directory ==="
DMG_TEMP_DIR="dmg_input"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
cp -R "SimplePDF.app" "$DMG_TEMP_DIR/"

# Step 3: Package using create-dmg
echo "=== Creating DMG package ==="
rm -f "SimplePDF.dmg"

create-dmg \
  --volname "SimplePDF" \
  --window-pos 200 120 \
  --window-size 600 350 \
  --icon-size 100 \
  --icon "SimplePDF.app" 175 120 \
  --app-drop-link 425 120 \
  --no-internet-enable \
  "SimplePDF.dmg" \
  "$DMG_TEMP_DIR"

# Step 4: Clean up
rm -rf "$DMG_TEMP_DIR"

echo "=== DMG Build Completed Successfully: SimplePDF.dmg ==="
