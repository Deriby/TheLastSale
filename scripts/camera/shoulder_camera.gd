class_name ShoulderCamera
extends Node3D
var arm: SpringArm3D
var camera: Camera3D
var target_distance := 2.5
var distance := 2.5
var pitch := -.12
var yaw := 0.0
var first_person := false
func _ready() -> void:
	position.y = 1.58
	arm = SpringArm3D.new()
	var shape := SphereShape3D.new();shape.radius=.18
	arm.shape = shape
	arm.margin = .12
	arm.collision_mask = 1
	add_child(arm)
	camera = Camera3D.new()
	camera.near = .06
	camera.current = true
	arm.add_child(camera)
	arm.add_excluded_object(get_parent().get_rid())
	target_distance = Preferences.camera_distance
	distance = target_distance
	arm.spring_length=distance
	camera.position.z=distance
	arm.position.x=.4
func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * Preferences.sensitivity
		pitch = clampf(pitch-event.relative.y*Preferences.sensitivity,-1.1,.95)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: target_distance=maxf(0,target_distance-.28)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: target_distance=minf(4,target_distance+.28)
func _process(delta: float) -> void:
	rotation = Vector3(pitch,yaw,0)
	distance = lerpf(distance,target_distance,1-exp(-delta*14))
	first_person = distance < .27
	arm.spring_length = maxf(.0,distance)
	arm.position.x = .4 * smoothstep(.1,1.25,distance)
	camera.fov = lerpf(camera.fov,Preferences.fov,1-exp(-delta*8))
	position.y = lerpf(position.y,1.05 if get_parent().crouching else 1.58,1-exp(-delta*12))
	get_parent().visual.visible = distance > .42
