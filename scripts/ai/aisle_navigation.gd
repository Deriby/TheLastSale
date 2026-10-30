class_name AisleNavigation
extends RefCounted
## Local A* at 25 cm resolution; furniture footprints inflated by actor radius.
## Shared path data avoids a navigation bake dependency on a particular editor.
var grid := AStarGrid2D.new()
var ground_height: Callable
var physical_blockers: Array[Rect2]=[]
const CELL := .25
func configure(blockers: Array[Rect2],ground: Callable=Callable()) -> void:
	ground_height=ground
	physical_blockers=blockers.duplicate()
	grid.region=Rect2i(-108,-92,216,164)
	grid.cell_size=Vector2(CELL,CELL)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(-108,108):
		for z in range(-92,72):
			var point:=Vector2(x*CELL,z*CELL)
			var blocked: bool=outside_bounds(point)
			for rect in blockers:
				if rect.grow(.33).has_point(point):blocked=true;break
			grid.set_point_solid(Vector2i(x,z),blocked)
func outside_bounds(point: Vector2) -> bool:
	return (point.y<-.15 and (absf(point.x)>5.65 or point.y< -15.6) and not ServiceYard.contains(point) and not SundayAccess.contains(point)) or point.y>16.2
func path(from: Vector3,to: Vector3) -> PackedVector3Array:
	var start:=Vector2i(roundi(from.x/CELL),roundi(from.z/CELL))
	var end:=Vector2i(roundi(to.x/CELL),roundi(to.z/CELL))
	var result:=PackedVector3Array()
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(end):return result
	start=open_start(from)
	for p in grid.get_point_path(start,end):result.append(Vector3(p.x,height_at(p.x,p.y),p.y))
	return result
func height_at(x: float,z: float) -> float:
	return float(ground_height.call(x,z)) if z>=0 and ground_height.is_valid() else 0.0
func open_start(at: Vector3) -> Vector2i:
	var origin:=Vector2i(roundi(at.x/CELL),roundi(at.z/CELL))
	if not grid.is_point_solid(origin):return origin
	var best:=origin;var distance:=INF
	for x in range(origin.x-4,origin.x+5):
		for z in range(origin.y-4,origin.y+5):
			var cell:=Vector2i(x,z)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):continue
			var candidate:=Vector2(x*CELL-at.x,z*CELL-at.z).length_squared()
			if candidate<distance:distance=candidate;best=cell
	return best
func path_around(from: Vector3,to: Vector3,people: Array[Vector3]) -> PackedVector3Array:
	var start:=Vector2i(roundi(from.x/CELL),roundi(from.z/CELL))
	var end:=Vector2i(roundi(to.x/CELL),roundi(to.z/CELL))
	var result:=PackedVector3Array()
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(end):return result
	var changed: Array[Vector2i]=[]
	# Path queries are synchronous: restore every temporary cell before another actor uses the grid.
	for person in people:
		var center:=Vector2i(roundi(person.x/CELL),roundi(person.z/CELL))
		for x in range(center.x-3,center.x+4):
			for z in range(center.y-3,center.y+4):
				var cell:=Vector2i(x,z)
				if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):continue
				if Vector2(x*CELL-person.x,z*CELL-person.z).length()<.65:
					grid.set_point_solid(cell,true);changed.append(cell)
	start=open_start(from)
	for point in grid.get_point_path(start,end):result.append(Vector3(point.x,height_at(point.x,point.y),point.y))
	for cell in changed:grid.set_point_solid(cell,false)
	return result
func restore_position(at: Vector3) -> Vector3:
	# Preserve valid narrow staff passages that the coarse customer path grid cannot represent.
	var cell:=Vector2i(roundi(at.x/CELL),roundi(at.z/CELL))
	var point:=Vector2(at.x,at.z)
	var blocked: bool=not grid.is_in_boundsv(cell) or outside_bounds(point)
	for rect in physical_blockers:
		if rect.grow(.27).has_point(point):blocked=true;break
	if not blocked:return Vector3(at.x,height_at(at.x,at.z)+.01,at.z) if at.z>=0 else at
	return nearest_walkable(at)

func nearest_walkable(at: Vector3) -> Vector3:
	# Geometry updates can put a checkpoint inside new furniture. Keep valid saves exact.
	var origin:=Vector2i(roundi(at.x/CELL),roundi(at.z/CELL))
	if grid.is_in_boundsv(origin) and not grid.is_point_solid(origin):return Vector3(at.x,height_at(at.x,at.z)+.01,at.z) if at.z>=0 else at
	var best:=Vector3(3.8,0,1.8)
	var best_distance:=INF
	for x in range(origin.x-12,origin.x+13):
		for z in range(origin.y-12,origin.y+13):
			var point:=Vector2i(x,z)
			if not grid.is_in_boundsv(point) or grid.is_point_solid(point):continue
			var candidate:=Vector3(x*CELL,height_at(x*CELL,z*CELL)+.01,z*CELL)
			var distance:=candidate.distance_squared_to(at)
			if distance<best_distance:best_distance=distance;best=candidate
	return best

func path_with_obstacles(from: Vector3,to: Vector3,obstacles: Array[Rect2]) -> PackedVector3Array:
	var changed: Array[Vector2i]=[]
	for rect in obstacles:
		var bounds:=rect.grow(.28)
		for x in range(floori(bounds.position.x/CELL),ceili(bounds.end.x/CELL)+1):
			for z in range(floori(bounds.position.y/CELL),ceili(bounds.end.y/CELL)+1):
				var point:=Vector2i(x,z)
				if grid.is_in_boundsv(point) and not grid.is_point_solid(point):grid.set_point_solid(point,true);changed.append(point)
	var result:=path(from,to)
	for point in changed:grid.set_point_solid(point,false)
	return result
