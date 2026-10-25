extends Control
# Ascension: portable, single-scene Godot 4 prototype.
const SAVE := "user://ascension.json"
const NAMES := ["Frostveil", "Emberfang", "Jade Whisper", "Stormheart"]
var stones := 0.0
var qi := 0.0
var power := 1
var realm := 1
var stage := 1
var hp := 40.0
var max_hp := 40.0
var charge := 0.0
var spirits := [true, true, false, false]
var equipped := 0
var cooldowns := [0.0, 0.0, 0.0]
var attack_clock := 0.0
var save_clock := 0.0
var ui := {}
var root: VBoxContainer

func _ready() -> void:
	load_state()
	var bg := ColorRect.new()
	bg.color = Color("#17243b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	root = VBoxContainer.new()
	root.custom_minimum_size.x = 700
	root.add_theme_constant_override("separation", 14)
	scroll.add_child(root)
	add_label("✦ ASCENSION ✦", 44)
	ui["status"] = add_label("")
	ui["enemy"] = add_label("")
	add_label("☁ MISTY SWORD PEAK ☁", 28)
	add_label("⚔", 120)
	ui["message"] = add_label("Automatic attacks are active.")
	var row := HBoxContainer.new()
	root.add_child(row)
	for i in range(3):
		var index := i
		var b := make_button(["Slash", "Pierce", "Burst"][i], func(): use_skill(index))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		ui["skill" + str(i)] = b
	ui["ultimate"] = make_button("HEAVENLY SWORD RAIN", ultimate)
	root.add_child(ui["ultimate"])
	add_label("CULTIVATION", 32)
	ui["upgrade"] = make_button("Improve Sword Art", upgrade)
	root.add_child(ui["upgrade"])
	ui["break"] = make_button("Breakthrough", breakthrough)
	root.add_child(ui["break"])
	add_label("SWORD SPIRITS", 32)
	ui["spirit"] = add_label("")
	for i in range(4):
		var index := i
		root.add_child(make_button(NAMES[i], func(): select_spirit(index)))
	add_label("Prototype UI • Ascension v0.1", 18)
	refresh()

func add_label(value: String, size: int = 25) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	root.add_child(label)
	return label

func make_button(value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 75
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(callback)
	return b

func _process(delta: float) -> void:
	attack_clock += delta
	save_clock += delta
	for i in range(3):
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
	if attack_clock >= 1.0:
		attack_clock -= 1.0
		hit(float(power) * (1.0 + realm * 0.2) * spirit_multiplier())
		charge = minf(100.0, charge + 7.0)
	if save_clock >= 20.0:
		save_clock = 0.0
		save_state()
	refresh()

func spirit_multiplier() -> float:
	return [1.0, 1.15, 1.08, 1.25][equipped]

func hit(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		stones += 5.0 + float(stage) * 2.0
		qi += 3.0 + float(stage)
		stage += 1
		max_hp = 40.0 + float(stage) * 16.0
		hp = max_hp
		ui["message"].text = "Enemy defeated! Stage " + str(stage)

func use_skill(index: int) -> void:
	if cooldowns[index] > 0.0:
		return
	hit(float(power) * [3.0, 5.0, 8.0][index] * spirit_multiplier())
	cooldowns[index] = [4.0, 7.0, 12.0][index]
	charge = minf(100.0, charge + 12.0)
	refresh()

func ultimate() -> void:
	if charge < 100.0:
		return
	charge = 0.0
	hit(float(power) * 25.0 * spirit_multiplier())
	ui["message"].text = "Heavenly Sword Rain!"
	refresh()

func upgrade() -> void:
	var cost := float(power * 10)
	if stones < cost:
		return
	stones -= cost
	power += 1
	save_state()
	refresh()

func breakthrough() -> void:
	var cost := float(realm * 30)
	if qi < cost:
		return
	qi -= cost
	realm += 1
	ui["message"].text = "Breakthrough! Realm " + str(realm)
	save_state()
	refresh()

func select_spirit(index: int) -> void:
	if not spirits[index]:
		if stones < 100.0:
			ui["message"].text = "Need 100 Spirit Stones to unlock."
			return
		stones -= 100.0
		spirits[index] = true
	equipped = index
	save_state()
	refresh()

func refresh() -> void:
	if not ui.has("status"):
		return
	ui["status"].text = "Realm %d  |  Sword Art %d\nQi %.0f  |  Spirit Stones %.0f" % [realm, power, qi, stones]
	ui["enemy"].text = "Stage %d   Enemy HP %.0f / %.0f" % [stage, hp, max_hp]
	ui["ultimate"].text = "HEAVENLY SWORD RAIN  %.0f%%" % charge
	ui["ultimate"].disabled = charge < 100.0
	ui["upgrade"].text = "Improve Sword Art  •  %.0f Stones" % float(power * 10)
	ui["break"].text = "Breakthrough  •  %.0f Qi" % float(realm * 30)
	ui["spirit"].text = "Equipped: " + NAMES[equipped] + "\nUnlock other spirits for 100 Stones"
	for i in range(3):
		ui["skill" + str(i)].disabled = cooldowns[i] > 0.0

func save_state() -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"stones":stones,"qi":qi,"power":power,"realm":realm,"stage":stage,"spirits":spirits,"equipped":equipped,"saved_at":Time.get_unix_time_from_system()}))

func load_state() -> void:
	if not FileAccess.file_exists(SAVE):
		return
	var file := FileAccess.open(SAVE, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return
	stones = maxf(0.0, float(data.get("stones", 0.0)))
	qi = maxf(0.0, float(data.get("qi", 0.0)))
	power = maxi(1, int(data.get("power", 1)))
	realm = maxi(1, int(data.get("realm", 1)))
	stage = maxi(1, int(data.get("stage", 1)))
	max_hp = 40.0 + float(stage) * 16.0
	hp = max_hp
	var owned = data.get("spirits", [])
	if owned is Array and owned.size() == 4:
		for i in range(4):
			spirits[i] = bool(owned[i])
	equipped = clampi(int(data.get("equipped", 0)), 0, 3)
	if not spirits[equipped]:
		equipped = 0
	var elapsed := clampf(Time.get_unix_time_from_system() - float(data.get("saved_at", Time.get_unix_time_from_system())), 0.0, 28800.0)
	qi += floorf(elapsed / 60.0) * float(realm)
	stones += floorf(elapsed / 60.0) * float(power)
