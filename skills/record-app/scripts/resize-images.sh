#!/bin/bash
# resize-images.sh — Resize screenshots for gallery embedding
# Usage: ./resize-images.sh <input-dir> <output-dir> [max-width]
# Default max-width: 1200px

set -e

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAX_WIDTH="${3:-1200}"

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: ./resize-images.sh <input-dir> <output-dir> [max-width]"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Detect available resize tool
if command -v sips &> /dev/null; then
  # macOS built-in
  RESIZE_TOOL="sips"
elif command -v convert &> /dev/null; then
  # ImageMagick
  RESIZE_TOOL="convert"
elif command -v ffmpeg &> /dev/null; then
  # ffmpeg fallback
  RESIZE_TOOL="ffmpeg"
else
  echo "Warning: No image resize tool found. Saving originals."
  echo "Install: brew install imagemagick (macOS/Linux) or choco install imagemagick (Windows)"
  cp "$INPUT_DIR"/*.png "$OUTPUT_DIR/" 2>/dev/null || true
  exit 0
fi

echo "Resizing images from $INPUT_DIR to $OUTPUT_DIR (max width: ${MAX_WIDTH}px)"
echo "Using: $RESIZE_TOOL"

COUNT=0
for img in "$INPUT_DIR"/*.png; do
  [ -f "$img" ] || continue
  filename=$(basename "$img")
  output="$OUTPUT_DIR/$filename"

  case "$RESIZE_TOOL" in
    sips)
      sips -Z "$MAX_WIDTH" "$img" --out "$output" >/dev/null 2>&1
      ;;
    convert)
      convert "$img" -resize "${MAX_WIDTH}x" -quality 95 "$output"
      ;;
    ffmpeg)
      ffmpeg -y -i "$img" -vf "scale=${MAX_WIDTH}:-1" -frames:v 1 "$output" 2>/dev/null
      ;;
  esac

  if [ -f "$output" ]; then
    original_size=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null || echo "?")
    new_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null || echo "?")
    echo "  $filename: ${original_size}B → ${new_size}B"
    COUNT=$((COUNT + 1))
  else
    echo "  FAILED: $filename"
  fi
done

echo ""
echo "Resized $COUNT images to $OUTPUT_DIR"
