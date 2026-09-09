# TÀI LIỆU THIẾT KẾ GAME: PROJECT DUAL BLADE
## (Dự Án Vượt Ải Đánh Boss 2D Pixel)

---

# PHẦN A — TỔNG QUAN & GAMEPLAY GỐC

## I. TỔNG QUAN DỰ ÁN (OVERVIEW)

* **Tên dự án:** Project Dual Blade (Tạm đặt).
* **Thể loại:** 2D Side-scrolling Action, Boss Rush kết hợp Roguelite / Stage-based progression.
* **Phong cách đồ họa:** Pixel Art chi tiết (16-bit), vệt chém hư ảnh (after-image) và vệt sáng phẩm chất trang bị rơi rực rỡ.
* **Góc nhìn (Perspective):** Màn hình ngang 2D (Side-scroller).
* **Trọng tâm trải nghiệm:** Tốc độ tấn công liên hoàn, phản đòn (Cross-Parry) chuẩn từng khung hình, nhặt đồ và build trang bị phân tầng phẩm cấp để áp đảo các trận đấu boss quy mô.

---

## II. CƠ CHẾ ĐIỀU KHIỂN & VŨ KHÍ: SONG ĐAO (DUAL BLADES)

### 1. Cơ Chế Đặc Trưng: Thanh Cuồng Bạo (Flow Meter)
* **Quy tắc tích lũy:** Tối đa 5 nấc. Mỗi đòn chém trúng kẻ địch tích 1 nấc Flow.
* **Hiệu ứng kích hoạt (Full 5 nấc):**
  * Kích hoạt trạng thái *Xuất Quỷ*: Tăng 20% tốc độ di chuyển và 20% tổng sát thương đầu ra.
  * Mọi đòn đánh đều kèm dư ảnh bóng ma (after-image) gây thêm sát thương phụ.
* **Cơ chế tụt:** Không tấn công hoặc bị dính đòn trong 2.5 giây sẽ khiến thanh Flow lập tức tụt về 0, buộc người chơi phải liên tục bám sát áp lực mục tiêu.

### 2. Bộ Kỹ Năng Cơ Bản (Moveset)
* **Cơ động môi trường (Platforming):**
  * Chạy, nhảy đơn (Single Jump) và nhảy đúp (Double Jump).
  * Bám tường trượt chậm và đạp tường nhảy cao (Wall Jump) để tiếp cận góc khuất hoặc né chiêu dội sàn.
  * Bám mép sàn/bục để leo lên nhanh chóng.
* **Combo đánh thường (4 nhát):**
  * Nhát 1 - 2: Hai đường chém chéo hình chữ X tốc độ cao.
  * Nhát 3: Xoay người chém kép theo trục ngang.
  * Nhát 4 (Finisher): Kéo hai lưỡi đao cắt ngang về phía trước rồi bật nhẹ lùi lại tạo khoảng cách an toàn.
* **Không chiến (Air Combat):**
  * *Air Combo:* Giữ nhân vật lơ lửng trên không thêm 0.3s khi chém, giúp né đòn quét sàn của boss mà không cần chạm đất ngay.
  * *Spinning Dive (Bổ nhào):* Cắm thẳng hai lưỡi đao xuống đất; nếu tiếp trúng đầu kẻ địch/búp nấm bẫy sẽ tự động nảy ngược lên trên để tái kích hoạt đòn nhảy.
* **Lướt hư ảnh (Shadow Dash):** Lướt cự ly ngắn xuyên người boss với khung bất tử (i-frame). Nếu né đòn ở tích tắc cuối (Just-dodge), để lại 1 phân thân phát nổ và tức thì xuất hiện sau lưng đối thủ.
* **Phản đòn (Cross-Parry):** Bắt chéo 2 lưỡi đao để đỡ đòn.
  * Cửa sổ thực hiện: Hẹp (khoảng 0.15 giây / 9-10 frames ở 60fps).
  * Thành công: Đóng băng khung hình (hit-stop) 0.1 giây, phá vỡ thế trận của kẻ địch, lướt ra sau lưng và phản đòn chí mạng.
* **Chiêu thức đặc biệt (Blade Dance):** Kích hoạt khi đầy năng lượng/Flow. Nhân vật biến mất trong 0.5s, tung bão đao liên hoàn 6-8 nhát trong vùng chỉ định, toàn bộ quá trình tung chiêu là khung bất tử.

---

## III. HỆ THỐNG TRANG BỊ & PHẨM CHẤT (LOOT & RARITY)

### 1. Thang Phẩm Chất Vũ Khí (D ➔ C ➔ B ➔ A ➔ R ➔ SR ➔ SSR)

| Bậc Phẩm | Màu Tia Sáng (VFX) | Tỷ Lệ Cơ Bản | Số Dòng Option Phụ | Đặc Điểm Nhận Diện |
| :---: | :---: | :---: | :---: | :--- |
| **D** | Xám tro (Gray) | Rất cao | 0 | Đao rỉ mẻ, tầm ngắn, sát thương thấp nhất. |
| **C** | Trắng bạc (White) | Cao | 1 dòng D | Đao thép thô, bắt đầu có vệt chém mờ. |
| **B** | Xanh lục (Green) | Trung bình | 1 dòng C + 1 dòng D | Vũ khí thợ rèn, tăng tốc độ vung đao. |
| **A** | Xanh lam (Blue) | Thấp | 2 dòng B | Đao thép tinh chế, đòn thứ 4 tạo luồng gió nhẹ. |
| **R** | Tím huyền bí (Purple) | Hiếm | 2 dòng A + 1 dòng R | Khắc cổ tự, mở hiệu ứng Đốt cháy/Băng giá. |
| **SR** | Vàng kim (Gold) | Cực hiếm | 3 dòng R + 1 Nội tại | Phát sáng lập lòe, biến đổi hoạt ảnh Parry/Air-Combo. |
| **SSR** | Cầu vồng/Đỏ thẫm (Prismatic) | Độc bản/Boss cuối | 3 dòng SR + 1 Lõi Thức Tỉnh | Dư ảnh trảm rợp màn hình, đổi toàn bộ chiêu Tất sát. |

### 2. Bể Dòng Option (Option Pool) Theo Bậc
* **Bậc D - C (Chỉ số nền):**
  * *[D] Cùn Nhẹ:* +5% Sát thương vật lý.
  * *[D] Nhẹ Tay:* +4% Tốc độ chạy khi rút vũ khí.
  * *[C] Mài Sắc:* +6% Tỷ lệ chí mạng.
  * *[C] Cân Bằng:* Giảm 8% thời gian khựng khi tiếp đất.
* **Bậc B - A (Tối ưu giao tranh):**
  * *[B] Huyết Khát Nhỏ:* Hồi 1% HP tối đa khi hạ 1 kẻ địch.
  * *[B] Nạp Khí:* Tăng 15% lượng Flow tích lũy mỗi đòn đánh.
  * *[A] Xuyên Giáp:* Bỏ qua 20% giáp của kẻ địch có giáp/khiên.
  * *[A] Hư Ảnh Bước:* Tăng thêm 0.04s bất tử (i-frame) cho Shadow Dash.
* **Bậc R - SR (Biến đổi chiêu thức):**
  * *[R] Lôi Kích Liêm:* Đòn chém thứ 4 phóng tia sét nảy sang 2 mục tiêu lân cận gây 40% sát thương.
  * *[R] Huyết Nhẫn:* Tích tụ hiệu ứng Chảy Máu tối đa 5 tầng; đầy tầng sẽ nổ 10% máu quái thường.
  * *[SR] Phản Kích Tử Thần:* Parry chuẩn xác khung cuối sẽ chém 2 nhát chí mạng gây 250% sát thương và hồi 5% HP.
  * *[SR] Vũ Điệu Phân Thân:* Ở trạng thái Full Flow, mỗi đòn đánh triệu hồi 1 bóng ma chém phụ 35% sát thương.
* **Bậc SSR (Lõi Thức Tỉnh - Build Definer):**
  * *[SSR] Luân Hồi Hư Không:* Just-dodge thành công sẽ làm chậm thời gian của toàn map 50% trong 1.5s (Bullet-time), người chơi giữ nguyên tốc độ.
  * *[SSR] Diệt Thế Thần Khí:* Chiêu Blade Dance nâng cấp thành *Vô Hạn Trảm*: Biến mất và tung 12 nhát chém toàn màn hình không thể né tránh.

### 3. Cơ Chế Thợ Rèn: Tái Chế & Tẩy Dòng (Reforge & Fusion)
* **Phân rã (Salvage):** Nấu chảy 3 vũ khí cùng bậc cũ để đổi lấy nguyên liệu rèn hoặc 1 vũ khí ngẫu nhiên ở bậc cao hơn liền kề.
* **Tẩy dòng (Re-roll):** Dùng tinh thể quái để quay lại 1 dòng Option phụ không mong muốn trên các trang bị từ bậc R trở lên.

---

## IV. CẤU TRÚC VƯỢT ẢI (STAGE PROGRESSION: X.1 ➔ X.10)

### 1. Nhịp Độ 1 Chu Kỳ (Loop Pacing)

```
[X.1 -> X.4]        [X.5]         [X.6 -> X.8]       [X.9]          [X.10]
Quái thường/Khởi động -> QUÁI TINH ANH -> Thử thách tăng tốc -> Trạm Nghỉ/Rèn đồ -> ĐẠI TRÙM CUỐI
(Thu lượm đồ D-C)     (Thưởng đồ B-A)    (Bẫy + Mê cung)    (Hồi phục + Ghép)   (Săn đồ A-R-SR)
```

* **X.1 – X.4 (Khởi động):** Đấu trường ngắn (30-45s/ải), gồm 2-3 đợt quái; làm quen môi trường và nhặt đồ D - C.
* **X.5 (Quái Tinh Anh - Mid-Boss):** Có thanh máu riêng; đánh bại chắc chắn rơi vũ khí Rank B hoặc A.
* **X.6 – X.8 (Đẩy cao độ khó):** Quái giáp nặng, lính bắn tỉa và mật độ bẫy sàn/laser dày đặc.
* **X.9 (Trạm Nghỉ An Toàn - Safe Haven):** Không có quái. Chứa Bàn Thợ Rèn, Đài tế hồi 50% HP và NPC đổi vật phẩm.
* **X.10 (Sàn Đấu Đại Trùm):** Trận đấu Boss 2-3 Phase, hạ gục để mở khóa World tiếp theo.

### 2. Phân Nhánh Phòng (Portal Choice)
Sau khi dọn sạch quái ở mỗi ải nhỏ (ví dụ 1.2 xong sang 1.3), sàn đấu xuất hiện 2 cánh cổng dịch chuyển để người chơi tự quyết định chiến lược:
* **Cổng Đao Kiếm (Combat Portal):** Mật độ quái dày hơn, có quái tinh anh nhỏ, tỷ lệ rơi phôi vũ khí và quặng rèn cao hơn.
* **Cổng Sinh Mệnh (Sustain Portal):** Quái thưa, có bẫy môi trường và ở cuối phòng chắc chắn có bình vỡ chứa Hạt Sinh Mệnh / Bình Máu Lớn.

---

## V. THIẾT KẾ CÁC THẾ GIỚI (WORLD DESIGN)

### World 1: Cổ Thành Hoang Tàn (The Forsaken Bastion)
* **Visual:** Lâu đài đá đổ nát, hoàng hôn u ám, rêu phong và cờ rách.
* **Thử thách môi trường:** Hào chông gai, bục đá rơi, lính nỏ trên cao.
* **1.5 (Quái Tinh Anh):** *Thủ Lĩnh Đao Phủ Quỷ* - Đòn vung búa nặng không thể đỡ (báo đỏ), gọi 2 lính nỏ hỗ trợ.
* **1.10 (Boss):** *Thống Lĩnh Thiết Vệ (The Ironclad Commander)*
  * Phase 1: Vung đại kiếm uy lực cao, báo hiệu vệt đỏ 0.8s (tập parry).
  * Phase 2: Bỏ khiên dùng song kiếm, combo 3 nhát kèm sóng chấn động mặt sàn.

### World 2: Hầm Ngục Huyết Rễ (The Crimson Catacombs)
* **Visual:** Cống ngầm ẩm ướt, rễ cây khổng lồ phát sáng đỏ máu, bào tử nấm độc.
* **Thử thách môi trường:** Vũng axit rút máu, búp nấm nảy, bám tường né gai độc.
* **2.5 (Quái Tinh Anh):** *Cổ Thụ Biến Dị* - Rễ cây đâm từ dưới sàn, phun phấn độc diện rộng.
* **2.10 (Boss):** *Mẫu Thể Ký Sinh (The Parasitic Broodmother)*
  * Phase 1: Nhện khổng lồ bám vách, phun tơ làm chậm, thả chân nhọn từ trần xuống.
  * Phase 2: Rơi xuống sàn, triệu hồi trứng nổ và quét mạng nhện bao phủ bản đồ.

### World 3: Tháp Đồng Hồ Cơ Giới (The Clockwork Spire)
* **Visual:** Lòng tháp bánh răng vàng đồng, khói hơi nước áp suất cao, piston giập.
* **Thử thách môi trường:** Sàn đấu là các trục bánh răng xoay, tia laser quét định kỳ, piston ép trần.
* **3.5 (Quái Tinh Anh):** *Cỗ Máy Hộ Vệ Lõi* - Khiên chắn năng lượng phản sát thương phía trước.
* **3.10 (Boss):** *Kẻ Hành Quyết Cơ Giới (The Automaton Executioner)*
  * Phase 1: Robot 4 tay cưa xoay càn quét sàn đấu, phóng tên lửa đuổi.
  * Phase 2: Tách rời bộ phận, bay lơ lửng phóng chùm laser quét 360 độ.

### World 4: Đền Thờ Hư Vô (The Void Sanctum)
* **Visual:** Mảnh vỡ kiến trúc trôi lơ lửng giữa nền vũ trụ tím thẫm, các vết rách không gian.
* **Thử thách môi trường:** Bục đá tan biến sau 1 giây, trọng lực thay đổi, ảo ảnh tập kích bất ngờ.
* **4.5 (Quái Tinh Anh):** *Chiến Binh Ảo Ảnh* - Phân thân liên tục, tốc độ lướt cực nhanh.
* **4.10 (Đại Trùm Cuối):** *Kẻ Thao Túng Hư Không (The Void Sovereign)*
  * Phase 1: Kiếm sĩ bóng tối dùng song đao, tốc độ ngang ngửa người chơi, chém kiếm khí.
  * Phase 2: Tạo 2 phân thân tấn công phối hợp từ hai hướng đối diện.
  * Phase 3 (Cuồng nộ <25% HP): Mặt sàn thu hẹp, tung chuỗi tất sát liên hoàn ép người chơi phải Parry hoàn hảo liên tục để mở đường sống.

---

## VI. HỆ THỐNG CHECKPOINT & HỒI SINH

### 1. Vị Trí Cột Mốc (3 Điểm / World)
* **Checkpoint 1:** Tại ải **X.1** (Khởi đầu World).
* **Checkpoint 2:** Tại ải **X.5** (Sau khi đánh bại Quái Tinh Anh, trụ phong ấn mở ra; Quái Tinh Anh không bao giờ hồi sinh lại).
* **Checkpoint 3:** Tại ải **X.9** (Phòng Thợ Rèn ngay trước cửa Boss X.10; khi chết ở Boss sẽ hồi sinh ngay tại đây).

### 2. Quy Tắc Giữ Đồ & Hình Phạt (Death Penalty)
* **Bảo toàn trang bị:** Toàn bộ vũ khí, phẩm chất và dòng Option đã nhặt được giữ nguyên 100% khi chết.
* **Dư Ảnh Hồn Thạch (Echo Shard):** Khi ngã xuống, rơi lại 50% số Quặng và Tinh Thể Nâng Cấp tại tọa độ chết dưới dạng Bóng Ma Pixel.
* **Thu hồi:** Chạy đến vị trí cũ và chém vỡ Bóng Ma để nhận lại toàn bộ tài nguyên. Nếu chết lần thứ hai trước khi nhặt lại, số tài nguyên đó biến mất vĩnh viễn.

### 3. Tiện Ích Mở Rộng Tại Bệ Thờ Checkpoint
* **Hồi phục (Rest):** Chạm vào bệ thờ để lưu tiến trình và hồi đầy máu.
* **Rương Đa Năng (Stash):** Cất giữ các thanh song đao phẩm cao chưa dùng đến để tránh quá tải hành trang mang theo.
* **Dịch Chuyển Nhanh (Fast Travel):** Sau khi hạ gục Boss X.10 của bất kỳ World nào, trạm Checkpoint của World đó sẽ mở khóa tính năng dịch chuyển hai chiều, cho phép quay về farm tài nguyên hoặc săn rương ẩn còn sót.

---

## VII. CƠ CHẾ BÌNH MÁU RƠI NGẪU NHIÊN & SINH TỒN

### 1. Phân Loại Vật Phẩm Rơi Dọc Đường

| Vật Phẩm | Tỷ Lệ Rơi Cơ Bản | Cơ Chế Hồi Phục |
| :--- | :---: | :--- |
| **Hạt Sinh Mệnh Nhỏ (Life Shard)** | 25% từ quái thường | Tự động hút trong tầm 2m, hồi ngay **8% HP**. |
| **Bình Máu Lớn (Life Flask)** | 5% quái thường, 40% quái to | Nhặt vào túi dự trữ (tối đa giữ **3 bình**), bấm nút để hồi **35% HP**. |
| **Trái Tim Huyết Tế (Heart Core)** | 100% từ Quái Tinh Anh (X.5) | Hồi ngay **50% HP** + Tăng 10% sát thương trong 20 giây kế tiếp. |

### 2. Thuật Toán "Thương Xót" (Mercy Drop System)
* **HP > 70%:** Tỷ lệ rớt Hạt Nhỏ là 15%, Bình Lớn là 2%.
* **HP từ 30% - 70%:** Tỷ lệ rớt Hạt Nhỏ là 30%, Bình Lớn là 8%.
* **HP < 30% (Báo động đỏ):** Tỷ lệ rớt Hạt Nhỏ vọt lên 60%; cứ tiêu diệt 3 quái thường chắc chắn rớt 1 Bình Máu Lớn.

### 3. Rơi Máu Trong Phòng Boss (X.10)
* **Cơ chế Ngưỡng Máu:** Cứ mỗi khi Boss tụt 25% lượng máu tối đa, boss bị khựng nhẹ và văng ra **2 Bình Máu Lớn** xuống sàn.
* **Thưởng Parry Chuẩn Xác:** Thực hiện thành công chuỗi 3 đòn Cross-Parry liên tiếp sẽ đánh văng ra 1 Hạt Sinh Mệnh Nhỏ từ người boss.

---

# PHẦN B — LORE & CỐT TRUYỆN (Bổ sung)

## I. CHỦ ĐỀ BAO TRÙM (CORE THEME)

**"Vượt Ải" theo nghĩa đen lẫn nghĩa bóng — hành trình từ Thể Xác đến Hư Vô.**

4 world đi theo trình tự: Thành trì vật lý (đá, sắt) → Sinh vật hữu cơ (rễ cây, thịt) → Cơ khí nhân tạo (bánh răng, kim loại) → Phi vật chất (không gian, hư không). Đây là đường cong "từ vật chất thô sơ đến sự phi-vật-chất."

**Câu chuyện khung (đã chốt):** Cả 4 thế giới từng là **một vương quốc duy nhất** đã sụp đổ qua 4 giai đoạn suy tàn khác nhau. Nhân vật chính không di chuyển qua không gian, mà đi ngược qua **các tầng ký ức/thời đại** của vương quốc đó để tìm ra nguyên nhân gốc rễ của sự sụp đổ — nằm ở World 4.

## II. NHÂN VẬT CHÍNH

* **Danh xưng tạm:** "Kẻ Mang Song Đao" / **Vệ Ẩn** (Silent Warden) — không tên thật, chỉ có danh hiệu, gợi bí ẩn.
* **Vai trò:** Không phải anh hùng cứu thế theo mô-típ thường — mà là **kẻ chấp hành lời thề cuối cùng** của một hiệp sĩ/vệ binh đã chết, được hồi sinh (hoặc là hồn ma) mỗi khi ngã xuống — lý giải cho hệ thống chết vô hạn lần không mất tiến trình (mục VI Phần A).
* **Động cơ:** Tìm ra "Lõi Thức Tỉnh" (trùng tên với vật phẩm SSR ở mục III.2) — vật phẩm huyền thoại chứa ký ức thật của vương quốc trước khi sụp đổ.
* **Ý nghĩa Song Đao:** Hai lưỡi kiếm tượng trưng cho **lời thề kép** — một lưỡi để bảo vệ, một lưỡi để trừng phạt kẻ phản bội lời thề đó. Lý giải vì sao Cross-Parry (phòng thủ) và combo tấn công đều mạnh ngang nhau về mặt thiết kế.

## III. MẠCH TRUYỆN XUYÊN SUỐT QUA 4 WORLD

| World | Ý nghĩa lore | Bí mật hé lộ ở cuối |
|---|---|---|
| **1. Cổ Thành Hoang Tàn** | Tầng ký ức gần nhất — nơi vương quốc sụp đổ vì phản loạn nội bộ | Thống Lĩnh Thiết Vệ thực chất là đồng đội cũ của nhân vật, bị nguyền thành quái vật canh giữ cổng |
| **2. Hầm Ngục Huyết Rễ** | Tầng sâu hơn — nơi vương quốc thử nghiệm sức mạnh cấm kỵ (rễ cây/ký sinh) để cứu vãn sự sụp đổ | Mẫu Thể Ký Sinh là hậu quả thí nghiệm thất bại — gieo mầm cho sự suy tàn tiếp theo |
| **3. Tháp Đồng Hồ Cơ Giới** | Tầng công nghệ — nơi con người cố dùng máy móc thay thế phép thuật đã mất kiểm soát | Kẻ Hành Quyết là cỗ máy được tạo ra để "xóa bỏ" mọi lỗi lầm — kể cả con người tạo ra nó |
| **4. Đền Thờ Hư Vô** | Cội nguồn — nơi mọi thứ bắt đầu, cũng là nơi Lõi Thức Tỉnh thật sự tồn tại | Kẻ Thao Túng Hư Không chính là **hình ảnh phản chiếu/tha hóa của chính nhân vật chính** |

Twist này lý giải Phase 2 của Boss World 4 ("2 phân thân tấn công từ hai hướng đối diện") — về lore đó chính là 2 mặt của cùng một con người.

## IV. TÍCH HỢP LORE VÀO GAMEPLAY

* **Trạm Nghỉ X.9** mỗi world: NPC linh hồn kể lại 1 mảnh ký ức ngắn (fragment lore, không bắt buộc đọc).
* **Item description:** Mỗi dòng Option bậc R trở lên (VD "Phản Kích Tử Thần", "Vũ Điệu Phân Thân") có 1 câu lore ngắn gắn với vương quốc cũ.

## V. HỆ THỐNG NPC PHỤ (Trạm Nghỉ X.9 mỗi World)

### 1. Lão Thợ Rèn — "Vulcan Tàn Diệt" (xuyên suốt cả 4 world)
* **Vai trò:** NPC duy nhất xuất hiện ở cả 4 Trạm Nghỉ — cùng một linh hồn di chuyển theo nhân vật chính qua các tầng ký ức.
* **Lore:** Từng là thợ rèn hoàng gia, người duy nhất từ chối tham gia thí nghiệm cấm kỵ ở World 2 — linh hồn ông ta "mắc kẹt" giữa các tầng ký ức.
* **Gameplay:** Thực hiện Tái Chế & Tẩy Dòng. Mỗi lần gặp lại ở world sau, hé lộ thêm 1 mảnh về sự sụp đổ.

### 2. Thương Nhân World 1 — "Bà Góa Chuông Gió" (Cổ Thành)
* **Lore:** Vợ của một lính gác đã chết trong trận phản loạn. Bán lại chiến lợi phẩm nhặt từ xác lính tử trận để đổi Hạt Sinh Mệnh.
* **Thoại gợi ý:** Ám chỉ Thống Lĩnh Thiết Vệ (boss 1.10) từng là người tốt trước khi bị nguyền.

### 3. NPC World 2 — "Thầy Lang Điên" (Hầm Ngục)
* **Lore:** Kẻ sống sót duy nhất của nhóm nghiên cứu tạo ra Mẫu Thể Ký Sinh, nay nửa người nửa nhiễm rễ ký sinh.
* **Gameplay:** Bán thuốc tăng hiệu ứng Chảy Máu/Độc. Lựa chọn đạo đức nhẹ (không bắt buộc): giúp hoàn thiện "thuốc giải" hay để mặc — ảnh hưởng 1 dòng thoại kết game.

### 4. NPC World 3 — "Kỹ Sư Sao Chép" (Tháp Đồng Hồ)
* **Lore:** Bản sao AI/máy móc của kỹ sư trưởng đã tạo ra Kẻ Hành Quyết — bản gốc đã chết, bản sao vẫn lặp lại công việc vô nghĩa.
* **Gameplay:** NPC duy nhất bán bản thiết kế Reforge cao cấp (unlock công thức ghép đồ A→R hiệu quả hơn).

### 5. NPC World 4 — Gương Phản Chiếu (không phải thương nhân)
* Trạm Nghỉ 4.9 chỉ có tấm gương vỡ phát ra giọng nói của chính nhân vật chính — gieo nghi ngờ trước trận cuối, ẩn ý cho twist Kẻ Thao Túng Hư Không.

## VI. MÔ TẢ CHI TIẾT QUÁI TINH ANH (X.5 mỗi World)

### 1.5 — Thủ Lĩnh Đao Phủ Quỷ (World 1)
* **Lore:** Đội trưởng đội hành quyết hoàng gia, từng tự tay xử tử kẻ phản loạn — cuối cùng bị chính phe mình phản bội và giết chết ngay nơi hắn từng hành quyết người khác.
* **Thiết kế hành vi:** Đòn búa không đỡ được (báo đỏ) = "công lý mù quáng" — dạy người chơi bài học: không phải đòn nào cũng nên Parry, đôi khi phải né.

### 2.5 — Cổ Thụ Biến Dị (World 2)
* **Lore:** Kết quả thí nghiệm cấy ghép sức mạnh sinh học lên một cái cây thiêng vốn dùng để chữa bệnh cho hoàng tộc.
* **Thiết kế hành vi:** Rễ đâm từ dưới sàn ngẫu nhiên, phun phấn độc diện rộng — phản ánh sự mất kiểm soát của phép thuật/khoa học từng có ý định tốt.

### 3.5 — Cỗ Máy Hộ Vệ Lõi (World 3)
* **Lore:** Nguyên mẫu đầu tiên trước khi có Kẻ Hành Quyết — bị bỏ lại vì "lỗi thiết kế" (khiên phản sát thương quá mạnh khiến nó tự gây sát thương ngược theo thời gian).
* **Thiết kế hành vi:** Khiên chắn phía trước dạy người chơi cơ chế né hướng/tấn công sau lưng — chuẩn bị cho pattern phức tạp hơn ở Boss 3.10.

### 4.5 — Chiến Binh Ảo Ảnh (World 4)
* **Lore:** Không phải một thực thể — là ký ức phân mảnh của chính nhân vật chính ở những lần "chết và hồi sinh" trước đó, bị hư không vật chất hóa thành kẻ địch.
* **Thiết kế hành vi:** Phân thân liên tục + tốc độ cực nhanh = báo trước cơ chế "song phân thân" của Boss cuối 4.10, củng cố twist "kẻ địch cuối cùng chính là bản thân người chơi."

---

# PHẦN C — ENEMY ROSTER (Quái thường từng World)

**Ghi chú thiết kế chung:** Mỗi world có 3 loại quái/giai đoạn (khởi động X.1-X.4 và đẩy độ khó X.6-X.8) để giữ scope vừa phải cho production. Loại quái ở X.6-X.8 luôn là "bản nâng cấp"/"biến thể nguy hiểm hơn" của loại tương ứng ở X.1-X.4 — vừa tái sử dụng animation, vừa tạo cảm giác leo thang tự nhiên.

## World 1: Cổ Thành Hoang Tàn

### X.1 – X.4 (Khởi động)
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Lính Gác Rỉ Sét** | Chém đơn giản, di chuyển chậm, dễ Parry | Vong hồn lính thường tử trận trong phản loạn |
| **Cung Thủ Tháp Canh** | Đứng xa bắn tên theo đường thẳng, buộc người chơi tiếp cận nhanh | Lính nỏ từng phục vụ hoàng gia |
| **Chó Săn Xích Sắt** | Lao nhanh thành cặp 2 con, dễ bị combo AoE nhát 3 | Thú canh ngục bị bỏ đói, hóa dại |

### X.6 – X.8 (Đẩy độ khó)
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Kỵ Sĩ Giáp Đen** | Giáp nặng (cần Xuyên Giáp mới hiệu quả), có thể dựng khiên chặn combo thường | Cận vệ trung thành sống sót sau phản loạn, nay canh giữ vô thức |
| **Lính Bắn Tỉa Cao Tháp** | Đứng trên bục cao, laser đỏ báo trước 0.5s, phối hợp bẫy sàn | Nâng cấp từ Cung Thủ Tháp Canh, dùng vũ khí cấm |
| **Quỷ Cờ Rách** | Bay lơ lửng, gây hiệu ứng làm chậm diện hẹp khi lại gần | Linh hồn dân thường chết trong loạn lạc, oán khí hóa quái |

## World 2: Hầm Ngục Huyết Rễ

### X.1 – X.4
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Bào Tử Nhảy** | Nổ chậm, gây độc diện hẹp nếu không hạ nhanh | Sản phẩm phụ lỗi của thí nghiệm |
| **Ấu Trùng Bám Tường** | Bám trần/tường, rơi bất ngờ khi người chơi đi ngang qua | Ký sinh trùng thí nghiệm sổng chuồng |
| **Rễ Con Đâm Sàn** | Bất động, chỉ đâm khi người chơi đứng gần — dạng "trap sống" | Tàn dư trực tiếp của Cổ Thụ Biến Dị |

### X.6 – X.8
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Nhện Máu Lớn** | Phun tơ làm chậm diện rộng, nhảy né đòn | Thế hệ "con" của Mẫu Thể Ký Sinh |
| **Xác Sống Nhiễm Độc** | Máu trâu, nổ độc khi chết (buộc đứng xa lúc kết liễu) | Nạn nhân dân thường bị nhiễm ký sinh |
| **Cầm Thú Rễ Cây** | Charge lao thẳng, phá vỡ giáp nếu trúng full lực, tạo khoảng trống địa hình | Thú rừng bị Cổ Thụ tha hóa hoàn toàn |

## World 3: Tháp Đồng Hồ Cơ Giới

### X.1 – X.4
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Robot Tuần Tra** | Đi theo tuyến cố định, dễ đoán, dạy pattern laser quét | Đơn vị an ninh cơ bản của tháp |
| **Turret Piston** | Bất động, bắn đạn theo nhịp piston giập | Hệ thống phòng thủ tự động còn sót |
| **Drone Trinh Sát** | Bay lượn, gọi thêm quái nếu không hạ nhanh trong 5s | Máy dò lỗi hệ thống, báo động nếu phát hiện xâm nhập |

### X.6 – X.8
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Cỗ Máy Nghiền** | Giáp cực dày, đòn quật sàn gây choáng nếu không né kịp | Máy nghiền phế liệu bị tái lập trình thành lính canh |
| **Robot Laser Kép** | Bắn 2 tia chéo hình chữ X, buộc dùng Shadow Dash xuyên qua | Nguyên mẫu thất bại trước Kẻ Hành Quyết |
| **Bầy Ong Cơ Khí** | Số lượng đông (4-5 con), từng con yếu nhưng dễ khiến Flow tụt nếu bị bao vây | Hệ thống sửa chữa tự động phản ứng nhầm với người chơi là "lỗi hệ thống" |

## World 4: Đền Thờ Hư Vô

### X.1 – X.4
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Bóng Vỡ Vụn** | Dịch chuyển tức thời ngắn, đánh lén từ góc khuất | Ký ức lỗi của những nhân vật/NPC đã gặp ở world trước, bị hư không tái tạo méo mó |
| **Ảo Ảnh Trọng Lực** | Bay lơ lửng, thay đổi hướng trọng lực cục bộ khi bị tấn công | Hiện tượng vật lý bị bẻ gãy của tầng ký ức khởi thủy |
| **Tinh Thể Vỡ** | Bất động, phát nổ chậm tạo vùng nổ chậm delay — luyện phản xạ Just-dodge | Mảnh vỡ Lõi Thức Tỉnh rải rác |

### X.6 – X.8
| Tên quái | Hành vi | Lore gắn kết |
|---|---|---|
| **Kiếm Sĩ Bóng Tối Nhỏ** | Combo tốc độ cao gần bằng người chơi — "phiên bản mini" báo trước Boss cuối | Mảnh ký ức phân liệt của chính nhân vật, giống Chiến Binh Ảo Ảnh nhưng yếu hơn |
| **Song Sinh Trôi Nổi** | Luôn xuất hiện theo cặp, một con tank hứng đòn/một con gây sát thương | Ẩn dụ trực tiếp cho "2 lưỡi song đao / 2 mặt bản ngã" |
| **Mắt Hư Không** | Bất động, quét laser xoay 360° chậm nhưng diện rộng, buộc dùng nhảy đúp/Wall Jump liên tục | Con mắt canh giữ cánh cổng dẫn tới Kẻ Thao Túng Hư Không |

---

# PHẦN D — CÂN BẰNG SỐ LIỆU (BALANCE)

## I. CHẨN ĐOÁN VẤN ĐỀ Ở BẢNG GỐC

Bảng DPS gốc có 2 trục tăng trưởng nhân với nhau cùng lúc (ATK theo bậc + Crit Rate theo bậc), khiến DPS Max ở SSR (1,600) gấp **57 lần** DPS D (28) trong khi ATK chỉ chênh ~24 lần — power creep rõ rệt. Đồng thời `DEF_flat` bị trừ thẳng trước Resist% khiến giáp Boss (4→25) gần như vô nghĩa khi ATK người chơi late-game đã 240-300.

## II. CÔNG THỨC SỬA LẠI

### 1. Đổi DEF sang giảm % (công thức Armor chuẩn ARPG)

$$\text{Mitigation\%} = \frac{\text{DEF}}{\text{DEF} + K}, \quad K = 50$$

$$\text{Damage} = \max\left(1, \text{ATK} \times \text{Skill Multiplier} \times (1 - \text{Mitigation\%}) \times (1 - \text{Resist\%})\right)$$

| Boss | DEF | Mitigation% (mới) |
|---|---|---|
| 1.10 | 4 | 7.4% |
| 2.10 | 8 | 13.8% |
| 3.10 | 15 | 23.1% |
| 4.10 | 25 | 33.3% |

*Lưu ý: K=50 chỉ là điểm khởi đầu — có thể tăng lên 70-80 nếu muốn giáp "cứng" hơn ở early game, cần playtest để tinh chỉnh.*

### 2. Crit Rate mới (tăng chậm hơn, không cộng dồn ATK)

| Phẩm | Crit Rate cũ | Crit Rate mới (base) |
|---|---|---|
| D | 5% | 5% |
| C | 8% | 7% |
| B | 14% | 10% |
| A | 20% | 14% |
| R | 28% | 18% |
| SR | 38% | 23% |
| SSR | 50% | 28% (đạt 50% phải build thêm qua Option/Flow) |

## III. BẢNG ATK & DPS SAU KHI SỬA

| Phẩm | ATK TB | Crit Rate mới | DPS Cơ Bản (mới) | Tăng trưởng so bậc trước |
|---|---|---|---|---|
| D | 12 | 5% | 31 | — |
| C | 21 | 7% | 54 | x1.74 |
| B | 36 | 10% | 94 | x1.74 |
| A | 61 | 14% | 163 | x1.73 |
| R | 100 | 18% | 271 | x1.66 |
| SR | 168 | 23% | 468 | x1.73 |
| SSR | 270 | 28% | 767 | x1.64 |

→ Tăng trưởng ổn định quanh 1.65-1.74x mỗi bậc, không còn "vỡ trận" ở late-game.

## IV. KIỂM TRA LẠI TIME-TO-KILL (TTK) VỚI BOSS

Giả định người chơi tấn công được ~55% thời gian trận đấu (còn lại né/di chuyển/chờ combo an toàn):

| Boss | Vũ khí khuyến nghị | DPS TB (mới) | HP hiện tại | TTK ước tính | TTK mục tiêu | HP đề xuất |
|---|---|---|---|---|---|---|
| 1.10 | C – B | 74 | 4,200 | ~103s | ~90s | **3,800** |
| 2.10 | B – A | 129 | 12,500 | ~175s | ~110s | **7,800** |
| 3.10 | A – R | 217 | 28,000 | ~234s | ~125s | **14,900** |
| 4.10 | R – SR | 370 | 65,000 | ~319s | ~140s | **28,500** |

HP Boss gốc quá dày so với DPS thực tế (đặc biệt World 3-4 lệch hơn gấp đôi mục tiêu).

## V. BẢNG BOSS SAU KHI CÂN BẰNG LẠI

| Chỉ Số | Boss 1.10 | Boss 2.10 | Boss 3.10 | Boss 4.10 |
|---|---|---|---|---|
| **Tổng HP (mới)** | **3,800** | **7,800** | **14,900** | **28,500** |
| - Phase 1 | 1,900 (50%) | 4,680 (60%) | 7,450 (50%) | 11,400 (40%) |
| - Phase 2 | 1,900 (50%) | 3,120 (40%) | 7,450 (50%) | 9,975 (35%) |
| - Phase 3 | — | — | — | 7,125 (25%) |
| **DEF (giữ nguyên)** | 4 | 8 | 15 | 25 |
| **Kháng Choáng (giữ nguyên)** | 300 | 500 | 800 | 1,200 |
| **TTK chuẩn (mới)** | ~90s | ~110s | ~125s | ~140s |

**Lưu ý:** Số liệu tính trên giả định 55% uptime tấn công. Cần playtest thực tế để hiệu chỉnh — người chơi giỏi có thể đạt 65-70% uptime, khi đó nên tăng nhẹ HP Boss lại.

## VI. CÁC ĐỀ XUẤT BỔ SUNG CHƯA TÍCH HỢP VÀO SỐ LIỆU (Cần playtest)

* **Flow Meter:** Cân nhắc cho Cross-Parry thành công giữ nguyên Flow dù bị "trúng đòn" (hiện tại bất kỳ đòn trúng nào cũng reset Flow về 0 — có thể gây ức chế quá mức).
* Bảng DPS/HP trên là điểm khởi đầu để cân bằng — không phải số liệu cuối cùng, cần vòng lặp playtest để tinh chỉnh thêm.

---

*File tổng hợp từ toàn bộ nội dung thảo luận thiết kế Project Dual Blade — Phần A (gốc), Phần B-D (bổ sung qua quá trình phát triển ý tưởng).*
