#!/usr/bin/env python3
"""
Kiểm thử tự động cho P2 (Damage Formula & TTK Simulation) theo Phần D Detail.md & plan.md.
Kiểm tra:
1. Mitigation% với DEF và K=50.
2. DPS thực tế theo bậc D -> SSR.
3. TTK (Time-To-Kill) dựa trên HP cũ vs HP đề xuất trong bảng IV.
"""

def calculate_mitigation(def_val, k=50.0):
    if def_val <= 0:
        return 0.0
    return def_val / (def_val + k)

def run_tests():
    print("=== P2: BẮT ĐẦU KIỂM THỬ CÔNG THỨC DAMAGE & SIMULATION TTK ===")
    
    # 1. Test Mitigation %
    boss_defs = { "Boss 1.10": 4, "Boss 2.10": 8, "Boss 3.10": 15, "Boss 4.10": 25 }
    expected_mit = { "Boss 1.10": 0.074, "Boss 2.10": 0.138, "Boss 3.10": 0.231, "Boss 4.10": 0.333 }
    
    print("\n--- 1. Kiểm tra Mitigation% (K=50) ---")
    for name, d in boss_defs.items():
        mit = calculate_mitigation(d, 50.0)
        exp = expected_mit[name]
        diff = abs(mit - exp)
        print(f"[{name}] DEF: {d} -> Mit: {mit*100:.1f}% (Kỳ vọng: {exp*100:.1f}%) -> {'PASS' if diff < 0.005 else 'FAIL'}")
    
    # 2. Test TTK theo bảng Phần D.IV với HP hiện tại (cũ)
    print("\n--- 2. Kiểm tra TTK với HP Hiện Tại (Cột 'HP hiện tại' trong Bảng D.IV) ---")
    old_hp_tests = [
        {"name": "Boss 1.10", "hp": 4200, "def": 4, "dps_avg": 74.0, "expected_ttk": 103.0},
        {"name": "Boss 2.10", "hp": 12500, "def": 8, "dps_avg": 129.0, "expected_ttk": 175.0},
        {"name": "Boss 3.10", "hp": 28000, "def": 15, "dps_avg": 217.0, "expected_ttk": 234.0},
        {"name": "Boss 4.10", "hp": 65000, "def": 25, "dps_avg": 370.0, "expected_ttk": 319.0}
    ]
    uptime = 0.55
    for b in old_hp_tests:
        mit = calculate_mitigation(b["def"], 50.0)
        eff_dps = b["dps_avg"] * (1.0 - mit) * uptime
        ttk = b["hp"] / eff_dps
        err = abs(ttk - b["expected_ttk"]) / b["expected_ttk"] * 100.0
        print(f"[{b['name']}] HP Cũ: {b['hp']} | TTK: {ttk:.1f}s | Bảng ghi: ~{b['expected_ttk']}s | Lệch: {err:.1f}% -> {'PASS' if err < 5.0 else 'FAIL'}")

    print("\n--- 3. TTK với HP Mới Đề Xuất (Bảng D.V) ---")
    new_hp_tests = [
        {"name": "Boss 1.10", "hp_new": 3800, "def": 4, "dps_avg": 74.0, "target": 90.0},
        {"name": "Boss 2.10", "hp_new": 7800, "def": 8, "dps_avg": 129.0, "target": 110.0},
        {"name": "Boss 3.10", "hp_new": 14900, "def": 15, "dps_avg": 217.0, "target": 125.0},
        {"name": "Boss 4.10", "hp_new": 28500, "def": 25, "dps_avg": 370.0, "target": 140.0}
    ]
    for b in new_hp_tests:
        mit = calculate_mitigation(b["def"], 50.0)
        eff_dps = b["dps_avg"] * (1.0 - mit) * uptime
        ttk = b["hp_new"] / eff_dps
        print(f"[{b['name']}] HP Mới: {b['hp_new']} | TTK mô phỏng (55% uptime): {ttk:.1f}s | Mục tiêu: ~{b['target']}s")

if __name__ == "__main__":
    run_tests()
