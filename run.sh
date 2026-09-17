#!/usr/bin/env bash
cd "$(dirname "$0")"

if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    /Applications/Godot.app/Contents/MacOS/Godot --path . "$@"
elif command -v godot &> /dev/null; then
    godot --path . "$@"
else
    echo "❌ Không tìm thấy Godot!"
    exit 1
fi
