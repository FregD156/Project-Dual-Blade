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
- [x] **P3 — Hệ Thống Vượt Ải 1.1 -> 1.10 (Loop Progression & Pacing)**:
  - Vòng lặp dọn quái qua từng ải: 1.1 đến 1.10.
  - Checkpoint tự động kích hoạt và lưu mốc tại 1.1, 1.5, 1.9, 1.10 (`CheckpointManager.gd`).
  - Cơ chế Phân Nhánh Cổng (Portal Choice): Cổng Đao Kiếm (Combat) vs Cổng Sinh Mệnh (Sustain).
  - Quái vật dàn trải các tầng lầu Bastion (Lính gác, Chó săn, Cung thủ bắn tỉa).
- [x] **P4 — Quái Tinh Anh 1.5 & Boss 1.10 (2-Phase & Mercy Drops)**:
  - Ải 1.5: Thủ Lĩnh Đao Phủ Quỷ (450 HP, đòn búa chấn động Unparryable).
  - Ải 1.9: Trạm Nghỉ An Toàn (Safe Haven) với Đài Tế Hoàng Gia (`SafeHavenAltar3D.tscn`) hồi 100% HP, Giáp, 3 Bình Máu.
  - Ải 1.10: Đại Trùm Thống Lĩnh Thiết Vệ (`BossIroncladCommander3D.gd`): 3,800 HP, DEF 4, Phase 1 Đại kiếm (báo đỏ tập Parry), Phase 2 Song đao cuồng nộ, quy tắc Mercy Drop mỗi 25% HP rơi 2 Bình Máu Lớn.
- [x] **P5 — Công Thức Máu & Sát Thương ARPG Chuẩn**:
  - `Mitigation% = DEF / (DEF + 50)`.
  - Sát thương hấp thụ qua Giáp trước rồi tới Máu; tỉ lệ Block từ Khiên; Crit Rate phụ thuộc phẩm cấp vũ khí.
- [ ] **P6 — Mở Rộng World 2, 3, 4 (2.5D Environments)**
- [ ] **P7 — Balance Pass, Polish & Full Release**

---

## CHI TIẾT CÁC GIAI ĐOẠN ĐÃ THỰC HIỆN

### 1. Vòng Lặp Vượt Ải (StageManager3D)
- **1.1 (Khởi đầu):** 2 Lính Gác Rỉ Sét dưới sàn để làm quen nhịp combo.
- **1.2 - 1.4 (Tăng nhịp):** Bổ sung Chó Săn bứt tốc và Cung Thủ bắn tỉa trên các bục lầu 2, 3.
- **1.5 (Quái Tinh Anh):** Thủ Lĩnh Đao Phủ Quỷ (450 HP, DEF=6) tung đòn bổ cự búa chấn động sàn, gọi cung thủ trợ chiến.
- **1.6 - 1.8 (Khốc liệt):** Lính bắn tỉa xuất hiện trên tháp cao tầng 4 (10.2m), bầy chó săn và lính giáp đen phục kích.
- **1.9 (Trạm Nghỉ An Toàn):** Không có quái. Đài Tế Cổ Xưa cho phép bấm `[E]` hồi phục 100% sinh lực, giáp và 3 bình máu, tạo điểm hồi sinh an toàn.
- **1.10 (Đại Trùm Cuối):** Thống Lĩnh Thiết Vệ 2 Phase (Phase 1 tập Parry đại kiếm, Phase 2 song kiếm cuồng nộ, mỗi 25% HP rơi 2 bình máu).

### 2. Phân Nhánh Cổng Dịch Chuyển (Portal Choice)
- Sau khi dọn sạch ải thường (1.1, 1.2, 1.3, 1.6, 1.7), xuất hiện 2 cánh cổng:
  - **Cổng Đao Kiếm (Màu Đỏ):** Mật độ quái dày hơn, rơi nhiều phôi vũ khí & quặng rèn.
  - **Cổng Sinh Mệnh (Màu Lục):** Ít quái hơn, chắc chắn rải thêm các bình máu lớn để hồi sức.
- Tại các ải 1.4, 1.8, 1.9 và 1.10 chỉ mở 1 Cổng Hoàng Gia chuẩn (Màu Lam) để tiến vào ải then chốt.

### 3. Công Thức Máu & Dame ARPG (Data-Driven)
- Sử dụng `DamageCalculator.gd`:
  $$\text{Mitigation\%} = \frac{\text{DEF}}{\text{DEF} + 50}$$
  $$\text{Damage} = \max(1, \text{ATK} \times \text{SkillMult} \times (1 - \text{Mitigation\%}))$$
- Toàn bộ quái vật và Boss có chỉ số DEF riêng (Lính thường DEF=0, Tinh Anh DEF=6, Boss DEF=4).
- Người chơi có Crit Rate tăng dần theo bậc song đao (D: 5% -> SSR: 28%), sát thương nhảy số 3D kèm hiệu ứng chí mạng vàng rực.

---

## KẾ HOẠCH BƯỚC TIẾP THEO (WORLD 2, 3, 4 & RELEASE)

- [ ] **P6.1 — World 2: Hầm Ngục Huyết Rễ (The Crimson Catacombs)**: Bào tử nấm, vũng axit ăn mòn, Cổ Thụ Biến Dị (2.5), Mẫu Thể Ký Sinh (2.10).
- [ ] **P6.2 — World 3: Tháp Đồng Hồ Cơ Giới (The Clockwork Spire)**: Sàn bánh răng xoay 3D, bẫy cưa, Cỗ Máy Hộ Vệ Lõi (3.5), Kẻ Hành Quyết Cơ Giới (3.10).
- [ ] **P6.3 — World 4: Đền Thờ Hư Vô (The Void Sanctum)**: Trọng lực đổi hướng, bục vỡ, Chiến Binh Ảo Ảnh (4.5), Kẻ Thao Túng Hư Không (4.10).
- [ ] **P7 — Cân Bằng TTK & Polish Cuối Cùng**: Đo đạc thời gian hạ gục Boss, tối ưu hiệu năng và build phát hành.
