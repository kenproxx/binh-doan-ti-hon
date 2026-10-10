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
 var db = root.get_node("GameDB")
 for objective in ["hold", "capture", "survive"]:
  var config: Dictionary = db.stage(5).duplicate(true)
  config.objective = objective
  var sim = Battle.new()
  sim.setup(config, ["blade"], {}, "bomb")
  sim.base_hp[1] = 0
  sim._resolve()
  check(not sim.finished, "Destroyed enemy base cannot bypass " + objective)
 var config: Dictionary = db.stage(9).duplicate(true)
 config.capture_hold_seconds = 120
 var sim = Battle.new()
 sim.setup(config, ["blade"], {}, "bomb")
 for point in sim.captures: point.owner = 0
 sim._capture(119)
 sim._resolve()
 check(not sim.finished, "Both posts must remain secured for the advertised duration")
 sim.captures[0].owner = 1
 sim._capture(1)
 sim.captures[0].owner = 0
 sim._capture(1)
 sim._resolve()
 check(not sim.finished, "Losing a post resets consecutive occupation")
 sim._capture(119)
 sim._resolve()
 check(sim.finished and sim.won, "Continuous occupation completes capture objective")
 var armored: Dictionary = db.stage(5).duplicate(true)
 armored.base_damage_multiplier = 0.35
 for id in ["blade", "siege"]:
  var attack = Battle.new()
  attack.setup(armored, [id], {}, "bomb")
  check(attack.deploy(0, id, attack.map.base_positions[0]), "Armor test uses legal purchase")
  var fighter: Dictionary = attack.units[0]
  fighter.pos = attack.map.base_positions[1] + Vector2(0, 20)
  var hp: float = attack.base_hp[1]
  attack._update_unit(fighter, 0.1)
  var expected: float = float(fighter.data.damage) * (3.0 if id == "siege" else 0.35)
  check(is_equal_approx(hp - attack.base_hp[1], expected), "Fortification reduces normal damage; siege bypasses it: " + id)
 for id in range(5,31):
  var stage: Dictionary = db.stage(id)
  check(stage.start_resource == stage.enemy_resource and stage.income == stage.enemy_income, "Symmetric economy %d" % id)
  check(stage.time_limit >= 180 and stage.time_limit <= 300, "Bounded match %d" % id)
 print("OBJECTIVE TESTS failures=", failures)
 var audio = root.get_node("Audio")
 audio.music_player.stop()
 audio.music_player.stream = null
 for player in audio.players:
  player.stop()
  player.stream = null
 await create_timer(0.1).timeout
 quit(1 if failures else 0)
