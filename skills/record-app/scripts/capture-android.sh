#!/bin/bash
# capture-android.sh — Android device/emulator screen capture
# Usage: ./capture-android.sh <config.json>

set -e

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: ./capture-android.sh <config.json>"
  exit 1
fi

# Check dependencies
if ! command -v adb &> /dev/null; then
  echo "Error: adb not found. Install Android SDK Platform Tools:"
  echo "  brew install --cask android-platform-tools  (macOS)"
  echo "  sudo apt install adb                        (Linux)"
  exit 1
fi

# Check device connected
if ! adb devices | grep -q "device$"; then
  echo "Error: No Android device or emulator connected."
  echo "  Start an emulator via Android Studio, or connect a device via USB."
  exit 1
fi

# Parse config
OUTPUT=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('output', 'docs/media/demo-android.webm'))
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

# Launch app if package name provided
APP_PACKAGE=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('appPackage', ''))
" 2>/dev/null || echo "")

if [ -n "$APP_PACKAGE" ]; then
  echo "Launching app: $APP_PACKAGE"
  adb shell monkey -p "$APP_PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  sleep 3
fi

# Capture each scene
CLIP_PATHS=()
while IFS=: read -r NAME PATH_VAL; do
  [ -z "$NAME" ] && continue
  echo "Capturing: $NAME"

  SCREENSHOT="$TMP_DIR/${NAME}-android.png"
  adb exec-out screencap -p > "$SCREENSHOT"
  CLIP_PATHS+=("$SCREENSHOT")
  echo "  Captured: $SCREENSHOT"
done <<< "$SCENES"

# Stitch into final video
echo ""
echo "Stitching final video..."

if [ ${#CLIP_PATHS[@]} -eq 0 ]; then
  echo "Error: No captures to stitch"
  exit 1
fi

if [ ${#CLIP_PATHS[@]} -eq 1 ]; then
  ffmpeg -y -loop 1 -i "${CLIP_PATHS[0]}" \
    -vf "zoompan=z='min(zoom+0.0015,1.5)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920:fps=25" \
    -t 5 -c:v libvpx-vp9 -pix_fmt yuv420p "$OUTPUT_FILE"
else
  INPUTS=""
  for i in "${!CLIP_PATHS[@]}"; do
    INPUTS="$INPUTS -loop 1 -t 3 -i \"${CLIP_PATHS[$i]}\""
  done

  FILTER=""
  for ((i=0; i<${#CLIP_PATHS[@]}; i++)); do
    FILTER="${FILTER}[${i}:v]scale=1080:1920,setsar=1,fps=25[v${i}];"
  done

  FILTER="${FILTER}[v0][v1]xfade=transition=fade:duration=0.5:offset=2.5[t1];"
  for ((i=2; i<${#CLIP_PATHS[@]}; i++)); do
    local prev="t$((i-1))"
    FILTER="${FILTER}[${prev}][v${i}]xfade=transition=fade:duration=0.5:offset=$(( (i-1) * 2500 / 1000 ))[t${i}];"
  done
  FILTER="${FILTER}[t$(( ${#CLIP_PATHS[@]} - 1 ))]null[outv]"

  ffmpeg -y $INPUTS -filter_complex "$FILTER" -map "[outv]" -c:v libvpx-vp9 -pix_fmt yuv420p "$OUTPUT_FILE"
fi

# Clean up
rm -rf "$TMP_DIR"

echo ""
echo "Done: $OUTPUT_FILE"
