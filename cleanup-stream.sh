#!/bin/sh
# Clean up thumbnail file when streaming stops
NAME="$1"
if [ -n "$NAME" ]; then
    rm -f "/tmp/thumbnails/${NAME}.jpg"
fi
