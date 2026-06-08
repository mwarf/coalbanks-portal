#!/bin/bash
# upload-video.sh — Upload video to Cloudflare Stream and output frontmatter
#
# Usage:
#   ./upload-video.sh <video-file> "Video Title"
#
# Examples:
#   ./upload-video.sh /Volumes/A022/kasko-social/kasko-rushes-june-5.mov "Kasko Cattle — Scouting Dailies, June 5"
#   ./upload-video.sh ~/Desktop/rough-cut-v1.mp4 "Better Everywhere — Rough Cut Edit 1"
#
# Requirements:
#   - Cloudflare Stream subscription active on your account
#   - Cloudflare API token with Stream:Edit permission
#   - Set CLOUDFLARE_API_TOKEN env var, or add it to .env in this directory
#
# Supports files up to 30GB via tus resumable upload.
# After upload, prints YAML frontmatter to paste into your Obsidian content file.

set -euo pipefail

# --- Config ---
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-31b8f0c35512bdf0006e669ed89ed74a}"
CUSTOMER_CODE="31b8f0c35512bdf0006e669ed89ed74a"  # for embed URLs

# Load .env if present
if [ -f "$(dirname "$0")/.env" ]; then
  set -a
  source "$(dirname "$0")/.env"
  set +a
fi

API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"

if [ -z "$API_TOKEN" ]; then
  echo "Error: CLOUDFLARE_API_TOKEN not set."
  echo ""
  echo "Set it as an env var:"
  echo "  export CLOUDFLARE_API_TOKEN=your-token-here"
  echo ""
  echo "Or add to .env in the repo root:"
  echo "  CLOUDFLARE_API_TOKEN=your-token-here"
  exit 1
fi

# --- Args ---
if [ $# -lt 2 ]; then
  echo "Usage: ./upload-video.sh <video-file> \"Video Title\""
  echo ""
  echo "Example:"
  echo "  ./upload-video.sh /Volumes/A022/kasko-social/kasko-rushes-june-5.mov \"Scouting Dailies — June 5\""
  exit 1
fi

VIDEO_FILE="$1"
VIDEO_TITLE="$2"

if [ ! -f "$VIDEO_FILE" ]; then
  echo "Error: File not found: $VIDEO_FILE"
  exit 1
fi

FILE_SIZE=$(stat -f%z "$VIDEO_FILE" 2>/dev/null || stat --printf="%s" "$VIDEO_FILE" 2>/dev/null)
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
FILE_SIZE_GB=$(echo "scale=1; $FILE_SIZE_MB / 1024" | bc 2>/dev/null || echo "${FILE_SIZE_MB}MB")

echo ""
echo "  ┌──────────────────────────────────────────┐"
echo "  │  Coalbanks Stream Upload                 │"
echo "  └──────────────────────────────────────────┘"
echo ""
echo "  File:  $(basename "$VIDEO_FILE")"
echo "  Size:  ${FILE_SIZE_MB} MB (${FILE_SIZE_GB} GB)"
echo "  Title: $VIDEO_TITLE"
echo ""

# --- Step 1: Initiate tus resumable upload ---
echo "→ Initiating resumable upload..."

HEADERS_FILE=$(mktemp)

curl -s -D "$HEADERS_FILE" -o /dev/null -X POST \
  "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/stream" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Tus-Resumable: 1.0.0" \
  -H "Upload-Length: ${FILE_SIZE}" \
  -H "Upload-Metadata: name $(echo -n "$VIDEO_TITLE" | base64)" \
  2>/dev/null

# Extract the upload URL and media ID from response headers
UPLOAD_URL=$(grep -i "^location:" "$HEADERS_FILE" | sed 's/[Ll]ocation: *//' | tr -d '\r\n')
STREAM_MEDIA_ID=$(grep -i "^stream-media-id:" "$HEADERS_FILE" | sed 's/[Ss]tream-[Mm]edia-[Ii][Dd]: *//' | tr -d '\r\n')
rm -f "$HEADERS_FILE"

if [ -z "$UPLOAD_URL" ]; then
  echo "Error: Failed to initiate tus upload."
  echo "Make sure your API token has Stream:Edit permissions."
  exit 1
fi

# If no media ID in headers, extract from URL
if [ -z "$STREAM_MEDIA_ID" ]; then
  STREAM_MEDIA_ID=$(echo "$UPLOAD_URL" | grep -oE '[a-f0-9]{32}' | head -1)
fi

echo "  Stream ID: $STREAM_MEDIA_ID"
echo ""

# --- Step 2: Upload the file via tus PATCH ---
echo "→ Uploading video..."
echo "  (${FILE_SIZE_MB} MB — this will take a while for large files)"
echo ""

CHUNK_SIZE=$((100 * 1024 * 1024))  # 100MB chunks
OFFSET=0
CHUNK_FILE=$(mktemp)

while [ $OFFSET -lt $FILE_SIZE ]; do
  REMAINING=$((FILE_SIZE - OFFSET))
  CURRENT_CHUNK=$CHUNK_SIZE
  if [ $REMAINING -lt $CURRENT_CHUNK ]; then
    CURRENT_CHUNK=$REMAINING
  fi

  PROGRESS=$((OFFSET * 100 / FILE_SIZE))
  UPLOADED_MB=$((OFFSET / 1024 / 1024))
  printf "\r  [%-50s] %d%% (%d / %d MB)" \
    "$(printf '#%.0s' $(seq 1 $((PROGRESS / 2))) 2>/dev/null)" \
    "$PROGRESS" "$UPLOADED_MB" "$FILE_SIZE_MB"

  # Extract chunk using dd
  SKIP_BLOCKS=$((OFFSET / 1048576))
  COUNT_BLOCKS=$((CURRENT_CHUNK / 1048576))
  REMAINDER_BYTES=$((CURRENT_CHUNK % 1048576))

  if [ $COUNT_BLOCKS -gt 0 ]; then
    dd if="$VIDEO_FILE" of="$CHUNK_FILE" bs=1048576 skip=$SKIP_BLOCKS count=$COUNT_BLOCKS 2>/dev/null
  else
    : > "$CHUNK_FILE"
  fi

  # Append any remainder bytes (last partial megabyte)
  if [ $REMAINDER_BYTES -gt 0 ]; then
    REMAINDER_OFFSET=$(( (SKIP_BLOCKS + COUNT_BLOCKS) * 1048576 ))
    dd if="$VIDEO_FILE" bs=1 skip=$REMAINDER_OFFSET count=$REMAINDER_BYTES 2>/dev/null >> "$CHUNK_FILE"
  fi

  ACTUAL_CHUNK=$(stat -f%z "$CHUNK_FILE" 2>/dev/null || stat --printf="%s" "$CHUNK_FILE" 2>/dev/null)

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$UPLOAD_URL" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Tus-Resumable: 1.0.0" \
    -H "Upload-Offset: ${OFFSET}" \
    -H "Content-Type: application/offset+octet-stream" \
    -H "Content-Length: ${ACTUAL_CHUNK}" \
    --data-binary "@${CHUNK_FILE}" \
    2>/dev/null)

  if [ "$HTTP_CODE" -ge 400 ] 2>/dev/null; then
    echo ""
    echo "Error: Upload chunk failed (HTTP $HTTP_CODE) at offset $OFFSET"
    echo "You can retry — tus uploads are resumable."
    rm -f "$CHUNK_FILE"
    exit 1
  fi

  OFFSET=$((OFFSET + ACTUAL_CHUNK))
done

rm -f "$CHUNK_FILE"

printf "\r  [%-50s] 100%% (%d / %d MB)\n" \
  "$(printf '#%.0s' $(seq 1 50))" "$FILE_SIZE_MB" "$FILE_SIZE_MB"
echo ""

# --- Step 3: Wait for processing ---
echo "→ Upload complete. Waiting for Stream to process..."

DURATION=""
THUMBNAIL=""
READY="False"

for i in $(seq 1 60); do
  STATUS_JSON=$(curl -s \
    "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/stream/${STREAM_MEDIA_ID}" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    2>/dev/null)

  READY=$(echo "$STATUS_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d.get('result', {})
print('True' if r.get('readyToStream') else 'False')
" 2>/dev/null || echo "False")

  if [ "$READY" = "True" ]; then
    DURATION=$(echo "$STATUS_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('result', {}).get('duration', 0))
" 2>/dev/null || echo "0")

    THUMBNAIL=$(echo "$STATUS_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('result', {}).get('thumbnail', ''))
" 2>/dev/null || echo "")

    PLAYBACK=$(echo "$STATUS_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
pb = d.get('result', {}).get('playback', {})
print(pb.get('hls', ''))
" 2>/dev/null || echo "")

    break
  fi

  PCT=$(echo "$STATUS_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d.get('result', {}).get('status', {})
print(s.get('pctComplete', '...'))
" 2>/dev/null || echo "...")

  printf "\r  Processing: %s%%" "$PCT"
  sleep 5
done

echo ""
echo ""

# --- Step 4: Output ---
echo "  ┌──────────────────────────────────────────┐"
echo "  │  Upload Complete                         │"
echo "  └──────────────────────────────────────────┘"
echo ""
echo "  Stream ID:  $STREAM_MEDIA_ID"

if [ -n "$DURATION" ] && [ "$DURATION" != "0" ]; then
  DUR_INT=${DURATION%.*}
  MINS=$((DUR_INT / 60))
  SECS=$((DUR_INT % 60))
  echo "  Duration:   ${MINS}m ${SECS}s"
fi

echo ""
echo "  ─── Paste into your Markdown frontmatter ───"
echo ""
echo "  videos:"
echo "    - id: \"${STREAM_MEDIA_ID}\""
echo "    title: \"${VIDEO_TITLE}\""

if [ -n "$THUMBNAIL" ]; then
  echo "    poster: \"${THUMBNAIL}\""
fi

echo ""
echo "  ─── Or as an asset link ───"
echo ""
echo "  asset_links:"
echo "    - label: \"${VIDEO_TITLE}\""
echo "    url: \"https://customer-${CUSTOMER_CODE}.cloudflarestream.com/${STREAM_MEDIA_ID}/watch\""
echo ""

if [ "$READY" != "True" ]; then
  echo "  Note: Video is still processing on Cloudflare's side."
  echo "  The Stream ID is correct — it will be playable shortly."
  echo "  Check status:"
  echo "    curl -s https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/stream/${STREAM_MEDIA_ID} \\"
  echo "      -H 'Authorization: Bearer \$CLOUDFLARE_API_TOKEN' | python3 -m json.tool"
fi

echo ""
