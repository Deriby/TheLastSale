class_name FaceAnchor
extends RefCounted
## The visible face can be offset from the imported head joint by its skin bind.
static var anchors: Dictionary={}
static func local_point(sk: Skeleton3D) -> Vector3:
	var root: Node=sk
	while root.get_parent()!=null and not root.has_meta("character_identity"):root=root.get_parent()
	var key:=str(root.get_meta("character_identity",sk.get_instance_id()))
	if anchors.has(key):return anchors[key]
	var head:=sk.find_bone("head");var rest:=sk.get_bone_global_rest(head)
	var low:=Vector3(INF,INF,INF);var high:=Vector3(-INF,-INF,-INF);var count:=0
	for node in root.find_children("*","MeshInstance3D",true,false):
		var mesh: MeshInstance3D=node
		if mesh.skin==null or mesh.mesh==null:continue
		var binds: Dictionary={}
		for bind in mesh.skin.get_bind_count():
			var bone:=mesh.skin.get_bind_bone(bind)
			if bone<0:bone=sk.find_bone(mesh.skin.get_bind_name(bind))
			if bone==head:binds[bind]=mesh.skin.get_bind_pose(bind)
		if binds.is_empty():continue
		for surface in mesh.mesh.get_surface_count():
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or bones.is_empty() or weights.is_empty():continue
			var width:=bones.size()/vertices.size()
			for vertex in vertices.size():
				for slot in width:
					var index:=vertex*width+slot;var bind:=bones[index]
					if weights[index]<.55 or not binds.has(bind):continue
					var relative: Vector3=rest.basis*(binds[bind]*vertices[vertex])
					low=low.min(relative);high=high.max(relative);count+=1;break
	var result:=rest.basis.inverse()*Vector3(0,.10,.10)
	if count>12:
		var front:=Vector3((low.x+high.x)*.5,lerpf(low.y,high.y,.35),lerpf(low.z,high.z,.85))
		result=rest.basis.inverse()*front
	anchors[key]=result
	return result
static func world_point(sk: Skeleton3D) -> Vector3:
	return sk.global_transform*sk.get_bone_global_pose(sk.find_bone("head"))*local_point(sk)
