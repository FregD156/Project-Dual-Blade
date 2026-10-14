class_name SoundManager3D
extends Node

## SoundManager3D - Hệ thống âm thanh Procedural SFX Dark Fantasy 16-bit
## Tự động tổng hợp sóng âm chân thực (AudioStreamWAV) cho toàn bộ thao tác combat & môi trường.
## Không cần phụ thuộc file âm thanh ngoài, hoạt động 100% độc lập, không độ trễ.

static var _instance: Node = null

static func get_instance() -> Node:
	if _instance == null:
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			var script = load("res://src_3d/audio/SoundManager3D.gd")
			var sm = script.new()
			tree.root.add_child(sm)
			_instance = sm
	return _instance

var _sound_cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _player_index: int = 0
const POOL_SIZE: int = 12

func _init() -> void:
	if _instance == null:
		_instance = self

func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Khởi tạo pool AudioStreamPlayer để âm thanh không bị ngắt quãng khi phát nhiều hiệu ứng cùng lúc
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
		
	# Tiền tổng hợp toàn bộ âm thanh vào bộ nhớ đệm
	_generate_all_sfx()

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream or _players.is_empty():
		return
	var p = _players[_player_index]
	_player_index = (_player_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale + randf_range(-0.06, 0.06)
	p.play()

# ==============================================================================
# PUBLIC SFX PLAY METHODS
# ==============================================================================

func play_slash(combo_index: int = 1) -> void:
	var key = "slash_%d" % clampi(combo_index, 1, 4)
	if _sound_cache.has(key):
		_play_stream(_sound_cache[key], -2.0, 0.95 + (combo_index * 0.08))

func play_hit(is_crit: bool = false) -> void:
	var key = "hit_crit" if is_crit else "hit_normal"
	if _sound_cache.has(key):
		_play_stream(_sound_cache[key], 1.5 if is_crit else -1.0)

func play_parry() -> void:
	if _sound_cache.has("parry"):
		_play_stream(_sound_cache["parry"], 2.5)

func play_dash() -> void:
	if _sound_cache.has("dash"):
		_play_stream(_sound_cache["dash"], -4.0)

func play_jump() -> void:
	if _sound_cache.has("jump"):
		_play_stream(_sound_cache["jump"], -6.0)

func play_dive_land() -> void:
	if _sound_cache.has("dive_land"):
		_play_stream(_sound_cache["dive_land"], 1.0)

func play_flask() -> void:
	if _sound_cache.has("flask"):
		_play_stream(_sound_cache["flask"], -1.0)

func play_item_pickup() -> void:
	if _sound_cache.has("item_pickup"):
		_play_stream(_sound_cache["item_pickup"], -2.0)

func play_portal_warp() -> void:
	if _sound_cache.has("portal_warp"):
		_play_stream(_sound_cache["portal_warp"], 0.0)

func play_boss_roar() -> void:
	if _sound_cache.has("boss_roar"):
		_play_stream(_sound_cache["boss_roar"], 3.0)

func play_mercy_drop() -> void:
	if _sound_cache.has("mercy_drop"):
		_play_stream(_sound_cache["mercy_drop"], 0.5)

func play_victory_bell() -> void:
	if _sound_cache.has("victory_bell"):
		_play_stream(_sound_cache["victory_bell"], 1.0)

# ==============================================================================
# PROCEDURAL SOUND SYNTHESIS ENGINES
# ==============================================================================

func _generate_all_sfx() -> void:
	_sound_cache["slash_1"] = _synth_slash(0.12, 600.0, 180.0)
	_sound_cache["slash_2"] = _synth_slash(0.14, 750.0, 220.0)
	_sound_cache["slash_3"] = _synth_slash(0.16, 900.0, 250.0)
	_sound_cache["slash_4"] = _synth_slash(0.22, 1100.0, 140.0)
	
	_sound_cache["hit_normal"] = _synth_hit(false)
	_sound_cache["hit_crit"] = _synth_hit(true)
	_sound_cache["parry"] = _synth_parry()
	_sound_cache["dash"] = _synth_dash()
	_sound_cache["jump"] = _synth_jump()
	_sound_cache["dive_land"] = _synth_dive_land()
	_sound_cache["flask"] = _synth_flask()
	_sound_cache["item_pickup"] = _synth_item_pickup()
	_sound_cache["portal_warp"] = _synth_portal_warp()
	_sound_cache["boss_roar"] = _synth_boss_roar()
	_sound_cache["mercy_drop"] = _synth_mercy_drop()
	_sound_cache["victory_bell"] = _synth_victory_bell()

func _create_wav(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	data.resize(samples.size() * 2)
	
	for i in range(samples.size()):
		var val = clampf(samples[i], -1.0, 1.0)
		var int_val = int(val * 32767.0)
		data.encode_s16(i * 2, int_val)
		
	wav.data = data
	return wav

func _synth_slash(duration: float, start_freq: float, end_freq: float) -> AudioStreamWAV:
	var sr = 22050
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(start_freq, end_freq, t * t)
		var env = sin(t * PI)
		phase += (freq * TAU) / float(sr)
		var noise = randf_range(-1.0, 1.0)
		# Kết hợp tiếng rít không khí (noise) và tần số quét kiếm (sine)
		var s = (sin(phase) * 0.45 + noise * 0.55) * env
		samples[i] = s
		
	return _create_wav(samples, sr)

func _synth_hit(is_crit: bool) -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.22 if is_crit else 0.15
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var phase: float = 0.0
	var phase_metal: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = (1.0 - t) * (1.0 - t)
		var kick_freq = lerpf(140.0, 35.0, t)
		phase += (kick_freq * TAU) / float(sr)
		
		var s = sin(phase) * 0.6
		if is_crit:
			phase_metal += (620.0 * TAU) / float(sr)
			s += sin(phase_metal) * 0.3
			s += randf_range(-0.35, 0.35)
		else:
			s += randf_range(-0.25, 0.25)
			
		samples[i] = s * env
		
	return _create_wav(samples, sr)

func _synth_parry() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.42
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p1: float = 0.0
	var p2: float = 0.0
	var p3: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-t * 6.5)
		p1 += (1320.0 * TAU) / float(sr)
		p2 += (1850.0 * TAU) / float(sr)
		p3 += (2640.0 * TAU) / float(sr)
		
		var clang = (sin(p1) * 0.45 + sin(p2) * 0.35 + sin(p3) * 0.2)
		if i < 400: # Cú nảy kim loại đanh thép ở 0.02s đầu
			clang += randf_range(-0.5, 0.5) * (1.0 - (float(i)/400.0))
		samples[i] = clang * env
		
	return _create_wav(samples, sr)

func _synth_dash() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.18
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = sin(t * PI)
		var freq = lerpf(380.0, 110.0, t)
		phase += (freq * TAU) / float(sr)
		var s = (sin(phase) * 0.3 + randf_range(-0.7, 0.7)) * env
		samples[i] = s
		
	return _create_wav(samples, sr)

func _synth_jump() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.11
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = (1.0 - t)
		var freq = lerpf(240.0, 480.0, t)
		phase += (freq * TAU) / float(sr)
		samples[i] = sin(phase) * 0.5 * env
		
	return _create_wav(samples, sr)

func _synth_dive_land() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.38
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = (1.0 - t) * (1.0 - t)
		var freq = lerpf(110.0, 22.0, t)
		phase += (freq * TAU) / float(sr)
		var s = (sin(phase) * 0.7 + randf_range(-0.4, 0.4)) * env
		samples[i] = s
		
	return _create_wav(samples, sr)

func _synth_flask() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.32
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-t * 5.0)
		var f1 = 660.0 if t < 0.5 else 880.0
		var f2 = 990.0 if t < 0.5 else 1320.0
		p1 += (f1 * TAU) / float(sr)
		p2 += (f2 * TAU) / float(sr)
		samples[i] = (sin(p1) * 0.5 + sin(p2) * 0.35) * env
		
	return _create_wav(samples, sr)

func _synth_item_pickup() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.24
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-t * 7.0)
		var freq = lerpf(880.0, 1760.0, t)
		p += (freq * TAU) / float(sr)
		samples[i] = sin(p) * 0.65 * env
		
	return _create_wav(samples, sr)

func _synth_portal_warp() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.5
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = sin(t * PI)
		var mod = sin(t * 24.0) * 80.0
		var freq = 320.0 + mod
		p += (freq * TAU) / float(sr)
		samples[i] = sin(p) * 0.6 * env
		
	return _create_wav(samples, sr)

func _synth_boss_roar() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.75
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = sin(t * PI)
		var freq = lerpf(65.0, 42.0, t)
		p += (freq * TAU) / float(sr)
		var s = sin(p) + (sin(p * 2.0) * 0.4) + (sin(p * 3.0) * 0.25)
		s += randf_range(-0.25, 0.25)
		samples[i] = s * 0.5 * env
		
	return _create_wav(samples, sr)

func _synth_mercy_drop() -> AudioStreamWAV:
	var sr = 22050
	var duration = 0.35
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-t * 6.0)
		p1 += (523.25 * TAU) / float(sr) # C5
		p2 += (659.25 * TAU) / float(sr) # E5
		samples[i] = (sin(p1) * 0.55 + sin(p2) * 0.45) * env
		
	return _create_wav(samples, sr)

func _synth_victory_bell() -> AudioStreamWAV:
	var sr = 22050
	var duration = 1.2
	var total_samples = int(duration * sr)
	var samples = PackedFloat32Array()
	samples.resize(total_samples)
	
	var p1: float = 0.0
	var p2: float = 0.0
	var p3: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-t * 3.5)
		p1 += (220.0 * TAU) / float(sr) # A3
		p2 += (440.0 * TAU) / float(sr) # A4
		p3 += (660.0 * TAU) / float(sr) # E5
		samples[i] = (sin(p1) * 0.45 + sin(p2) * 0.35 + sin(p3) * 0.2) * env
		
	return _create_wav(samples, sr)
