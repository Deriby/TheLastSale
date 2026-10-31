class_name QuietObserver
extends CharacterBody3D
## An ordinary person across the street; departure follows the real navigation.
signal left
var navigation: AisleNavigation
var visual: Node3D
var motion: LivingMotion
var leaving:=false
var waypoints:=PackedVector3Array()
var destination:=Vector3.ZERO
var blocked_time:=0.0
func _ready() -> void:
	add_to_group("atmosphere_actor");collision_layer=2;collision_mask=3
	var collision:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.70;capsule.radius=.24
	collision.shape=capsule;collision.position.y=.85;add_child(collision)
	visual=CharacterModels.create("ClienteCinza");add_child(visual);visual.rotation.y=PI
	for mesh in visual.find_children("*","MeshInstance3D",true,false):mesh.layers=2
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
func depart() -> void:
	if leaving:return
	leaving=true;destination=navigation.nearest_walkable(Vector3(-24,0,11.4));waypoints=navigation.path(global_position,destination)
func _physics_process(delta: float) -> void:
	while not waypoints.is_empty() and Vector2(waypoints[0].x-position.x,waypoints[0].z-position.z).length()<.15:waypoints.remove_at(0)
	var direction:=Vector3.ZERO
	if leaving and not waypoints.is_empty():direction=((waypoints[0]-global_position)*Vector3(1,0,1)).normalized()
	velocity=Vector3(direction.x*.82,velocity.y-18*delta if not is_on_floor() else 0,direction.z*.82)
	var before:=global_position;move_and_slide();var speed:=Vector2(position.x-before.x,position.z-before.z).length()/maxf(.001,delta)
	motion.locomotion(delta,speed,false,false,false)
	if direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*7))
	else:motion.look_at_position(Vector3(1,1.65,-1.0))
	blocked_time=blocked_time+delta if leaving and speed<.1 else 0.0
	if blocked_time>2.5:waypoints=navigation.path(global_position,destination);blocked_time=0
	if leaving and global_position.distance_to(destination)<.5:left.emit();queue_free()
func snapshot() -> Dictionary:
	return {"state":"leaving" if leaving else "standing","position":[position.x,position.y,position.z],"facing":visual.rotation.y}
func restore(data: Dictionary) -> void:
	global_position=navigation.restore_position(Session.read_position(data.get("position"),global_position));visual.rotation.y=float(data.get("facing",PI))
	if data.get("state","")=="leaving":depart()
	reset_physics_interpolation()
