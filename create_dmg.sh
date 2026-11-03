#!/bin/bash
set -e

DMG_TEMP_DIR="dmg_input"

# Cleanup function to be run on exit or interrupt
cleanup() {
  echo "=== Cleaning up temporary build artifacts ==="
  
  # 1. Detach any lingering temporary dmg mounts or Sindri PDF mounts
  hdiutil info | grep -o "/Volumes/[^	]*" | grep -E "(/Volumes/dmg\.|/Volumes/Sindri)" | while read -r mount_point; do
    echo "Detaching leftover mount point $mount_point..."
    hdiutil detach "$mount_point" -force 2>/dev/null || true
  done
  
  # 2. Remove temporary packaging directory
  if [ -d "$DMG_TEMP_DIR" ]; then
    rm -rf "$DMG_TEMP_DIR"
  fi
  
  # 3. Clean up any leftover rw.*.dmg temporary files
  rm -f rw.*.Sindri\ PDF.dmg rw.*.dmg 2>/dev/null || true
  
  # 4. Unregister temporary build copies and volume copies from macOS LaunchServices
  LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
  if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -dump 2>/dev/null | grep -o "/Volumes/[^()]*Sindri PDF[^()]*" | sort -u | while read -r p; do
      "$LSREGISTER" -u "$p" 2>/dev/null || true
    done
    "$LSREGISTER" -u "$PWD/$DMG_TEMP_DIR/Sindri PDF.app" 2>/dev/null || true
    "$LSREGISTER" -u "$PWD/Sindri PDF.app" 2>/dev/null || true
    if [ -d "/Applications/Sindri PDF.app" ]; then
      "$LSREGISTER" -f "/Applications/Sindri PDF.app" 2>/dev/null || true
    fi
  fi
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

# Step 4: Keep installed version in /Applications in sync and clean duplicate app
echo "Updating installed /Applications/Sindri PDF.app..."
rm -rf "/Applications/Sindri PDF.app"
cp -R "Sindri PDF.app" "/Applications/"
if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -f "/Applications/Sindri PDF.app" 2>/dev/null || true
  "$LSREGISTER" -u "$PWD/Sindri PDF.app" 2>/dev/null || true
fi
# Remove local duplicate bundle so macOS LaunchServices only sees /Applications/Sindri PDF.app
rm -rf "Sindri PDF.app"
