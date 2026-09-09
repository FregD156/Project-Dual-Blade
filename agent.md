# AGENT.md — Project Dual Blade

> File này định nghĩa **cách một AI coding agent (Claude Code, Cursor, Copilot Agent, v.v.) làm việc trên dự án này**. Đọc file này trước khi chạm vào bất kỳ dòng code nào. Với lộ trình triển khai theo từng giai đoạn, xem `plan.md`.

---

## 1. TÓM TẮT DỰ ÁN

**Project Dual Blade** — game 2D side-scrolling action, pixel art 16-bit, thể loại Boss Rush + Roguelite/Stage-based progression. Nhân vật dùng song đao, trọng tâm là combat tốc độ cao, Cross-Parry theo khung hình, và hệ thống loot/rèn phân tầng phẩm cấp (D → SSR).

Toàn bộ đặc tả gameplay, lore, enemy roster và số liệu cân bằng nằm trong `Detail.md` (tài liệu gốc). Agent **luôn coi `Detail.md` là nguồn sự thật (source of truth)** cho design — không tự sáng tác thêm cơ chế mới nếu không được yêu cầu, và không mâu thuẫn với các con số đã chốt ở Phần D (Balance).

---

## 2. VAI TRÒ CỦA AGENT

Agent đóng vai trò **kỹ sư gameplay / systems engineer** hỗ trợ hiện thực hóa design doc thành code chạy được, theo đúng thứ tự ưu tiên trong `plan.md`. Cụ thể agent chịu trách nhiệm:

1. Dịch các cơ chế mô tả bằng lời (tiếng Việt, đôi khi mơ hồ) thành thông số kỹ thuật cụ thể (frame, giây, %, công thức).
2. Viết code **data-driven** — số liệu (ATK, HP, Crit Rate, tỉ lệ rơi đồ...) phải nằm trong file dữ liệu (JSON/Resource/ScriptableObject), không hard-code trong logic, để việc balance-pass ở Giai đoạn 6 (xem `plan.md`) không cần sửa code.
3. Khi một chi tiết trong `Detail.md` không đủ rõ để implement (ví dụ: chưa có số khung hình chính xác cho một animation), agent **đặt giả định hợp lý, ghi chú rõ trong code comment hoặc PR description dạng `ASSUMPTION:`**, rồi tiếp tục — không dừng lại chờ hỏi trừ khi giả định đó ảnh hưởng lớn đến core feel (ví dụ: thời lượng cửa sổ Parry).
4. Luôn tự viết test/scene thử nghiệm nhỏ (test harness) cho mỗi cơ chế combat trước khi coi là "xong".

---

## 3. TECH STACK & KIẾN TRÚC ĐỀ XUẤT

Design chưa chỉ định engine. Giả định mặc định để agent tiến hành (có thể đổi nếu người dùng chỉ định khác):

- **Engine:** Godot 4.x (GDScript hoặc C#) — phù hợp 2D pixel art, physics 2D nhẹ, tách state machine dễ, miễn phí, cộng đồng lớn cho action platformer.
  - *Thay thế được chấp nhận:* Unity 2D (nếu team quen C#/muốn asset store), hoặc HTML5/Phaser nếu mục tiêu là web game nhẹ.
- **Ngôn ngữ dữ liệu:** JSON hoặc `.tres` (Godot Resource) cho bảng Item/Enemy/Boss/Option Pool — KHÔNG hard-code trong script.
- **Kiến trúc combat:** Finite State Machine (FSM) cho Player và mỗi loại Enemy/Boss, tách riêng theo file:
  - `PlayerStateMachine` (Idle, Run, Jump, WallSlide, AirCombo, Dash, Parry, BladeDance...)
  - `EnemyStateMachine` / `BossPhaseController` (mỗi Boss có N phase, mỗi phase là 1 sub-state-machine).
- **Input buffering:** bắt buộc — do combo 4 nhát + Cross-Parry (cửa sổ 9-10 frame ở 60fps) cần buffer input ±2-3 frame để cảm giác mượt.
- **Hit-detection:** Hitbox/Hurtbox theo frame data (không dùng collision thô của sprite) — cần công cụ debug vẽ hitbox khi dev build.
- **Framerate tham chiếu:** mọi số liệu thời gian trong Detail.md quy đổi ở **60 FPS** (vd: cửa sổ Parry 0.15s = 9 frame). Nếu engine chạy biến thiên framerate, dùng `delta time`, không đếm frame cứng.

---

## 4. CẤU TRÚC THƯ MỤC ĐỀ XUẤT

```
/project-dual-blade
├── docs/
│   ├── Detail.md              # design doc gốc — read-only, không sửa
│   ├── agent.md                # file này
│   └── plan.md                 # lộ trình dev
├── data/
│   ├── items/                  # bảng Option Pool theo bậc D→SSR (JSON)
│   ├── enemies/                 # stat + behavior config từng loại quái
│   ├── bosses/                  # HP theo phase, DEF, kháng choáng, pattern timing
│   └── balance/                 # công thức Mitigation%, Crit, DPS curve (Phần D)
├── src/
│   ├── player/                  # FSM, combo system, Flow Meter, Dash, Parry
│   ├── combat/                  # damage formula, hit-stop, i-frame handler
│   ├── enemies/
│   ├── bosses/
│   ├── loot/                    # rarity roll, salvage, reforge, re-roll
│   ├── world/                   # stage loader, portal choice, checkpoint
│   └── ui/
├── scenes/                       # world 1-4, X.1–X.10 layouts
└── tests/                        # test scene cho từng cơ chế (parry timing, DPS sim...)
```

---

## 5. NGUYÊN TẮC THIẾT KẾ BẮT BUỘC TUÂN THỦ

### 5.1 Combat & Flow Meter
- Flow Meter: 5 nấc, +1/đòn trúng, reset về 0 nếu **không tấn công HOẶC bị trúng đòn trong 2.5s**. Đây là timer riêng, reset ngay khi 1 trong 2 điều kiện xảy ra — không phải cộng dồn.
- Full Flow (5 nấc): +20% tốc độ di chuyển, +20% sát thương, mọi đòn có after-image gây damage phụ. Phải tắt hiệu ứng ngay khi Flow tụt khỏi mức 5 (không phải về 0).
- **Lưu ý cân bằng chưa tích hợp (Phần D.VI):** cân nhắc cho Cross-Parry thành công **giữ nguyên Flow** dù bị trúng đòn ngay sau đó — đây là item cần playtest, đánh dấu bằng flag `flow_preserve_on_parry` trong config để bật/tắt dễ dàng khi thử nghiệm, KHÔNG hard-code cứng 1 hướng.

### 5.2 Cross-Parry
- Cửa sổ: 9-10 frame @ 60fps (~0.15s) — implement bằng frame-counter hoặc timer tuyệt đối, ưu tiên buffer input.
- Thành công: hit-stop 0.1s, phá thế địch, dịch chuyển ra sau lưng, cho phép đòn phản chí mạng.
- Một số đòn boss KHÔNG parry được (ví dụ búa Thủ Lĩnh Đao Phủ Quỷ, báo hiệu màu đỏ) — cần flag riêng `is_unparryable = true` trên hitbox của đòn đó, khác với đòn thường (báo vàng/trắng).

### 5.3 Công thức sát thương (Phần D — BẮT BUỘC dùng bản đã sửa, không dùng bản gốc)
```
Mitigation% = DEF / (DEF + K)      # K = 50 mặc định, để config được (70-80 cho early-game "cứng" hơn)
Damage = max(1, ATK * SkillMultiplier * (1 - Mitigation%) * (1 - Resist%))
```
- Không được trừ DEF dạng flat trước Resist% (đây chính là lỗi của bảng gốc đã bị Phần D sửa).
- Crit Rate dùng **bảng mới** (D=5%, C=7%, B=10%, A=14%, R=18%, SR=23%, SSR=28% base), không dùng bảng cũ.
- Toàn bộ số ATK/DPS/HP Boss lấy theo bảng "sau khi sửa" ở mục III–V Phần D, KHÔNG lấy số ở Phần A/C nếu có xung đột.

### 5.4 Loot & Rarity
- 7 bậc D→C→B→A→R→SR→SSR, mỗi bậc có số dòng Option riêng (xem bảng III.1 Detail.md) — cấu trúc dữ liệu Item nên có field `sub_options: List<OptionID>` với giới hạn số lượng theo bậc được validate khi generate loot.
- Salvage: 3 vũ khí cùng bậc → nguyên liệu HOẶC 1 vũ khí ngẫu nhiên bậc kế tiếp.
- Re-roll: chỉ áp dụng từ bậc R trở lên.

### 5.5 Stage Progression
- Nhịp 1 world = 10 ải: X.1-X.4 (thường) → X.5 (Elite, chắc chắn rơi B/A) → X.6-X.8 (khó tăng) → X.9 (Safe Haven: rèn, hồi, đổi đồ) → X.10 (Boss).
- Portal Choice xuất hiện sau khi dọn sạch quái mỗi ải nhỏ, 2 lựa chọn: Combat Portal (nhiều quái, rơi phôi rèn) / Sustain Portal (ít quái, có bẫy, đảm bảo rơi Life Shard/Life Flask).
- Checkpoint tại X.1, X.5 (sau khi hạ Elite, Elite không respawn), X.9 (Boss chết hồi sinh về đây). Chết rơi 50% quặng/tinh thể tại nơi chết dạng "Bóng Ma Pixel", chết lần 2 trước khi nhặt lại → mất vĩnh viễn.

### 5.6 Mercy Drop System (rơi máu theo % HP người chơi)
Tỉ lệ rơi Hạt Sinh Mệnh/Bình Máu Lớn thay đổi theo ngưỡng HP hiện tại (>70%, 30-70%, <30%) — implement như một bảng lookup theo HP%, tính lại tỉ lệ rơi mỗi lần quái chết, không tính 1 lần khi spawn.

### 5.7 Boss room đặc thù
- Cứ mỗi mốc Boss tụt 25% HP tối đa → boss khựng nhẹ (stagger nhỏ, không phải full stun) + rơi 2 Bình Máu Lớn.
- 3 Cross-Parry liên tiếp thành công (không bị ngắt quãng bởi đòn trúng) → rơi 1 Life Shard từ boss.

---

## 6. QUY ƯỚC CODE

- **Đặt tên:** dùng tiếng Anh cho code/biến (`FlowMeter`, `CrossParryWindow`), tiếng Việt chỉ ở comment/design note hoặc string hiển thị UI/lore.
- **Không hard-code số liệu balance** — mọi ATK/HP/DEF/tỉ lệ rơi đọc từ `data/`.
- **Mỗi cơ chế mới cần kèm 1 test scene** trong `tests/` chứng minh nó hoạt động đúng số liệu thiết kế (vd: test đo chính xác cửa sổ Parry bằng frame counter).
- **Balance là dữ liệu sống:** Phần D ghi rõ "chưa phải số liệu cuối cùng, cần playtest". Agent không được coi bảng số hiện tại là bất biến — thiết kế hệ thống sao cho designer chỉnh số trong file data mà không cần sửa code hay build lại.
- **Commit message** nên gắn với hạng mục trong `plan.md` (ví dụ: `feat(combat): implement Cross-Parry window per Plan P2.3`).
- **Đừng tự thêm cơ chế/animation mới ngoài Detail.md** trừ khi người dùng yêu cầu — nếu thấy thiếu chi tiết kỹ thuật, ưu tiên suy luận hợp lý + ghi `ASSUMPTION:` thay vì bịa thêm gameplay mới.

---

## 7. GIỚI HẠN & KHI NÀO CẦN HỎI LẠI NGƯỜI DÙNG

Agent tự quyết và tiếp tục làm việc trong hầu hết trường hợp, NHƯNG nên dừng lại hỏi khi:
- Cần chọn engine/ngôn ngữ chính thức nếu người dùng chưa từng xác nhận giả định ở mục 3.
- Một con số balance mới (không có trong Detail.md) sẽ ảnh hưởng lớn đến core loop (vd: đổi hẳn công thức Mitigation%).
- Cần asset pixel art / âm thanh thật — ngoài phạm vi code, cần người dùng cung cấp hoặc xác nhận nguồn.

---

## 8. THAM CHIẾU NHANH TỚI DETAIL.MD

| Chủ đề | Vị trí trong Detail.md |
|---|---|
| Flow Meter, Moveset, Parry | Phần A, Mục II |
| Rarity, Option Pool, Reforge | Phần A, Mục III |
| Stage structure X.1–X.10, Portal | Phần A, Mục IV |
| World design & Boss pattern | Phần A, Mục V |
| Checkpoint & death penalty | Phần A, Mục VI |
| Bình máu & Mercy Drop | Phần A, Mục VII |
| Lore & cốt truyện | Phần B |
| Enemy roster từng world | Phần C |
| Công thức & bảng cân bằng số liệu | Phần D |
