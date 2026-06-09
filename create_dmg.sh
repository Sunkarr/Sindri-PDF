#!/bin/bash
set -e

DMG_TEMP_DIR="dmg_input"

# Cleanup function to be run on exit or interrupt
cleanup() {
  echo "=== Cleaning up temporary build artifacts ==="
  
  # 1. Detach any lingering temporary dmg mounts
  hdiutil info | grep -o "/Volumes/dmg\.[a-zA-Z0-9]*" | while read -r mount_point; do
    echo "Detaching leftover mount point $mount_point..."
    hdiutil detach "$mount_point" -force || true
  done
  
  # 2. Remove temporary packaging directory
  if [ -d "$DMG_TEMP_DIR" ]; then
    rm -rf "$DMG_TEMP_DIR"
  fi
  
  # 3. Clean up any leftover rw.*.dmg temporary files
  rm -f rw.*.Sindri\ PDF.dmg rw.*.dmg 2>/dev/null || true
}

# Run cleanup on script exit (whether successful or aborted)
trap cleanup EXIT

# Step 0: Initial cleanup of leftover files from previous failed runs
cleanup

# Step 1: Build the app
echo "=== Building Sindri PDF.app ==="
chmod +x build.sh
./build.sh

# Step 2: Prepare temporary packaging directory
echo "=== Preparing Packaging Directory ==="
mkdir -p "$DMG_TEMP_DIR"
cp -R "Sindri PDF.app" "$DMG_TEMP_DIR/"

# Step 3: Package using create-dmg
echo "=== Creating DMG package ==="
rm -f "Sindri PDF.dmg"

# Try running create-dmg with full styling.
# If it fails (commonly due to macOS AppleScript/Finder automation permissions - error -1743),
# fallback to running with --skip-jenkins which skips Finder window/icon formatting.
if ! create-dmg \
  --volname "Sindri PDF" \
  --volicon "Sindri PDF.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 350 \
  --icon-size 100 \
  --icon "Sindri PDF.app" 175 120 \
  --hide-extension "Sindri PDF.app" \
  --app-drop-link 425 120 \
  --no-internet-enable \
  "Sindri PDF.dmg" \
  "$DMG_TEMP_DIR"; then
  
  echo "⚠️ create-dmg with Finder styling failed (likely due to missing macOS AppleScript/Finder permissions)."
  echo "Retrying build with --skip-jenkins (skips Finder icon layout, but creates a working DMG)..."
  
  # Clean up the failed/partial run's temporary disk image
  rm -f "Sindri PDF.dmg"
  rm -f rw.*.Sindri\ PDF.dmg rw.*.dmg 2>/dev/null || true
  
  create-dmg \
    --volname "Sindri PDF" \
    --volicon "Sindri PDF.app/Contents/Resources/AppIcon.icns" \
    --no-internet-enable \
    --skip-jenkins \
    "Sindri PDF.dmg" \
    "$DMG_TEMP_DIR"
fi

echo "=== DMG Build Completed Successfully: Sindri PDF.dmg ==="
