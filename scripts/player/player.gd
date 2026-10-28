class_name DepotPlayer
extends CharacterBody3D
signal focused(text: String)
signal made_noise(position_value: Vector3, strength: float)
var visual: Node3D
var animator: AnimationPlayer
var camera_rig: ShoulderCamera
var socket: Node3D
var carried: Node3D
var target: Interaction
var crouching := false
var stamina := 1.0
var step_time := 0.0
var animation_lock := 0.0
var foot_audio: AudioStreamPlayer3D
var capsule: CapsuleShape3D
var torch: SpotLight3D
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1|2
	var col:=CollisionShape3D.new()
	capsule=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.74
	col.shape=capsule;col.position.y=.87
	add_child(col)
	visual=load("res://assets/models/characters/Dery.glb").instantiate()
	add_child(visual)
	visual.rotation.y=PI
	animator=visual.find_child("AnimationPlayer",true,false)
	prepare_animation(animator)
	camera_rig=ShoulderCamera.new();add_child(camera_rig)
	socket=Node3D.new();add_child(socket);socket.position=Vector3(0,.94,-.43)
	foot_audio=AudioStreamPlayer3D.new();add_child(foot_audio);foot_audio.stream=load("res://assets/audio/step.wav");foot_audio.volume_db=-11
	torch=SpotLight3D.new();camera_rig.camera.add_child(torch);torch.position=Vector3(.15,-.12,0);torch.spot_range=12;torch.spot_angle=29;torch.light_energy=2.2;torch.light_color=Color("ece7c2");torch.visible=false
	add_to_group("player")
func prepare_animation(ap: AnimationPlayer) -> void:
	if ap == null:return
	for name in ap.get_animation_list():
		if name.contains("idle") or name.contains("walk") or name.contains("run") or name.contains("carry") or name.contains("cashier") or name.contains("look"):
			ap.get_animation(name).loop_mode=Animation.LOOP_LINEAR
func play_clip(clip: String) -> void:
	if animator == null:return
	for key in animator.get_animation_list():
		if key == clip or key.ends_with("/"+clip):
			if animator.current_animation!=key:animator.play(key,.17)
			return
func _physics_process(delta: float) -> void:
	crouching=Input.is_action_pressed("crouch") and carried==null
	# Standing is blocked by overhead geometry; do not grow into a ceiling.
	if not crouching and capsule.height<1.7:
		var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.8,global_position+Vector3.UP*1.8,1,[get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():crouching=true
	capsule.height=1.12 if crouching else 1.74
	get_child(0).position.y=capsule.height*.5
	var input:=Input.get_vector("left","right","forward","backward")
	var direction:=Basis(Vector3.UP,camera_rig.yaw)*Vector3(input.x,0,input.y)
	var running:=Input.is_action_pressed("sprint") and not crouching and carried==null and stamina>.05 and input.length()>.1
	stamina=clampf(stamina+delta*(-.18 if running else .16),0,1)
	var speed:=4.0 if running else (1.3 if crouching else (1.7 if carried!=null else 2.0))
	velocity.x=move_toward(velocity.x,direction.x*speed,delta*13)
	velocity.z=move_toward(velocity.z,direction.z*speed,delta*13)
	if not is_on_floor():velocity.y-=18*delta
	else:velocity.y=0
	move_and_slide()
	if direction.length()>.05:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*15))
	elif camera_rig.first_person:visual.rotation.y=camera_rig.yaw+PI
	animation_lock=maxf(0,animation_lock-delta)
	if animation_lock<=0:
		if carried!=null:play_clip("carry_walk" if direction.length()>.1 else "carry")
		elif direction.length()>.1:play_clip("crouch_walk" if crouching else ("run" if running else "walk"))
		else:play_clip("crouch_idle" if crouching else "idle")
	if animator!=null and not animator.current_animation.is_empty():
		var clip:=animator.current_animation
		var stride:=1.9 if running else (.65 if crouching else 1.15)
		animator.speed_scale=maxf(.55,Vector2(velocity.x,velocity.z).length()*animator.get_animation(clip).length/stride) if direction.length()>.1 and animation_lock<=0 else 1.0
	if direction.length()>.1 and is_on_floor():
		step_time+=delta
		if step_time>(.32 if running else .52):
			step_time=0;foot_audio.volume_db=linear_to_db(maxf(Preferences.effects_volume,.001))-11;foot_audio.play()
			made_noise.emit(global_position,8.0 if running else 3.0)
	socket.rotation.y=visual.rotation.y
	socket.position=Vector3(sin(visual.rotation.y)*.43,.94,cos(visual.rotation.y)*.43)
	update_focus()
func update_focus() -> void:
	target=null
	var cam:=camera_rig.camera
	var start:=cam.global_position
	var end:=start-cam.global_basis.z*5.5
	var query:=PhysicsRayQueryParameters3D.create(start,end,1|4,[get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("interaction"):
		var found: Interaction=hit.collider.get_meta("interaction")
		if is_instance_valid(found) and found.global_position.distance_to(global_position)<2.65:target=found
	# Shoulder framing may put the crosshair beside a small crate. Check nearby visible objects.
	if target==null:
		var best:=0.67
		for candidate in get_tree().get_nodes_in_group("interactables"):
			if not candidate.is_inside_tree() or not candidate.get_parent().is_visible_in_tree() or candidate.get_parent()==carried:continue
			var aim: Vector3=candidate.global_position+Vector3.UP*.7
			if global_position.distance_to(candidate.global_position)>2.65:continue
			var dot:=(-cam.global_basis.z).dot((aim-start).normalized())
			if dot<best:continue
			var sight:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.2,aim,1,[get_rid()])
			var obstruction:=get_world_3d().direct_space_state.intersect_ray(sight)
			if not obstruction.is_empty() and obstruction.collider.get_meta("interaction",null)!=candidate:continue
			best=dot;target=candidate
	focused.emit("[E]  "+target.prompt(self) if target!=null else "")
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and target!=null:target.activate(self)
	if event.is_action_pressed("drop"):drop_carried()
	if event.is_action_pressed("flashlight") and Session.stage>=6:torch.visible=not torch.visible
func set_collision(node: Node,enabled: bool) -> void:
	for c in node.find_children("*","CollisionShape3D",true,false):c.set_deferred("disabled",not enabled)
func pick_up(item: Node3D,id: String) -> void:
	carried=item
	Session.carried_id=id
	set_collision(item,false)
	item.reparent(socket)
	item.position=Vector3(0,-.23,0)
	item.rotation=Vector3.ZERO
	play_clip("pickup");animation_lock=.4
	made_noise.emit(global_position,4)
func consume_carried() -> void:
	if carried!=null:carried.queue_free()
	carried=null
	Session.carried_id=""
	play_clip("place");animation_lock=.45
func place_carried(at: Vector3) -> void:
	if carried==null:return
	carried.reparent(get_parent())
	carried.global_position=at
	set_collision(carried,true)
	carried=null
	Session.carried_id=""
	play_clip("place");animation_lock=.45
func drop_carried() -> void:
	if carried==null:return
	var forward:=Basis(Vector3.UP,camera_rig.yaw)*Vector3.FORWARD
	var desired:=global_position+forward*.9
	var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.3,desired+Vector3.UP*.3,1,[get_rid()]))
	if not hit.is_empty():return
	# Snap to support below; an item cannot fall through the world or be lost.
	var floor_hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(desired+Vector3.UP*1.8,desired-Vector3.UP*2,1,[get_rid()]))
	if floor_hit.is_empty():return
	desired.y=floor_hit.position.y
	place_carried(desired)
