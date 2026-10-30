extends Node
const PoseAuthor=preload("res://tools/natural_pose.gd")
func _ready() -> void:call_deferred("bake")
func bake() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/motion")
	var report:={}
	for identity in ["Dery","Felps","Enemy","Bryan","Zirico","Garota1","Garota2","Velha1","Customer1","Customer2","Customer3"]:
		var visual:=CharacterModels.create(identity);add_child(visual)
		var skeleton: Skeleton3D=visual.find_child("Skeleton3D",true,false)
		var animator: AnimationPlayer=visual.find_child("AnimationPlayer",true,false)
		var author:=PoseAuthor.new();author.init(skeleton,visual,identity)
		var library:=AnimationLibrary.new();var strides:={}
		var root: Node=animator.get_node(animator.root_node);var path:=str(root.get_path_to(skeleton))
		for clip in PoseAuthor.LOOPS:
			# Missing NPC actions still use their existing authored actions.
			if not animator.has_animation(clip) and not (identity=="Enemy" and clip=="run"):continue
			var animation:=Animation.new();animation.length=PoseAuthor.LOOPS[clip]
			animation.loop_mode=Animation.LOOP_NONE if clip in ["idle_shift","idle_look","idle_adjust","browse","pay"] else Animation.LOOP_LINEAR
			var tracks: Array[Vector3i]=[]
			for bone in skeleton.get_bone_count():
				var position_track:=animation.add_track(Animation.TYPE_POSITION_3D);var rotation_track:=animation.add_track(Animation.TYPE_ROTATION_3D)
				var bone_path:=NodePath(path+":"+skeleton.get_bone_name(bone))
				animation.track_set_path(position_track,bone_path);animation.track_set_path(rotation_track,bone_path)
				var scale_track:=animation.add_track(Animation.TYPE_SCALE_3D);animation.track_set_path(scale_track,bone_path)
				tracks.append(Vector3i(position_track,rotation_track,scale_track))
			var frames:=roundi(animation.length*30)
			for frame in frames+1:
				var time:=float(frame)/frames;var poses:=author.sample(clip,time)
				for bone in skeleton.get_bone_count():
					animation.position_track_insert_key(tracks[bone].x,time*animation.length,poses[bone].origin)
					animation.rotation_track_insert_key(tracks[bone].y,time*animation.length,poses[bone].basis.orthonormalized().get_rotation_quaternion())
					animation.scale_track_insert_key(tracks[bone].z,time*animation.length,poses[bone].basis.get_scale())
			simplify(animation)
			library.add_animation(clip,animation)
			if PoseAuthor.GAITS.has(clip):strides[clip]=PoseAuthor.GAITS[clip]*author.stride_scale*author.actor_scale
		library.set_meta("strides",strides);library.set_meta("revision",22);library.set_meta("source_model_sha256",FileAccess.get_sha256(visual.scene_file_path));library.set_meta("authoring","rig measured stance/swing, offline 30 Hz")
		var error:=ResourceSaver.save(library,"res://resources/motion/"+identity+".res",ResourceSaver.FLAG_COMPRESS)
		assert(error==OK)
		report[identity]={"clips":library.get_animation_list().size(),"strides":strides,"bones":skeleton.get_bone_count(),"sole_samples":[author.soles.L.size(),author.soles.R.size()]}
		visual.free();print("MOTION_BAKED ",identity)
	var file:=FileAccess.open("res://resources/motion/authoring.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close();get_tree().quit()

func simplify(animation: Animation) -> void:
	for track in animation.get_track_count():
		var type:=animation.track_get_type(track)
		if type not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D] or animation.track_get_key_count(track)<3:continue
		var count:=animation.track_get_key_count(track);var values: Array=[];var times: Array[float]=[]
		for i in count:values.append(animation.track_get_key_value(track,i));times.append(animation.track_get_key_time(track,i))
		var tolerance:=.0012 if type==Animation.TYPE_ROTATION_3D else .0001 if type==Animation.TYPE_SCALE_3D else .0003
		var constant:=true
		for value in values:
			var error: float=values[0].distance_to(value) if type!=Animation.TYPE_ROTATION_3D else values[0].angle_to(value)
			if error>tolerance:constant=false;break
		var keep: Dictionary={0:true};var stack: Array[Vector2i]=[]
		if not constant:keep[count-1]=true;stack.append(Vector2i(0,count-1))
		while not stack.is_empty():
			var ends: Vector2i=stack.pop_back();var maximum:=tolerance;var split:=-1
			for i in range(ends.x+1,ends.y):
				var t: float=(times[i]-times[ends.x])/(times[ends.y]-times[ends.x])
				var predicted: Variant=values[ends.x].lerp(values[ends.y],t) if type!=Animation.TYPE_ROTATION_3D else values[ends.x].slerp(values[ends.y],t)
				var error: float=predicted.distance_to(values[i]) if type!=Animation.TYPE_ROTATION_3D else predicted.angle_to(values[i])
				if error>maximum:maximum=error;split=i
			if split>=0:keep[split]=true;stack.append(Vector2i(ends.x,split));stack.append(Vector2i(split,ends.y))
		for i in range(count-1,-1,-1):
			if not keep.has(i):animation.track_remove_key(track,i)
