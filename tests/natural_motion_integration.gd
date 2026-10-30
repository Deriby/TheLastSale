extends Node
## Independent CPU skinning samples check exported library deformations and contact.
var failures: Array[String]=[]
var checks:=0
var report: Dictionary={}
func check(value: bool,message: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",message)
	if not value:failures.append(message)
func samples(visual: Node3D,sk: Skeleton3D) -> Dictionary:
	var result: Dictionary={"L":[],"R":[]}
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		if mesh.skin==null:continue
		var binds: Array[Transform3D]=[];var mapped: Array[int]=[]
		for i in mesh.skin.get_bind_count():
			mapped.append(sk.find_bone(mesh.skin.get_bind_name(i)));binds.append(mesh.skin.get_bind_pose(i))
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_BONES]==null:continue
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var count: int=bones.size()/vertices.size()
			for v in range(0,vertices.size(),2):
				var at: Vector3=sk.global_transform.affine_inverse()*mesh.global_transform*vertices[v]
				if at.y>.26:continue
				for side in ["L","R"]:
					var foot:=sk.find_bone("foot_"+side);var influence:=0.0
					for j in count:
						var bone: int=mapped[bones[v*count+j]]
						while bone>=0 and bone!=foot:bone=sk.get_bone_parent(bone)
						if bone==foot:influence+=weights[v*count+j]
					if influence<.7:continue
					var item: Dictionary={"at":vertices[v],"joints":[],"weights":[],"binds":[]}
					for j in count:
						var weight: float=weights[v*count+j]
						if weight>.001:
							var bind: int=bones[v*count+j];item.joints.append(mapped[bind]);item.weights.append(weight);item.binds.append(binds[bind])
					result[side].append(item)
	return result
func lowest(data: Array,sk: Skeleton3D) -> float:
	var minimum:=INF;var transforms: Dictionary={}
	for item in data:
		var at:=Vector3.ZERO
		for i in item.joints.size():
			var joint: int=item.joints[i]
			if not transforms.has(joint):transforms[joint]=sk.get_bone_global_pose(joint)
			at+=(transforms[joint]*item.binds[i]*item.at)*item.weights[i]
		minimum=minf(minimum,(sk.global_transform*at).y)
	return minimum
func _ready() -> void:call_deferred("run")
func run() -> void:
	for identity in ["Dery","Felps","Enemy","Bryan","Zirico","Garota1","Garota2","Velha1","Customer2"]:
		var actor:=Node3D.new();add_child(actor);var visual:=CharacterModels.create(identity);actor.add_child(visual)
		var motion:=LivingMotion.new();actor.add_child(motion);motion.setup(visual,actor);motion.feet.active=false;motion.detail.active=false;motion.attention.active=false
		var sk:=motion.skeleton;var sole:=samples(visual,sk)
		check(not sole.L.is_empty() and not sole.R.is_empty(),identity+" tem amostras reais da sola, com pesos do modelo")
		check(str(motion.clips.walk).begins_with("natural/"),identity+" usa caminhada medida para seu rig")
		var results:={}
		for clip in ["idle","walk","run","carry_walk","crouch_walk"]:
			if not motion.clips.has(clip):continue
			motion.play(clip,0);var penetration:=0.0;var floating:=0.0;var finite:=true
			for frame in 25:
				var t:=float(frame)/24;motion.animator.seek(t*motion.animator.current_animation_length,true);motion.animator.advance(0)
				for side in ["L","R"]:
					var floor:=lowest(sole[side],sk);penetration=maxf(penetration,-floor)
					var phase:=fposmod(t+(0 if side=="L" else .5),1)
					if clip=="idle" or phase<(.36 if clip=="run" else .61):floating=maxf(floating,floor)
				for bone in sk.get_bone_count():finite=finite and sk.get_bone_global_pose(bone).is_finite()
			results[clip]={"penetration_m":penetration,"support_gap_m":floating,"finite":finite}
			check(finite and penetration<.025 and floating<.025,identity+" • "+clip+" mantém solas no piso sem deformação inválida (pen=%.3f, gap=%.3f)"%[penetration,floating])
		if identity in ["Dery","Felps"]:
			motion.play("crouch_idle",0);motion.animator.seek(1,true);motion.animator.advance(0)
			var head:=sk.find_bone("head");var crown:=0.0
			for mesh in visual.find_children("*","MeshInstance3D",true,false):
				if not str(mesh.name).contains("Head"):continue
				for surface in mesh.mesh.get_surface_count():
					var vertices: PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
					for point in vertices:
						var at: Vector3=sk.global_transform.affine_inverse()*mesh.global_transform*point
						crown=maxf(crown,at.y-sk.get_bone_global_rest(head).origin.y)
			var height: float=(sk.global_transform*sk.get_bone_global_pose(head).origin).y+crown*sk.global_basis.get_scale().y
			check(height<1.38,identity+" • agachamento mantém cabeça próxima da cápsula baixa (%.3f m)"%height)
			results["crouch_height_m"]={"height_m":height}
		report[identity]=results;actor.free()
	var path:=OS.get_environment("MOTION_REPORT_PATH")
	if path.is_empty():path="user://natural_contact_report.json"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(report,"  "));file.close()
	print("NATURAL RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	Geo.materials.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if failures.is_empty() else 1)
