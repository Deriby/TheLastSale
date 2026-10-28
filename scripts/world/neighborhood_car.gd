class_name NeighborhoodCar
extends RefCounted
## Low-poly compact body with sloped panels and wheel-arch silhouettes.
static func face(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	var normal: Vector3=(b-a).cross(c-a).normalized()
	for point in [a,c,b,a,d,c]:st.set_normal(normal);st.add_vertex(point)
static func body(parent: Node3D,color: Color) -> Material:
	var paint:=StreetDetail.material(color).duplicate();paint.roughness=.57;paint.cull_mode=BaseMaterial3D.CULL_DISABLED
	var outline:=PackedVector2Array([
		Vector2(-1.86,.40),Vector2(-1.86,.73),Vector2(-1.43,.91),Vector2(-.92,.94),Vector2(.70,.92),Vector2(1.64,.79),Vector2(1.86,.64),Vector2(1.86,.40),
		Vector2(1.50,.40),Vector2(1.45,.59),Vector2(1.30,.71),Vector2(1.10,.72),Vector2(.89,.61),Vector2(.82,.40),
		Vector2(-.81,.40),Vector2(-.88,.60),Vector2(-1.05,.72),Vector2(-1.27,.71),Vector2(-1.44,.59),Vector2(-1.50,.40)])
	var indices:=Geometry2D.triangulate_polygon(outline)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		for index in indices:
			var p:=outline[index];st.set_normal(Vector3(0,0,side));st.add_vertex(Vector3(p.x,p.y,side*.78))
	var ridge: Array[Vector2]=[Vector2(-1.86,.73),Vector2(-1.43,.91),Vector2(-.92,.94),Vector2(.70,.92),Vector2(1.64,.79),Vector2(1.86,.64)]
	for i in ridge.size()-1:
		var a:=ridge[i];var b:=ridge[i+1]
		face(st,Vector3(a.x,a.y,-.78),Vector3(a.x,a.y,.78),Vector3(b.x,b.y,.78),Vector3(b.x,b.y,-.78))
	for x in [-1.86,1.86]:face(st,Vector3(x,.40,-.78),Vector3(x,.40,.78),Vector3(x,.73 if x<0 else .64,.78),Vector3(x,.73 if x<0 else .64,-.78))
	var node:=MeshInstance3D.new();node.name="ShapedBody";node.mesh=st.commit();node.material_override=paint;parent.add_child(node)
	return paint
