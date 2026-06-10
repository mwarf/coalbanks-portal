#!/bin/bash
# upload-gallery.sh — Resize, optimize, and upload images to Coalbanks R2 bucket
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
# Output: WebP format at quality 80 — optimizes for R2 storage cost.
#
# Requirements:
#   - macOS (uses sips for resizing, cwebp for optimization)
#   - wrangler CLI authenticated with Cloudflare

set -euo pipefail

# --- Config ---
BUCKET="coalbanks-assets"
R2_PUBLIC_URL="https://assets.coalbanks.com"
MAX_WIDTH="${3:-2400}"
WEBP_QUALITY=80

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

# Check for cwebp
if ! command -v cwebp &> /dev/null; then
  echo "Error: cwebp not found. Install with: brew install webp"
  exit 1
fi

# Count images — collect all common image extensions
VALID_IMAGES=()
for ext in jpg jpeg png JPG JPEG PNG webp WEBP; do
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
echo " Format:    WebP (quality ${WEBP_QUALITY})"
echo "=========================================="
echo ""

# --- Create temp directory ---
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# --- Process and upload ---
YAML_OUTPUT=""
TOTAL_ORIGINAL=0
TOTAL_UPLOADED=0
COUNT=0

for img in "${VALID_IMAGES[@]}"; do
  COUNT=$((COUNT + 1))
  FILENAME=$(basename "$img")
  BASENAME="${FILENAME%.*}"

  TEMP_RESIZED="$TEMP_DIR/${BASENAME}_resized.jpg"
  TEMP_WEBP="$TEMP_DIR/${BASENAME}.webp"

  # Get original dimensions and size
  ORIG_WIDTH=$(sips -g pixelWidth "$img" 2>/dev/null | awk '/pixelWidth/{print $2}')
  ORIG_SIZE=$(stat -f%z "$img")
  TOTAL_ORIGINAL=$((TOTAL_ORIGINAL + ORIG_SIZE))

  # Step 1: Resize if wider than max
  if [ "$ORIG_WIDTH" -gt "$MAX_WIDTH" ]; then
    echo "[$COUNT/${#VALID_IMAGES[@]}] $FILENAME (${ORIG_WIDTH}px → ${MAX_WIDTH}px)..."
    sips --resampleWidth "$MAX_WIDTH" "$img" --out "$TEMP_RESIZED" > /dev/null 2>&1
  else
    echo "[$COUNT/${#VALID_IMAGES[@]}] $FILENAME (already ${ORIG_WIDTH}px)..."
    cp "$img" "$TEMP_RESIZED"
  fi

  # Step 2: Convert to WebP
  cwebp -q "$WEBP_QUALITY" "$TEMP_RESIZED" -o "$TEMP_WEBP" > /dev/null 2>&1

  WEBP_SIZE=$(stat -f%z "$TEMP_WEBP")
  TOTAL_UPLOADED=$((TOTAL_UPLOADED + WEBP_SIZE))
  WEBP_KB=$(echo "scale=0; $WEBP_SIZE / 1024" | bc)

  # Step 3: Upload to R2
  OBJECT_KEY="$R2_PATH/${BASENAME}.webp"
  echo "    WebP ${WEBP_KB}KB → $OBJECT_KEY"
  env -i HOME="$HOME" \
    PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.npm-global/bin:$HOME/.nvm/versions/node/v25.9.0/bin" \
    npx wrangler r2 object put "$BUCKET/$OBJECT_KEY" \
      --file="$TEMP_WEBP" \
      --content-type="image/webp" \
      --remote 2>&1 | grep -E "Upload complete|Creating|Error"

  # Build YAML entry
  R2_URL="$R2_PUBLIC_URL/$OBJECT_KEY"
  YAML_OUTPUT+="  - src: \"$R2_URL\""$'\n'
  YAML_OUTPUT+="    alt: \"$BASENAME\""$'\n'
  YAML_OUTPUT+="    caption: \"\""$'\n'

  echo "    ✅ Done"
  echo ""
done

# --- Summary ---
ORIG_MB=$(echo "scale=1; $TOTAL_ORIGINAL / 1048576" | bc)
UPLOADED_MB=$(echo "scale=1; $TOTAL_UPLOADED / 1048576" | bc)
SAVINGS=$(echo "scale=0; 100 - ($TOTAL_UPLOADED * 100 / $TOTAL_ORIGINAL)" | bc)

echo "=========================================="
echo " Upload Complete"
echo "=========================================="
echo " Images:     ${#VALID_IMAGES[@]}"
echo " Original:   ${ORIG_MB}MB"
echo " Uploaded:   ${UPLOADED_MB}MB (WebP q${WEBP_QUALITY})"
echo " Savings:    ${SAVINGS}%"
echo "=========================================="
echo ""
echo "--- Frontmatter YAML ---"
echo ""
echo "gallery:"
echo "$YAML_OUTPUT"
