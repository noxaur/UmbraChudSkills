#!/bin/bash
# capture-linux.sh — Linux native app screen capture
# Usage: ./capture-linux.sh <config.json>

set -e

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: ./capture-linux.sh <config.json>"
  exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg not found."
  echo "  Ubuntu/Debian: sudo apt install ffmpeg"
  echo "  Fedora: sudo dnf install ffmpeg"
  echo "  Arch: sudo pacman -S ffmpeg"
  exit 1
fi

# Parse config
OUTPUT=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('output', 'docs/media/demo-linux.webm'))
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

# Launch app if command provided
APP_CMD=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('appCommand', ''))
" 2>/dev/null || echo "")

if [ -n "$APP_CMD" ]; then
  echo "Launching app: $APP_CMD"
  $APP_CMD &
  APP_PID=$!
  sleep 3
fi

# Detect display server (X11 or Wayland)
if [ -n "$WAYLAND_DISPLAY" ]; then
  CAPTURE_METHOD="wayland"
  if ! command -v wf-recorder &> /dev/null && ! command -v gnome-screenshot &> /dev/null; then
    echo "Warning: No Wayland screenshot tool found. Install gnome-screenshot or slurp+grim."
  fi
else
  CAPTURE_METHOD="x11"
  if ! command -v import &> /dev/null && ! command -v scrot &> /dev/null; then
    echo "Warning: No X11 screenshot tool found. Install imagemagick (import) or scrot."
  fi
fi

# Capture each scene
CLIP_PATHS=()
while IFS=: read -r NAME PATH_VAL; do
  [ -z "$NAME" ] && continue
  echo "Capturing: $NAME"

  SCREENSHOT="$TMP_DIR/${NAME}-linux.png"

  if [ "$CAPTURE_METHOD" = "x11" ]; then
    if command -v import &> /dev/null; then
      import -window root "$SCREENSHOT"
    elif command -v scrot &> /dev/null; then
      scrot "$SCREENSHOT"
    else
      echo "Error: No screenshot tool available for X11"
      exit 1
    fi
  else
    if command -v grim &> /dev/null; then
      grim "$SCREENSHOT"
    elif command -v gnome-screenshot &> /dev/null; then
      gnome-screenshot -f "$SCREENSHOT"
    else
      echo "Error: No screenshot tool available for Wayland"
      exit 1
    fi
  fi

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
    -vf "zoompan=z='min(zoom+0.0015,1.5)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=25" \
    -t 5 -c:v libvpx-vp9 -pix_fmt yuv420p "$OUTPUT_FILE"
else
  INPUTS=""
  for i in "${!CLIP_PATHS[@]}"; do
    INPUTS="$INPUTS -loop 1 -t 3 -i \"${CLIP_PATHS[$i]}\""
  done

  FILTER=""
  for ((i=0; i<${#CLIP_PATHS[@]}; i++)); do
    FILTER="${FILTER}[${i}:v]scale=1280:720,setsar=1,fps=25[v${i}];"
  done

  FILTER="${FILTER}[v0][v1]xfade=transition=fade:duration=0.5:offset=2.5[t1];"
  for ((i=2; i<${#CLIP_PATHS[@]}; i++)); do
    FILTER="${FILTER}[t$((i-1))][v${i}]xfade=transition=fade:duration=0.5:offset=$(( (i-1) * 2500 / 1000 ))[t${i}];"
  done
  FILTER="${FILTER}[t$(( ${#CLIP_PATHS[@]} - 1 ))]null[outv]"

  ffmpeg -y $INPUTS -filter_complex "$FILTER" -map "[outv]" -c:v libvpx-vp9 -pix_fmt yuv420p "$OUTPUT_FILE"
fi

# Kill launched app if started
if [ -n "$APP_PID" ]; then
  kill $APP_PID 2>/dev/null || true
fi

# Clean up
rm -rf "$TMP_DIR"

echo ""
echo "Done: $OUTPUT_FILE"
