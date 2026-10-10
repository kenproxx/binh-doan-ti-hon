extends RefCounted
const Grid = preload("res://scripts/map_grid.gd")
var map = Grid.new()
var stage: Dictionary = {}
var units: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var resource: Array[float] = [0.0,0.0]
var base_hp: Array[float] = [1500.0,1500.0]
var base_max: Array[float] = [1500.0,1500.0]
var cooldowns: Array[Dictionary] = [{},{}]
var captures: Array[Dictionary] = []
var elapsed: float = 0
var skill_cooldown: float = 0
var finished: bool = false
var won: bool = false
var stars: int = 0
var statistics: Dictionary = {"deployed":0,"kills":0,"losses":0}
var tutorial_events: Dictionary = {"deploy":false,"command":false,"capture":false,"skill":false}
var token: String = ""
var mode: String = "attack"
var rally: Vector2 = Vector2.ZERO
var loadout: Array = []
var skill: String = "bomb"
var hold_time: float = 0
var capture_hold_time: float = 0
var levels: Dictionary = {}
var unit_defs: Dictionary = {}
var rng = RandomNumberGenerator.new()
var next_uid: int = 1
var ai_timer: float = 0
var base_attack_timers: Array[float] = [0.0,0.0]
func setup(config: Dictionary, selected: Array, upgrades: Dictionary, selected_skill: String, seed_value: int = 1) -> void:
	stage = config.duplicate(true)
	map.setup(stage)
	loadout = selected.duplicate()
	levels = upgrades.duplicate()
	skill = selected_skill
	rng.seed = seed_value
	var file = FileAccess.open("res://data/units.json",FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			unit_defs = parsed.get("units",parsed)
		elif parsed is Array:
			for item in parsed: unit_defs[item.id] = item
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var db = tree.root.get_node_or_null("GameDB")
		if db: unit_defs = db.units
	units.clear()
	effects.clear()
	captures.clear()
	for p in map.points: captures.append({"pos":p,"owner":-1,"progress":0.0,"claimant":-1})
	resource = [float(stage.get("start_resource",180)),float(stage.get("enemy_resource",180))]
	base_max = [float(stage.get("base_hp",1500)),float(stage.get("base_hp",1500))]
	base_hp = base_max.duplicate()
	cooldowns = [{},{}]
	elapsed = 0
	skill_cooldown = 0
	finished = false
	won = false
	stars = 0
	statistics = {"deployed":0,"kills":0,"losses":0}
	tutorial_events = {"deploy":false,"command":false,"capture":false,"skill":false}
	mode = "attack"
	rally = map.base_positions[0]
	hold_time = 0
	capture_hold_time = 0
	next_uid = 1
	ai_timer = 0.8
	base_attack_timers = [0.0,0.0]
	token = "%s-%s-%s" % [Time.get_unix_time_from_system(),Time.get_ticks_usec(),rng.randi()]
func _definition(id: String,team: int) -> Dictionary:
	var definition: Dictionary = unit_defs.get(id,{}).duplicate(true)
	if definition.is_empty(): return definition
	var level: int = clampi(int(levels.get(id,0)) if team == 0 else 0,0,5)
	for stat in ["hp","damage","heal"]: definition[stat] = roundf(float(definition.get(stat,0))*(1.0+0.12*level))
	return definition
func deployment_allowed(team: int,pos: Vector2) -> bool:
	if finished or team < 0 or team > 1 or not map.walkable(pos): return false
	var allowed: bool = pos.distance_to(map.base_positions[team]) <= 180.0 and ((pos.y >= map.height*map.tile/2.0) if team == 0 else (pos.y <= map.height*map.tile/2.0))
	for point in captures:
		if point.owner == team and pos.distance_to(point.pos) <= 100: allowed = true
	return allowed and not map.path(map.base_positions[team],pos).is_empty()
func can_deploy(team: int,id: String) -> bool:
	if finished or team < 0 or team > 1 or not unit_defs.has(id): return false
	var roster: Array = loadout if team == 0 else stage.get("enemy_roster",["blade"])
	if id not in roster: return false
	var definition: Dictionary = _definition(id,team)
	if resource[team] < float(definition.get("cost",40)) or float(cooldowns[team].get(id,0)) > 0: return false
	var count: int = 0
	var same: int = 0
	for unit in units:
		if unit.team == team:
			count += 1
			if unit.type == id: same += 1
	return count < 48 and same < int(definition.get("cap",12))
func deploy(team: int,id: String,pos: Vector2) -> bool:
	if not deployment_allowed(team,pos) or not can_deploy(team,id): return false
	var definition: Dictionary = _definition(id,team)
	resource[team] -= float(definition.get("cost",40))
	cooldowns[team][id] = float(definition.get("cooldown",2))
	units.append({"uid":next_uid,"team":team,"type":id,"pos":pos,"hp":float(definition.hp),"max_hp":float(definition.hp),"state":"move","flash":0.0,"attack_timer":0.0,"data":definition,"path":PackedVector2Array(),"path_timer":0.0,"goal":Vector2(-999,-999)})
	next_uid += 1
	if team == 0:
		statistics.deployed += 1
		tutorial_events.deploy = true
	return true
func command(order: String,pos: Vector2) -> bool:
	if finished or order not in ["attack","defend","rally"]: return false
	if order == "rally" and (not map.walkable(pos) or map.path(map.base_positions[0],pos).is_empty()): return false
	mode = order
	rally = pos if order == "rally" else map.base_positions[0]
	for unit in units:
		if unit.team == 0: unit.path_timer = 0.0
	tutorial_events.command = true
	return true
func cast(pos: Vector2) -> bool:
	if finished or skill_cooldown > 0 or not map.walkable(pos): return false
	skill_cooldown = 30
	for unit in units:
		if unit.pos.distance_to(pos) > 96: continue
		if skill == "heal" and unit.team == 0: unit.hp = minf(unit.max_hp,unit.hp+180)
		elif skill == "bomb" and unit.team == 1:
			unit.hp -= 160
			unit.flash = 0.2
	effects.append({"kind":skill,"pos":pos,"end":pos,"ttl":0.65,"radius":96.0,"team":0})
	tutorial_events.skill = true
	return true
func step(delta: float) -> void:
	if finished: return
	var remaining: float = maxf(delta,0)
	while remaining > 0 and not finished:
		var dt: float = minf(remaining,0.1)
		_tick(dt)
		remaining -= dt
func _tick(dt: float) -> void:
	elapsed += dt
	skill_cooldown = maxf(0,skill_cooldown-dt)
	for team in range(2):
		var bonus: float = 0
		for point in captures:
			if point.owner == team: bonus += 4
		resource[team] = minf(9999,resource[team]+(float(stage.get("income" if team == 0 else "enemy_income",8))+bonus)*dt)
		for id in cooldowns[team]: cooldowns[team][id] = maxf(0,float(cooldowns[team][id])-dt)
	ai_timer -= dt
	if ai_timer <= 0:
		_ai()
		ai_timer = maxf(0.5,float(stage.get("ai_interval",2)))
	for effect in effects: effect.ttl -= dt
	effects = effects.filter(func(effect): return effect.ttl > 0)
	_base_defense(dt)
	for unit in units:
		if unit.hp <= 0: continue
		unit.flash = maxf(0,unit.flash-dt)
		unit.attack_timer -= dt
		unit.path_timer -= dt
		_update_unit(unit,dt)
	var living: Array[Dictionary] = []
	for unit in units:
		if unit.hp > 0: living.append(unit)
		else:
			effects.append({"kind":"death","pos":unit.pos,"end":unit.pos,"ttl":0.4,"radius":12.0,"team":unit.team})
			if unit.team == 0: statistics.losses += 1
			else: statistics.kills += 1
	units = living
	_capture(dt)
	_resolve()
func _goal(unit: Dictionary) -> Vector2:
	if unit.team == 0:
		if mode == "defend": return map.base_positions[0]
		if mode == "rally": return rally
	if unit.team == 1 and int(stage.get("id",1)) >= 11:
		for opponent in units:
			if opponent.team == 0 and opponent.hp > 0 and opponent.pos.distance_to(map.base_positions[1]) < 210:
				return map.base_positions[1]
		for point in captures:
			if point.owner != 1: continue
			for opponent in units:
				if opponent.team == 0 and opponent.hp > 0 and opponent.pos.distance_to(point.pos) < 100:
					return point.pos
	# Capture and hold attackers secure points before assaulting the base.
	if stage.get("objective","destroy") in ["capture","hold"]:
		var best: Vector2 = map.base_positions[1-unit.team]
		var distance: float = INF
		for point in captures:
			if point.owner != unit.team and unit.pos.distance_to(point.pos) < distance:
				distance = unit.pos.distance_to(point.pos)
				best = point.pos
		if distance < INF: return best
		# Once secured, defend the nearest post instead of bypassing the objective.
		for point in captures:
			if unit.pos.distance_to(point.pos) < distance:
				distance = unit.pos.distance_to(point.pos)
				best = point.pos
		return best
	if stage.get("objective", "destroy") == "survive" and unit.team == 0:
		var closest: Vector2 = map.base_positions[0]
		var distance: float = INF
		for point in captures:
			if unit.pos.distance_to(point.pos) < distance:
				distance = unit.pos.distance_to(point.pos)
				closest = point.pos
		return closest
	return map.base_positions[1-unit.team]
func _update_unit(unit: Dictionary,dt: float) -> void:
	var data: Dictionary = unit.data
	var attack_range: float = float(data.get("range",32))
	var target: Dictionary = {}
	var best_score: float = INF
	var medic: bool = unit.type == "medic"
	for other in units:
		if other.hp <= 0 or other.uid == unit.uid: continue
		if medic:
			if other.team != unit.team or other.hp >= other.max_hp: continue
		elif other.team == unit.team: continue
		var distance: float = unit.pos.distance_to(other.pos)
		if distance > maxf(150,attack_range+24): continue
		if not _line_clear(unit.pos,other.pos): continue
		var score: float = distance
		if other.type in data.get("counters",[]): score -= 80
		if other.type in data.get("priority",[]): score -= 45
		if medic: score -= (1.0-other.hp/other.max_hp)*90
		if score < best_score:
			best_score = score
			target = other
	var goal: Vector2 = _goal(unit)
	if not target.is_empty():
		goal = target.pos
		if unit.pos.distance_to(goal) <= attack_range:
			unit.state = "heal" if medic else "attack"
			if unit.attack_timer <= 0:
				unit.attack_timer = maxf(0.2,float(data.get("interval",1)))
				if medic: target.hp = minf(target.max_hp,target.hp+float(data.get("heal",18)))
				else:
					var damage: float = float(data.get("damage",10))
					if target.type in data.get("counters",[]): damage *= 1.25
					target.hp -= damage
					target.flash = 0.14
					var splash: float = float(data.get("splash",0))
					if splash > 0:
						for other in units:
							if other.uid != target.uid and other.team != unit.team and other.pos.distance_to(target.pos) <= splash: other.hp -= damage*0.6
					effects.append({"kind":"heal" if medic else "hit","pos":unit.pos,"end":target.pos,"ttl":0.18,"radius":float(data.get("splash",4)),"team":unit.team})
			return
	elif not medic and (unit.team == 1 or mode == "attack") and (unit.team == 1 or stage.get("objective", "destroy") == "destroy") and unit.pos.distance_to(map.base_positions[1-unit.team]) <= attack_range+25:
		unit.state = "attack"
		if unit.attack_timer <= 0:
			unit.attack_timer = maxf(0.2,float(data.get("interval",1)))
			var multiplier: float = 3.0 if unit.type == "siege" else clampf(float(stage.get("base_damage_multiplier", 1.0)), 0.0, 1.0)
			base_hp[1-unit.team] -= float(data.get("damage",10))*multiplier
		return
	if unit.pos.distance_to(goal) <= 12:
		unit.state = "idle"
		return
	unit.state = "move"
	if unit.path_timer <= 0 or unit.goal.distance_to(goal) > 48:
		unit.path = map.path(unit.pos,goal)
		unit.goal = goal
		unit.path_timer = 1.5+rng.randf()*0.5
	var route: PackedVector2Array = unit.path
	var budget: float = float(data.get("speed",50))*float(stage.get("movement_scale",1.0))*dt
	while not route.is_empty() and budget > 0:
		var next: Vector2 = route[0]
		var distance: float = unit.pos.distance_to(next)
		if distance <= budget:
			unit.pos = next
			budget -= distance
			route.remove_at(0)
		else:
			unit.pos = unit.pos.move_toward(next,budget)
			budget = 0
	unit.path = route
	# A cheap, bounded nudge separates marching sprites without bypassing terrain.
	var push: Vector2 = Vector2.ZERO
	for other in units:
		if other.uid == unit.uid or other.hp <= 0: continue
		var offset: Vector2 = unit.pos-other.pos
		var distance: float = offset.length()
		if distance < 14:
			if distance < 0.01:
				offset = Vector2.LEFT if unit.uid < other.uid else Vector2.RIGHT
			else: offset /= distance
			push += offset*(14-distance)
	var shifted: Vector2 = unit.pos+push.limit_length(18)*dt*float(stage.get("movement_scale",1.0))
	if map.walkable(shifted) and _line_clear(unit.pos,shifted): unit.pos = shifted
func _line_clear(from: Vector2,to: Vector2) -> bool:
	var samples: int = maxi(1,ceili(from.distance_to(to)/12))
	for index in range(1,samples):
		if not map.walkable(from.lerp(to,float(index)/samples)): return false
	return true
func _capture(dt: float) -> void:
	for point in captures:
		var present: Array[bool] = [false,false]
		for unit in units:
			if unit.pos.distance_to(point.pos) <= 70: present[unit.team] = true
		if present[0] == present[1]: continue
		var claimant: int = 0 if present[0] else 1
		if point.owner == claimant:
			point.progress = 0.0
			point.claimant = claimant
			continue
		if point.claimant != claimant:
			point.progress = 0.0
			point.claimant = claimant
		point.progress += dt
		if point.progress >= 5:
			point.owner = claimant
			point.progress = 0.0
			if claimant == 0: tutorial_events.capture = true
	var owned: bool = true
	for point in captures:
		if point.owner != 0: owned = false
	if owned:
		hold_time += dt
		capture_hold_time += dt
	else:
		capture_hold_time = 0
func _base_defense(dt: float) -> void:
	var damage: float = float(stage.get("base_defense_damage",0))
	if damage <= 0: return
	for team in range(2):
		base_attack_timers[team] -= dt
		if base_attack_timers[team] > 0 or base_hp[team] <= 0: continue
		var target: Dictionary = {}
		var distance: float = float(stage.get("base_defense_range",165))
		for unit in units:
			if unit.team == team or unit.hp <= 0: continue
			var candidate: float = unit.pos.distance_to(map.base_positions[team])
			if candidate <= distance and _line_clear(map.base_positions[team],unit.pos):
				target = unit
				distance = candidate
		if target.is_empty(): continue
		base_attack_timers[team] = maxf(0.2,float(stage.get("base_defense_interval",1)))
		target.hp -= damage
		target.flash = 0.15
		effects.append({"kind":"hit","pos":map.base_positions[team],"end":target.pos,"ttl":0.2,"radius":4.0,"team":team})
func _ai() -> void:
	for purchase in range(3):
		if not _ai_purchase(): break
func _ai_purchase() -> bool:
	var roster: Array = stage.get("enemy_roster",["blade"])
	var choices: Array = roster.duplicate()
	# Rotate roster, then use counter roles when enemy pressure exists.
	for index in range(choices.size()-1,0,-1):
		var swap: int = rng.randi_range(0,index)
		var temporary = choices[index]
		choices[index] = choices[swap]
		choices[swap] = temporary
	var pressure: Dictionary = {}
	for unit in units:
		if unit.team == 0: pressure[unit.type] = int(pressure.get(unit.type,0))+1
	var best_id: String = ""
	var best_score: float = -INF
	for id in choices:
		if not can_deploy(1,str(id)): continue
		if str(id) == "medic":
			var supporters: int = 0
			var fighters: int = 0
			for ally in units:
				if ally.team != 1 or ally.hp <= 0: continue
				if ally.type == "medic": supporters += 1
				else: fighters += 1
			if supporters >= 2 or fighters < 3*(supporters+1): continue
		var data: Dictionary = _definition(str(id),1)
		var score: float = rng.randf()*3
		for counter in data.get("counters",[]): score += int(pressure.get(counter,0))*0.7
		if str(id) == "medic":
			for ally in units:
				if ally.team == 1 and ally.hp < ally.max_hp*0.6: score += 0.5
		if score > best_score:
			best_score = score
			best_id = str(id)
	if best_id.is_empty(): return false
	var origin: Vector2 = map.base_positions[1]
	for point in captures:
		if point.owner == 1 and rng.randf() < 0.6: origin = point.pos
	if int(stage.get("id",1)) >= 11:
		for opponent in units:
			if opponent.team == 0 and opponent.hp > 0 and opponent.pos.distance_to(map.base_positions[1]) < 220:
				origin = map.base_positions[1]
				break
	for attempt in range(8):
		var pos: Vector2 = origin+Vector2(rng.randf_range(-70,70),rng.randf_range(-55,55))
		if deploy(1,best_id,pos): return true
	return deploy(1,best_id,origin)
func _resolve() -> void:
	if base_hp[0] <= 0:
		_finish(false)
		return
	var objective: String = stage.get("objective","destroy")
	if base_hp[1] <= 0 and objective == "destroy":
		_finish(true)
		return
	var owned: bool = true
	for point in captures:
		if point.owner != 0: owned = false
	if objective == "capture" and owned and capture_hold_time >= float(stage.get("capture_hold_seconds", 0)):
		_finish(true)
	elif objective == "hold" and hold_time >= float(stage.get("hold_seconds",30)):
		_finish(true)
	elif elapsed >= float(stage.get("time_limit",240)):
		if objective == "survive": _finish(true)
		elif objective == "destroy": _finish(base_hp[0]/base_max[0] > base_hp[1]/base_max[1])
		else: _finish(false)
func _finish(victory: bool) -> void:
	if finished: return
	finished = true
	won = victory
	stars = 0
	if not won: return
	stars = 1
	if base_hp[0]/base_max[0] >= 0.6: stars += 1
	if (statistics.losses <= int(stage.get("star_losses",12))) if stage.get("objective","") == "survive" else (elapsed <= float(stage.get("star_time",180))): stars += 1
