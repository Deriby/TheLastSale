class_name ShoulderCamera
extends Node3D
var arm: SpringArm3D
var camera: Camera3D
var target_distance:=2.5
var distance:=2.5
var pitch:=-.12
var yaw:=0.0
var first_person:=false
var shoulder:=.36
var allowed_shoulder:=.36
var occluded:=false
var probe: SphereShape3D
func _ready() -> void:
	top_level=true;physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	position.y=1.58
	arm=SpringArm3D.new();probe=SphereShape3D.new();probe.radius=.18;arm.shape=probe;arm.margin=.10;arm.collision_mask=1
	add_child(arm)
	camera=Camera3D.new();camera.near=.055;camera.current=true;arm.add_child(camera)
	arm.add_excluded_object(get_parent().get_rid())
	target_distance=Preferences.camera_distance;distance=target_distance;arm.spring_length=distance;camera.position.z=distance;arm.position.x=shoulder
func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw-=event.relative.x*Preferences.sensitivity
		pitch=clampf(pitch-event.relative.y*Preferences.sensitivity,-1.03,.86)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:target_distance=maxf(0,target_distance-.24)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:target_distance=minf(3.6,target_distance+.24)
func _physics_process(_delta: float) -> void:
	# Test the lateral move too: SpringArm alone does not protect a shoulder offset.
	var desired:=.36*smoothstep(.1,1.0,distance)
	var motion:=global_basis.x*desired
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=probe;query.transform=Transform3D(Basis.IDENTITY,global_position);query.motion=motion;query.collision_mask=1;query.exclude=[get_parent().get_rid()]
	var result:=get_world_3d().direct_space_state.cast_motion(query)
	allowed_shoulder=desired*(maxf(0,result[0]-.06) if result.size()>0 else 1.0)
func _process(delta: float) -> void:
	var player: DepotPlayer=get_parent()
	rotation=Vector3(pitch,yaw,0)
	distance=lerpf(distance,target_distance,1-exp(-delta*13))
	first_person=distance<.25 and target_distance<.2
	var head:=player.motion.skeleton.get_bone_global_pose(player.motion.skeleton.find_bone("head"))
	var eyes: Vector3=player.motion.skeleton.global_transform*head.origin+Vector3.UP*.15
	var third_height:=1.15 if player.crouching else 1.55
	var blend:=1-smoothstep(.15,1.0,distance)
	var height:=lerpf(third_height,clampf(eyes.y-player.global_position.y,1.0,1.72),blend)
	var center:=player.get_global_transform_interpolated().origin
	global_position=Vector3(center.x,lerpf(global_position.y,center.y+height,1-exp(-delta*16)),center.z)
	shoulder=minf(shoulder,allowed_shoulder) if allowed_shoulder<shoulder else lerpf(shoulder,allowed_shoulder,1-exp(-delta*7))
	arm.position.x=shoulder
	arm.position.z=-.16*blend
	arm.spring_length=maxf(0,distance)
	camera.fov=lerpf(camera.fov,Preferences.fov,1-exp(-delta*8))
	var actual: float=camera.global_position.distance_to(global_position)
	if not first_person:
		if actual<.46:occluded=true
		elif actual>.68:occluded=false
	else:occluded=false
	player.visual.visible=true
	player.motion.set_first_person(first_person,occluded)

func reset_follow() -> void:
	global_position=get_parent().global_position+Vector3.UP*1.55
	rotation=Vector3(pitch,yaw,0)
	reset_physics_interpolation()
