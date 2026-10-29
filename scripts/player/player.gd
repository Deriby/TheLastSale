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
var motion: LivingMotion
var handling: BoxHandling
var action_facing:=Vector3.ZERO
var actual_speed:=0.0
var foot_audio: AudioStreamPlayer3D
var tile_step: AudioStream=preload("res://assets/audio/step_tile.wav")
var asphalt_step: AudioStream=preload("res://assets/audio/step_asphalt.wav")
var capsule: CapsuleShape3D
var torch: SpotLight3D
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1|2
	var col:=CollisionShape3D.new()
	capsule=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.74
	col.shape=capsule;col.position.y=.87
	add_child(col)
	visual=CharacterModels.create("Dery")
	add_child(visual)
	visual.rotation.y=PI
	animator=visual.find_child("AnimationPlayer",true,false)
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	camera_rig=ShoulderCamera.new();add_child(camera_rig)
	socket=Node3D.new();add_child(socket);socket.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	handling=BoxHandling.new();add_child(handling);handling.setup(self);motion.pose_updated.connect(handling.sync_grip)
	foot_audio=AudioStreamPlayer3D.new();add_child(foot_audio);foot_audio.stream=tile_step;foot_audio.volume_db=-11
	torch=SpotLight3D.new();camera_rig.camera.add_child(torch);torch.position=Vector3(.15,-.12,0);torch.spot_range=12;torch.spot_angle=29;torch.light_energy=2.2;torch.light_color=Color("ece7c2");torch.visible=false
	motion.pose_updated.connect(update_footsteps)
	add_to_group("player")
func play_clip(clip: String) -> void:
	motion.play(clip)
func _physics_process(delta: float) -> void:
	crouching=Input.is_action_pressed("crouch") and carried==null and not motion.action_active
	if not crouching and capsule.height<1.7:
		var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.9,global_position+Vector3.UP*1.8,1,[get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():crouching=true
	capsule.height=1.30 if crouching else 1.74
	get_child(0).position.y=capsule.height*.5
	var input:=Input.get_vector("left","right","forward","backward") if not motion.action_active else Vector2.ZERO
	var direction:=Basis(Vector3.UP,camera_rig.yaw)*Vector3(input.x,0,input.y)
	var running:=Input.is_action_pressed("sprint") and not crouching and carried==null and stamina>.05 and input.length()>.1
	stamina=clampf(stamina+delta*(-.18 if running else .16),0,1)
	var speed:=3.9 if running else (.85 if crouching else (1.15 if carried!=null else 1.55))
	var acceleration:=10.0 if running else (8.0 if input.length()<.1 else 6.5)
	velocity.x=move_toward(velocity.x,direction.x*speed,delta*acceleration)
	velocity.z=move_toward(velocity.z,direction.z*speed,delta*acceleration)
	velocity.y=velocity.y-18*delta if not is_on_floor() else 0.0
	var before:=global_position;move_and_slide()
	actual_speed=Vector2(global_position.x-before.x,global_position.z-before.z).length()/maxf(delta,.001)
	if motion.action_active and action_facing.length()>.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(action_facing.x,action_facing.z),1-exp(-delta*10))
	elif camera_rig.first_person:
		visual.rotation.y=lerp_angle(visual.rotation.y,camera_rig.yaw+PI,1-exp(-delta*16))
	elif direction.length()>.05:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*10))
	var gait: String="walk"
	if camera_rig.first_person:
		if input.y>.2:gait="walk_back"
		elif absf(input.x)>.4 and absf(input.y)<.3:gait="strafe_left" if input.x<0 else "strafe_right"
	motion.locomotion(delta,actual_speed,crouching,carried!=null,stamina<.35,gait)
	motion.look_at_position(global_position-Basis(Vector3.UP,camera_rig.yaw).z*4+Vector3.UP*1.6,not motion.action_active)
	update_focus()
var last_step_half:=-1
func update_footsteps() -> void:
	if animator==null or not motion.strides.has(motion.current_clip) or not is_on_floor() or actual_speed<.1:
		last_step_half=-1;return
	var half:=int(fmod(animator.current_animation_position/maxf(.01,animator.current_animation_length),1)*2)
	if last_step_half!=-1 and half!=last_step_half:
		foot_audio.stream=asphalt_step if global_position.z>=0 else tile_step
		foot_audio.volume_db=linear_to_db(maxf(Preferences.effects_volume,.001))-11;foot_audio.play()
		made_noise.emit(global_position,8.0 if actual_speed>2.55 else 3.0)
	last_step_half=half
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
	if motion.action_active:return
	if event.is_action_pressed("interact") and target!=null:target.activate(self)
	if event.is_action_pressed("drop"):drop_carried()
	if event.is_action_pressed("flashlight") and Session.stage>=6:torch.visible=not torch.visible
func set_collision(node: Node,enabled: bool) -> void:
	for c in node.find_children("*","CollisionShape3D",true,false):c.set_deferred("disabled",not enabled)
func pick_up(item: Node3D,id: String,instant := false) -> void:
	handling.pickup(item,id,instant)
func consume_carried(destination: Vector3 = Vector3.ZERO,on_placed: Callable = Callable()) -> void:
	if destination==Vector3.ZERO:destination=global_position+visual.global_basis.z*.7+Vector3.UP*.85
	handling.place(destination,true,on_placed)
func place_carried(at: Vector3) -> void:
	handling.place(at)
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
