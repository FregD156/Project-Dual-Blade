#!/bin/bash
cd "$(dirname "$0")"
echo "=== ĐANG KHỞI CHẠY PROJECT DUAL BLADE ==="

# Ưu tiên ứng dụng Godot.app trong máy hoặc Homebrew godot
if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    /Applications/Godot.app/Contents/MacOS/Godot --path . scenes_3d/World1_Bastion_3D.tscn
elif command -v godot &> /dev/null; then
    godot --path . scenes_3d/World1_Bastion_3D.tscn
else
    echo "❌ Không tìm thấy Godot!"
    read -p "Nhấn Enter để thoát..."
    exit 1
fi
