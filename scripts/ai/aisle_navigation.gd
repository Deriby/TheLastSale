class_name AisleNavigation
extends RefCounted
## Local A* at 25 cm resolution; furniture footprints inflated by actor radius.
## Shared path data avoids a navigation bake dependency on a particular editor.
var grid := AStarGrid2D.new()
var ground_height: Callable
const CELL := .25
func configure(blockers: Array[Rect2],ground: Callable=Callable()) -> void:
	ground_height=ground
	grid.region=Rect2i(-108,-68,216,140)
	grid.cell_size=Vector2(CELL,CELL)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(-108,108):
		for z in range(-68,72):
			var point:=Vector2(x*CELL,z*CELL)
			var blocked: bool=(point.y < -.15 and (absf(point.x)>5.65 or point.y< -15.6)) or point.y>16.2
			for rect in blockers:
				if rect.grow(.33).has_point(point):blocked=true;break
			grid.set_point_solid(Vector2i(x,z),blocked)
func path(from: Vector3,to: Vector3) -> PackedVector3Array:
	var start:=Vector2i(roundi(from.x/CELL),roundi(from.z/CELL))
	var end:=Vector2i(roundi(to.x/CELL),roundi(to.z/CELL))
	var result:=PackedVector3Array()
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(end):return result
	for p in grid.get_point_path(start,end):result.append(Vector3(p.x,height_at(p.x,p.y),p.y))
	return result
func height_at(x: float,z: float) -> float:
	return float(ground_height.call(x,z)) if z>=0 and ground_height.is_valid() else 0.0

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
