extends Control

const Battlefield = preload("res://scripts/battlefield.gd")
const Minimap = preload("res://scripts/minimap.gd")
const Battle = preload("res://scripts/battle_sim.gd")
const BG: Color = Color("142a34")
const LIGHT: Color = Color("f4ecd0")
const TEAL: Color = Color("55d4cc")
const GOLD: Color = Color("ebc16d")
const UNIT_NAMES: Dictionary = {"blade":"Kiếm sĩ", "guard":"Vệ binh", "archer":"Cung thủ", "bomber":"Pháo thủ", "medic":"Quân y", "siege":"Công thành"}
var screen: String = "startup"
var body: VBoxContainer
var page: Control
var stage_id: int = 1
var selected: Array = ["blade", "archer"]
var skill: String = "bomb"
var sim
var field
var mini
var hud: Label
var hint: Label
var card_buttons: Dictionary = {}
var selected_card: String = ""
var target_action: String = ""
var paused: bool = false
var pause_overlay: Control
var settled_tokens: Dictionary = {}
var tutorial_label: Label
var battle_cards: HBoxContainer
var skill_button: Button
var health_bars: Array[ProgressBar] = []
var sound_timer: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	_clear("startup")
	_menu("Binh Đoàn Tí Hon", GameDB.text("loading"))
	var art: Banner = Banner.new()
	art.custom_minimum_size.y = 156
	body.add_child(art)
	call_deferred("show_main")

func _build_theme() -> void:
	var theme_value: Theme = Theme.new()
	theme_value.default_font_size = 18
	theme_value.set_color("font_color", "Label", LIGHT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("29444e") if state == "normal" else Color("386371")
		if state == "disabled":
			style.bg_color = Color("20343b")
		style.border_color = TEAL if state in ["focus", "pressed"] else Color("466169")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.content_margin_left = 12
		style.content_margin_right = 12
		theme_value.set_stylebox(state, "Button", style)
	theme_value.set_color("font_color", "Button", LIGHT)
	theme_value.set_color("font_disabled_color", "Button", Color("748d91"))
	theme = theme_value

func _clear(next: String) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	screen = next
	page = null
	pause_overlay = null
	var background: ColorRect = ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	Audio.menu_music() if next != "battle" else Audio.battle_music()

func _safe_margins() -> Vector4:
	var margins: Vector4 = Vector4(20, 18, 20, 18)
	if OS.get_name() == "Android":
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var display: Vector2i = DisplayServer.screen_get_size()
		if display.x > 0 and display.y > 0:
			var ratio: Vector2 = size / Vector2(display)
			margins.x = maxf(20, safe.position.x * ratio.x)
			margins.y = maxf(18, safe.position.y * ratio.y)
			margins.z = maxf(20, (display.x - safe.end.x) * ratio.x)
			margins.w = maxf(18, (display.y - safe.end.y) * ratio.y)
	return margins

func _menu(title: String, subtitle: String = "") -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe: Vector4 = _safe_margins()
	margin.add_theme_constant_override("margin_left", int(safe.x))
	margin.add_theme_constant_override("margin_top", int(safe.y))
	margin.add_theme_constant_override("margin_right", int(safe.z))
	margin.add_theme_constant_override("margin_bottom", int(safe.w))
	add_child(margin)
	page = margin
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	_label("BINH ĐOÀN / TÍ HON", 14, TEAL)
	_label(title, 31, LIGHT)
	if not subtitle.is_empty():
		_label(subtitle, 16, Color("a9c0be"))
	var line: HSeparator = HSeparator.new()
	body.add_child(line)

func _label(value: String, font_size: int = 18, color: Color = LIGHT, parent: Node = null) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(parent if parent != null else body).add_child(label)
	return label

func _button(value: String, callback: Callable, parent: Node = null, id: String = "") -> Button:
	var button: Button = Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not id.is_empty():
		button.name = id
	button.pressed.connect(func():
		Audio.cue("ui")
		callback.call()
	)
	(parent if parent != null else body).add_child(button)
	return button

func _row(parent: Node = null) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	(parent if parent != null else body).add_child(row)
	return row

func _coins() -> String:
	return "%d vàng" % int(Profile.data.get("coins", 0))

func show_main() -> void:
	sim = null
	paused = false
	_clear("main")
	_menu("Binh Đoàn Tí Hon", "30 trận chiến • 6 lớp quân • Chơi offline")
	body.add_theme_constant_override("separation", 7)
	var art: Banner = Banner.new()
	art.custom_minimum_size = Vector2(0, 156)
	body.add_child(art)
	_label("⚑  GIỮ VỮNG PHÒNG TUYẾN", 18, GOLD)
	_label("Qua sông, chiếm trạm tiếp tế, phá căn cứ. Dẫn đội quân nhỏ đến chiến thắng lớn.", 17)
	var total_stars: int = 0
	for value in Profile.data.get("stars", {}).values():
		total_stars += int(value)
	var nearest: int = 1
	for id in range(1, 31):
		if Profile.stage_unlocked(id):
			nearest = id
	_label("%s  •  %d / 90 ★" % [_coins(), total_stars], 22, GOLD)
	_button(GameDB.text("continue").to_upper() + " • ẢI %02d" % nearest, show_prepare.bind(nearest), null, "ContinueButton").disabled = not GameDB.error.is_empty()
	_button(GameDB.text("play").to_upper(), show_campaign, null, "CampaignButton").disabled = not GameDB.error.is_empty()
	_button(GameDB.text("army").to_upper() + " & " + GameDB.text("upgrade").to_upper(), show_army, null, "ArmyButton")
	_button(GameDB.text("settings").to_upper(), show_settings, null, "SettingsButton")
	_button(GameDB.text("guide").to_upper(), show_help, null, "HelpButton")
	if not Profile.notice.is_empty():
		_label(Profile.notice, 15, GOLD)
	if not GameDB.error.is_empty():
		_label(GameDB.error, 16, Color("f8a286"))
	if GameDB.units.is_empty() or GameDB.stages.size() != 30:
		_label("Dữ liệu trò chơi chưa đầy đủ. Hãy kiểm tra bộ cài.", 16, Color("f8a286"))
	_label("Mỹ thuật pixel & âm thanh tổng hợp nguyên bản.\nKhông cần tài khoản hay kết nối mạng.", 14, Color("a9c0be"))

func show_campaign() -> void:
	_clear("campaign")
	_menu("Chiến dịch", "Chọn ải • Sao mới mang thêm vàng")
	for chapter in range(3):
		_label(["01 / BỜ SÔNG XANH", "02 / HAI DÒNG NƯỚC", "03 / THÀNH TRÌ CUỐI"][chapter], 19, GOLD)
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		body.add_child(grid)
		for index in range(10):
			var id: int = chapter * 10 + index + 1
			var stars: int = int(Profile.data.get("stars", {}).get(str(id), 0))
			var unlocked: bool = Profile.stage_unlocked(id)
			var button: Button = _button("%02d  %s" % [id, "★".repeat(stars) + "☆".repeat(3 - stars) if unlocked else "KHÓA"], show_detail.bind(id), grid, "Stage%d" % id)
			button.disabled = not unlocked
	_button("← Về trang chính", show_main, null, "BackButton")

func _objective(stage: Dictionary) -> String:
	var objectives: Dictionary = {"destroy":"Phá căn cứ địch", "capture":"Chiếm cả hai trạm", "hold":"Giữ cả hai trạm", "survive":"Bảo vệ căn cứ đến hết giờ"}
	return str(objectives.get(str(stage.get("objective", "destroy")), "Phá căn cứ địch"))

func show_detail(id: int) -> void:
	stage_id = id
	_clear("detail")
	var stage: Dictionary = GameDB.stage(id)
	_menu("Ải %02d" % id, str(stage.get("name", "Chiến tuyến tí hon")))
	_label(_objective(stage), 26, GOLD)
	_label("Độ khó: " + str(stage.get("difficulty", "")), 18, TEAL)
	_label(_battle_rules(stage), 15, Color("a9c0be"))
	if str(stage.get("objective", "")) == "hold":
		_label("Tích lũy %ds giữ cả hai trạm cùng lúc trước khi hết giờ." % int(stage.get("hold_seconds", 45)), 18)
	elif str(stage.get("objective", "")) == "survive":
		_label("Căn cứ phải còn HP khi hết giờ. Phá căn cứ địch cũng thắng.", 18)
	elif str(stage.get("objective", "")) == "destroy":
		_label("Hết giờ so tỷ lệ HP căn cứ; hòa được tính là thua.", 18)
	else:
		_label("Cần giữ cả hai trạm cùng lúc trước khi hết giờ.", 18)
	_label("Giới hạn: %d giây\nTài nguyên: 180 • Thu nhập: 8/giây\nChiếm trạm: +4/giây • Mở vùng triển khai" % int(stage.get("duration", stage.get("time_limit", 240))))
	_label(str(stage.get("terrain_hint", "")) + "\n" + str(stage.get("suggestion", "")), 17, TEAL)
	_label("ĐIỀU KIỆN SAO", 16, TEAL)
	_label("★ Thắng trận\n★ Căn cứ còn ít nhất 60% HP\n★ " + ("Mất không quá 12 quân" if str(stage.get("objective", "destroy")) == "survive" else "Hoàn thành trong %d giây" % int(stage.get("star_time", 180))))
	_label("Thưởng đầu: %d vàng • Sao mới: 20 vàng/sao\nChơi lại: 15 vàng, tối đa 3 lần/ải" % (120 + 8 * id), 16, GOLD)
	_button("CHUẨN BỊ ĐỘI HÌNH", show_prepare.bind(id), null, "PrepareButton")
	_button("← Chiến dịch", show_campaign, null, "BackButton")

func show_prepare(id: int) -> void:
	stage_id = id
	selected = selected.filter(func(unit_id): return Profile.data.get("unlocked", []).has(unit_id))
	if selected.is_empty() and not Profile.data.get("unlocked", []).is_empty():
		selected.append(Profile.data.unlocked[0])
	_clear("prepare")
	_menu("Chuẩn bị / %02d" % id, "Chọn từ 1 đến 4 loại quân và 1 kỹ năng")
	var stage: Dictionary = GameDB.stage(id)
	_label(str(stage.get("terrain_hint", "")) + "\n" + str(stage.get("suggestion", "")), 16, GOLD)
	_label(_battle_rules(stage), 14, Color("a9c0be"))
	_label("ĐỘI HÌNH %d / 4" % selected.size(), 19, TEAL)
	for unit_id in GameDB.units:
		var unit: Dictionary = GameDB.unit(unit_id, int(Profile.data.get("upgrades", {}).get(unit_id, 0)))
		var unlocked: bool = Profile.data.get("unlocked", []).has(unit_id)
		var caption: String = "%s %s • %d vàng" % ["✓" if selected.has(unit_id) else "+", UNIT_NAMES.get(unit_id, unit_id), int(unit.get("cost", 0))]
		var button: Button = _button(caption if unlocked else "%s • CHƯA MỞ" % UNIT_NAMES.get(unit_id, unit_id), _toggle_unit.bind(unit_id), null, "Unit_" + unit_id)
		button.disabled = not unlocked
		_label(str(unit.get("role", "")) + " • " + str(unit.get("description", "")), 14, Color("a9c0be"))
	_label("KỸ NĂNG • BÁN KÍNH 96 • HỒI 30 GIÂY", 16, GOLD)
	_button(("✓ " if skill == "bomb" else "") + "Mưa bom • Gây sát thương diện rộng", _select_skill.bind("bomb"), null, "BombButton")
	_button(("✓ " if skill == "heal" else "") + "Hồi phục • Chữa quân đồng minh", _select_skill.bind("heal"), null, "HealButton")
	var safe: Vector4 = _safe_margins()
	page.add_theme_constant_override("margin_bottom", int(safe.w + 72))
	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "PrepareFooter"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = safe.x
	footer.offset_right = -safe.z
	footer.offset_top = -safe.w - 58
	footer.offset_bottom = -safe.w
	footer.add_theme_constant_override("separation", 8)
	add_child(footer)
	_button("← Chi tiết", show_detail.bind(id), footer, "BackButton")
	_button("VÀO TRẬN →", start_battle, footer, "StartButton").disabled = selected.is_empty() or not Profile.stage_unlocked(id) or not GameDB.error.is_empty()


func _battle_rules(stage: Dictionary) -> String:
	var pace: float = float(stage.get("movement_scale", 1.0))
	var damage: int = int(stage.get("base_defense_damage", 0))
	var text: String = "Cả hai phe: tốc độ di chuyển ×%.2f." % pace
	if damage > 0:
		text += "\nCả hai căn cứ có tháp: %d sát thương / %.1fs, tầm %d." % [damage, float(stage.get("base_defense_interval", 1.0)), int(stage.get("base_defense_range", 165))]
	else:
		text += " Căn cứ không có tháp phòng thủ."
	return text

func _toggle_unit(id: String) -> void:
	if selected.has(id):
		if selected.size() > 1:
			selected.erase(id)
	elif selected.size() < 4:
		selected.append(id)
	show_prepare(stage_id)

func _select_skill(id: String) -> void:
	skill = id
	show_prepare(stage_id)

func start_battle() -> void:
	if selected.is_empty() or not Profile.stage_unlocked(stage_id) or not GameDB.error.is_empty():
		return
	sim = Battle.new()
	sim.setup(GameDB.stage(stage_id), selected.duplicate(), Profile.data.get("upgrades", {}).duplicate(), skill, stage_id * 7919)
	paused = false
	selected_card = str(selected[0])
	target_action = "deploy"
	_clear("battle")
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe: Vector4 = _safe_margins()
	for side in ["left", "top", "right", "bottom"]:
		var amount: float = safe.x if side == "left" else (safe.y if side == "top" else (safe.z if side == "right" else safe.w))
		margin.add_theme_constant_override("margin_" + side, int(amount))
	add_child(margin)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	margin.add_child(layout)
	var top: HBoxContainer = _row(layout)
	hud = _label("", 16, LIGHT, top)
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pause_button: Button = _button("Ⅱ", _pause, top, "PauseButton")
	pause_button.custom_minimum_size = Vector2(48, 48)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	health_bars.clear()
	var health_row: HBoxContainer = _row(layout)
	for team in range(2):
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false
		bar.max_value = sim.base_max[team]
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = TEAL if team == 0 else Color("ed9873")
		bar.add_theme_stylebox_override("fill", fill)
		health_row.add_child(bar)
		health_bars.append(bar)
	var map_holder: Control = Control.new()
	map_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_holder.custom_minimum_size.y = 180
	layout.add_child(map_holder)
	field = Battlefield.new()
	field.name = "Battlefield"
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_holder.add_child(field)
	field.set_sim(sim)
	field.call_deferred("center_on", Vector2(384, 990))
	field.tapped.connect(_world_tapped)
	mini = Minimap.new()
	mini.name = "Minimap"
	mini.field = field
	mini.sim = sim
	mini.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini.position = Vector2(-72, 8)
	mini.size = Vector2(64, 96)
	map_holder.add_child(mini)
	tutorial_label = _label("", 16, GOLD, layout)
	hint = _label("Chọn quân rồi chạm vùng sáng để triển khai. Kéo bản đồ để quan sát.", 15, LIGHT, layout)
	battle_cards = _row(layout)
	card_buttons.clear()
	for id in selected:
		card_buttons[id] = _button("", _choose_card.bind(str(id)), battle_cards, "Deploy_" + str(id))
		card_buttons[id].add_theme_font_size_override("font_size", 14)
		card_buttons[id].clip_text = true
		card_buttons[id].custom_minimum_size = Vector2(72, 78)
	var commands: HBoxContainer = _row(layout)
	_button("Tiến công", _command.bind("attack"), commands, "AttackButton").add_theme_font_size_override("font_size", 15)
	_button("Phòng thủ", _command.bind("defend"), commands, "DefendButton").add_theme_font_size_override("font_size", 15)
	_button("Tập kết", _rally, commands, "RallyButton").add_theme_font_size_override("font_size", 15)
	skill_button = _button("Kỹ năng", _choose_skill, layout, "SkillButton")
	_update_hud()

func _choose_card(id: String) -> void:
	selected_card = id
	target_action = "deploy"
	field.preview_radius = 0
	hint.text = "Triển khai %s: chạm gần căn cứ hoặc trạm đã chiếm." % UNIT_NAMES.get(id, id)
	_update_hud()

func _command(mode: String) -> void:
	if sim.command(mode, sim.map.base_positions[0] if mode == "defend" else sim.map.base_positions[1]):
		hint.text = "Toàn quân: " + ("tiến công căn cứ địch!" if mode == "attack" else "bảo vệ căn cứ!")
		field.marker = sim.map.base_positions[0] if mode == "defend" else sim.map.base_positions[1]
		field.queue_redraw()
		Audio.cue("ui")
	_update_tutorial()

func _rally() -> void:
	target_action = "rally"
	field.preview_radius = 24
	hint.text = "Chạm đất trống để tập kết toàn quân."

func _choose_skill() -> void:
	if sim.skill_cooldown > 0:
		return
	target_action = "skill"
	field.preview_radius = 96
	hint.text = "Chạm mục tiêu: " + ("mưa bom trong bán kính 96." if skill == "bomb" else "hồi phục quân trong bán kính 96.")

func _world_tapped(pos: Vector2) -> void:
	if paused or sim.finished:
		return
	if not sim.map.walkable(pos):
		hint.text = "Không thể chọn nước hoặc chướng ngại. Hãy chạm vùng đất trống."
		return
	var accepted: bool = false
	var action: String = target_action
	match target_action:
		"deploy":
			accepted = sim.deploy(0, selected_card, pos)
			if not accepted:
				var unit: Dictionary = GameDB.unit(selected_card)
				if float(sim.resource[0]) < float(unit.get("cost", 0)):
					hint.text = "Chưa đủ vàng để triển khai loại quân này."
				elif not sim.deployment_allowed(0, pos):
					hint.text = "Ngoài vùng triển khai: cần gần căn cứ (180) hoặc trạm của ta (100), phía ta."
				else:
					hint.text = "Loại quân đang hồi triển khai hoặc đã đạt giới hạn."
		"rally":
			accepted = sim.command("rally", pos)
		"skill":
			accepted = sim.cast(pos)
			if accepted:
				target_action = "deploy"
				field.preview_radius = 0
	if accepted:
		Audio.cue("skill" if action == "skill" else ("deploy" if action == "deploy" else "ui"))
		hint.text = "Đã nhận lệnh • Kéo bản đồ / chạm bản đồ nhỏ để quan sát."
	_update_hud()

func _process(dt: float) -> void:
	if screen != "battle" or sim == null or paused:
		return
	sim.step(minf(dt, 0.1))
	sound_timer -= dt
	if sound_timer <= 0:
		for effect in sim.effects:
			if str(effect.get("kind", "")) in ["hit", "projectile", "death"]:
				Audio.cue("hit" if effect.kind in ["hit", "death"] else "attack")
				sound_timer = 0.18
				break
	field.queue_redraw()
	mini.queue_redraw()
	_update_hud()
	if sim.finished:
		show_result()

func _update_hud() -> void:
	if hud == null or sim == null:
		return
	var limit: int = int(sim.stage.get("duration", sim.stage.get("time_limit", 240)))
	var remain: int = maxi(0, limit - int(sim.elapsed))
	hud.text = "ẢI %02d   %02d:%02d   %d VÀNG\nTA %d / ĐỊCH %d   •   %s" % [stage_id, floori(remain / 60.0), remain % 60, int(sim.resource[0]), int(sim.base_hp[0]), int(sim.base_hp[1]), _objective(sim.stage)]
	var short_names: Dictionary = {"blade":"Kiếm", "guard":"Giáp", "archer":"Cung", "bomber":"Bom", "medic":"Quân y", "siege":"Pháo"}
	for team in range(health_bars.size()):
		health_bars[team].value = sim.base_hp[team]
	for id in card_buttons:
		var unit: Dictionary = GameDB.unit(id)
		var cooldown: float = float(sim.cooldowns[0].get(id, 0))
		card_buttons[id].text = "%s%s\n%d vàng\n%s" % ["✓ " if id == selected_card and target_action == "deploy" else "", short_names.get(id, id), int(unit.get("cost", 0)), "%.1fs" % cooldown if cooldown > 0 else "Sẵn"]
	skill_button.text = "%s  •  %s" % ["MƯA BOM" if skill == "bomb" else "HỒI PHỤC", "%ds" % ceili(sim.skill_cooldown) if sim.skill_cooldown > 0 else "CHỌN MỤC TIÊU"]
	skill_button.disabled = sim.skill_cooldown > 0
	if str(sim.stage.get("objective", "")) == "capture":
		var owned: int = 0
		for point in sim.captures:
			if int(point.owner) == 0:
				owned += 1
		hud.text += "\nTrạm của ta: %d / 2" % owned
	if str(sim.stage.get("objective", "")) == "hold":
		hud.text += "\nGiữ trạm: %d / %ds" % [int(sim.hold_time), int(sim.stage.get("hold_seconds", 45))]
	_update_tutorial()

func _update_tutorial() -> void:
	var keys: Dictionary = {1:"deploy", 2:"command", 3:"skill", 4:"capture"}
	var key: String = str(keys.get(stage_id, ""))
	if key.is_empty():
		tutorial_label.text = ""
		return
	if bool(sim.tutorial_events.get(key, false)):
		if not Profile.data.get("tutorial", []).has(key):
			Profile.mark_tutorial(key)
	if Profile.data.get("tutorial", []).has(key):
		tutorial_label.text = ""
	else:
		var texts: Dictionary = {"deploy":"HƯỚNG DẪN 1 / Chọn quân và triển khai gần căn cứ.", "command":"HƯỚNG DẪN 2 / Bấm Tiến công, Phòng thủ hoặc Tập kết.", "skill":"HƯỚNG DẪN 3 / Bấm kỹ năng rồi chạm mục tiêu.", "capture":"HƯỚNG DẪN 4 / Đưa quân đến trạm và giữ 5 giây."}
		tutorial_label.text = texts[key]

func _pause() -> void:
	if screen != "battle" or paused:
		return
	paused = true
	pause_overlay = PanelContainer.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.16, 0.96)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 130
	pause_overlay.add_theme_stylebox_override("panel", style)
	add_child(pause_overlay)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	pause_overlay.add_child(box)
	_label("TẠM DỪNG", 30, GOLD, box)
	_label("Trận chiến đang chờ lệnh của bạn.", 18, LIGHT, box)
	_button("TIẾP TỤC", _resume, box, "ResumeButton")
	_button("CHƠI LẠI", start_battle, box, "RestartButton")
	_button("CHIẾN DỊCH", show_campaign, box, "LeaveButton")
	_button("VỀ TRANG CHÍNH", show_main, box, "MainButton")

func _resume() -> void:
	paused = false
	if is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null

func show_result() -> void:
	var reward: int = 0
	if not settled_tokens.has(sim.token):
		reward = Profile.settle(stage_id, sim.won, sim.stars, sim.token)
		if Profile.data.get("transactions", []).has(sim.token):
			settled_tokens[sim.token] = reward
	else:
		reward = int(settled_tokens[sim.token])
	_clear("result")
	_menu("CHIẾN THẮNG" if sim.won else "CHƯA THÀNH CÔNG", "Ải %02d • %s" % [stage_id, _objective(sim.stage)])
	Audio.cue("victory" if sim.won else "defeat")
	_label("★".repeat(sim.stars) + "☆".repeat(3 - sim.stars), 48, GOLD)
	var durable: bool = Profile.data.get("transactions", []).has(sim.token)
	_label("+%d VÀNG" % reward if durable else "PHẦN THƯỞNG CHƯA ĐƯỢC LƯU", 30, TEAL if durable else GOLD)
	if not durable:
		_label("Không thể lưu kết quả. Kiểm tra quyền lưu hoặc dung lượng, rồi thử lại để nhận thưởng.", 17, GOLD)
		_button("THỬ LƯU KẾT QUẢ LẠI", show_result, null, "RetrySaveButton")
	_label("Thời gian: %ds\nCăn cứ còn: %d%%\nTriển khai: %s\nHạ gục: %s\nTổn thất: %s" % [int(sim.elapsed), int(sim.base_hp[0] / sim.base_max[0] * 100), str(sim.statistics.get("deployed", 0)), str(sim.statistics.get("kills", 0)), str(sim.statistics.get("losses", 0))], 21)
	if not durable and not Profile.notice.is_empty():
		_label(Profile.notice, 16, GOLD)
	if durable and sim.won and stage_id < 30 and Profile.stage_unlocked(stage_id + 1):
		_button("ẢI TIẾP THEO →", show_prepare.bind(stage_id + 1), null, "NextButton")
	_button("CHƠI LẠI", show_prepare.bind(stage_id), null, "RetryButton")
	_button("CHIẾN DỊCH", show_campaign, null, "CampaignButton")

func show_army() -> void:
	_clear("army")
	_menu("Đội quân", _coins() + " • Nâng cấp +12% mỗi cấp, tối đa 5")
	var roles: Dictionary = {"blade":"Cận chiến • Cơ động", "guard":"Chống chịu • Bảo vệ", "archer":"Tầm xa • Khắc chế cận chiến", "bomber":"Diện rộng • Phá đội hình", "medic":"Hồi phục • Hỗ trợ", "siege":"Công thành • Phá căn cứ"}
	for id in GameDB.units:
		var level: int = int(Profile.data.get("upgrades", {}).get(id, 0))
		var unit: Dictionary = GameDB.unit(id, level)
		_label("%s   %d / 5" % [UNIT_NAMES.get(id, id), level], 24, TEAL)
		var power_key: String = "heal" if id == "medic" else "damage"
		var next_unit: Dictionary = GameDB.unit(id, mini(level + 1, 5))
		var counter_names: Array[String] = []
		for counter in unit.get("counters", []):
			counter_names.append(str(UNIT_NAMES.get(counter, "Căn cứ")))
		_label("%s\nHP %d → %d • %s %s → %s\nTầm %d • Tốc độ %d • Giá %d\nKhắc chế: %s" % [roles.get(id, ""), int(unit.get("hp", 0)), int(next_unit.get("hp", 0)), "Hồi" if id == "medic" else "Đánh", str(unit.get(power_key, 0)), str(next_unit.get(power_key, 0)), int(unit.get("range", 0)), int(unit.get("speed", 0)), int(unit.get("cost", 0)), ", ".join(counter_names) if not counter_names.is_empty() else "Hỗ trợ đồng đội"], 16)
		_label(str(unit.get("description", "")), 15, Color("a9c0be"))
		var unlocked: bool = Profile.data.get("unlocked", []).has(id)
		var cost: int = Profile.upgrade_cost(id)
		var button: Button = _button("Nâng cấp • %d vàng" % cost if unlocked and level < 5 else ("ĐÃ TỐI ĐA" if unlocked else "Mở sau ải %d" % int({"archer":1,"guard":3,"medic":6,"bomber":10,"siege":15}.get(id, 1))), _upgrade.bind(id), null, "Upgrade_" + id)
		button.disabled = not unlocked or level >= 5 or int(Profile.data.get("coins", 0)) < cost
	if not Profile.notice.is_empty():
		_label(Profile.notice, 15, GOLD)
	_button("← Về trang chính", show_main, null, "BackButton")

func _upgrade(id: String) -> void:
	if Profile.upgrade(id):
		Audio.cue("upgrade")
	show_army()

func show_settings() -> void:
	_clear("settings")
	_menu("Cài đặt", "Tùy chỉnh âm thanh và hiệu năng")
	for item in [["music", "Nhạc nền"], ["sfx", "Hiệu ứng âm thanh"], ["vibration", "Rung"]]:
		var key: String = item[0]
		_button("%s: %s" % [item[1], "BẬT" if Profile.data.settings.get(key, true) else "TẮT"], _toggle_setting.bind(key), null, "Setting_" + key)
	_button("Chất lượng: %s" % str(Profile.data.settings.get("quality", "high")), _toggle_quality, null, "QualityButton")
	_label("Tiến trình được lưu trên thiết bị. Xóa tiến trình sẽ xóa vàng, sao và nâng cấp.", 16)
	_button("XÓA TIẾN TRÌNH…", _confirm_reset, null, "ResetButton")
	if not Profile.notice.is_empty():
		_label(Profile.notice, 16, GOLD)
	_button("← Về trang chính", show_main, null, "BackButton")

func _toggle_setting(key: String) -> void:
	var old = Profile.data.settings.get(key, true)
	Profile.data.settings[key] = not old
	if not Profile.save_profile():
		Profile.data.settings[key] = old
	Audio.apply_settings()
	show_settings()

func _toggle_quality() -> void:
	var old = Profile.data.settings.get("quality", "high")
	Profile.data.settings.quality = "low" if old == "high" else "high"
	if not Profile.save_profile():
		Profile.data.settings.quality = old
	Audio.apply_settings()
	show_settings()

func _confirm_reset() -> void:
	_clear("reset_confirm")
	_menu("Xóa tiến trình?", "Thao tác này không thể hoàn tác.")
	_label("Tất cả sao, vàng, đội hình và nâng cấp sẽ trở về ban đầu.", 22)
	_button("GIỮ TIẾN TRÌNH", show_settings, null, "CancelResetButton")
	_button("XÁC NHẬN XÓA", _reset, null, "ConfirmResetButton")

func _reset() -> void:
	Profile.reset_profile()
	selected = ["blade", "archer"]
	show_main()

func show_help() -> void:
	_clear("help")
	_menu("Sổ tay chỉ huy", "Luật dễ học. Chiến thuật do bạn chọn.")
	_label("1. Chọn 1–4 loại quân đã mở và một kỹ năng.\n\n2. Bấm thẻ quân rồi chạm gần căn cứ: bán kính 180. Trạm đã chiếm mở vùng triển khai bán kính 100. Chỉ triển khai trên đất trống phía ta.\n\n3. Quân tự tìm đường qua cầu, tìm và đánh mục tiêu. Kéo bản đồ để quan sát; chạm bản đồ nhỏ để chuyển góc nhìn.\n\n4. Tiến công, Phòng thủ và Tập kết đổi lệnh toàn quân. Tập kết cần chạm vị trí hợp lệ.\n\n5. Kỹ năng cần chọn tâm vùng ảnh hưởng. Hồi chiêu 30 giây, không tốn vàng.\n\n6. Trạm có quân một phe trong bán kính 70 sẽ bị chiếm sau 5 giây; tranh chấp dừng tiến độ.\n\n7. Đọc mục tiêu từng ải. Hết giờ, chế độ phá căn cứ so tỷ lệ HP; hòa được tính là thua.\n\n8. Thắng mở ải và quân mới. Dùng vàng nâng cấp đội hình.", 19)
	_button("← Về trang chính", show_main, null, "BackButton")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if screen == "battle":
			_pause()
		if is_node_ready():
			Profile.save_profile()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()

func _back() -> void:
	match screen:
		"battle":
			_pause()
		"detail", "prepare", "result":
			show_campaign()
		"reset_confirm":
			show_settings()
		"main":
			pass
		_:
			show_main()


class Banner extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("244854"))
		for x in range(0, int(size.x), 28):
			draw_rect(Rect2(Vector2(x, 110), Vector2(28, 46)), Color("526f46") if x % 56 == 0 else Color("5b7949"))
		draw_rect(Rect2(Vector2(0, 84), Vector2(size.x, 22)), Color("3d94a4"))
		for x in range(12, int(size.x), 64):
			draw_rect(Rect2(Vector2(x, 91), Vector2(27, 3)), Color("70bfc4"))
		draw_rect(Rect2(Vector2(size.x * .55, 80), Vector2(35, 33)), Color("a78658"))
		for y in range(83, 111, 7):
			draw_line(Vector2(size.x * .55, y), Vector2(size.x * .55 + 35, y), Color("685744"), 2)
		for x in [27, 59, 91]:
			draw_rect(Rect2(Vector2(x, 28), Vector2(28, 60)), Color("a4ac91"))
			draw_rect(Rect2(Vector2(x, 22), Vector2(10, 14)), Color("c6c7a5"))
			draw_rect(Rect2(Vector2(x + 18, 22), Vector2(10, 14)), Color("c6c7a5"))
			draw_rect(Rect2(Vector2(x + 8, 52), Vector2(11, 18)), Color("25414a"))
		draw_rect(Rect2(Vector2(77, 3), Vector2(3, 27)), Color("e3d6ab"))
		draw_rect(Rect2(Vector2(80, 4), Vector2(26, 13)), Color("5ee0d5"))
		for i in range(7):
			var p: Vector2 = Vector2(38 + i * 47, 133 - (i % 2) * 13)
			var color: Color = Color("74ddd0") if i < 4 else Color("f3a37a")
			draw_rect(Rect2(p + Vector2(-7, -8), Vector2(14, 15)), color)
			draw_rect(Rect2(p + Vector2(-6, -20), Vector2(12, 12)), Color("ebd8b2"))
			draw_rect(Rect2(p + Vector2(-8, -23), Vector2(16, 6)), Color("18313b"))
			draw_rect(Rect2(p + Vector2(-6, 7), Vector2(4, 8)), Color("18313b"))
			draw_rect(Rect2(p + Vector2(3, 7), Vector2(4, 8)), Color("18313b"))
			draw_line(p + Vector2(10, 3), p + Vector2(16, -19), Color("f6efd2"), 3)
		draw_rect(Rect2(Vector2(size.x - 65, 17), Vector2(18, 18)), Color("efce83"))
		draw_rect(Rect2(Vector2(170, 30), Vector2(45, 8)), Color("47707b"))
		draw_rect(Rect2(Vector2(185, 24), Vector2(21, 7)), Color("47707b"))
