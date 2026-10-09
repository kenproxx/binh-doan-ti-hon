extends RefCounted
const width: int = 24
const height: int = 36
const tile: int = 32
var stage: Dictionary = {}
var cells: Dictionary = {}
var bridge_cells: Array[Vector2i] = []
var water_cells: Array[Vector2i] = []
var base_positions: Array[Vector2] = [Vector2(384,1056),Vector2(384,96)]
var points: Array[Vector2] = []
var graph: AStarGrid2D
func setup(config: Dictionary) -> void:
	stage = config.duplicate(true)
	cells.clear()
	bridge_cells.clear()
	water_cells.clear()
	var water: Dictionary = {}
	var rows: Array = [17]
	if int(stage.get("chapter",1)) == 2: rows = [14,21]
	if int(stage.get("chapter",1)) >= 3: rows = [11,17,24]
	for y in rows:
		for x in range(width):
			var c = Vector2i(x,int(y))
			cells[c] = true
			water[c] = true
	if int(stage.get("chapter",1)) >= 3:
		# Coastal water forms three islands, with irregular shores set by the map seed.
		var variation: int = int(stage.get("seed",1))+int(stage.get("map_variant",0))
		for y in range(height):
			var left: int = 2+(1 if y > 4 and y < 31 and (y/4+variation)%3 == 0 else 0)
			var right: int = 2+(1 if y > 4 and y < 31 and (y/5+variation)%3 == 1 else 0)
			for x in range(width):
				if x < left or x >= width-right:
					var c = Vector2i(x,y)
					cells[c] = true
					water[c] = true
	for x in stage.get("bridges",[5,18]):
		for y in rows:
			var c = Vector2i(int(x),int(y))
			cells.erase(c)
			bridge_cells.append(c)
	for obstacle in stage.get("obstacles",[]):
		var c = Vector2i(int(obstacle[0]),int(obstacle[1]))
		if c not in bridge_cells: cells[c] = true
	# Keep base entrances and bridge entrances traversable.
	for b in base_positions:
		for dx in range(-2,3):
			for dy in range(-2,3): cells.erase(cell(b) + Vector2i(dx,dy))
	for c in bridge_cells:
		cells.erase(c + Vector2i(0,-1))
		cells.erase(c + Vector2i(0,1))
	for c in water:
		if cells.has(c): water_cells.append(c)
	graph = AStarGrid2D.new()
	graph.region = Rect2i(0,0,width,height)
	graph.cell_size = Vector2(tile,tile)
	graph.offset = Vector2(tile/2.0,tile/2.0)
	graph.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	graph.update()
	for c in cells: graph.set_point_solid(c,true)
	points.clear()
	for proposed in [Vector2(192,480),Vector2(576,704)]:
		points.append(_nearest_reachable(proposed))
func cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x/tile),floori(pos.y/tile))
func blocked(c: Vector2i) -> bool:
	return c.x < 0 or c.y < 0 or c.x >= width or c.y >= height or cells.has(c)
func is_water(c: Vector2i) -> bool:
	return c in water_cells
func walkable(pos: Vector2) -> bool:
	return not blocked(cell(pos))
func path(from: Vector2,to: Vector2) -> PackedVector2Array:
	if not walkable(from) or not walkable(to): return PackedVector2Array()
	if cell(from) == cell(to): return PackedVector2Array([to])
	var route: PackedVector2Array = graph.get_point_path(cell(from),cell(to))
	if not route.is_empty(): route.append(to)
	return route
func _nearest_reachable(pos: Vector2) -> Vector2:
	var origin: Vector2i = cell(pos)
	for distance in range(height):
		for dy in range(-distance,distance+1):
			for dx in range(-distance,distance+1):
				if absi(dx)+absi(dy) != distance: continue
				var c: Vector2i = origin+Vector2i(dx,dy)
				if blocked(c): continue
				var candidate = Vector2(c)*tile+Vector2.ONE*tile/2.0
				if not path(base_positions[0],candidate).is_empty() and not path(base_positions[1],candidate).is_empty(): return candidate
	return base_positions[0]
