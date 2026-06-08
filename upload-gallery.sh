#!/bin/bash
# upload-gallery.sh — Resize images and upload to Coalbanks R2 bucket
#
# Usage:
#   ./upload-gallery.sh <r2-path> <source-folder> [max-width]
#
# Examples:
#   ./upload-gallery.sh kasko-cattle/location-scouting /Volumes/A022/Kasko-Drone-Edits
#   ./upload-gallery.sh stranville-living/bts ~/Photos/stranville 1800
#
# Arguments:
#   r2-path       Path prefix in the R2 bucket (e.g., client/folder)
#   source-folder Local folder containing the source images
#   max-width     Optional. Max width in pixels (default: 2400)
#
# Requirements:
#   - macOS (uses sips for resizing)
#   - wrangler CLI authenticated with Cloudflare

set -euo pipefail

# --- Config ---
BUCKET="coalbanks-assets"
R2_PUBLIC_URL="https://assets.coalbanks.com"
MAX_WIDTH="${3:-2400}"
QUALITY=85

# --- Validate args ---
if [ $# -lt 2 ]; then
  echo "Usage: ./upload-gallery.sh <r2-path> <source-folder> [max-width]"
  echo "  e.g. ./upload-gallery.sh kasko-cattle/location-scouting /Volumes/A022/Kasko-Drone-Edits"
  exit 1
fi

R2_PATH="$1"
SOURCE_DIR="$2"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source folder not found: $SOURCE_DIR"
  exit 1
fi

# Count images — collect all common image extensions
VALID_IMAGES=()
for ext in jpg jpeg png JPG JPEG PNG; do
  for img in "$SOURCE_DIR"/*."$ext"; do
    [ -f "$img" ] && VALID_IMAGES+=("$img")
  done
done

if [ ${#VALID_IMAGES[@]} -eq 0 ]; then
  echo "Error: No images found in $SOURCE_DIR"
  exit 1
fi

echo "=========================================="
echo " Coalbanks Gallery Upload"
echo "=========================================="
echo " Source:    $SOURCE_DIR"
echo " R2 path:  $BUCKET/$R2_PATH/"
echo " Images:   ${#VALID_IMAGES[@]}"
echo " Max width: ${MAX_WIDTH}px"
echo "=========================================="
echo ""

# --- Create temp directory ---
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# --- Process and upload ---
YAML_OUTPUT=""
TOTAL_ORIGINAL=0
TOTAL_RESIZED=0
COUNT=0

for img in "${VALID_IMAGES[@]}"; do
  COUNT=$((COUNT + 1))
  FILENAME=$(basename "$img")
  # Normalize extension to lowercase
  EXT="${FILENAME##*.}"
  BASENAME="${FILENAME%.*}"
  LOWER_EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

  # Determine content type
  case "$LOWER_EXT" in
    jpg|jpeg) CONTENT_TYPE="image/jpeg" ;;
    png)      CONTENT_TYPE="image/png" ;;
    *)        CONTENT_TYPE="application/octet-stream" ;;
  esac

  TEMP_FILE="$TEMP_DIR/${BASENAME}.${LOWER_EXT}"

  # Get original dimensions and size
  ORIG_WIDTH=$(sips -g pixelWidth "$img" 2>/dev/null | awk '/pixelWidth/{print $2}')
  ORIG_SIZE=$(stat -f%z "$img")
  TOTAL_ORIGINAL=$((TOTAL_ORIGINAL + ORIG_SIZE))

  # Resize if wider than max
  if [ "$ORIG_WIDTH" -gt "$MAX_WIDTH" ]; then
    echo "[$COUNT/${#VALID_IMAGES[@]}] Resizing $FILENAME (${ORIG_WIDTH}px -> ${MAX_WIDTH}px)..."
    sips --resampleWidth "$MAX_WIDTH" "$img" --out "$TEMP_FILE" > /dev/null 2>&1
  else
    echo "[$COUNT/${#VALID_IMAGES[@]}] $FILENAME already <= ${MAX_WIDTH}px, copying..."
    cp "$img" "$TEMP_FILE"
  fi

  RESIZED_SIZE=$(stat -f%z "$TEMP_FILE")
  TOTAL_RESIZED=$((TOTAL_RESIZED + RESIZED_SIZE))

  # Upload to R2
  OBJECT_KEY="$R2_PATH/${BASENAME}.${LOWER_EXT}"
  echo "    Uploading to $BUCKET/$OBJECT_KEY ($(echo "scale=0; $RESIZED_SIZE / 1024" | bc)KB)..."
  wrangler r2 object put "$BUCKET/$OBJECT_KEY" \
    --file="$TEMP_FILE" \
    --content-type="$CONTENT_TYPE" \
    --remote 2>&1 | grep -v "wrangler\|---\|WARNING\|local simulator"

  # Build YAML entry
  R2_URL="$R2_PUBLIC_URL/$OBJECT_KEY"
  YAML_OUTPUT+="  - src: \"$R2_URL\""$'\n'
  YAML_OUTPUT+="    alt: \"$BASENAME\""$'\n'
  YAML_OUTPUT+="    caption: \"\""$'\n'

  echo "    Done."
  echo ""
done

# --- Summary ---
ORIG_MB=$(echo "scale=1; $TOTAL_ORIGINAL / 1048576" | bc)
RESIZED_MB=$(echo "scale=1; $TOTAL_RESIZED / 1048576" | bc)
SAVINGS=$(echo "scale=0; 100 - ($TOTAL_RESIZED * 100 / $TOTAL_ORIGINAL)" | bc)

echo "=========================================="
echo " Upload Complete"
echo "=========================================="
echo " Images:     ${#VALID_IMAGES[@]}"
echo " Original:   ${ORIG_MB}MB"
echo " Uploaded:   ${RESIZED_MB}MB"
echo " Savings:    ${SAVINGS}%"
echo "=========================================="
echo ""
echo "--- Frontmatter YAML (paste into Obsidian) ---"
echo ""
echo "gallery:"
echo "$YAML_OUTPUT"
