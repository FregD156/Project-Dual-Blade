# AGENT.md — Project Dual Blade (2.5D Cel-Shaded / HD-2D)

> File này định nghĩa **quy chuẩn kỹ thuật và hướng dẫn vận hành cho AI Agent** làm việc trên dự án Project Dual Blade. Đọc kỹ file này trước khi can thiệp vào bất kỳ module code nào. Với lộ trình triển khai chi tiết, xem `plan.md`.

---

## 1. TỔNG QUAN DỰ ÁN & ĐỊNH HƯỚNG MỸ THUẬT

- **Tên dự án:** Project Dual Blade.
- **Thể loại:** 2.5D Side-scrolling Action RPG / Boss Rush + Roguelite Progression.
- **Phong cách đồ họa (Art Style):** **2.5D Cel-Shaded / HD-2D** (tương tự *Octopath Traveler*, *Ender Lilies*, *Nine Sols*).
  - Kết hợp Sprite hoạt họa 16-bit / Hi-Res Pixel Art trên các đối tượng `Sprite3D` đặt trong không gian 3D.
  - Sử dụng ánh sáng thực tế (Directional Light, Torch OmniLight), bóng đổ thời gian thực (Real-time Shadows), Shader Cel-Toon 3 dải sáng và Inverted Hull Outline đen đậm nét.
- **Nguồn chân lý (Source of Truth):** `Detail.md` (Đặc tả gameplay, công thức sát thương, bể Option Pool, hệ thống World và Lore). Agent không tự ý thay đổi các nguyên lý chiến đấu song đao nếu không có yêu cầu từ người dùng.

---

## 2. TECH STACK & KIẾN TRÚC KỸ THUẬT

- **Engine:** Godot 4.7 Forward+ Renderer (Tối ưu hóa độ sâu, bóng đổ và Spatial Shaders).
- **Trục chuyển động (2.5D Constraint):**
  - **Bắt buộc khóa cứng trục Z = 0** trong `_physics_process`: `global_position.z = 0.0` và `velocity.z = 0.0` cho tất cả nhân vật (`CharacterBody3D`) và đạn/vật phẩm rơi.
  - Camera 2.5D (`Camera25D.gd`): Đặt ở vị trí `Z = 9.5`, góc nhìn chính diện có độ chúc nhẹ (`rotation_degrees.x = -2.5`), hỗ trợ nội suy mượt mà (lerp follow), look-ahead và screen shake.
- **Rendering & Shaders (`src_3d/shaders/`):**
  - `cel_toon.gdshader`: Shading 3 bậc ánh sáng (Shadow, Mid, Highlight) tạo chiều sâu cel-shading.
  - `outline.gdshader`: Kỹ thuật Inverted Hull với culling Front để tạo viền đen quanh các khối kiến trúc.
  - `slash_arc.gdshader`: Shader vệt chém lưỡi liềm phát sáng rực rỡ có vệt tia điện.
- **Sprite Display:** `Sprite3D` với `texture_filter = 0` (Nearest), `cast_shadow = 2` (Double-Sided), `alpha_cut = 1` (Discard) để pixel art luôn sắc nét, không bị nhòe và đổ bóng chân thực xuống sàn đá.

---

## 3. CẤU TRÚC THƯ MỤC DỰ ÁN

```
HeroFD/
├── data/                      # Bảng dữ liệu JSON (combat balance, options pool, enemy stats)
├── assets/
│   ├── sprites/
│   │   ├── player/            # Sprite sheet hoạt họa 36 frame nhân vật
│   │   ├── enemies/           # Sprite sheet các loài quái vật và Boss
│   │   ├── environment/       # Phông nền 2.5D, banner, props kiến trúc Gothic
│   │   ├── items/             # Icon vũ khí D->SSR, khiên, bình máu, tim huyết tế
│   │   └── ui/                # Khung Gothic Vitals HUD, Flow frame, Ruby gem, Bag/Map icon
│   └── fonts/                 # Phông chữ Pixel Art
├── src_3d/                    # Code logic nền tảng 2.5D
│   ├── player/                # Player3D.gd (FSM, Song Đao Combo, Dash, Parry, Wall Slide)
│   ├── camera/                # Camera25D.gd (Follow, Look-ahead, Shake)
│   ├── combat/                # StageManager3D.gd, Hitbox3D, Damage calculation
│   ├── enemies/               # EnemyBase3D.gd, Lính gác, Cung thủ, Chó săn, Đao phủ
│   ├── items/                 # DropItem3D.gd (Loot rơi 3D, hút nam châm, tia sáng phẩm cấp)
│   ├── materials/             # Toon materials (.tres)
│   ├── shaders/               # Cel-toon, Outline, Slash VFX shaders
│   ├── ui/                    # HUD3D.gd (Gothic Vitals, Armor, Flow Ruby, Boss bar)
│   └── world/                 # Portal3D.gd (Cổng hoàng gia xoay vortex), SpikeTrap3D.gd
├── scenes_3d/                 # Các Scene hoàn chỉnh 2.5D
│   ├── World1_Bastion_3D.tscn # Cổ Thành Bastion (Đấu trường 80m, 4 tầng lầu)
│   ├── Player3D.tscn          # Nhân vật chính 2.5D tích hợp VisualRoot & SlashArc
│   ├── Portal3D.tscn          # Cổng dịch chuyển Gothic Gate
│   ├── SpikeTrap3D.tscn       # Bẫy chông sàn kích hoạt theo va chạm
│   ├── DropItem3D.tscn        # Vật phẩm rơi 3D
│   └── Enemy*.tscn            # Các loại quái 3D
├── src/                       # Các hệ thống Data / Logic dùng chung (2D & 3D)
│   ├── items/                 # MergeSystem.gd (ghép 5 thành 1), ArmorSystem, ShieldSystem
│   └── ui/                    # InventoryUI.gd (Túi đồ [B]), FastTravelMapUI.gd ([M]), MainMenu.gd
└── scenes/
    ├── MainMenu.tscn          # Trang chủ chính mở màn Dark Fantasy
    ├── InventoryUI.tscn       # Giao diện Túi Đồ [B]
    └── FastTravelMapUI.tscn   # Giao diện Chọn Bản Đồ [M]
```

---

## 4. QUY TẮC PHÁT TRIỂN & NGUYÊN TẮC BẮT BUỘC

1. **Khóa trục Z tuyệt đối:**
   Mọi chuyển động của nhân vật, quái vật, đường đạn và đồ rơi phải tuân thủ nghiêm ngặt mặt phẳng Z = 0. Không cho phép trôi dạt trên trục Z.
2. **Hệ thống Combat Song Đao:**
   - **Flow Meter:** 5 nấc, +1 nấc mỗi đòn trúng, reset về 0 nếu không tấn công trong 2.5s hoặc bị dính đòn (trừ khi có Option giữ Flow). Đạt 5 nấc bật **Xuất Quỷ (Overdrive)**: +20% Speed, +20% Damage, bừng sáng dư ảnh đỏ thẫm.
   - **Cross-Parry:** Cửa sổ 0.15s - 0.16s, hit-stop khựng khung hình, dịch chuyển tức thời sau lưng mục tiêu và kích hoạt đòn phản kích chí mạng.
   - **Shadow Dash:** Lướt nhanh xuyên thấu quái vật, i-frame toàn bộ quá trình lướt.
3. **Hệ thống Trang Bị & Hợp Thành (Merge 5-to-1):**
   - Hỗ trợ đầy đủ 7 phẩm cấp: **Tier D → C → B → A → R → SR → SSR**.
   - Hợp thành: Cứ 5 món cùng loại, cùng bậc trong Túi Đồ (`InventoryUI.gd`) tự động hoặc bấm nút ghép thành 1 món thuộc bậc kế tiếp (`MergeSystem.gd`).
   - Tích hợp 3 nhóm đồ: Vũ khí Song Đao, Bộ Giáp 4 món (Mũ, Áo, Tay, Chân), Khiên Hộ Thân (Shield).
4. **Giao Diện Gothic Đồng Bộ:**
   - Mọi HUD và Menu phải dùng đúng các asset khung viền đã thiết kế: `vitals_hud_frame.png`, `flow_hud_frame.png`, `ruby_gem.png`, `inventory_hud_frame.png`, `title_logo.png`.
5. **Data-Driven & Kiểm Thử Headless:**
   - Trước khi báo cáo hoàn thành, agent luôn chạy lệnh kiểm tra engine không lỗi parse scene:
     `godot --headless scenes_3d/World1_Bastion_3D.tscn --quit-after 10`
   - Đảm bảo commit git rõ ràng, thông điệp phản ánh chính xác các module được triển khai.
