#!/bin/bash
cd "$(dirname "$0")"

# Màu sắc terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}${BOLD}========================================================================${NC}"
echo -e "${CYAN}${BOLD}           PROJECT DUAL BLADE (HeroFD) — 2.5D HD-2D DEMO               ${NC}"
echo -e "${MAGENTA}${BOLD}   ★ WORLD 1: PHÁO ĐÀI BỊ RUỒNG BỎ (THÀNH TRÌ 3 PHÂN KHU RÕ RỆT) ★     ${NC}"
echo -e "${CYAN}${BOLD}========================================================================${NC}"
echo -e "${YELLOW}${BOLD}BỐ CỤC 3 PHÂN KHU WORLD 1 (HÀNH LANG 120M):${NC}"
echo -e " 🛡️  ${BOLD}Khu 1 [X: -58 -> -12]${NC} : Tiền Đồn Ngoài Thành (Hào chông, rào sắt, bục gác cao)"
echo -e " 🏰 ${BOLD}Khu 2 [X: -12 -> +22]${NC} : Nội Viện 2 Tầng (Dốc nêm liền mạch, cầu vòm, 4 đại trụ)"
echo -e " 👑 ${BOLD}Khu 3 [X: +22 -> +58]${NC} : Đấu Trường Đỉnh Tháp (Đài tế 1.9 & Ngai vàng Boss 1.10)"
echo -e "${CYAN}------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}${BOLD}HỆ THỐNG ÂM THANH & HÌNH ẢNH MỚI:${NC}"
echo -e " 🔊 ${BOLD}Âm Thanh Procedural 16-Bit${NC} : 12 SFX chém, parry, lướt bóng, rống boss, chuông thắng"
echo -e " ✨ ${BOLD}Hiệu Ứng Tia Lửa & Khí Quyển${NC}: Hit sparks 3D, tàn tro lơ lửng, vạc lửa bập bùng"
echo -e " 🎥 ${BOLD}Camera 2.5D Điện Ảnh${NC}        : Depth-of-Field Bokeh, rung chấn & Boss zoom-out"
echo -e "${CYAN}------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}${BOLD}HƯỚNG DẪN BÀN PHÍM ĐIỀU KHIỂN:${NC}"
echo -e " • ${BOLD}[A / D]${NC}        : Di chuyển trái / phải"
echo -e " • ${BOLD}[Space]${NC}        : Nhảy đơn / Nhảy đúp / Bám tường nhảy cao"
echo -e " • ${BOLD}[J]${NC}            : Combo Song Đao 4 hit (Kèm Hit-stop & Tia lửa va chạm)"
echo -e " • ${BOLD}[K]${NC}            : Phản đòn Cross-Parry (Cửa sổ 0.16s, nổ tia lửa vàng làm choáng)"
echo -e " • ${BOLD}[L]${NC}            : Lướt hư ảnh Shadow Dash (Khung bất tử i-frame)"
echo -e " • ${BOLD}[S + J]${NC}        : Bổ nhào Spinning Dive từ trên cao"
echo -e " • ${BOLD}[I]${NC}            : Vũ điệu bão kiếm Blade Dance (Tất sát diện rộng)"
echo -e " • ${BOLD}[B]${NC}            : Mở Túi Đồ & Hợp thành (Gợi ý ghép 5 món cùng bậc)"
echo -e " • ${BOLD}[M]${NC}            : Mở Bản Đồ Vượt Ải Fast Travel (Dịch chuyển tức thời)"
echo -e " • ${BOLD}[F3]${NC}           : Bật/Tắt Debug HUD Overlay (Tọa độ, 14 SpawnPoints, quái)"
echo -e "${CYAN}------------------------------------------------------------------------${NC}"

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
    echo "Vui lòng tải hoặc cài đặt Godot vào /Applications/Godot.app"
    read -p "Nhấn Enter để thoát..."
    exit 1
fi

echo -e "${GREEN}✓ Đã tìm thấy Godot:${NC} $GODOT_BIN"
echo -e "${CYAN}------------------------------------------------------------------------${NC}"

run_all_tests() {
    echo -e "\n${YELLOW}=== ĐANG CHẠY BỘ KIỂM THỬ TỰ ĐỘNG TOÀN DIỆN (5 TEST SUITES) ===${NC}\n"
    
    echo -e "${BLUE}▶ [1/5] Kiểm tra Spawn System, Dốc nêm & Debug F3...${NC}"
    "$GODOT_BIN" --headless --path . -s tests/test_milestone1_spawn_system.gd
    if [ $? -ne 0 ]; then echo -e "${RED}❌ Test 1 thất bại!${NC}"; exit 1; fi
    
    echo -e "\n${BLUE}▶ [2/5] Kiểm tra Tiến trình Vượt Ải 1.1 -> 1.10 & Cổng dịch chuyển...${NC}"
    "$GODOT_BIN" --headless --path . -s tests/test_stage_portal.gd
    if [ $? -ne 0 ]; then echo -e "${RED}❌ Test 2 thất bại!${NC}"; exit 1; fi
    
    echo -e "\n${BLUE}▶ [3/5] Kiểm tra Tự động trang bị & Gợi ý Ghép đồ 5-to-1...${NC}"
    "$GODOT_BIN" --headless --path . -s tests/test_auto_equip_and_merge.gd
    if [ $? -ne 0 ]; then echo -e "${RED}❌ Test 3 thất bại!${NC}"; exit 1; fi
    
    echo -e "\n${BLUE}▶ [4/5] Kiểm tra Dịch chuyển tức thời Fast Travel...${NC}"
    "$GODOT_BIN" --headless --path . -s tests/test_fast_travel.gd
    if [ $? -ne 0 ]; then echo -e "${RED}❌ Test 4 thất bại!${NC}"; exit 1; fi
    
    echo -e "\n${BLUE}▶ [5/5] Kiểm tra Tiến trình World 2: Hầm Ngục Huyết Rễ...${NC}"
    "$GODOT_BIN" --headless --path . -s tests/test_world2_progression.gd
    if [ $? -ne 0 ]; then echo -e "${RED}❌ Test 5 thất bại!${NC}"; exit 1; fi
    
    echo -e "\n${GREEN}${BOLD}🎉 TẤT CẢ 5 BỘ KIỂM THỬ ĐỀU VƯỢT QUA 100%! HỆ THỐNG HOÀN TOÀN ỔN ĐỊNH!${NC}\n"
    if [ "$1" == "interactive" ] && [ -t 0 ]; then
        read -p "Nhấn Enter để quay lại hoặc hoàn tất..."
    fi
}

TARGET_SCENE=""
EXTRA_ARGS=()

# Xử lý tham số dòng lệnh nhanh
if [ "$1" == "w1" ] || [ "$1" == "1" ]; then
    TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
elif [ "$1" == "boss" ] || [ "$1" == "10" ] || [ "$1" == "boss1" ]; then
    TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
    EXTRA_ARGS=("--stage=10")
elif [ "$1" == "elite" ] || [ "$1" == "5" ] || [ "$1" == "elite1" ]; then
    TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
    EXTRA_ARGS=("--stage=5")
elif [ "$1" == "w2" ] || [ "$1" == "2" ]; then
    TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
elif [ "$1" == "boss2" ] || [ "$1" == "20" ]; then
    TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
    EXTRA_ARGS=("--stage=10")
elif [ "$1" == "elite2" ] || [ "$1" == "25" ]; then
    TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
    EXTRA_ARGS=("--stage=5")
elif [ "$1" == "menu" ] || [ "$1" == "m" ]; then
    TARGET_SCENE="scenes/MainMenu.tscn"
elif [ "$1" == "test" ] || [ "$1" == "t" ]; then
    run_all_tests
    exit 0
fi

# Nếu chưa chỉ định tham số, hiển thị menu lựa chọn phong phú
if [ -z "$TARGET_SCENE" ]; then
    echo -e "${BOLD}CHỌN CHẾ ĐỘ TRẢI NGHIỆM (Tự động chọn 1 sau 5 giây):${NC}"
    echo -e " [1] 🏰 Khám phá ${BOLD}World 1: Pháo Đài Bị Ruồng Bỏ (Khởi đầu Ải 1.1)${NC} [Mặc định]"
    echo -e " [2] 👑 Tử chiến ngay ${BOLD}World 1 Boss 1.10: Thống Lĩnh Thiết Vệ (Đỉnh Tháp)${NC}"
    echo -e " [3] 🌿 Khám phá ${BOLD}World 2: Hầm Ngục Huyết Rễ (Khởi đầu Ải 2.1)${NC}"
    echo -e " [4] 🕷️  Tử chiến ngay ${BOLD}World 2 Boss 2.10: Mẫu Thể Ký Sinh (Nhện Chúa)${NC}"
    echo -e " [5] 🌳 Khiêu chiến ${BOLD}World 2 Quái Tinh Anh 2.5: Cổ Thụ Biến Dị${NC}"
    echo -e " [6] 📋 Mở ${BOLD}Trang Chủ Chính (MainMenu)${NC}"
    echo -e " [7] 🧪 Chạy toàn bộ ${BOLD}5 Bộ Kiểm Thử Tự Động (Test Suite)${NC}"
    echo ""
    read -t 5 -p "Lựa chọn của bạn [1-7] (Mặc định 1): " CHOICE
    echo ""
    
    case "$CHOICE" in
        2)
            TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
            EXTRA_ARGS=("--stage=10")
            ;;
        3)
            TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
            ;;
        4)
            TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
            EXTRA_ARGS=("--stage=10")
            ;;
        5)
            TARGET_SCENE="scenes_3d/World2_Crimson_Catacombs_3D.tscn"
            EXTRA_ARGS=("--stage=5")
            ;;
        6)
            TARGET_SCENE="scenes/MainMenu.tscn"
            ;;
        7)
            run_all_tests "interactive"
            exit 0
            ;;
        *)
            TARGET_SCENE="scenes_3d/World1_Bastion_3D.tscn"
            ;;
    esac
fi

echo -e "${GREEN}🎮 ĐANG KHỞI CHẠY:${NC} ${BOLD}$TARGET_SCENE${NC} ${YELLOW}${EXTRA_ARGS[*]}${NC}"
echo -e "${CYAN}========================================================================${NC}"

# Chạy game
"$GODOT_BIN" --path . "$TARGET_SCENE" "${EXTRA_ARGS[@]}"

echo -e "\n${GREEN}Cảm ơn bạn đã trải nghiệm Project Dual Blade!${NC}"
