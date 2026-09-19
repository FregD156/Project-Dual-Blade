class_name FastTravelMapUI
extends Control

## Bảng Chọn Map & Dịch Chuyển Nhanh Pixel-Art (World Map & Checkpoint Navigation)
## - Giao diện chọn trực quan 4 World kèm hình ảnh Thumbnail mô phỏng của từng World
## - Hiển thị trạng thái: ĐÃ MỞ (UNLOCKED) / ĐANG KHÓA (LOCKED 🔒)
## - Khi chọn World đã mở, hiển thị các mốc Checkpoint (X.1, X.5, X.9, X.10)
## - Bấm chọn Checkpoint sẽ tức thì Fast Travel chuyển đến màn chơi tương ứng!

signal checkpoint_selected(world: int, stage: int)

@onready var world_cards_container: HBoxContainer = find_child("WorldCardsContainer", true, false)
@onready var checkpoint_panel: PanelContainer = find_child("CheckpointPanel", true, false)
@onready var checkpoint_buttons_container: HBoxContainer = find_child("CheckpointButtons", true, false)
@onready var selected_world_title: Label = find_child("SelectedWorldTitle", true, false)
@onready var close_btn: Button = find_child("CloseBtn", true, false)
@onready var unlock_all_btn: Button = find_child("UnlockAllBtn", true, false)
@onready var current_loc_label: Label = find_child("CurrentLocLabel", true, false)

const WORLD_THUMBNAILS = {
	1: preload("res://assets/sprites/ui/map_thumbs/thumb_world1.png"),
	2: preload("res://assets/sprites/ui/map_thumbs/thumb_world2.png"),
	3: preload("res://assets/sprites/ui/map_thumbs/thumb_world3.png"),
	4: preload("res://assets/sprites/ui/map_thumbs/thumb_world4.png")
}

const WORLD_INFO = {
	1: {
		"name": "CỔ THÀNH HOANG TÀN",
		"desc": "Thành lũy đá hoang tàn, rêu phong hoàng hôn u ám. Nơi vương quốc bắt đầu suy tàn.",
		"boss": "Thống Lĩnh Thiết Vệ (1.10)"
	},
	2: {
		"name": "HẦM NGỤC HUYẾT RỄ",
		"desc": "Cống ngầm rễ máu đỏ rực, bào tử nấm độc & vũng axit ăn mòn.",
		"boss": "Mẫu Thể Ký Sinh (2.10)"
	},
	3: {
		"name": "THÁP ĐỒNG HỒ CƠ GIỚI",
		"desc": "Bánh răng xoay khổng lồ, hơi nước áp suất cao & cưa máy tàn sát.",
		"boss": "Kẻ Hành Quyết Cơ Giới (3.10)"
	},
	4: {
		"name": "ĐỀN THỜ HƯ VÔ",
		"desc": "Tàn tích trôi nổi giữa không gian vũ trụ tím thẫm & vết rách hư không.",
		"boss": "Kẻ Thao Túng Hư Không (4.10)"
	}
}

var active_selected_world: int = 1

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_btn:
		close_btn.pressed.connect(close_map)
	if unlock_all_btn:
		unlock_all_btn.pressed.connect(func():
			CheckpointManager.get_instance().unlock_all_checkpoints()
			_render_world_cards()
			_render_checkpoints_for_world(active_selected_world)
		)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_map()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			close_map()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_U:
			CheckpointManager.get_instance().unlock_all_checkpoints()
			_render_world_cards()
			_render_checkpoints_for_world(active_selected_world)
			get_viewport().set_input_as_handled()

func toggle_map() -> void:
	if visible:
		close_map()
	else:
		open_map()

func open_map() -> void:
	visible = true
	modulate.a = 0.0
	
	var mgr = CheckpointManager.get_instance()
	active_selected_world = mgr.current_world
	
	_render_world_cards()
	_render_checkpoints_for_world(active_selected_world)
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func close_map() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): visible = false)

func _render_world_cards() -> void:
	if not world_cards_container:
		return
		
	for child in world_cards_container.get_children():
		child.queue_free()
		
	var mgr = CheckpointManager.get_instance()
	if current_loc_label:
		current_loc_label.text = "VỊ TRÍ HIỆN TẠI: WORLD %d - ẢI %d (%s)" % [
			mgr.current_world,
			mgr.current_checkpoint_stage,
			mgr.get_checkpoint_name(mgr.current_world, mgr.current_checkpoint_stage)
		]

	for w_idx in range(1, 5):
		var card = _create_world_card(w_idx)
		world_cards_container.add_child(card)

func _create_world_card(world_num: int) -> Control:
	var mgr = CheckpointManager.get_instance()
	
	# Kiểm tra World này đã có ít nhất 1 Checkpoint mở khóa chưa
	var is_unlocked = false
	for cp in mgr.unlocked_checkpoints:
		if cp["world"] == world_num:
			is_unlocked = true
			break
			
	# Thẻ World (Card)
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(98, 128)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card_panel.add_child(vbox)
	
	# Hình ảnh Thumbnail Map
	var thumb_rect = TextureRect.new()
	thumb_rect.custom_minimum_size = Vector2(94, 52)
	thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if WORLD_THUMBNAILS.has(world_num):
		thumb_rect.texture = WORLD_THUMBNAILS[world_num]
		
	if not is_unlocked:
		thumb_rect.modulate = Color(0.2, 0.2, 0.25, 0.8) # Tối màu nếu đang khóa
	elif world_num == mgr.current_world:
		thumb_rect.modulate = Color(1.1, 1.1, 1.1, 1.0)
	else:
		thumb_rect.modulate = Color(0.85, 0.85, 0.9, 1.0)
	vbox.add_child(thumb_rect)
	
	# Tên World
	var name_lbl = Label.new()
	name_lbl.text = "W%d: %s" % [world_num, WORLD_INFO[world_num]["name"]]
	name_lbl.add_theme_font_size_override("font_size", 6)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_unlocked:
		name_lbl.modulate = Color(0.2, 1.0, 0.6) if world_num == mgr.current_world else Color(1.0, 0.9, 0.4)
	else:
		name_lbl.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(name_lbl)
	
	# Nút bấm chọn World hoặc Báo khóa
	var select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(90, 18)
	select_btn.add_theme_font_size_override("font_size", 6)
	select_btn.focus_mode = Control.FOCUS_NONE
	select_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if not is_unlocked:
		if world_num == active_selected_world:
			select_btn.text = "🔒 ĐANG XEM (KHÓA)"
			select_btn.modulate = Color(0.8, 0.5, 0.5)
		else:
			select_btn.text = "🔒 XEM CHI TIẾT"
			select_btn.modulate = Color(0.65, 0.65, 0.7)
	else:
		if world_num == active_selected_world:
			select_btn.text = "▶ ĐANG XEM"
			select_btn.modulate = Color(0.3, 1.0, 0.6)
		else:
			select_btn.text = "XEM ẢI"
			select_btn.modulate = Color(0.9, 0.9, 0.9)
			
	select_btn.pressed.connect(func():
		active_selected_world = world_num
		_render_world_cards()
		_render_checkpoints_for_world(world_num)
	)
		
	vbox.add_child(select_btn)
	return card_panel

func _render_checkpoints_for_world(world_num: int) -> void:
	if not checkpoint_buttons_container:
		return
		
	for child in checkpoint_buttons_container.get_children():
		child.queue_free()
		
	var mgr = CheckpointManager.get_instance()
	if selected_world_title:
		selected_world_title.text = "CHỌN ĐIỂM DỊCH CHUYỂN — WORLD %d: %s" % [world_num, WORLD_INFO[world_num]["name"]]
		
	# Các mốc Checkpoint chuẩn của World: X.1, X.5, X.9, X.10
	var stages = [1, 5, 9, 10]
	for st in stages:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(85, 24)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 6)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var is_unlocked = mgr.is_checkpoint_unlocked(world_num, st)
		var is_current = (world_num == mgr.current_world and st == mgr.current_checkpoint_stage)
		var cp_name = mgr.get_checkpoint_name(world_num, st)
		
		if not is_unlocked:
			btn.text = "Ải %d.%d: 🔒 Khóa" % [world_num, st]
			btn.modulate = Color(0.5, 0.5, 0.55)
			btn.tooltip_text = "Chưa mở khóa! Vượt qua ải hoặc bấm 'MỞ HẾT MAP (TEST)'."
			btn.pressed.connect(func():
				print("[FAST TRAVEL MAP] Ải %d.%d đang bị khóa! Bấm nút 'MỞ HẾT MAP' để thử nghiệm tự do." % [world_num, st])
			)
		elif is_current:
			btn.text = "▶ Ải %d.%d: %s [HIỆN TẠI]" % [world_num, st, cp_name]
			btn.modulate = Color(1.0, 0.85, 0.2)
			btn.pressed.connect(func():
				_on_checkpoint_clicked(world_num, st)
			)
		else:
			btn.text = "✦ Ải %d.%d: %s" % [world_num, st, cp_name]
			btn.modulate = Color(0.2, 1.0, 0.6)
			btn.pressed.connect(func():
				_on_checkpoint_clicked(world_num, st)
			)
			
		checkpoint_buttons_container.add_child(btn)

func _on_checkpoint_clicked(world_num: int, stage_num: int) -> void:
	print("[FAST TRAVEL MAP] Chọn dịch chuyển đến World %d - Ải %d!" % [world_num, stage_num])
	checkpoint_selected.emit(world_num, stage_num)
	close_map()
