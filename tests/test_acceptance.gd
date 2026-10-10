extends SceneTree
const Battle = preload("res://scripts/battle_sim.gd")
var failures: int = 0
func check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  printerr("FAIL: ", label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var p = root.get_node("Profile")
 var db = root.get_node("GameDB")
 p.storage_root = "user://acceptance_tests/"
 DirAccess.make_dir_recursive_absolute(p.storage_root)
 check(p.reset_profile(), "Acceptance profile saved")
 check(not p.upgrade("siege"), "Locked upgrades rejected")
 for stage_id in range(1,31):
  check(p.stage_unlocked(stage_id), "Stage %d reachable through previous wins" % stage_id)
  var roster: Array = []
  var roster_order: Array = ["blade","bomber","archer","medic"]
  if OS.get_cmdline_user_args().has("--siege") and p.data.unlocked.has("siege"):
   roster_order = ["siege", "blade", "archer", "medic"]
  for id in roster_order:
   if p.data.unlocked.has(id): roster.append(id)
  # Spend only earned gold, buying the cheapest next upgrade in the active squad.
  for purchase in range(20):
   var candidate: String = ""
   var cheapest: int = 100000
   for id in roster:
    var cost: int = p.upgrade_cost(id)
    if cost >= 0 and cost < cheapest:
     cheapest = cost
     candidate = id
   if candidate.is_empty() or cheapest > p.data.coins: break
   check(p.upgrade(candidate), "Earned-gold upgrade persisted")
  var sim = Battle.new()
  sim.setup(db.stage(stage_id), roster, p.data.upgrades, "bomb", stage_id*7919)
  var next_order: float = 0.0
  while not sim.finished:
   if sim.elapsed >= next_order:
    next_order += 0.5
    var spawn: Vector2 = sim.map.base_positions[0]+Vector2(0,-140)
    for point in sim.captures:
     if point.owner == 0 and point.pos.y < spawn.y: spawn = point.pos
    # Use a normal 4-card roster and the ordinary resource/cooldown/deployment APIs.
    for id in roster:
     if id == "medic":
      var count: int = 0
      for u in sim.units:
       if u.team == 0 and u.type == "medic": count += 1
      if count >= 2: continue
     sim.deploy(0,id,spawn)
    if sim.skill_cooldown <= 0:
     var target: Vector2 = Vector2(-1,-1)
     var best: int = 0
     for enemy in sim.units:
      if enemy.team != 1: continue
      var score: int = 0
      for other in sim.units:
       if other.team == 1 and other.pos.distance_to(enemy.pos) < 96: score += 1
      if score > best:
       best = score
       target = enemy.pos
     if best > 0: sim.cast(target)
   sim.step(0.1)
  print("ACCEPTANCE stage=",stage_id," won=",sim.won," elapsed=",snappedf(sim.elapsed,0.1)," stars=",sim.stars," roster=",roster," levels=",p.data.upgrades," base=",sim.base_hp)
  check(sim.won, "Stage %d winnable using reachable loadout and earned upgrades" % stage_id)
  if not sim.won: break
  var before: int = p.data.coins
  var reward: int = p.settle(stage_id,sim.won,sim.stars,sim.token)
  check(reward > 0 and p.data.coins == before+reward, "Actual battle reward durable")
  check(p.load_profile(), "Actual progress reload")
  check(p.settle(stage_id,true,sim.stars,sim.token) == 0 and p.data.coins == before+reward, "Reload cannot duplicate reward")
 await ui_checks()
 await recovery_checks()
 await failed_result_checks()
 var audio = root.get_node("Audio")
 audio.music_player.stop()
 audio.music_player.stream = null
 for player in audio.players:
  player.stop()
  player.stream = null
 await create_timer(0.1).timeout
 print("ACCEPTANCE TESTS failures=",failures)
 quit(1 if failures else 0)

func press(main: Node, id: String) -> void:
 var control: Button = main.find_child(id,true,false)
 check(control != null, "Real control exists: "+id)
 if control == null: return
 check(not control.disabled, "Real control enabled: "+id)
 control.pressed.emit()
func ui_checks() -> void:
 var p = root.get_node("Profile")
 var main = load("res://main.tscn").instantiate()
 root.add_child(main)
 root.content_scale_size = Vector2i(480,854)
 await process_frame
 check(main.screen == "main", "Initial real scene menu")
 main.show_prepare(30)
 press(main,"Unit_bomber")
 press(main,"Unit_medic")
 press(main,"Unit_guard")
 check(main.selected.size() == 4, "Actual preparation limits unlocked squad to four")
 check(p.reset_profile(), "UI starts from a fresh profile")
 main.show_main()
 press(main,"ArmyButton")
 check(main.screen == "army", "Army button connected")
 check(main.find_child("Upgrade_siege",true,false).disabled, "Locked upgrade disabled in real UI")
 press(main,"Upgrade_blade")
 check(int(p.data.upgrades.blade) == 1, "Upgrade button changes durable stats")
 main._back()
 press(main,"SettingsButton")
 var music: bool = p.data.settings.music
 press(main,"Setting_music")
 check(p.data.settings.music != music, "Music button works")
 press(main,"QualityButton")
 check(Engine.max_fps == 30, "Quality applies FPS immediately")
 press(main,"ResetButton")
 check(main.screen == "reset_confirm", "Reset opens confirmation")
 main._back()
 check(main.screen == "settings", "Back cancels reset")
 main._back()
 press(main,"HelpButton")
 check(main.screen == "help", "Help button works")
 main._back()
 press(main,"CampaignButton")
 check(main.find_child("Stage2",true,false).disabled, "Next stage disabled initially")
 press(main,"Stage1")
 press(main,"PrepareButton")
 check(main.selected == ["blade"], "Only unlocked initial roster retained")
 check(main.find_child("Unit_siege",true,false).disabled, "Locked roster control disabled")
 press(main,"StartButton")
 await process_frame
 check(main.screen == "battle", "Start control enters live battle")
 check(not p.data.tutorial.has("deploy"), "Tutorial remains until action")
 main.field.tapped.emit(main.sim.map.base_positions[0])
 check(main.sim.statistics.deployed == 1 and p.data.tutorial.has("deploy"), "Actual battlefield signal deploys and completes tutorial")
 press(main,"DefendButton")
 check(main.sim.mode == "defend", "Defense control works")
 press(main,"RallyButton")
 main.field.tapped.emit(main.sim.map.base_positions[0]+Vector2(0,-80))
 check(main.sim.mode == "rally", "Rally target selection works")
 press(main,"SkillButton")
 main.field.tapped.emit(main.sim.map.base_positions[0])
 check(main.sim.skill_cooldown > 0, "Skill control casts at selected target")
 main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
 check(main.paused, "Application background pauses battle")
 var elapsed: float = main.sim.elapsed
 main._process(2.0)
 check(main.sim.elapsed == elapsed, "Paused simulation stops")
 press(main,"ResumeButton")
 check(not main.paused, "Resume control works")
 main._back()
 check(main.paused, "Back pauses battle")
 press(main,"RestartButton")
 check(not main.paused and main.sim.elapsed == 0.0, "Restart starts a fresh battle")
 # Complete a real battle through the live scene, then exercise result controls.
 var next_order: float = 0.0
 while main.screen == "battle":
  if main.sim.elapsed >= next_order:
   next_order += 0.5
   main.field.tapped.emit(main.sim.map.base_positions[0]+Vector2(0,-140))
   if main.sim.skill_cooldown <= 0:
    for enemy in main.sim.units:
     if enemy.team == 1:
      press(main,"SkillButton")
      main.field.tapped.emit(enemy.pos)
      break
  main._process(0.1)
 check(main.screen == "result" and main.sim.won, "Actual scene battle reaches victory result")
 var result_coins: int = p.data.coins
 var result_token: String = main.sim.token
 main.show_result()
 check(p.data.coins == result_coins, "Repeated result UI cannot duplicate gold")
 check(p.load_profile() and p.data.transactions.has(result_token), "UI settlement saved token")
 press(main,"NextButton")
 check(main.screen == "prepare" and main.stage_id == 2, "Next result button prepares unlocked stage")
 press(main,"StartButton")
 press(main,"AttackButton")
 check(p.data.tutorial.has("command"), "Stage2 command tutorial completes only on command")
 for tutorial_stage in range(2,5):
  if tutorial_stage > 2:
   press(main,"NextButton")
   press(main,"StartButton")
  main._choose_card("blade")
  var order_at: float = 0.0
  while main.screen == "battle":
   if main.sim.elapsed >= order_at:
    order_at += 0.5
    var spawn: Vector2 = main.sim.map.base_positions[0]+Vector2(0,-140)
    for point in main.sim.captures:
     if point.owner == 0 and point.pos.y < spawn.y: spawn = point.pos
    main.field.tapped.emit(spawn)
    if main.sim.skill_cooldown <= 0:
     for enemy in main.sim.units:
      if enemy.team == 1:
       press(main,"SkillButton")
       main.field.tapped.emit(enemy.pos)
       break
   main._process(0.1)
  check(main.sim.won, "Real tutorial-stage battle won %d" % tutorial_stage)
 check(p.data.tutorial.has("skill"), "Stage3 skill tutorial records actual cast")
 check(p.data.tutorial.has("capture"), "Stage4 tutorial records actual reachable-point capture")
 press(main,"NextButton")
 press(main,"StartButton")
 press(main,"PauseButton")
 press(main,"LeaveButton")
 check(main.screen == "campaign", "Leave returns to campaign")
 main.queue_free()
 await process_frame
func recovery_checks() -> void:
 var p = root.get_node("Profile")
 check(p.reset_profile(), "Recovery reset")
 p.settle(1,true,3,"recovery-win")
 p.save_profile()
 var coins: int = p.data.coins
 var f = FileAccess.open(p.storage_root+"profile.json",FileAccess.WRITE)
 f.store_string("{corrupted")
 f.close()
 check(p.load_profile() and p.data.coins == coins, "Checksum corruption recovers valid backup")
 check(p.settle(1,true,3,"recovery-win") == 0, "Recovery retains durable reward token")
 var invalid: Dictionary = p.data.duplicate(true)
 invalid.version = 999
 var payload: String = JSON.stringify(invalid)
 f = FileAccess.open(p.storage_root+"profile.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}))
 f.close()
 check(p.load_profile() and p.data.coins == coins, "Future schema recovers backup")
 var previous: Dictionary = p.data.duplicate(true)
 var old_root: String = p.storage_root
 p.storage_root = "user://missing_acceptance_parent/absent/"
 check(not p.upgrade("blade") and p.data == previous, "Failed durable upgrade rolls back")
 check(p.settle(1,true,3,"must-not-persist") == 0 and p.data == previous, "Failed durable reward rolls back token and gold")
 p.storage_root = old_root
 check(not p.data.transactions.has("must-not-persist"), "Failed settlement can be retried")

func failed_result_checks() -> void:
 # Terminal-result fixture isolates a storage failure; campaign above proves genuine wins.
 var p = root.get_node("Profile")
 check(p.reset_profile(), "Failed-result test starts fresh")
 var main = load("res://main.tscn").instantiate()
 root.add_child(main)
 main.stage_id = 1
 main.sim = Battle.new()
 main.sim.setup(root.get_node("GameDB").stage(1),["blade"],{},"bomb",1)
 main.sim.finished = true
 main.sim.won = true
 main.sim.stars = 3
 var token: String = main.sim.token
 var valid_root: String = p.storage_root
 p.storage_root = "user://missing_result_parent/absent/"
 main.show_result()
 check(not p.data.transactions.has(token) and p.data.coins == 200, "Failed UI result rolls back progress")
 check(not main.settled_tokens.has(token), "Failed UI result must remain retryable")
 check(main.find_child("RetrySaveButton",true,false) != null, "Failed UI result exposes retry control")
 p.storage_root = valid_root
 press(main,"RetrySaveButton")
 check(p.data.transactions.has(token) and p.data.coins == 388, "Retry control persists correct reward exactly once")
 main.show_result()
 check(p.data.coins == 388, "Repeated repaired result remains idempotent")
 main.sim = null
 main.queue_free()
 await process_frame
