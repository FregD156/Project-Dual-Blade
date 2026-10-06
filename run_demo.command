#!/bin/bash
cd "$(dirname "$0")"

# Màu sắc terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}${BOLD}============================================================${NC}"
echo -e "${CYAN}${BOLD}       PROJECT DUAL BLADE (HeroFD) — 2.5D HD-2D DEMO       ${NC}"
echo -e "${CYAN}${BOLD}============================================================${NC}"
echo -e "${YELLOW}HƯỚNG DẪN ĐIỀU KHIỂN:${NC}"
echo -e " • ${BOLD}[A / D]${NC}      : Di chuyển trái / phải"
echo -e " • ${BOLD}[Space]${NC}      : Nhảy đơn / Nhảy đúp / Bám tường nhảy cao"
echo -e " • ${BOLD}[J]${NC}          : Tấn công Song Đao (Combo 4 hit)"
echo -e " • ${BOLD}[K]${NC}          : Phản đòn Cross-Parry (Cửa sổ 0.16s, phản kích chí mạng)"
echo -e " • ${BOLD}[L]${NC}          : Lướt hư ảnh Shadow Dash (Khung bất tử i-frame)"
echo -e " • ${BOLD}[S + J]${NC}      : Bổ nhào Spinning Dive"
echo -e " • ${BOLD}[I]${NC}          : Vũ điệu bão kiếm Blade Dance (Tất sát)"
echo -e " • ${BOLD}[B]${NC}          : Mở Túi Đồ & Hợp thành đồ (Merge 5-to-1)"
echo -e " • ${BOLD}[M]${NC}          : Mở Bản Đồ Vượt Ải Fast Travel"
echo -e " • ${BOLD}[F3]${NC}         : Bật/Tắt Debug Overlay (SpawnPoints, PlayerStart, Quái)"
echo -e "${CYAN}------------------------------------------------------------${NC}"

# Tìm kiếm Godot Engine trên macOS
GODOT_BIN=""
if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -f "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
elif command -v godot &> /dev/null; then
    GODOT_BIN="$(command -v godot)"
elif command -v godot4 &> /dev/null; then
    GODOT_BIN="$(command -v godot4)"
fi

if [ -z "$GODOT_BIN" ]; then
    echo -e "${RED}❌ LỖI: Không tìm thấy Godot Engine!${NC}"
    echo "Vui lòng cài đặt Godot vào /Applications/Godot.app"
    read -p "Nhấn Enter để thoát..."
    exit 1
fi

echo -e "${GREEN}✓ Đã tìm thấy Godot:${NC} $GODOT_BIN"
echo -e "${CYAN}------------------------------------------------------------${NC}"

TARGET_SCENE=""

# Kiểm tra nếu có tham số dòng lệnh
if [ "$1" == "w1" ] || [ "$1" == "1" ]; then
    TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
elif [ "$1" == "w2" ] || [ "$1" == "2" ]; then
    TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
elif [ "$1" == "menu" ] || [ "$1" == "3" ]; then
    TARGET_SCENE="scenes/MainMenu.tscn"
elif [ "$1" == "test" ] || [ "$1" == "4" ]; then
    echo -e "\n${YELLOW}=== ĐANG CHẠY BỘ KIỂM THỬ TỰ ĐỘNG (TEST SUITE) ===${NC}"
    "$GODOT_BIN" --headless -s tests/test_milestone1_spawn_system.gd
    exit $?
fi

# Nếu chưa chỉ định tham số, hiển thị menu chọn nhanh (tự động vào World 1 sau 4 giây)
if [ -z "$TARGET_SCENE" ]; then
    echo -e "${BOLD}CHỌN CHẾ ĐỘ KHỞI CHẠY (Tự động chọn 1 sau 4 giây):${NC}"
    echo -e " [1] Chơi ngay ${BOLD}World 1: Cổ Thành Bastion${NC} (Mặc định)"
    echo -e " [2] Chơi ngay ${BOLD}World 2: Hầm Ngục Huyết Rễ${NC}"
    echo -e " [3] Mở ${BOLD}Trang Chủ Chính (MainMenu)${NC}"
    echo -e " [4] Chạy ${BOLD}Bộ kiểm thử tự động (Test Suite)${NC}"
    echo ""
    read -t 4 -p "Lựa chọn của bạn [1-4] (Mặc định 1): " CHOICE
    echo ""
    
    case "$CHOICE" in
        2)
            TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
            ;;
        3)
            TARGET_SCENE="scenes/MainMenu.tscn"
            ;;
        4)
            echo -e "\n${YELLOW}=== ĐANG CHẠY BỘ KIỂM THỬ TỰ ĐỘNG (TEST SUITE) ===${NC}"
            "$GODOT_BIN" --headless -s tests/test_milestone1_spawn_system.gd
            read -p "Nhấn Enter để hoàn tất..."
            exit 0
            ;;
        *)
            TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
            ;;
    esac
fi

echo -e "${GREEN}🎮 ĐANG KHỞI CHẠY:${NC} ${BOLD}$TARGET_SCENE${NC}"
echo -e "${CYAN}============================================================${NC}"

# Chạy game
"$GODOT_BIN" --path . "$TARGET_SCENE"

echo -e "\n${GREEN}Cảm ơn bạn đã trải nghiệm Project Dual Blade!${NC}"
