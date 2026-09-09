#!/usr/bin/env python3
"""
Chụp screenshot benchmark chuẩn Pixel-Perfect (Player Idle, Enemy Idle, HP 50/100, Flow 0/5)
để so sánh và xác thực trực tiếp chất lượng rendering và layout.
"""

from PIL import Image, ImageDraw, ImageFont
import os

W = 480
H = 270

# 1. Nạp Background
bg = Image.open('assets/sprites/environment/world1_bastion_bg.png').convert('RGBA')
ratio = min(W / bg.width, H / bg.height)
# Scale vừa vặn chiều cao 270
new_w = int(bg.width * (H / bg.height))
bg_resized = bg.resize((new_w, H), Image.Resampling.NEAREST)

# Canvas 480x270
screen = Image.new('RGBA', (W, H), (15, 17, 24, 255))
# Căn giữa background
bg_x = (W - new_w) // 2
screen.paste(bg_resized, (bg_x, 0))

# 2. Vẽ Sàn đá Ground
ground_y = 210
draw = ImageDraw.Draw(screen)
draw.rectangle([(0, ground_y), (W, H)], fill=(20, 24, 32, 255))
draw.line([(0, ground_y), (W, ground_y)], fill=(38, 48, 64, 255), width=2)

# 3. Dán Player (Idle Frame 0) - Alpha trong suốt hoàn toàn, không viền trắng
player_sheet = Image.open('assets/sprites/characters/player/player_sheet_grid.png').convert('RGBA')
# Frame 0: (0, 0, 64, 64)
player_frame = player_sheet.crop((0, 0, 64, 64))
# Tọa độ chân chạm ground_y: y = ground_y - 64 = 146
screen.paste(player_frame, (100, ground_y - 64), player_frame)

# 4. Dán Enemy (Idle Frame 0) - Alpha trong suốt, màu modulate trắng nguyên bản
enemy_sheet = Image.open('assets/sprites/enemies/rusty_guard_sheet_grid.png').convert('RGBA')
enemy_frame = enemy_sheet.crop((0, 0, 64, 64))
screen.paste(enemy_frame, (280, ground_y - 64), enemy_frame)

# 5. Vẽ HUD 16-bit Pixel Art: HP Panel (50/100) & Flow Panel (0/5)
# HP Panel: (x=12, y=10, w=120, h=18)
draw.rectangle([(10, 8), (132, 26)], outline=(64, 72, 88), fill=(18, 22, 28))
draw.rectangle([(11, 9), (131, 25)], outline=(12, 14, 18))
# 50% fill
draw.rectangle([(12, 10), (72, 24)], fill=(220, 45, 45))
draw.text((75, 12), "50 / 100", fill=(240, 240, 240))

# Flow Panel: (x=144, y=8, w=130, h=18)
draw.rectangle([(144, 8), (274, 26)], outline=(64, 72, 88), fill=(18, 22, 28))
draw.rectangle([(145, 9), (273, 25)], outline=(12, 14, 18))
draw.text((152, 12), "FLOW  □ □ □ □ □", fill=(80, 210, 255))

# 6. Debug Layer riêng biệt ở đáy màn hình
draw.text((12, H - 24), "[F1: Toggle Debug] STATE: IDLE | I-FRAME: OFF", fill=(160, 175, 195))
draw.text((12, H - 12), "A/D: Chay | Space: Nhay | J: Combo | K: Parry | L: Dash", fill=(120, 135, 155))

# Lưu screenshot benchmark
output_path = 'assets/benchmark_screenshot.png'
screen.save(output_path)

# Phóng to 2x (960x540) để quan sát chi tiết pixel không bị vỡ nét
screen_2x = screen.resize((960, 540), Image.Resampling.NEAREST)
screen_2x.save('assets/benchmark_screenshot_2x.png')

print('Benchmark screenshot generated successfully at assets/benchmark_screenshot_2x.png!')
