class_name BoxHandling
extends Node
signal completed
signal feedback(text: String)
var player: DepotPlayer
var actor_motion: LivingMotion
var actor_visual: Node3D
var actor_socket: Node3D
var busy:=false
var operation:=""
var preview: Node3D
var preview_material: StandardMaterial3D
var preview_wait:=0.0
var can_place:=false
func setup(owner_actor: Node3D) -> void:
	# Animation review scenes also use the grip, without creating a playable body.
	player=owner_actor as DepotPlayer
	actor_motion=owner_actor.get("motion");actor_visual=owner_actor.get("visual");actor_socket=owner_actor.get("socket")
func sync_grip() -> void:
	if actor_motion==null or actor_motion.skeleton==null:return
	var sk: Skeleton3D=actor_motion.skeleton
	var left: Vector3=sk.get_global_transform_interpolated()*sk.get_bone_global_pose(sk.find_bone("hand_L")).origin
	var right: Vector3=sk.get_global_transform_interpolated()*sk.get_bone_global_pose(sk.find_bone("hand_R")).origin
	var across: Vector3=(left-right).normalized()
	var forward:=across.cross(Vector3.UP).normalized()
	if forward.dot(actor_visual.global_basis.z)<0:forward=-forward;across=-across
	var up:=forward.cross(across).normalized()
	actor_socket.global_transform=Transform3D(Basis(across,up,forward),(left+right)*.5+forward*.09-Vector3.UP*.045)
func sync_inventory() -> void:
	if player.controlled:Session.carried_id=player.carried_id
func pickup(item: Node3D,id: String,instant := false) -> void:
	if player.carried!=null or busy:return
	player.carried=item;player.carried_id=id;sync_inventory()
	if instant:
		player.set_collision(item,false);sync_grip();item.reparent(player.socket);item.position=Vector3(0,-.23,0);item.rotation=Vector3.ZERO
		player.motion.play("carry",.1);return
	busy=true;operation="pickup"
	player.action_facing=item.global_position-player.global_position
	player.motion.action("pickup")
	await get_tree().create_timer(.55,false).timeout
	if not is_instance_valid(item) or player.carried!=item:busy=false;operation="";return
	player.set_collision(item,false);sync_grip();item.reparent(player.socket)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(item,"position",Vector3(0,-.23,0),.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(item,"rotation",Vector3.ZERO,.48)
	player.made_noise.emit(player.global_position,4)
	await tween.finished
	busy=false;operation="";completed.emit()
func place(at: Vector3,consume := false,on_placed: Callable = Callable(),yaw := 0.0) -> void:
	if player.carried==null or busy:return
	var item: Node3D=player.carried
	busy=true;operation="place";hide_preview()
	player.carried=null;player.carried_id="";player.drop_pending=false;sync_inventory()
	player.action_facing=at-player.global_position
	player.motion.action("place" if consume else "put_down")
	item.reparent(player.get_parent())
	var tween:=create_tween()
	tween.tween_interval(.18)
	tween.tween_property(item,"global_position",at,.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(item,"global_rotation",Vector3(0,yaw,0),.65)
	await tween.finished
	if consume:item.queue_free()
	else:player.set_collision(item,true)
	if on_placed.is_valid():on_placed.call()
	busy=false;operation="";completed.emit()
func placement() -> Dictionary:
	var forward:=Basis(Vector3.UP,player.camera_rig.yaw)*Vector3.FORWARD
	var desired:=player.global_position+forward*.95
	var result:={"valid":false,"at":desired,"yaw":atan2(forward.x,forward.z)}
	var excluded: Array[RID]=[player.get_rid()]
	if player.carried!=null:
		for body in player.carried.find_children("*","CollisionObject3D",true,false):excluded.append(body.get_rid())
	var space:=player.get_world_3d().direct_space_state
	# A wall between the actor and the candidate must not be crossed by the box.
	var path:=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*.75,desired+Vector3.UP*.75,1,excluded)
	if not space.intersect_ray(path).is_empty():return result
	var ray:=PhysicsRayQueryParameters3D.create(desired+Vector3.UP*1.55,desired-Vector3.UP*1.5,1,excluded)
	var floor_hit:=space.intersect_ray(ray)
	if floor_hit.is_empty() or floor_hit.normal.y<.9:return result
	desired.y=floor_hit.position.y
	result.at=desired
	var basis:=Basis(Vector3.UP,float(result.yaw))
	# All four corners need support, so crates cannot balance on an edge or bridge a gap.
	for x in [-.30,.30]:
		for z in [-.20,.20]:
			var corner:=desired+basis*Vector3(x,0,z)
			var support:=space.intersect_ray(PhysicsRayQueryParameters3D.create(corner+Vector3.UP*.08,corner-Vector3.UP*.10,1,excluded))
			if support.is_empty() or support.normal.y<.9 or absf(support.position.y-desired.y)>.035:return result
	var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.69,.44,.48)
	query.shape=shape;query.transform=Transform3D(basis,desired+Vector3.UP*.26);query.collision_mask=1|2;query.exclude=excluded
	result.valid=space.intersect_shape(query,1).is_empty()
	return result
func update_preview(delta: float) -> void:
	if player.carried==null or busy or player.motion.action_active:hide_preview();return
	preview_wait-=delta
	if preview_wait>0:return
	preview_wait=.10
	if preview==null:
		preview=Node3D.new();preview.name="BoxPlacementPreview";player.add_child(preview);preview.top_level=true;preview.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		preview_material=StandardMaterial3D.new();preview_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;preview_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		for x in [-.35,.35]:Geo.box(preview,Vector3(x,.018,0),Vector3(.018,.012,.48),preview_material,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for z in [-.24,.24]:Geo.box(preview,Vector3(0,.018,z),Vector3(.70,.012,.018),preview_material,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var spot:=placement();can_place=spot.valid;preview.visible=true
	preview.global_position=spot.at;preview.global_rotation=Vector3(0,spot.yaw,0)
	preview_material.albedo_color=Color(.32,.85,.48,.8) if can_place else Color(.95,.28,.20,.8)
func hide_preview() -> void:
	if preview!=null:preview.hide()
