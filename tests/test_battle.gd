extends SceneTree
const Sim = preload("res://scripts/battle_sim.gd")
const Grid = preload("res://scripts/map_grid.gd")
var failures: int = 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))
	for entry in records:
		var grid = Grid.new()
		grid.setup(entry)
		var route: PackedVector2Array = grid.path(grid.base_positions[0], grid.base_positions[1])
		check(not route.is_empty(), "Connected map %s" % entry.id)
		for p in route:
			check(grid.walkable(p), "Path stays on land")
		for p in grid.points:
			check(not grid.path(grid.base_positions[0], p).is_empty(), "Accessible capture point")
	var sim = Sim.new()
	sim.setup(records[0], ["blade","guard","medic","siege"], {}, "bomb", 42)
	check(not sim.deploy(0,"blade",Vector2(-20,0)), "Reject outside map")
	check(not sim.deploy(0,"blade",sim.map.base_positions[1]), "Reject enemy base")
	check(not sim.deploy(0,"unknown",sim.map.base_positions[0]), "Reject unknown unit")
	var money: float = sim.resource[0]
	check(sim.deploy(0,"blade",sim.map.base_positions[0]), "Valid deploy")
	check(sim.resource[0] < money, "Deployment costs money")
	check(not sim.deploy(0,"blade",sim.map.base_positions[0]), "Deployment cooldown")
	check(not sim.command("rally",Vector2(-10,-10)), "Rally rejects invalid ground")
	check(sim.command("defend",sim.map.base_positions[0]), "Defend accepted")
	check(sim.cast(sim.map.base_positions[0]), "Skill cast")
	check(not sim.cast(sim.map.base_positions[0]), "Skill cooldown")
	var ai_stage: Dictionary = records[0].duplicate(true)
	ai_stage.enemy_roster = ["blade","guard","archer","medic"]
	var ai = Sim.new()
	ai.setup(ai_stage,["blade"],{},"bomb")
	ai.resource[1] = 1000
	ai._ai()
	check(ai.units.size() == 3, "AI makes up to three legal purchases")
	var paid: float = 0
	for unit in ai.units:
		paid += float(ai.unit_defs[unit.type].cost)
		check(unit.type != "medic", "AI starts with damaging fighters")
	check(ai.resource[1] == 1000-paid, "AI purchases spend exact shared prices")
	var defense_stage: Dictionary = records[0].duplicate(true)
	defense_stage.base_defense_damage = 10
	var defense = Sim.new()
	defense.setup(defense_stage,["blade"],{},"bomb")
	defense.deploy(0,"blade",defense.map.base_positions[0])
	defense.deploy(1,"blade",defense.map.base_positions[1])
	defense.units[0].pos = defense.map.base_positions[1]+Vector2(0,100)
	defense.units[1].pos = defense.map.base_positions[0]-Vector2(0,100)
	defense._base_defense(0.1)
	check(defense.units[0].hp == defense.units[1].hp and defense.units[0].hp == defense.units[0].max_hp-10, "Both bases use identical defense damage")
	var poor = Sim.new()
	poor.setup(records[0],["blade"],{},"bomb")
	poor.resource[0] = 0
	check(not poor.deploy(0,"blade",poor.map.base_positions[0]), "Cannot deploy without resources")
	check(poor.units.is_empty() and poor.cooldowns[0].is_empty(), "Failed deploy is read-only")
	var water: Vector2 = Vector2(16,17*32+16)
	check(not poor.map.walkable(water), "River cell blocked")
	check(not poor.command("rally",water), "Water rally rejected")
	check(not poor.cast(water), "Water cast rejected")
	var capped = Sim.new()
	capped.setup(records[0],["blade","guard","archer","bomber","medic","siege"],{},"bomb")
	capped.resource[0] = 9999
	var unit_cap: int = int(capped.unit_defs.blade.cap)
	for i in range(unit_cap):
		capped.cooldowns[0].blade = 0.0
		check(capped.deploy(0,"blade",capped.map.base_positions[0]), "Deploy up to type cap")
	capped.cooldowns[0].blade = 0.0
	check(not capped.deploy(0,"blade",capped.map.base_positions[0]), "Type cap enforced")
	for id in capped.loadout:
		for i in range(int(capped.unit_defs[id].cap)):
			capped.cooldowns[0][id] = 0.0
			capped.deploy(0,id,capped.map.base_positions[0])
	check(capped.units.size() == 48, "Global team cap enforced")
	var upgraded = Sim.new()
	upgraded.setup(records[0],["blade"],{"blade":1},"bomb")
	upgraded.deploy(0,"blade",upgraded.map.base_positions[0])
	check(upgraded.units[0].max_hp == roundf(float(upgraded.unit_defs.blade.hp)*1.12), "Rounded upgrade matches GameDB")
	var symmetric = Sim.new()
	symmetric.setup(records[0], ["blade"], {}, "heal", 1)
	symmetric.resource[0] = 1000.0
	symmetric.resource[1] = 1000.0
	check(symmetric.deploy(0,"blade",symmetric.map.base_positions[0]), "Player deploy")
	check(symmetric.deploy(1,"blade",symmetric.map.base_positions[1]), "Enemy same deploy")
	check(is_equal_approx(symmetric.resource[0],symmetric.resource[1]), "Same unit price")
	check(not symmetric.deploy(1,"blade",symmetric.map.base_positions[1]), "Enemy cooldown")
	for objective in ["destroy","capture","hold","survive"]:
		var stage: Dictionary = records[0].duplicate(true)
		stage.objective = objective
		stage.time_limit = 0.1
		var end = Sim.new()
		end.setup(stage,["blade"],{},"bomb")
		if objective == "destroy": end.base_hp[1] -= 1
		if objective == "capture":
			end.captures[0].owner = 0
			end.captures[1].owner = 0
		if objective == "hold": end.hold_time = float(stage.hold_seconds)
		end.step(0.2)
		check(end.finished and end.won, "Winning objective " + objective)
		var elapsed: float = end.elapsed
		end.step(5)
		check(end.elapsed == elapsed, "Terminal state is idempotent")
	for objective in ["destroy","capture","hold"]:
		var losing_stage: Dictionary = records[0].duplicate(true)
		losing_stage.objective = objective
		losing_stage.time_limit = 0.1
		var losing = Sim.new()
		losing.setup(losing_stage,["blade"],{},"bomb")
		losing.step(0.2)
		check(losing.finished and not losing.won, "Unmet objective loses " + objective)
	var healing = Sim.new()
	healing.setup(records[0],["blade","medic"],{},"heal")
	healing.resource[0] = 1000
	healing.deploy(0,"blade",healing.map.base_positions[0])
	healing.deploy(0,"medic",healing.map.base_positions[0]+Vector2(20,0))
	healing.command("defend",healing.map.base_positions[0])
	healing.units[0].hp = 20
	healing.step(0.1)
	check(healing.units[0].hp > 20, "Medic heals injured ally")
	var before: float = healing.units[0].hp
	healing.cast(healing.map.base_positions[0])
	check(healing.units[0].hp > before, "Heal skill restores HP")
	var control = Sim.new()
	control.setup(records[0],["blade"],{},"bomb")
	control.resource[0] = 1000
	control.deploy(0,"blade",control.map.base_positions[0])
	control.units[0].pos = control.captures[0].pos
	control.command("rally",control.captures[0].pos)
	control.step(5.1)
	check(control.captures[0].owner == 0, "Five-second capture")
	check(control.deployment_allowed(0,control.captures[0].pos), "Deploy at owned point")
	check(not control.deployment_allowed(1,control.captures[0].pos), "Enemy cannot use player point")
	var contested = Sim.new()
	contested.setup(records[0],["blade"],{},"bomb")
	contested.deploy(0,"blade",contested.map.base_positions[0])
	contested.deploy(1,"blade",contested.map.base_positions[1])
	for unit in contested.units: unit.pos = contested.captures[0].pos
	contested.captures[0].progress = 2.0
	contested.captures[0].claimant = 0
	contested._capture(1.0)
	check(contested.captures[0].progress == 2.0 and contested.captures[0].owner == -1, "Contested capture pauses")
	var defeat = Sim.new()
	defeat.setup(records[0],["blade"],{},"bomb")
	defeat.base_hp[0] = 0.0
	defeat.step(0.1)
	check(defeat.finished and not defeat.won, "Player base destruction loses")
	var victory = Sim.new()
	victory.setup(records[0],["blade"],{},"bomb")
	victory.base_hp[1] = 0.0
	victory.step(0.1)
	check(victory.finished and victory.won, "Enemy base destruction wins")
	var both = Sim.new()
	both.setup(records[0],["blade"],{},"bomb")
	both.base_hp[0] = 0.0
	both.base_hp[1] = 0.0
	both.step(0.1)
	check(both.finished and not both.won, "Simultaneous base loss loses")
	var combat = Sim.new()
	combat.setup(records[0],["blade","guard","medic","siege"],{},"bomb",12)
	combat.resource[0] = 10000
	for i in range(2400):
		if i % 40 == 0:
			for id in combat.loadout: combat.deploy(0,id,combat.map.base_positions[0])
		combat.step(0.1)
		if combat.finished: break
	check(combat.finished, "Battle bounded by time")
	check(combat.statistics.deployed > 0, "Battle deploy statistics")
	print("Battle tests: %d failures" % failures)
	var audio = root.get_node("Audio")
	audio.music_player.stop()
	audio.music_player.stream = null
	for player in audio.players:
		player.stop()
		player.stream = null
	await create_timer(0.1).timeout
	quit(1 if failures else 0)

