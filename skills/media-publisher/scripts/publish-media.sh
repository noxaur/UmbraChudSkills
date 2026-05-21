#!/bin/bash
# publish-media.sh — Publish media assets for inline GitHub README embedding
# Usage: ./publish-media.sh [media-dir]
# Default media-dir: docs/media
#
# Uploads media to GitHub user-attachments for inline video playback in READMEs.
# Uses gh-image or gh-attach CLI extensions to get user-attachments URLs.
# Falls back to GitHub Releases if those aren't available.

set -e

MEDIA_DIR="${1:-docs/media}"
MANIFEST="$MEDIA_DIR/media-manifest.json"

if [ ! -d "$MEDIA_DIR" ]; then
  echo "Error: Media directory '$MEDIA_DIR' does not exist."
  exit 1
fi

# Count non-manifest files
FILE_COUNT=$(find "$MEDIA_DIR" -type f ! -name "media-manifest.json" ! -name "*.json" | wc -l | tr -d ' ')
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

# Detect upload method
UPLOAD_METHOD=""

# Method 1: gh-image (reads browser cookies, gets user-attachments URLs)
if gh extension list 2>/dev/null | grep -q "gh-image"; then
  UPLOAD_METHOD="gh-image"
  echo "Using: gh-image (user-attachments URLs — inline video support)"
  echo "Note: Requires browser auth session token. Falls back to Releases if unavailable."
# Method 2: gitshot (zero-config, uses Releases on dedicated repo)
elif command -v gitshot &> /dev/null || (gh extension list 2>/dev/null | grep -q "gitshot"); then
  UPLOAD_METHOD="gitshot"
  echo "Using: gitshot (Release assets — clickable thumbnails)"
# Method 3: GitHub Releases (official API, no inline video)
else
  UPLOAD_METHOD="releases"
  echo "Using: GitHub Releases (official API — clickable thumbnails, no inline video)"
  echo "Tip: Install gh-image for inline video: gh extension install drogers0/gh-image"
fi

echo ""

FAILED=0
SUCCESS=0
declare -A URLS_MAP

# Upload files based on method
echo "Uploading $FILE_COUNT files..."

for file in "$MEDIA_DIR"/*; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")
  [[ "$filename" == *.json ]] && continue

  echo "  Uploading: $filename"
  asset_url=""

  case "$UPLOAD_METHOD" in
    gh-image)
      # gh-image outputs markdown: ![filename](URL)
      output=$(gh image "$file" --repo "$REPO_FULL" 2>/dev/null) || true
      # Extract URL from markdown: ![name](URL)
      asset_url=$(echo "$output" | grep -oP 'https://github\.com/user-attachments/assets/[^)]+' || echo "")
      ;;

    gitshot)
      # gitshot: `gh shot` when installed as gh extension, `gitshot` when global npm
      if command -v gitshot &> /dev/null; then
        output=$(gitshot "$file" --raw 2>/dev/null) || true
      else
        output=$(gh shot "$file" --raw 2>/dev/null) || true
      fi
      asset_url="$output"
      ;;

    releases)
      # Find latest media-vN release; reuse it to avoid tag pollution
      LATEST_TAG=$(gh release list --limit 30 --json tagName -q '.[].tagName' 2>/dev/null | grep '^media-v' | sort -V | tail -1 || echo "")

      if [ -z "$LATEST_TAG" ]; then
        LATEST_TAG="media-v1"
        gh release create "$LATEST_TAG" \
          --title "Media Assets v1" \
          --notes "Cumulative media assets for $REPO_FULL" \
          2>/dev/null || true
      fi

      # Upload file to the existing/latest release (--clobber overwrites duplicates)
      if gh release upload "$LATEST_TAG" "$file" --clobber 2>/dev/null; then
        asset_url="$REPO_URL/releases/download/$LATEST_TAG/$filename"
      fi
      ;;
  esac

  if [ -n "$asset_url" ]; then
    URLS_MAP["$filename"]="$asset_url"
    SUCCESS=$((SUCCESS + 1))
    echo "    → $asset_url"
  else
    echo "    ✗ Failed to upload $filename"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "Upload complete: $SUCCESS succeeded, $FAILED failed"

# Generate manifest
echo "Generating manifest..."
echo '{' > "$MANIFEST"
echo "  \"upload_method\": \"$UPLOAD_METHOD\"," >> "$MANIFEST"
echo "  \"repo\": \"$REPO_FULL\"," >> "$MANIFEST"
echo "  \"assets\": {" >> "$MANIFEST"

count=0
total=${#URLS_MAP[@]}
for filename in "${!URLS_MAP[@]}"; do
  url="${URLS_MAP[$filename]}"
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

for filename in "${!URLS_MAP[@]}"; do
  url="${URLS_MAP[$filename]}"
  ext="${filename##*.}"
  name="${filename%.*}"

  case "$ext" in
    mp4|webm|mov)
      if [[ "$url" == *"user-attachments"* ]]; then
        # Inline video — works in README
        echo "<video src=\"$url\" controls width=\"640\"></video>"
      else
        # Release URL — clickable thumbnail fallback
        echo "[![$name (video)](https://img.shields.io/badge/▶-Play-blue?style=for-the-badge)]($url)"
      fi
      ;;
    png|jpg|jpeg|gif|webp)
      echo "[![$name]($url)]($url)"
      ;;
    *)
      echo "[$filename]($url)"
      ;;
  esac
done

echo ""
echo "=== End Snippets ==="
