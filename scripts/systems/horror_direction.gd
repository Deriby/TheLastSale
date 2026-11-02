class_name HorrorDirection
extends Node
## Nearby, readable beats share one quiet interval and one camera owner.
var world: ShiftWorld
var focused_event:=""
var focus_actor: DepotPlayer
var door_age:=-1.0
func _ready() -> void:
	Session.saving.connect(capture)
	if bool(state().get("stock_ajar",false)):
		world.depot.stock_door.rotation.y=float(state().get("stock_angle",-.62))
		for child in world.depot.stock_door.get_children():
			if child is Interaction and child.kind=="door":
				child.open=bool(state().get("stock_open",false))
				if bool(state().get("stock_busy",false)):
					child.busy=true
					var angle: float=-1.45 if child.open else 0.0
					var duration:=maxf(.02,.5*absf(world.depot.stock_door.rotation.y-angle)/1.45)
					child.create_tween().tween_property(world.depot.stock_door,"rotation:y",angle,duration).finished.connect(func():child.busy=false)
func capture() -> void:
	if not bool(state().get("stock_ajar",false)):return
	state().stock_angle=world.depot.stock_door.rotation.y
	for child in world.depot.stock_door.get_children():
		if child is Interaction and child.kind=="door":state().stock_open=child.open;state().stock_busy=child.busy
func state() -> Dictionary:
	if not Session.campaign.experience.get("horror_direction") is Dictionary:
		Session.campaign.experience.horror_direction={"quiet_until":0.0,"last_major":-1000.0,"events":{},"terminal_seen":false}
	return Session.campaign.experience.horror_direction
func busy() -> bool:
	return is_instance_valid(focus_actor) and focus_actor.camera_rig.focusing()
func safe() -> bool:
	if not world.active or Dialogue.active or world.cashier_open or world.surveillance_open or world.sunday.desk_open or world.friday.finishing or busy():return false
	for actor in world.characters.values():
		if actor.input_locked or actor.motion.action_active or actor.handling.busy:return false
	return world.player.carried==null
func ready_for(point: Vector3,radius: float) -> bool:
	return safe() and world.player.global_position.distance_to(point)<radius and Session.world_seconds>=float(state().quiet_until)
func clear_view(point: Vector3,excluded: Array[RID]=[]) -> bool:
	var start:=world.player.camera_rig.camera.global_position
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,point,1,excluded))
	return hit.is_empty() or hit.position.distance_to(point)<.20
func focus(id: String,point: Vector3,seconds: float=1.5,radius: float=5.0,excluded: Array[RID]=[]) -> bool:
	if not ready_for(point,radius) or not clear_view(point,excluded):return false
	focus_actor=world.player;focused_event=id
	var lens:=48.0 if id=="bryan_jump" or id.begins_with("watching_") else 52.0 if id=="car_window" else 60.0
	focus_actor.camera_rig.focus_on(point,seconds,13.0,lens)
	state().last_major=Session.world_seconds
	state().quiet_until=Session.world_seconds+seconds+24.0
	return true
func calm(seconds: float=24.0) -> void:
	state().quiet_until=maxf(float(state().quiet_until),Session.world_seconds+seconds)
func ambient_blocked() -> bool:
	return busy() or Session.world_seconds<float(state().quiet_until) or world.scary!=null and world.scary.blocks_ambient()
func _physics_process(delta: float) -> void:
	if not world.active:return
	if not busy():focused_event="";focus_actor=null
	if world.surveillance_open or world.sunday.desk_open:
		state().terminal_seen=true;calm(7.0)
	if door_age>=0:
		door_age+=delta
		world.scary.handle.rotation.z=sin(door_age*37)*.16*maxf(0,1-door_age/.8)
		if door_age>.8:door_age=-1;world.scary.handle.rotation.z=0
	if int(Session.campaign.night)==1:tick_ajar()
	if int(Session.campaign.night)!=0 or Session.campaign.phase not in ["routine","restored","closing"]:return
	if not world.scary.done("stock_handle") or not world.scary.done("bryan_prank") or bool(state().events.get("return_bang",false)):return
	if Session.world_seconds-float(state().last_major)<45 or world.player.identity!="Dery":return
	var point: Vector3=world.scary.handle.global_position+Vector3(0,.15,.08)
	if not focus("return_bang",point,1.3,3.6):return
	state().events.return_bang=true;door_age=0
	world.sound.play_spatial("res://assets/audio/scares/door_slam.ogg",point,1)
	Session.save_shift(world.player.position)
func tick_ajar() -> void:
	if not bool(state().terminal_seen) or not safe():return
	if Session.campaign.phase not in ["saturday_investigation","saturday_decisions","closing"]:return
	var door:=world.depot.stock_door
	var point:=door.to_global(Vector3(.85,1.45,.12))
	if not ready_for(point,5.5) or bool(state().events.get("ajar_seen",false)):return
	if world.presence!=null and is_instance_valid(world.presence.watcher):return
	if not bool(state().get("stock_ajar",false)):
		if world.player.camera_rig.camera.is_position_in_frustum(point) and clear_view(point):return
		for actor in world.characters.values():
			if actor.position.distance_to(door.position+Vector3(.85,0,0))<2.2:return
		for child in door.get_children():
			if child is Interaction and child.kind=="door":
				if child.open or child.busy:return
				child.open=false
		# The leaf moves only while unwatched and with its whole sweep clear.
		door.rotation.y=-.62;state().stock_ajar=true
		world.sound.play_spatial("res://assets/audio/scares/handle_rattle.ogg",point,-8)
		Session.save_shift(world.player.position)
		return
	point=door.to_global(Vector3(.85,1.45,.12))
	if focus("stock_ajar",point,1.45,5.5):
		state().events.ajar_seen=true;Session.save_shift(world.player.position)
