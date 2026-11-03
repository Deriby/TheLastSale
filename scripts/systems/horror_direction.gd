class_name HorrorDirection
extends Node
## Nearby, readable beats share one quiet interval and one camera owner.
var world: ShiftWorld
var focused_event:=""
var focus_actor: DepotPlayer
var door_age:=-1.0
var focus_skeleton: Skeleton3D
var focus_face_offset:=.10
var focus_pose: WatcherLean
var focus_contact: ContactThreatPose
var impact_age:=-1.0
var impact_strength:=0.0
var impact_red:=0.0
var capture_age:=-1.0
var capture_pose: ContactThreatPose
var capture_killer: KillerAgent
var capture_hit:=false
var capture_fade:=0.0
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
	var lens:=28.0 if id.begins_with("contact_") else 36.0 if id=="bryan_jump" else 52.0 if id=="car_window" else 48.0 if id.begins_with("watching_") else 60.0
	focus_skeleton=null
	focus_pose=null
	focus_contact=null
	focus_actor.camera_rig.focus_on(point,seconds,48.0 if id.begins_with("contact_") else 38.0 if id=="bryan_jump" else 13.0,lens)
	focus_actor.camera_rig.focus_hide_body=id=="bryan_jump" or id.begins_with("contact_")
	state().last_major=Session.world_seconds
	state().quiet_until=Session.world_seconds+seconds+24.0
	return true
func follow_face(skeleton: Skeleton3D,offset: float=.10,pose: WatcherLean=null) -> void:
	focus_skeleton=skeleton;focus_face_offset=offset;focus_pose=pose;focus_contact=null
	if is_instance_valid(focus_actor):focus_actor.camera_rig.focus_tracker=tracked_face;focus_actor.camera_rig.process_priority=50
func follow_contact(skeleton: Skeleton3D,pose: ContactThreatPose,offset: float=.10) -> void:
	follow_face(skeleton,offset);focus_contact=pose
func tracked_face() -> Vector3:
	if not is_instance_valid(focus_skeleton):return focus_actor.camera_rig.focus_target
	var transform_value:=focus_skeleton.get_global_transform_interpolated()
	if is_instance_valid(focus_contact) and focus_contact.revision>0:return transform_value*focus_contact.face_in_skeleton
	if is_instance_valid(focus_pose) and focus_pose.points.has("face"):return transform_value*focus_pose.face_in_skeleton
	return FaceAnchor.world_point(focus_skeleton)
func face_point(skeleton: Skeleton3D,offset: float=.10) -> Vector3:
	return skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("head")).origin+Vector3.UP*offset
func contact_hit(strength: float=1.0,red: float=.5) -> void:
	if not busy():return
	impact_age=0.0;impact_strength=clampf(strength,0,1);impact_red=clampf(red,0,1)
	focus_actor.camera_rig.contact_kick(impact_strength)
	world.sound.play_contact(impact_strength)
func impact_weight() -> float:
	if impact_age<0:return 0.0
	return impact_strength*(1.0-smoothstep(.08,.78,impact_age))
func begin_capture(killer: KillerAgent,victim: DepotPlayer) -> bool:
	if not world.sunday.stopped or world.sunday.caught_identity!=victim.identity:return false
	if victim!=world.player or not is_instance_valid(killer) or victim.position.distance_to(killer.position)>1.1:return false
	var point:=FaceAnchor.world_point(killer.motion.skeleton)
	if not clear_view(point):return false
	focus_actor=victim;focused_event="killer_capture";capture_age=0;capture_hit=false;capture_fade=0;capture_killer=killer
	focus_actor.camera_rig.focus_on(point,1.20,48.0,24.0 if focus_actor.camera_rig.target_distance>.8 else 44.0);focus_actor.camera_rig.focus_hide_body=true
	var toward:=victim.position-killer.position;killer.visual.rotation.y=atan2(toward.x,toward.z)
	killer.motion.look_at_position(victim.camera_rig.camera.global_position)
	capture_pose=ContactThreatPose.new();killer.motion.skeleton.add_child(capture_pose)
	follow_contact(killer.motion.skeleton,capture_pose)
	return true
func _process(delta: float) -> void:
	if impact_age>=0:
		impact_age+=delta
		if impact_age>=.80:impact_age=-1
	if busy() and is_instance_valid(focus_skeleton):
		if is_instance_valid(focus_contact) and focus_contact.revision>0:
			focus_actor.camera_rig.focus_target=focus_contact.face_point
		elif is_instance_valid(focus_pose) and focus_pose.points.has("head"):
			focus_actor.camera_rig.focus_target=focus_pose.points.get("face",focus_pose.points.head+focus_pose.head_up*focus_face_offset)
		else:focus_actor.camera_rig.focus_target=face_point(focus_skeleton,focus_face_offset)
	if capture_age<0:return
	capture_age+=delta
	if is_instance_valid(capture_pose):
		capture_pose.target=focus_actor.camera_rig.camera.global_position
		capture_pose.amount=smoothstep(0,.16,capture_age)
	if not capture_hit and capture_age>=.12:capture_hit=true;contact_hit(1.0,.70)
	capture_fade=smoothstep(.76,1.04,capture_age)
	if capture_age>=1.04:
		capture_age=-1;capture_fade=0;impact_age=-1;focus_actor.camera_rig.cancel_focus();focus_skeleton=null
		world.sunday.finish_caught()
func calm(seconds: float=24.0) -> void:
	state().quiet_until=maxf(float(state().quiet_until),Session.world_seconds+seconds)
func ambient_blocked() -> bool:
	return busy() or Session.world_seconds<float(state().quiet_until) or world.scary!=null and world.scary.blocks_ambient() or world.encounters!=null and world.encounters.blocking()
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
