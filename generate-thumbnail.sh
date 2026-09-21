#!/bin/sh
# Generate thumbnail snapshots with Intel VA-API hardware acceleration fallback to CPU
APP="$1"
NAME="$2"

if [ -z "$APP" ] || [ -z "$NAME" ]; then
    echo "Usage: $0 <app> <name>"
    exit 1
fi

INPUT_URL="rtmp://localhost:1935/${APP}/${NAME}"
OUTPUT_PATH="/tmp/thumbnails/${NAME}.jpg"

# Check if Intel VA-API device is present and accessible
if [ -e "/dev/dri/renderD128" ] && [ -r "/dev/dri/renderD128" ] && [ -w "/dev/dri/renderD128" ]; then
    exec /usr/bin/ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
        -i "$INPUT_URL" \
        -vf "fps=24,scale=320:180" \
        -update 1 -y "$OUTPUT_PATH"
else
    # Fallback to software (CPU) decoding/scaling
    exec /usr/bin/ffmpeg \
        -i "$INPUT_URL" \
        -vf "fps=24,scale=320:180" \
        -update 1 -y "$OUTPUT_PATH"
fi
