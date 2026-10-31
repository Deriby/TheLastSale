class_name FrightIntruder
extends CharacterBody3D
## A physical Friday glimpse. The later Sunday antagonist remains independent.
signal reached_yard
signal departed
var world: ShiftWorld
var visual: Node3D
var motion: LivingMotion
var state:="crossing"
var leg:=0
var waypoints:=PackedVector3Array()
var route: Array[Vector3]=[Vector3(4.65,0,-8.5),Vector3(4.75,0,-12.2),Vector3(4.75,0,-17.3),Vector3(4.05,0,-20.0)]
var blocked:=0.0
var repath:=0.0
var walked:=0.0
var foot: AudioStreamPlayer3D
func _ready() -> void:
	add_to_group("atmosphere_actor");collision_layer=2;collision_mask=3
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.70;capsule.radius=.23;shape.shape=capsule;shape.position.y=.85;add_child(shape)
	visual=CharacterModels.create("ClienteCinza");add_child(visual)
	for mesh in visual.find_children("*","MeshInstance3D",true,false):mesh.layers=2
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	foot=AudioStreamPlayer3D.new();world.sound.add_child(foot);foot.set_meta("loop_base_db",-11);foot.set_meta("music_loop",false);world.sound.loop_players.append(foot);foot.stream=load("res://assets/audio/step_tile.wav");foot.max_distance=17
	go_to_leg()
func go_to_leg() -> void:
	if leg>=route.size():return
	# Include the open leaves, which project into the corridor but are absent
	# from the fixed furniture grid. Plan around people without changing it.
	var avoid: Array[Rect2]=[Rect2(3.65,-11.0,.38,1.8),Rect2(3.65,-17.85,.38,1.85)]
	for actor in world.characters.values():avoid.append(Rect2(actor.position.x-.30,actor.position.z-.30,.60,.60))
	waypoints=world.navigation.path_with_obstacles(global_position,route[leg],avoid)
func leave() -> void:
	if state=="leaving":return
	state="leaving";leg=0
	route=[Vector3(4.75,0,-17.2),Vector3(4.75,0,-12.2),Vector3(4.65,0,-8.5),Vector3(3.25,0,-5),Vector3(3.1,0,.8),Vector3(-24,0,1.8)]
	go_to_leg()
func open_nearby_doors() -> void:
	if leg>=route.size():return
	for door in [world.depot.stock_door,world.depot.service_door]:
		if (position.z-door.global_position.z)*(route[leg].z-door.global_position.z)>=0:continue
		if global_position.distance_to(door.global_position+Vector3(.85,0,0))>2.0:continue
		for child in door.get_children():
			if child is Interaction and child.kind=="door" and not child.open and not child.busy:child.activate(self)
func _physics_process(delta: float) -> void:
	if not world.active or foot.stream==null:return
	if state=="hiding":
		motion.locomotion(delta,0,false,false,false)
		if world.player.position.distance_to(position)<4 or Session.campaign.phase=="closing":leave()
		return
	if world.cashier_open or world.surveillance_open or Dialogue.active:return
	open_nearby_doors();repath-=delta
	if repath<=0:repath=.65;go_to_leg()
	while not waypoints.is_empty() and Vector2(waypoints[0].x-position.x,waypoints[0].z-position.z).length()<.16:waypoints.remove_at(0)
	var direction:=Vector3.ZERO
	if not waypoints.is_empty():direction=((waypoints[0]-global_position)*Vector3(1,0,1)).normalized()
	var speed:=3.15 if state=="crossing" and leg==0 else 2.05
	velocity=Vector3(direction.x*speed,velocity.y-18*delta if not is_on_floor() else 0,direction.z*speed)
	var before:=global_position;move_and_slide();var travel:=Vector2(position.x-before.x,position.z-before.z).length()
	motion.locomotion(delta,travel/maxf(delta,.001),false,false,false)
	if direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*12))
	walked+=travel
	if walked>.72:walked=0;foot.global_position=global_position+Vector3.UP*.08;foot.volume_db=-11+linear_to_db(maxf(.001,Preferences.effects_volume));foot.play()
	blocked=blocked+delta if travel<.01 else 0
	if blocked>2:repath=0;blocked=0
	if leg<route.size() and Vector2(position.x-route[leg].x,position.z-route[leg].z).length()<.32:
		leg+=1;go_to_leg()
		if state=="crossing" and leg>=route.size():state="hiding";reached_yard.emit()
	if state=="leaving" and leg>=route.size() and world.player.position.distance_to(position)>12 and not world.scary.can_see(position+Vector3.UP*1.5):departed.emit();queue_free()
func snapshot() -> Dictionary:
	return {"state":state,"leg":leg,"position":[position.x,position.y,position.z],"facing":visual.rotation.y}
func restore(data: Dictionary) -> void:
	position=world.navigation.restore_position(Session.read_position(data.get("position"),position))
	if data.get("state","")=="leaving":leave()
	state=str(data.get("state","crossing"));leg=clampi(int(data.get("leg",0)),0,route.size());visual.rotation.y=float(data.get("facing",0));go_to_leg();reset_physics_interpolation()
func _exit_tree() -> void:
	if is_instance_valid(foot):foot.stop();foot.stream=null
