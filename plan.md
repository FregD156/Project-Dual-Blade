# PLAN.md — Lộ Trình Phát Triển Project Dual Blade (Phiên Bản 2.5D Cel-Shaded / HD-2D)

> Kế hoạch triển khai theo thứ tự ưu tiên, đi từ core loop nhỏ nhất có thể chơi được (playable core) đến full 4 World. Đã nâng cấp toàn diện sang kiến trúc **2.5D Cel-Shaded / HD-2D** (Godot 4.7 Forward+, Sprite3D kết hợp không gian 3D, Toon Shaders, Dynamic Lighting & Shadow, Camera 2.5D khóa trục Z). Đánh số P0–P7.

---

## TỔNG QUAN TIẾN ĐỘ THỰC TẾ (UPDATED)

- [x] **P0 — Nền Tảng Kỹ Thuật 2.5D**: Kiến trúc `src_3d/` & `scenes_3d/`, Toon Shaders (`cel_toon.gdshader`, `outline.gdshader`), Camera 2.5D (`Camera25D.gd`), VFX (`GhostTrail3D`, `SlashArc3D`, `DamageNumber3D`).
- [x] **P1 — Core Combat 2.5D**: Player 3D (`Player3D.gd`), Sprite 36-frame (`player_sheet_grid.png`), 4-hit Combo, Không chiến (Air Float & Spinning Dive), Wall Slide & Wall Jump, Shadow Dash xuyên thấu + i-frame, Cross-Parry (hit-stop + dịch chuyển sau lưng), Flow Meter 5 nấc & Trạng thái Xuất Quỷ (Overdrive).
- [x] **P2 — Trang Chủ & Gothic HUD & UI Túi Đồ**:
  - Main Menu Dark Fantasy (`MainMenu.tscn`) kết nối chuyển cảnh mượt sang World 3D.
  - Gothic Vitals & Flow Meter (`vitals_hud_frame.png`, `flow_hud_frame.png`, `ruby_gem.png`): HP Bar, Armor Bar (Lớp Giáp Bảo Vệ), 5 Ngọc Ruby phát sáng.
  - Túi Đồ [B] (`InventoryUI.tscn`): Trang bị Vũ Khí D→SSR, Bộ Giáp 4 món (Mũ, Áo Giáp, Hộ Thủ, Chiến Ngoa), Khiên Hộ Thân (Shield), Lưới ô chứa đồ và Tính năng Ghép 5-thành-1 (`MergeSystem.gd`).
  - Bản đồ nhanh [M] (`FastTravelMapUI.tscn`): Xem 4 World và chọn Checkpoint.
- [x] **P3 — Stage 1.1 Bastion 3D (Đấu Trường 80m & 4 Tầng Kiến Trúc)**:
  - Sàn đấu 80m, kiến trúc 4 tầng, bẫy chông sàn `SpikeTrap3D.tscn`, cờ vương triều Gothic `gothic_wall_banner.png`.
  - Quái vật World 1 (Lính Gác Rỉ Sét, Cung Thủ Bắn Tỉa, Chó Săn Xích Sắt, Đao Phủ Tinh Anh).
  - Cổng Dịch Chuyển Hoàng Gia (`portal_gothic_gate.png` + 12-frame xoay vortex).
  - Loot rơi 3D (`DropItem3D.gd`): Hạt Sinh Mệnh (tự hút nam châm), Bình Máu, Tim Huyết Tế, Song Đao D->SSR chiếu tia sáng.
- [ ] **P4 — Boss 1.10 Thống Lĩnh Thiết Vệ (2.5D Boss Rush)**
- [ ] **P5 — Hệ Thống Checkpoint, Đài Tế Safe Haven & Bóng Ma Pixel**
- [ ] **P6 — Mở Rộng World 2, 3, 4 (2.5D Environments)**
- [ ] **P7 — Balance Pass, Polish & Full Release**

---

## P0 — NỀN TẢNG KỸ THUẬT 2.5D CEL-SHADED (HOÀN THÀNH)

**Mục tiêu:** Xây dựng hệ sinh thái 2.5D (HD-2D) trên Godot 4.7 Forward+.
- [x] Thiết lập cấu trúc `src_3d/` và `scenes_3d/`.
- [x] Khóa cứng trục Z (`global_position.z = 0.0`, `velocity.z = 0.0`) tạo mặt phẳng chuyển động 2.5D hoàn hảo.
- [x] Pipeline Cel-Shading Toon Shader 3 dải sáng + Inverted Hull Outline đen phong cách manga/anime.
- [x] Dynamic Lighting: DirectionalLight3D đổ bóng mềm + OmniLight3D ngọn đuốc lâu đài.
- [x] Camera 2.5D (`Camera25D.gd`): Smooth Follow, Look Ahead theo hướng nhìn, Screen Shake chấn động khi parry/hit.
- [x] VFX Không Gian 3D: Dư ảnh ma quái (`GhostTrail3D.gd`), Nhát chém lưỡi liềm phát sáng (`SlashArc3D.gd`), Số sát thương nhảy (`DamageNumber3D.gd`).

---

## P1 — CORE COMBAT SONG ĐAO 2.5D (HOÀN THÀNH)

**Mục tiêu:** Cảm giác chặt chém tốc độ cao, nhịp nhàng theo `Detail.md` Phần A.II.
- [x] **Platforming 2.5D:** Chạy mượt, Nhảy đơn, Nhảy đúp (Double Jump), Bám tường trượt chậm (Wall Slide), Bật tường nhảy cao (Wall Jump).
- [x] **Combo Song Đao 4 Nhát:** Đòn 1-2 chém chéo chữ X → Đòn 3 xoay chém ngang 360° → Đòn 4 Finisher quét cực mạnh lùi nhẹ tạo khoảng cách.
- [x] **Không Chiến:** Air Combo lơ lửng trên không 0.25s + Spinning Dive bổ nhào thần tốc nảy người khi chạm đất/quái.
- [x] **Shadow Dash:** Lướt nhanh 16m/s xuyên thấu thân thể địch, bất tử i-frame 0.22s, sinh chuỗi dư ảnh xanh ngọc.
- [x] **Cross-Parry:** Khung thủ 0.16s, hit-stop đóng băng khung hình khi chặn đúng đòn, tốc biến sau lưng mục tiêu và kích hoạt đòn phản chí mạng.
- [x] **Flow Meter & Xuất Quỷ (Overdrive):** Tích lũy 5 nấc ngọc Ruby, tăng 20% tốc độ chạy + 20% sát thương, bừng sáng dư ảnh đỏ thẫm rực cháy, tự decay sau 2.5s.
- [x] **Blade Dance:** Chiêu tất sát bão kiếm khi đầy 5 nấc Flow, chém liên hoàn lướt qua kẻ thù.

---

## P2 — TRANG CHỦ, GOTHIC HUD & TÚI ĐỒ INVENTORY (HOÀN THÀNH)

**Mục tiêu:** Hệ thống giao diện Dark Fantasy và quản lý trang bị rèn ghép.
- [x] **Trang Chủ (Main Menu):**
  - Dark Fantasy UI với logo thở Breathing, nút bấm viền vàng Gothic.
  - Chuyển cảnh Fade mượt mà sang `scenes_3d/World1_Bastion_3D.tscn`.
  - Bảng hướng dẫn phím tắt và tuỳ chọn âm thanh/hình ảnh.
- [x] **Gothic HUD 3D:**
  - Khung Vitals Gothic (`vitals_hud_frame.png`): HP Bar xanh lá và Armor Bar xanh ngọc.
  - Khung Flow Meter (`flow_hud_frame.png`): 5 viên Ngọc Ruby phát sáng đỏ rực rỡ khi tích đủ nấc.
  - Icon Nút bấm Túi Đồ [B] và Bản Đồ [M] góc trên màn hình.
  - Thanh HP Boss / Tinh Anh với vương miện hoàng gia vàng kim.
- [x] **Túi Đồ (Inventory Panel) & Ghép Đồ 5-thành-1:**
  - Mở/đóng bằng phím `[B]`, `[Tab]` hoặc click chuột vào icon Túi.
  - Hiển thị trang bị: Vũ khí đang cầm (D→SSR) kèm thuộc tính ATK, Crit, Dòng Option Pool.
  - Bộ giáp 4 món: Mũ Thiết Vệ, Áo Giáp Huyết Nguyệt, Hộ Thủ Gai Thép, Chiến Ngoa Thiết Giáp.
  - Khiên Hộ Thân (Shield System): Tăng Max HP, Tăng Giáp, Tỉ lệ Block đòn đánh hoàn toàn.
  - Lưới ô chứa đồ nhặt được và tính năng Hợp thành (Merge 5 món cùng loại/cùng bậc lên bậc kế tiếp).

---

## P3 — STAGE 1.1 BASTION 3D & LOOT DROPS (HOÀN THÀNH)

**Mục tiêu:** Đấu trường mẫu mực hoàn chỉnh phong cách Octopath Traveler / Ender Lilies.
- [x] Đấu trường đá dài 80m, cấu trúc 4 tầng lầu với bậc thang nhảy leo trèo.
- [x] Phông nền lâu đài Bastion u ám (`world1_bastion_bg.png`), cờ vương triều Gothic, cột trụ đá cổ.
- [x] Bẫy chông sàn `SpikeTrap3D.tscn` gây sát thương khi giẫm phải.
- [x] Cổng Dịch Chuyển Cổ Xưa (`Portal3D.tscn`): Khung cổng Gothic kết hợp 12 frame vòng xoáy hư không phát sáng, tự động mở khi dọn sạch quái.
- [x] Roster quái vật 3D: Lính Gác Rỉ Sét, Cung Thủ Tháp Canh, Chó Săn Xích Sắt, Đao Phủ Tinh Anh.
- [x] Loot rơi 3D (`DropItem3D.gd`): Hạt Sinh Mệnh (hút nam châm về người chơi), Bình Máu Lớn, Tim Huyết Tế, Song Đao rực sáng theo bậc (D=Trắng, B=Lục, A=Lam, R=Tím, SR=Vàng kim, SSR=Hồng tím thần thánh).

---

## P4 — BOSS 1.10 THỐNG LĨNH THIẾT VỆ (ƯU TIÊN TIẾP THEO)

**Mục tiêu:** Trận Boss đỉnh cao khép lại World 1 theo `Detail.md` Phần A.V và Phần D.V.
- [ ] Dựng scene `Boss1_IroncladCommander_3D.tscn` kế thừa `EnemyBase3D`.
- [ ] **Phase 1 (Đại Kiếm & Đại Khiên):** 
  - Vung kiếm chém quét báo vệt đỏ 0.8s (tập luyện Cross-Parry).
  - Giậm khiên chấn động mặt đất gây sóng xung kích sàn.
- [ ] **Phase 2 (Thức Tỉnh Song Kiếm <50% HP):**
  - Vứt bỏ đại khiên, cầm song kiếm cuồng nộ, tăng 35% tốc độ.
  - Combo 3 nhát chém chéo hình chữ X + Xung kích phóng sóng kiếm tầm xa.
  - Bão xoay kiếm (Whirlwind) đòi hỏi người chơi dùng Shadow Dash luồn ra sau.
- [ ] Tích hợp thanh máu Boss 2-phase trên `HUD3D.gd`, mốc rơi máu Mercy Drop (mỗi 25% HP rơi bình máu).

---

## P5 — HỆ THỐNG CHECKPOINT & AN TOÀN (SAFE HAVEN 1.9)

**Mục tiêu:** Cơ chế sinh tồn, hồi sinh và bàn thợ rèn.
- [ ] Checkpoint 1.1, 1.5 (sau khi diệt Elite) và 1.9 (Safe Haven).
- [ ] Đài Tế Cổ Xưa (`altar_gothic_monolith.png`) tại Safe Haven 1.9: Tương tác hồi phục 100% HP & Giáp.
- [ ] Rương Đa Năng lưu trữ trang bị và Bàn Thợ Rèn nâng cấp dòng Option.
- [ ] Death Penalty: Khi chết lưu lại "Bóng Ma Pixel" 3D chứa 50% tinh thể rơi ra, người chơi có 1 mạng để nhặt lại.

---

## P6 — MỞ RỘNG WORLD 2, 3, 4 (2.5D WORLDS)

- [ ] **World 2: Hầm Ngục Huyết Rễ (Root Catacombs):**
  - Môi trường cống rễ máu, bào tử nấm nảy, vũng axit độc hại rút máu.
  - Boss 2.10: Mẫu Thể Ký Sinh (Nhện khổng lồ bám vách, phun tơ độc).
- [ ] **World 3: Tháp Đồng Hồ Cơ Giới (Clockwork Spire):**
  - Bánh răng khổng lồ xoay 3D, piston dập trần, bẫy cưa máy.
  - Boss 3.10: Kẻ Hành Quyết Cơ Giới (Robot 4 tay cưa xoay + đại bác laser).
- [ ] **World 4: Đền Thờ Hư Vô (Void Sanctuary):**
  - Tàn tích trôi nổi giữa vũ trụ tím thẫm, bục đá tan biến, trọng lực dị thường.
  - Boss 4.10: Kẻ Thao Túng Hư Không (Bóng ma song sinh của chính nhân vật).

---

## P7 — BALANCE PASS, POLISH & TỐI ƯU HÓA

- [ ] Cân chỉnh TTK (Time-To-Kill) của Boss theo bảng Phần D.V (Boss 1 ~90s, Boss 2 ~110s, Boss 3 ~125s, Boss 4 ~140s).
- [ ] Tối ưu hóa hiệu năng Forward+ rendering trên máy Mac và PC: Giảm draw call, bật Occlusion Culling.
- [ ] Cân bằng tỉ lệ rơi đồ và chỉ số các Option Pool SSR (Luân Hồi Hư Không, Diệt Thế Thần Khí).
- [ ] Kiểm thử toàn diện không crash, hoàn thiện build xuất bản.
