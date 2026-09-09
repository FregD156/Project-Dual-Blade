# PLAN.md — Lộ Trình Phát Triển Project Dual Blade

> Kế hoạch triển khai theo thứ tự ưu tiên, đi từ core loop nhỏ nhất có thể chơi được (playable core) đến full 4 World. Mỗi giai đoạn có mục tiêu rõ ràng, danh sách task, tiêu chí "Definition of Done" (DoD), và phụ thuộc vào mục nào của `Detail.md` / `agent.md`. Đánh số P0–P7.

---

## P0 — CHUẨN BỊ & NỀN TẢNG KỸ THUẬT

**Mục tiêu:** Dựng khung project, pipeline dữ liệu, không có gameplay thật.

- [ ] Khởi tạo project theo engine đã chọn (mặc định Godot 4.x — xem `agent.md` mục 3).
- [ ] Dựng cấu trúc thư mục theo `agent.md` mục 4.
- [ ] Viết schema dữ liệu JSON/Resource cho: Item, Enemy, Boss, Option (sub-stat), World/Stage config.
- [ ] Viết công cụ debug: vẽ hitbox/hurtbox, hiển thị Flow Meter, hiển thị frame counter cho Parry window.
- [ ] Import placeholder pixel art (nhân vật + 1 quái test) để có visual test ngay từ đầu.

**DoD:** Chạy được 1 scene trống có nhân vật đứng yên, đọc dữ liệu từ file JSON mẫu, debug overlay hoạt động.

---

## P1 — CORE COMBAT PROTOTYPE (Ưu tiên cao nhất)

**Mục tiêu:** Cảm giác chiến đấu "đã đúng" trước khi làm bất kỳ nội dung nào khác — đây là rủi ro lớn nhất của game action, làm trước để fail-fast nếu feel không ổn.

**Tham chiếu:** Detail.md Phần A.II (Cơ chế điều khiển & vũ khí)

- [ ] Platforming cơ bản: chạy, nhảy đơn, nhảy đúp, wall-slide, wall-jump, bám mép leo lên.
- [ ] Combo đánh thường 4 nhát (2 chém chéo X → xoay chém ngang → finisher lùi lại tạo khoảng cách).
- [ ] Air Combo (lơ lửng 0.3s khi chém trên không) + Spinning Dive (bổ nhào, nảy lại nếu trúng đầu quái/nấm bẫy).
- [ ] Shadow Dash: lướt ngắn xuyên người, i-frame, Just-dodge để lại phân thân nổ + dịch chuyển sau lưng địch.
- [ ] Cross-Parry: cửa sổ 9-10 frame, hit-stop 0.1s khi thành công, phản đòn chí mạng.
- [ ] Flow Meter: tích lũy 5 nấc, timer reset 2.5s, hiệu ứng Full Flow (+20% tốc độ, +20% dmg, after-image gây dmg phụ).
- [ ] Blade Dance (chiêu đặc biệt khi đầy năng lượng): 6-8 nhát trong vùng chỉ định, i-frame toàn quá trình.
- [ ] 1 quái test đơn giản để có mục tiêu luyện combo/parry (không cần AI phức tạp).
- [ ] Test scene đo chính xác: cửa sổ Parry, thời gian i-frame Dash, timing reset Flow.

**DoD:** 1 người chơi ngoài team thử và xác nhận combo + parry "đã đúng nhịp", tốc độ tấn công đúng cảm giác action nhanh như mô tả.

**Điểm dừng go/no-go:** Nếu feel chưa ổn ở đây, KHÔNG tiến sang P2 — lặp lại P1 trước.

---

## P2 — DAMAGE FORMULA & DATA-DRIVEN STATS

**Mục tiêu:** Đưa công thức sát thương và toàn bộ stat vào hệ thống dữ liệu, chuẩn bị nền cho loot & balance.

**Tham chiếu:** Detail.md Phần D (dùng bản đã sửa, không dùng số gốc)

- [ ] Implement công thức: `Mitigation% = DEF/(DEF+K)`, `Damage = max(1, ATK * SkillMult * (1-Mitigation%) * (1-Resist%))`, K config được (mặc định 50).
- [ ] Bảng Crit Rate mới theo bậc (D=5% ... SSR=28% base).
- [ ] Bảng ATK/DPS cơ bản theo bậc (D=12 ATK ... SSR=270 ATK).
- [ ] Hit-stop, damage number popup, crit visual feedback.
- [ ] Test tự động: dựng bot giả lập 55% uptime tấn công, kiểm tra TTK khớp với bảng mục tiêu (90s/110s/125s/140s cho Boss 1-4) trước khi có Boss thật.

**DoD:** Script test cho ra TTK nằm trong khoảng ±10% so với bảng mục tiêu Phần D.IV–V với input ATK/DPS giả định.

---

## P3 — HỆ THỐNG LOOT, PHẨM CHẤT & THỢ RÈN

**Mục tiêu:** Vòng lặp nhặt đồ → build → mạnh hơn hoạt động độc lập, test bằng vũ khí giả lập trước khi có world thật.

**Tham chiếu:** Detail.md Phần A.III

- [ ] 7 bậc phẩm chất D→SSR: định nghĩa VFX màu tia sáng, tỉ lệ rơi cơ bản, số dòng Option mỗi bậc.
- [ ] Bể Option Pool: nhập toàn bộ option theo bậc (mục III.2) vào data — mỗi option là 1 entry độc lập, có thể gắn vào bất kỳ vũ khí cùng bậc trở lên.
- [ ] Hệ thống roll loot: random bậc theo tỉ lệ, random số dòng option theo đúng công thức bậc (vd A = 2 dòng B).
- [ ] Salvage: 3 vũ khí cùng bậc → nguyên liệu hoặc 1 vũ khí ngẫu nhiên bậc kế tiếp.
- [ ] Re-roll (từ bậc R+): dùng tinh thể quái đổi lại 1 dòng option không mong muốn.
- [ ] UI: bảng kê vũ khí, so sánh stat, xác nhận salvage/re-roll (có cảnh báo hành động không hoàn tác).
- [ ] Hiệu ứng đặc biệt các option biến đổi chiêu thức (R/SR/SSR) — vd Lôi Kích Liêm, Phản Kích Tử Thần, Luân Hồi Hư Không (bullet-time), Diệt Thế Thần Khí (Vô Hạn Trảm) — mỗi cái là 1 module riêng, bật/tắt qua flag khi vũ khí được trang bị.

**DoD:** Có thể roll ra vũ khí ngẫu nhiên từ D đến SSR, trang bị, thấy stat và hiệu ứng thay đổi combat rõ rệt (đặc biệt option SSR phải "đổi hẳn cảm giác chơi" đúng như thiết kế Build Definer).

---

## P4 — CHECKPOINT, HỒI SINH & BÌNH MÁU

**Mục tiêu:** Vòng lặp risk/reward khi chết và cơ chế sinh tồn khi di chuyển.

**Tham chiếu:** Detail.md Phần A.VI, VII

- [ ] 3 checkpoint/world: X.1, X.5 (sau Elite, Elite không respawn), X.9 (Safe Haven).
- [ ] Death penalty: giữ 100% trang bị, rơi 50% quặng/tinh thể tại vị trí chết dạng "Bóng Ma Pixel", mất vĩnh viễn nếu chết lần 2 trước khi nhặt lại.
- [ ] Safe Haven (X.9): Bàn Thợ Rèn, Đài tế hồi 50% HP, NPC đổi vật phẩm, Rương Đa Năng (Stash), Fast Travel mở sau khi hạ Boss world đó.
- [ ] Bình máu rơi ngẫu nhiên: Life Shard (25% quái thường, hồi 8% HP tự hút), Life Flask (5%/40% theo quái nhỏ/to, tối đa giữ 3, hồi 35% HP theo nút bấm), Heart Core (100% từ Elite, hồi 50% HP + 10% dmg buff 20s).
- [ ] Mercy Drop System: bảng tỉ lệ rơi thay đổi theo ngưỡng HP người chơi (>70% / 30-70% / <30%), tính lại mỗi lần quái chết.
- [ ] Cơ chế rơi máu phòng Boss: mỗi mốc 25% HP boss mất → khựng nhẹ + rơi 2 Life Flask; 3 Parry liên tiếp không bị ngắt → rơi 1 Life Shard.

**DoD:** Chơi thử 1 vòng chết → hồi sinh → quay lại nhặt Bóng Ma → tiếp tục, không có bug mất tiến trình sai quy tắc.

---

## P5 — STAGE PROGRESSION & PORTAL CHOICE (World 1 hoàn chỉnh — Vertical Slice)

**Mục tiêu:** Ráp toàn bộ hệ thống P1-P4 vào 1 world đầy đủ 10 ải để có bản chơi được từ đầu đến cuối (vertical slice) — mốc quan trọng nhất để đánh giá tổng thể trước khi nhân bản sang World 2-4.

**Tham chiếu:** Detail.md Phần A.IV, V (World 1), Phần C (Enemy roster World 1), Phần B (lore tích hợp)

- [ ] Layout 10 ải X.1–X.10 theo nhịp: khởi động (X.1-4) → Elite (X.5) → tăng khó (X.6-8) → Safe Haven (X.9) → Boss (X.10).
- [ ] Portal Choice: sau khi dọn quái mỗi ải nhỏ, spawn 2 cổng — Combat Portal (nhiều quái, rơi phôi rèn) / Sustain Portal (ít quái, bẫy, đảm bảo Life Shard/Flask).
- [ ] Enemy roster World 1: Lính Gác Rỉ Sét, Cung Thủ Tháp Canh, Chó Săn Xích Sắt (X.1-4); Kỵ Sĩ Giáp Đen, Lính Bắn Tỉa Cao Tháp, Quỷ Cờ Rách (X.6-8) — với hành vi mô tả đúng bảng Phần C.
- [ ] Elite 1.5: Thủ Lĩnh Đao Phủ Quỷ — đòn búa không thể đỡ (báo đỏ), gọi 2 lính nỏ hỗ trợ.
- [ ] Boss 1.10: Thống Lĩnh Thiết Vệ — 2 phase (Phase 1: đại kiếm báo vệt đỏ 0.8s tập parry; Phase 2: bỏ khiên dùng song kiếm, combo 3 nhát + sóng chấn động sàn). HP/Phase split theo bảng Phần D.V (Tổng HP 3,800: Phase1 1,900/Phase2 1,900).
- [ ] Môi trường: hào chông gai, bục đá rơi, lính nỏ trên cao.
- [ ] Tích hợp lore nhẹ: NPC "Bà Góa Chuông Gió" tại Safe Haven X.9, fragment lore từ "Vulcan Tàn Diệt" (thợ rèn xuyên suốt 4 world).

**DoD:** Chơi được trọn vẹn World 1 từ X.1 đến hạ Boss 1.10, TTK Boss ~90s (uptime tấn công giả định 55%), không có bug chặn tiến trình.

---

## P6 — NHÂN BẢN NỘI DUNG WORLD 2, 3, 4

**Mục tiêu:** Dùng khung hệ thống đã ổn định ở P5, chỉ thay nội dung (art, enemy, boss, lore) — không phát sinh cơ chế mới trừ khi Detail.md yêu cầu riêng cho World đó (ví dụ trọng lực đổi hướng ở World 4).

**Tham chiếu:** Detail.md Phần A.V (World 2-4), Phần C, Phần B, Phần D

### P6.1 — World 2: Hầm Ngục Huyết Rễ
- [ ] Môi trường: vũng axit rút máu, búp nấm nảy, bám tường né gai độc.
- [ ] Enemy X.1-4: Bào Tử Nhảy, Ấu Trùng Bám Tường, Rễ Con Đâm Sàn. X.6-8: Nhện Máu Lớn, Xác Sống Nhiễm Độc, Cầm Thú Rễ Cây.
- [ ] Elite 2.5: Cổ Thụ Biến Dị (rễ đâm sàn ngẫu nhiên + phun phấn độc diện rộng).
- [ ] Boss 2.10: Mẫu Thể Ký Sinh — Phase 1 (nhện bám vách, tơ làm chậm, chân nhọn rơi từ trần), Phase 2 (rơi sàn, triệu hồi trứng nổ + mạng nhện phủ map). HP theo Phần D.V (7,800: P1 4,680/P2 3,120), TTK mục tiêu ~110s.
- [ ] NPC "Thầy Lang Điên" tại Safe Haven 2.9 (bán buff Chảy máu/Độc, lựa chọn đạo đức nhẹ ảnh hưởng thoại kết game).

### P6.2 — World 3: Tháp Đồng Hồ Cơ Giới
- [ ] Môi trường: sàn bánh răng xoay, laser quét định kỳ, piston ép trần.
- [ ] Enemy X.1-4: Robot Tuần Tra, Turret Piston, Drone Trinh Sát. X.6-8: Cỗ Máy Nghiền, Robot Laser Kép (X hình chéo, cần Shadow Dash), Bầy Ong Cơ Khí (dễ khiến Flow tụt do bị bao vây).
- [ ] Elite 3.5: Cỗ Máy Hộ Vệ Lõi (khiên phản sát thương phía trước — dạy cơ chế đánh sau lưng).
- [ ] Boss 3.10: Kẻ Hành Quyết Cơ Giới — Phase 1 (robot 4 tay cưa xoay + tên lửa đuổi), Phase 2 (tách bộ phận, bay, laser 360°). HP theo Phần D.V (14,900: P1 7,450/P2 7,450), TTK mục tiêu ~125s.
- [ ] NPC "Kỹ Sư Sao Chép" tại Safe Haven 3.9 (bán bản thiết kế Reforge cao cấp A→R).

### P6.3 — World 4: Đền Thờ Hư Vô (Final)
- [ ] Cơ chế riêng world này: bục đá tan biến sau 1s, trọng lực thay đổi cục bộ, ảo ảnh tập kích bất ngờ — cần module riêng ngoài core (`gravity_zone`, `crumbling_platform`).
- [ ] Enemy X.1-4: Bóng Vỡ Vụn (dịch chuyển tức thời, đánh lén), Ảo Ảnh Trọng Lực (đổi hướng trọng lực khi bị tấn công), Tinh Thể Vỡ (nổ chậm, luyện Just-dodge). X.6-8: Kiếm Sĩ Bóng Tối Nhỏ (mini-boss báo trước final boss), Song Sinh Trôi Nổi (cặp tank/dmg), Mắt Hư Không (laser xoay 360° chậm, buộc dùng double-jump/wall-jump).
- [ ] Elite 4.5: Chiến Binh Ảo Ảnh (phân thân liên tục, tốc độ cực nhanh).
- [ ] Boss 4.10 (final): Kẻ Thao Túng Hư Không — 3 Phase (Phase 1: song đao tốc độ ngang người chơi; Phase 2: 2 phân thân tấn công 2 hướng; Phase 3 <25% HP: sàn thu hẹp, chuỗi tất sát ép Parry hoàn hảo liên tục). HP theo Phần D.V (28,500: P1 11,400/P2 9,975/P3 7,125), TTK mục tiêu ~140s.
- [ ] Safe Haven 4.9 đặc biệt: KHÔNG có NPC thương nhân, chỉ có "Gương Phản Chiếu" phát thoại twist — cần cutscene/dialogue riêng, không dùng UI thương nhân chuẩn.
- [ ] Twist ending: Kẻ Thao Túng Hư Không là phản chiếu của chính nhân vật — cần đoạn cutscene/dialogue kết thúc riêng, phối hợp với đội viết lore.

**DoD mỗi World con:** Chơi trọn X.1→X.10, TTK Boss khớp bảng Phần D.V trong khoảng ±10-15%, toàn bộ NPC/lore fragment xuất hiện đúng vị trí.

---

## P7 — BALANCE PASS, POLISH & PRE-RELEASE

**Mục tiêu:** Playtest thật để tinh chỉnh — Phần D nhấn mạnh nhiều lần bảng số "chỉ là điểm khởi đầu".

- [ ] Playtest đo uptime tấn công thực tế của người chơi thường/giỏi (thiết kế giả định 55%, người giỏi có thể 65-70% → cần tăng nhẹ HP Boss nếu lệch nhiều).
- [ ] Thử nghiệm bật/tắt `flow_preserve_on_parry` (Phần D.VI) để quyết định có giữ Flow khi Parry thành công dù bị "trúng đòn" hay không.
- [ ] Tinh chỉnh K trong công thức Mitigation% (mặc định 50, thử 70-80 nếu muốn giáp early-game "cứng" hơn).
- [ ] Cân bằng chéo giữa Portal Choice (Combat vs Sustain) — đảm bảo không có lựa chọn nào bị bỏ qua hoàn toàn vì lệch lợi ích.
- [ ] Polish VFX/SFX: after-image, vệt sáng phẩm chất rơi đồ, hit-stop, screen shake khi Parry/Crit.
- [ ] Cân bằng tỉ lệ rơi đồ D-C (rất cao) so với SSR (độc bản/boss cuối) — kiểm tra tốc độ tiến triển build không quá nhanh/chậm.
- [ ] QA toàn bộ 4 World liên tiếp không nghỉ (full playthrough run) để bắt lỗi tích lũy (memory leak, save/load checkpoint xuyên world).
- [ ] Kiểm tra bản dịch/ổn định thoại NPC và fragment lore không bị trùng lặp khi gặp lại "Vulcan Tàn Diệt" qua 4 world.

**DoD:** Full playthrough 4 World không crash, số liệu TTK/tỉ lệ rơi nằm trong khoảng mục tiêu đã playtest xác nhận, không còn cơ chế nào gắn nhãn `ASSUMPTION:` chưa được duyệt.

---

## GHI CHÚ ƯU TIÊN CHUNG

1. **Không làm nội dung (World 2-4) trước khi P1 (core combat feel) đã "đúng cảm giác".** Đây là game action, feel sai thì mọi nội dung phía sau đều phải làm lại.
2. **Balance luôn là dữ liệu, không phải hằng số cứng** — vì chính Phần D của Detail.md đã chỉ ra bảng gốc từng bị lỗi nặng (power creep 57 lần), nên toàn bộ pipeline phải cho phép chỉnh sửa nhanh mà không rebuild.
3. World 2-4 (P6) có thể làm song song bởi các dev/agent khác nhau **sau khi P5 (World 1 vertical slice) đã pass DoD**, vì lúc đó khung hệ thống đã ổn định, chỉ còn thay nội dung.
4. Lore (Phần B) là lớp phủ lên trên gameplay đã có — không nên thiết kế ngược từ lore ra cơ chế, trừ hệ thống trọng lực riêng của World 4 (đã ghi rõ trong P6.3).
