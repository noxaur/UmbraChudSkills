#!/bin/bash
# publish-media.sh — Publish media assets to GitHub Releases
# Usage: ./publish-media.sh [media-dir]
# Default media-dir: docs/media
#
# Creates cumulative versioned releases (media-v1, media-v2, ...)
# with ALL files from the media directory.

set -e

MEDIA_DIR="${1:-docs/media}"
MANIFEST="$MEDIA_DIR/media-manifest.json"

if [ ! -d "$MEDIA_DIR" ]; then
  echo "Error: Media directory '$MEDIA_DIR' does not exist."
  exit 1
fi

# Count non-manifest files
FILE_COUNT=$(find "$MEDIA_DIR" -type f ! -name "media-manifest.json" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -eq 0 ]; then
  echo "Warning: No media files found in '$MEDIA_DIR'. Nothing to publish."
  exit 0
fi

# Check gh CLI
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' CLI not found. Install: brew install gh"
  exit 1
fi

# Check auth
if ! gh auth status &> /dev/null; then
  echo "Error: Not authenticated with GitHub. Run: gh auth login"
  exit 1
fi

# Get repo info
REPO_FULL=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [ -z "$REPO_FULL" ]; then
  echo "Error: Not in a GitHub repository. Run from within a cloned repo."
  exit 1
fi

REPO_URL="https://github.com/$REPO_FULL"

# Find latest media-vN release
echo "Finding latest media release..."
LATEST_TAG=$(gh release list --limit 30 --json tagName -q '.[].tagName' 2>/dev/null | grep '^media-v' | sort -V | tail -1 || echo "")

if [ -z "$LATEST_TAG" ]; then
  NEXT_VERSION=1
else
  CURRENT_VERSION=$(echo "$LATEST_TAG" | sed 's/media-v//')
  NEXT_VERSION=$((CURRENT_VERSION + 1))
fi

NEW_TAG="media-v${NEXT_VERSION}"
echo "Creating release: $NEW_TAG"

# Create release
gh release create "$NEW_TAG" \
  --title "Media Assets v${NEXT_VERSION}" \
  --notes "Cumulative media assets for $REPO_FULL. Includes $FILE_COUNT files." \
  2>/dev/null || {
    echo "Warning: Release '$NEW_TAG' may already exist. Attempting to upload anyway."
  }

# Upload all files (excluding manifest)
echo "Uploading $FILE_COUNT files..."
UPLOAD_FILES=$(find "$MEDIA_DIR" -type f ! -name "media-manifest.json")

FAILED=0
SUCCESS=0
URLS=()

for file in $UPLOAD_FILES; do
  filename=$(basename "$file")
  echo "  Uploading: $filename"

  if gh release upload "$NEW_TAG" "$file" --clobber 2>/dev/null; then
    asset_url="$REPO_URL/releases/download/$NEW_TAG/$filename"
    URLS+=("$asset_url")
    SUCCESS=$((SUCCESS + 1))
    echo "    → $asset_url"
  else
    echo "    ✗ Failed to upload $filename"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "Publish complete: $SUCCESS uploaded, $FAILED failed"
echo "Release: $REPO_URL/releases/tag/$NEW_TAG"

# Generate manifest
echo "Generating manifest..."
echo '{' > "$MANIFEST"
echo "  \"version\": $NEXT_VERSION," >> "$MANIFEST"
echo "  \"tag\": \"$NEW_TAG\"," >> "$MANIFEST"
echo "  \"repo\": \"$REPO_FULL\"," >> "$MANIFEST"
echo "  \"release_url\": \"$REPO_URL/releases/tag/$NEW_TAG\"," >> "$MANIFEST"
echo "  \"assets\": {" >> "$MANIFEST"

count=0
total=${#URLS[@]}
for i in "${!URLS[@]}"; do
  url="${URLS[$i]}"
  filename=$(basename "$url")
  count=$((count + 1))
  if [ $count -lt $total ]; then
    echo "    \"$filename\": \"$url\"," >> "$MANIFEST"
  else
    echo "    \"$filename\": \"$url\"" >> "$MANIFEST"
  fi
done

echo "  }" >> "$MANIFEST"
echo "}" >> "$MANIFEST"

echo "Manifest saved: $MANIFEST"

# Print embeddable snippets
echo ""
echo "=== Embeddable Snippets ==="
echo ""

for url in "${URLS[@]}"; do
  filename=$(basename "$url")
  ext="${filename##*.}"

  case "$ext" in
    mp4|webm|mov)
      echo "<video src=\"$url\" controls width=\"640\"></video>"
      ;;
    png|jpg|jpeg|gif|webp)
      name="${filename%.*}"
      echo "[![$name]($url)]($url)"
      ;;
    *)
      echo "[$filename]($url)"
      ;;
  esac
done

echo ""
echo "=== End Snippets ==="
