#!/bin/bash
# capture-ios.sh — iOS Simulator screen capture
# Usage: ./capture-ios.sh <config.json>
# Config format: see SKILL.md Phase 2 example

set -e

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: ./capture-ios.sh <config.json>"
  exit 1
fi

# Check dependencies
if ! command -v xcrun &> /dev/null; then
  echo "Error: xcrun not found. Install Xcode Command Line Tools:"
  echo "  xcode-select --install"
  exit 1
fi

# Parse config (basic JSON parsing with python3)
OUTPUT=$(python3 -c "
import json, sys
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('output', 'docs/media/demo-ios.webm'))
scenes = config.get('scenes', [])
for s in scenes:
    print(f\"SCENE:{s['name']}:{s.get('path', '/')}\")
")

OUTPUT_FILE=$(echo "$OUTPUT" | head -1)
SCENES=$(echo "$OUTPUT" | grep "^SCENE:" | sed 's/^SCENE://')

OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

TMP_DIR="$OUTPUT_DIR/.raw-captures"
mkdir -p "$TMP_DIR"

# Get simulator device ID
DEVICE_ID=$(xcrun simctl list devices available | grep -m1 "iPhone" | sed 's/.*(\(.*\)).*/\1/')
if [ -z "$DEVICE_ID" ]; then
  echo "Error: No iPhone simulator found. Open Xcode → Window → Devices and Simulators → + iPhone"
  exit 1
fi

echo "Using simulator: $DEVICE_ID"

# Boot simulator if not running
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
sleep 3

# Launch app (assumes app is already installed in simulator)
# If app bundle ID is provided, launch it
APP_BUNDLE_ID=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('appBundleId', ''))
" 2>/dev/null || echo "")

if [ -n "$APP_BUNDLE_ID" ]; then
  echo "Launching app: $APP_BUNDLE_ID"
  xcrun simctl launch "$DEVICE_ID" "$APP_BUNDLE_ID" || true
  sleep 2
fi

# Capture each scene
CLIP_PATHS=()
while IFS=: read -r NAME PATH_VAL; do
  [ -z "$NAME" ] && continue
  echo "Capturing: $NAME"

  # Take screenshot
  SCREENSHOT="$TMP_DIR/${NAME}-ios.png"
  xcrun simctl io "$DEVICE_ID" screenshot "$SCREENSHOT"
  CLIP_PATHS+=("$SCREENSHOT")
  echo "  Captured: $SCREENSHOT"
done <<< "$SCENES"

# Stitch into final video using ffmpeg
echo ""
echo "Stitching final video..."

if [ ${#CLIP_PATHS[@]} -eq 0 ]; then
  echo "Error: No captures to stitch"
  exit 1
fi

if [ ${#CLIP_PATHS[@]} -eq 1 ]; then
  ffmpeg -y -loop 1 -i "${CLIP_PATHS[0]}" \
    -vf "zoompan=z='min(zoom+0.0015,1.5)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=25" \
    -t 5 -c:v libvpx-vp9 -pix_fmt yuv420p "$OUTPUT_FILE"
else
  # Build ffmpeg command for multiple images
  INPUTS=""
  FILTER=""
  for i in "${!CLIP_PATHS[@]}"; do
    INPUTS="$INPUTS -loop 1 -t 3 -i \"${CLIP_PATHS[$i]}\""
  done

  # Simple fade transitions between scenes
  ffmpeg -y $INPUTS \
    -filter_complex "$(build_ios_filter ${#CLIP_PATHS[@]})" \
    -map "[outv]" -c:v libvpx-vp9 -pix_fmt yuv420p "$OUTPUT_FILE"
fi

# Clean up
rm -rf "$TMP_DIR"

echo ""
echo "Done: $OUTPUT_FILE"

build_ios_filter() {
  local count=$1
  if [ "$count" -le 1 ]; then
    echo "[0:v]scale=1280:720,setsar=1,fps=25[outv]"
    return
  fi

  local filter=""
  for ((i=0; i<count; i++)); do
    filter="${filter}[${i}:v]scale=1280:720,setsar=1,fps=25[v${i}];"
  done

  # Chain with fade transitions
  filter="${filter}[v0][v1]xfade=transition=fade:duration=0.5:offset=2.5[t1];"
  for ((i=2; i<count; i++)); do
    local prev="t$((i-1))"
    filter="${filter}[${prev}][v${i}]xfade=transition=fade:duration=0.5:offset=$(( (i-1) * 2500 / 1000 ))[t${i}];"
  done
  filter="${filter}[t$((count-1))]null[outv]"
  echo "$filter"
}
