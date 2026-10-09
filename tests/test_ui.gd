extends SceneTree
var failures: int = 0
var main
var profile
var original: Dictionary
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func click(id: String) -> void:
	var node = main.find_child(id, true, false)
	check(node is Button, "button exists: " + id)
	if node is Button:
		check(not node.disabled, "button enabled: " + id)
		node.pressed.emit()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	profile = root.get_node("Profile")
	original = profile.data.duplicate(true)
	profile.reset_profile()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	check(main.screen == "main", "startup enters main")
	click("CampaignButton")
	check(main.screen == "campaign", "main -> campaign")
	check(main.find_child("Stage30", true, false) is Button, "all 30 stages exist")
	check(main.find_child("Stage2", true, false).disabled, "future stage locked")
	click("Stage1")
	check(main.screen == "detail", "stage detail")
	click("PrepareButton")
	check(main.screen == "prepare" and main.selected == ["blade"], "loadout only unlocked")
	check(not main.body.is_ancestor_of(main.find_child("StartButton", true, false)), "start is outside scrolling loadout")
	click("HealButton")
	check(main.skill == "heal", "skill selection")
	click("BombButton")
	click("StartButton")
	await process_frame
	check(main.screen == "battle", "battle started")
	check(main.find_child("PauseButton", true, false).size_flags_horizontal == Control.SIZE_SHRINK_END, "pause does not consume expanded HUD width")
	check(main.sim.loadout == ["blade"], "simulation loadout")
	check(not profile.data.tutorial.has("deploy"), "tutorial never completed from showing battle")
	click("Deploy_blade")
	main._world_tapped(Vector2(384, 1040))
	check(main.sim.units.size() == 1, "actual deployment from UI")
	check(profile.data.tutorial.has("deploy"), "tutorial completes only from actual deployment")
	var count: int = main.sim.units.size()
	main._world_tapped(Vector2(384, 96))
	check(main.sim.units.size() == count, "invalid zone refuses deployment")
	check(not main.hint.text.is_empty(), "declined deployment hint")
	click("AttackButton")
	check(main.sim.mode == "attack", "attack button sends command")
	click("DefendButton")
	check(main.sim.mode == "defend", "defend button sends command")
	click("RallyButton")
	main._world_tapped(Vector2(384, 940))
	check(main.sim.mode == "rally", "rally next tap")
	click("SkillButton")
	main._world_tapped(Vector2(384, 940))
	check(main.sim.skill_cooldown > 0, "skill next tap casts")
	click("PauseButton")
	check(main.paused, "pause button")
	var elapsed: float = main.sim.elapsed
	main._process(1.0)
	check(main.sim.elapsed == elapsed, "pause stops time")
	click("ResumeButton")
	check(not main.paused, "resume button")
	main._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	check(main.paused, "app background pauses")
	main._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	check(main.paused, "foreground does not automatically resume")
	main._resume()
	var field = main.field
	field.center_on(Vector2(384, 800))
	var before: Vector2 = field.camera
	field._pointer(Vector2(100, 100), true)
	field._motion(Vector2(100, 160))
	field._pointer(Vector2(100, 160), false)
	check(field.camera != before, "drag pans")
	check(main.sim.units.size() == count, "drag does not deploy")
	field.center_on(Vector2(-100, -100))
	check(field.camera.x >= 0 and field.camera.y >= 0, "camera clamped")
	main.sim.finished = true
	main.sim.won = true
	main.sim.stars = 3
	var coins: int = profile.data.coins
	var storage_root: String = profile.storage_root
	profile.storage_root = "/proc/binh-ui-no-write/"
	main.show_result()
	check(profile.data.coins == coins, "failed result save leaves coins untouched")
	check(not main.settled_tokens.has(main.sim.token), "failed result save never caches token")
	check(not profile.data.transactions.has(main.sim.token), "failed result save leaves durable token absent")
	check(main.find_child("RetrySaveButton", true, false) is Button, "failed result offers retry save")
	check(main.find_child("NextButton", true, false) == null, "failed result cannot advance")
	profile.storage_root = storage_root
	click("RetrySaveButton")
	check(profile.data.transactions.has(main.sim.token), "retry save records durable token")
	check(profile.stage_unlocked(2), "retry save unlocks next stage")
	check(main.screen == "result", "result screen")
	check(profile.data.coins > coins, "result settles rewards")
	coins = profile.data.coins
	main.show_result()
	check(profile.data.coins == coins, "result cannot reward twice")
	click("NextButton")
	check(main.screen == "prepare" and main.stage_id == 2, "next-stage flow")
	profile.data.unlocked = ["blade", "guard", "archer", "bomber", "medic", "siege"]
	main.show_prepare(2)
	click("Unit_guard")
	click("Unit_archer")
	click("Unit_bomber")
	click("Unit_medic")
	check(main.selected.size() == 4, "maximum four units")
	click("StartButton")
	await process_frame
	await process_frame
	var cards_width: float = 0
	for card in main.card_buttons.values():
		cards_width += card.size.x
	check(cards_width + 24 <= main.battle_cards.size.x + 1, "four deployment cards fit container")
	var safe_right: float = main.get_global_rect().end.x - main._safe_margins().z
	for card in main.card_buttons.values():
		check(card.get_global_rect().end.x <= safe_right + 1, "card fits actual viewport safe edge: " + card.name)
	var pause_control = main.find_child("PauseButton", true, false)
	check(pause_control.get_global_rect().end.x <= safe_right + 1, "pause fits actual viewport safe edge")
	main.show_main()
	click("ArmyButton")
	check(main.screen == "army", "army screen")
	coins = profile.data.coins
	click("Upgrade_blade")
	check(profile.data.coins < coins and profile.data.upgrades.blade == 1, "upgrade button buys durable upgrade")
	click("BackButton")
	click("SettingsButton")
	var old: bool = profile.data.settings.music
	click("Setting_music")
	check(profile.data.settings.music != old, "settings toggle")
	click("ResetButton")
	check(main.screen == "reset_confirm", "reset requires review")
	click("CancelResetButton")
	check(main.screen == "settings", "reset cancellation")
	click("BackButton")
	click("HelpButton")
	check(main.screen == "help", "help screen")
	main.show_settings()
	click("ResetButton")
	click("ConfirmResetButton")
	check(main.screen == "main" and profile.data.stars.is_empty() and profile.data.coins == 200, "confirmed reset clears durable progression")
	main.show_detail(7)
	var hold_copy: String = ""
	for label in main.find_children("*", "Label", true, false):
		hold_copy += label.text + "\n"
	check(hold_copy.contains("giữ cả hai trạm"), "hold description matches both-point rule")
	profile.data = original
	profile.save_profile()
	main.free()
	var audio = root.get_node("Audio")
	audio.music_player.stop()
	audio.music_player.stream = null
	for player in audio.players:
		player.stop()
		player.stream = null
	await create_timer(0.1).timeout
	await process_frame
	print("UI CHECKS: ", "PASS" if failures == 0 else str(failures) + " FAILED")
	quit(failures)
