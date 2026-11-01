class_name FrightIntruder
extends CharacterBody3D
## A brief, partly concealed look from the stockroom. Never enters the shop floor.
signal departed
const HIDDEN:=Vector3(2.8,0,-12.4)
const EDGE:=Vector3(3.82,0,-12.4)
var world: ShiftWorld
var visual: Node3D
var motion: LivingMotion
var state:="emerging"
var leg:=0
var route: Array[Vector3]=[EDGE]
var waypoints:=PackedVector3Array()
var held:=0.0
var seen_time:=0.0
var walked:=0.0
var foot: AudioStreamPlayer3D
func _ready() -> void:
	add_to_group("atmosphere_actor");collision_layer=2;collision_mask=3
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.70;capsule.radius=.23;shape.shape=capsule;shape.position.y=.85;add_child(shape)
	visual=CharacterModels.create("Enemy");add_child(visual)
	for mesh in visual.find_children("*","MeshInstance3D",true,false):mesh.layers=2
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	foot=AudioStreamPlayer3D.new();add_child(foot);foot.stream=load("res://assets/audio/step_tile.wav");foot.max_distance=6
	go_to_leg()
func go_to_leg() -> void:
	waypoints.clear()
	if leg>=route.size():return
	if state=="emerging" or leg==0:waypoints.append(route[leg])
	else:waypoints=world.navigation.path_with_obstacles(global_position,route[leg],[Rect2(3.65,-17.85,.38,1.85)])
func retreat() -> void:
	if state=="retreating":return
	state="retreating";leg=0
	# Ordinarily the wall hides him at the first point. If pursued, continue
	# physically into the rear yard, never back through customers or the counter.
	route=[HIDDEN,Vector3(2.65,0,-14.35),Vector3(4.75,0,-14.8),Vector3(4.75,0,-17.3),Vector3(4.05,0,-20)]
	go_to_leg()
func _physics_process(delta: float) -> void:
	if not world.active or world.cashier_open or world.surveillance_open or Dialogue.active:return
	if state!="retreating" and (seen_time>.55 or world.scary.other_witnesses(EDGE) or world.player.position.distance_to(position)<4):retreat()
	if state=="waiting":
		held+=delta;motion.locomotion(delta,0,false,false,false)
		if held>.12:retreat()
		return
	while not waypoints.is_empty() and Vector2(waypoints[0].x-position.x,waypoints[0].z-position.z).length()<.04:waypoints.remove_at(0)
	var direction:=Vector3.ZERO
	if not waypoints.is_empty():direction=((waypoints[0]-global_position)*Vector3(1,0,1)).normalized()
	var speed:=.85 if state=="emerging" else 1.65
	velocity=Vector3(direction.x*speed,velocity.y-18*delta if not is_on_floor() else 0,direction.z*speed)
	var before:=position;move_and_slide();var travel:=Vector2(position.x-before.x,position.z-before.z).length()
	motion.locomotion(delta,travel/maxf(delta,.001),false,false,false,"strafe_right" if state=="emerging" else "strafe_left" if leg==0 else "walk")
	if state=="retreating" and leg>0 and direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*10))
	walked+=travel
	if walked>.65:
		walked=0;foot.volume_db=-29+linear_to_db(maxf(.001,Preferences.effects_volume));foot.play()
	if leg<route.size() and Vector2(position.x-route[leg].x,position.z-route[leg].z).length()<.07:
		if state=="emerging":state="waiting"
		else:leg+=1;go_to_leg()
	# Only retire behind actual cover or outside every observer's view.
	if state=="retreating" and position.x<3.15 and not world.scary.player_sees_body(position) and not world.scary.other_witnesses(position):
		departed.emit();queue_free()
func snapshot() -> Dictionary:
	return {"kind":"stock_glimpse","state":state,"leg":leg,"held":held,"seen_time":seen_time,"position":[position.x,position.y,position.z],"facing":visual.rotation.y}
func restore(data: Dictionary) -> void:
	position=Session.read_position(data.get("position"),HIDDEN)
	if data.get("state","")=="retreating":retreat()
	state=str(data.get("state","emerging"));leg=clampi(int(data.get("leg",0)),0,route.size());held=float(data.get("held",0));seen_time=float(data.get("seen_time",0));visual.rotation.y=float(data.get("facing",0));go_to_leg();reset_physics_interpolation()
func _exit_tree() -> void:
	if is_instance_valid(foot):foot.stop();foot.stream=null
