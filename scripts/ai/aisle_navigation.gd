class_name AisleNavigation
extends RefCounted
## Local A* at 25 cm resolution; furniture footprints inflated by actor radius.
## Shared path data avoids a navigation bake dependency on a particular editor.
var grid := AStarGrid2D.new()
const CELL := .25
func configure(blockers: Array[Rect2]) -> void:
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
	for p in grid.get_point_path(start,end):result.append(Vector3(p.x,0,p.y))
	return result
