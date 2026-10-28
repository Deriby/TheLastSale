class_name BoxHandling
extends Node
var player
func setup(owner_player) -> void:player=owner_player
func sync_grip() -> void:
	if player.motion==null or player.motion.skeleton==null:return
	var sk: Skeleton3D=player.motion.skeleton
	var left: Vector3=sk.get_global_transform_interpolated()*sk.get_bone_global_pose(sk.find_bone("hand_L")).origin
	var right: Vector3=sk.get_global_transform_interpolated()*sk.get_bone_global_pose(sk.find_bone("hand_R")).origin
	var across: Vector3=(left-right).normalized()
	var forward:=across.cross(Vector3.UP).normalized()
	if forward.dot(player.visual.global_basis.z)<0:forward=-forward;across=-across
	var up:=forward.cross(across).normalized()
	player.socket.global_transform=Transform3D(Basis(across,up,forward),(left+right)*.5+forward*.09-Vector3.UP*.045)
func pickup(item: Node3D,id: String,instant := false) -> void:
	if player.carried!=null:return
	player.carried=item;Session.carried_id=id
	if instant:
		player.set_collision(item,false);sync_grip();item.reparent(player.socket);item.position=Vector3(0,-.23,0);item.rotation=Vector3.ZERO
		player.motion.play("carry",.1);return
	player.action_facing=item.global_position-player.global_position
	player.motion.action("pickup")
	await get_tree().create_timer(.55,false).timeout
	if not is_instance_valid(item) or player.carried!=item:return
	player.set_collision(item,false);sync_grip();item.reparent(player.socket)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(item,"position",Vector3(0,-.23,0),.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(item,"rotation",Vector3.ZERO,.48)
	player.made_noise.emit(player.global_position,4)
func place(at: Vector3,consume := false,on_placed: Callable = Callable()) -> void:
	if player.carried==null:return
	var item: Node3D=player.carried
	player.carried=null;Session.carried_id=""
	player.action_facing=at-player.global_position
	player.motion.action("place" if consume else "put_down")
	item.reparent(player.get_parent())
	var tween:=create_tween()
	tween.tween_interval(.18)
	tween.tween_property(item,"global_position",at,.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		if consume:item.queue_free()
		else:player.set_collision(item,true)
		if on_placed.is_valid():on_placed.call())
