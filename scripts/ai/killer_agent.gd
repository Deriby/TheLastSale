class_name KillerAgent
extends CharacterBody3D
## Shared-world pursuer: sight and hearing drive durable last-known-position memory.
var chapter: SundayShift
var visual: Node3D
var motion: LivingMotion
var mode:="patrol"
var target_identity:=""
var last_seen:=Vector3.ZERO
var goal:=Vector3.ZERO
var waypoints:=PackedVector3Array()
var patrol_index:=0
var search_time:=0.0
var lost_for:=0.0
var grace:=8.0
var sense_wait:=0.0
var path_wait:=0.0
var attack_time:=0.0
const PATROL: Array[Vector3]=[Vector3(0,0,-18.5),Vector3(0,0,-14.2),Vector3(4.8,0,-13.2),Vector3(4.8,0,-18),Vector3(2.25,0,-19.6)]
func _ready() -> void:
	collision_layer=2;collision_mask=1|2
	var shape:=CapsuleShape3D.new();shape.radius=.27;shape.height=1.8
	var col:=CollisionShape3D.new();col.shape=shape;col.position.y=.9;add_child(col)
	visual.reparent(self,false);visual.transform=Transform3D.IDENTITY;visual.show();visual.process_mode=Node.PROCESS_MODE_INHERIT
	# The measured library supplies this rig's own run, without retargeting body offsets.
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	goal=PATROL[0]
func snapshot() -> Dictionary:
	return {"position":[position.x,position.y,position.z],"facing":visual.rotation.y,"mode":mode,"target":target_identity,"last_seen":[last_seen.x,last_seen.y,last_seen.z],"goal":[goal.x,goal.y,goal.z],"patrol":patrol_index,"search":search_time,"lost":lost_for,"grace":grace,"attack":attack_time}
func restore(data: Dictionary) -> void:
	position=chapter.world.navigation.restore_position(Session.read_position(data.get("position"),Vector3(0,.01,-18.5)))
	visual.rotation.y=float(data.get("facing",0));mode=str(data.get("mode","patrol"))
	if mode not in ["patrol","investigate","chase","search","attack"]:mode="patrol"
	target_identity=str(data.get("target",""));last_seen=Session.read_position(data.get("last_seen"),position)
	goal=Session.read_position(data.get("goal"),PATROL[0]);patrol_index=posmod(int(data.get("patrol",0)),PATROL.size())
	search_time=maxf(0,float(data.get("search",0)));lost_for=maxf(0,float(data.get("lost",0)));grace=clampf(float(data.get("grace",8)),0,8)
	attack_time=clampf(float(data.get("attack",0)),0,.8)
	if mode=="attack":motion.action("attack")
	reset_physics_interpolation()
func clear_line(to: Vector3) -> bool:
	var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.48,to,1,[get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func can_see(actor: DepotPlayer) -> bool:
	var offset:=actor.global_position-global_position;offset.y=0
	var distance:=offset.length()
	var lit: bool=chapter.actor_lit(actor)
	var reach:=11.0 if actor.torch.visible else (8.5 if lit else 4.5)
	if actor.crouching or actor.concealed:reach*=.62
	if distance>reach:return false
	var forward:=visual.global_basis.z.normalized()
	if distance>1.6 and forward.dot(offset.normalized())<.15:return false
	return clear_line(actor.global_position+Vector3.UP*(.92 if actor.crouching or actor.concealed else 1.45))
func hear(at: Vector3,strength: float) -> void:
	if not chapter.threat_active() or grace>0 or mode in ["chase","attack"]:return
	var reach:=strength if clear_line(at+Vector3.UP) else strength*.45
	if global_position.distance_to(at)>reach:return
	mode="investigate";last_seen=at;goal=at;search_time=0;path_wait=0
func sense() -> void:
	var seen: DepotPlayer
	var nearest:=INF
	for actor in chapter.world.characters.values():
		if can_see(actor):
			var score:=global_position.distance_squared_to(actor.global_position)
			if actor.identity==target_identity:score*=.6
			if score<nearest:nearest=score;seen=actor
	if seen!=null:
		if mode!="chase":chapter.world.notice.emit(seen.display_name()+": ele me viu! Apague a lanterna, quebre a linha de visão e procure cobertura.")
		mode="chase";target_identity=seen.identity;last_seen=seen.global_position;goal=last_seen;lost_for=0
func _physics_process(delta: float) -> void:
	if not chapter.threat_active() or Dialogue.active:
		velocity=Vector3.ZERO;motion.locomotion(delta,0,false,false,false);return
	grace=maxf(0,grace-delta)
	if grace>0:motion.locomotion(delta,0,false,false,false);return
	if mode=="attack":
		velocity=Vector3.ZERO;attack_time-=delta
		if attack_time<=0:
			var target: DepotPlayer=chapter.world.characters.get(target_identity)
			if target!=null and target.position.distance_to(position)<1.05 and clear_line(target.position+Vector3.UP*.9):chapter.caught(target.identity)
			else:mode="chase";motion.action_active=false;path_wait=0
		return
	sense_wait-=delta;path_wait-=delta
	if sense_wait<=0:sense_wait=.12;sense()
	if mode=="chase":
		var target: DepotPlayer=chapter.world.characters.get(target_identity)
		if target!=null and can_see(target):last_seen=target.global_position;goal=last_seen;lost_for=0
		else:
			lost_for+=delta
			if lost_for>2.0:mode="search";goal=last_seen;search_time=0;target_identity=""
	elif mode in ["investigate","search"]:
		search_time+=delta
		if global_position.distance_to(goal)<.55:visual.rotation.y+=delta*.65
		if search_time>9:mode="patrol";goal=PATROL[patrol_index];search_time=0
	else:
		if global_position.distance_to(goal)<.55:patrol_index=(patrol_index+1)%PATROL.size();goal=PATROL[patrol_index]
	if path_wait<=0:
		path_wait=.45
		chapter.open_nearby_doors(self)
		waypoints=chapter.route(global_position,goal)
		if waypoints.is_empty():
			var approach:=chapter.door_approach(global_position,goal)
			if approach!=Vector3.INF:waypoints=chapter.route(global_position,approach)
	while not waypoints.is_empty() and Vector2(waypoints[0].x-position.x,waypoints[0].z-position.z).length()<.12:waypoints.remove_at(0)
	var direction:=Vector3.ZERO
	if not waypoints.is_empty():direction=(waypoints[0]-global_position)*Vector3(1,0,1);direction=direction.normalized()
	var speed:=2.65 if mode=="chase" else (1.35 if mode in ["investigate","search"] else 1.05)
	velocity.x=direction.x*speed;velocity.z=direction.z*speed;velocity.y=-2 if is_on_floor() else velocity.y-18*delta
	var before:=position;move_and_slide()
	var actual:=Vector2(position.x-before.x,position.z-before.z).length()/maxf(delta,.001)
	if direction.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*7)
	motion.locomotion(delta,actual,false,false,false)
	for actor in chapter.world.characters.values():
		if actor.global_position.distance_to(global_position)<.85 and clear_line(actor.global_position+Vector3.UP*.9):
			mode="attack";target_identity=actor.identity;attack_time=.8;motion.action("attack")
			chapter.world.notice.emit(actor.display_name()+": cuidado! Afaste-se do golpe!");return
