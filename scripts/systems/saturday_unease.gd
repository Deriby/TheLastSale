class_name SaturdayUnease
extends Node3D
## Optional physical aftermath and a rare car-window encounter; no journal or dialogue cues.
const OLD_BOARD:=Rect2(-1.52,-15.07,.74,.55)
const SHIFT:=Vector3(.28,0,-.04)
const FOOT_A:=Vector3(4.65,.12,-17.15)
const FOOT_B:=Vector3(5.15,.12,-17.4)
const CLOTH:=Vector3(.65,1.05,-16.18)
var world: ShiftWorld
var car: Node3D
var figure: CarWindowPresence
var car_bodies: Array[RID]=[]
var board_bodies: Array[RID]=[]
var extra_marks: Node3D
var cue:=""
var cue_age:=0.0
var second_step:=false
func state() -> Dictionary:
	if not Session.campaign.experience.get("saturday_unease") is Dictionary:
		Session.campaign.experience.saturday_unease={"entered":-1.0,"inspected":-1.0,"shifted":false,"steps":false,"cloth":false,"last_sound":-1000.0,"quiet_until":0.0,"head_quiet":0.0,"turn_wait":0.0,"rattle_seen":false,"face_used":false,"face":{}}
	return Session.campaign.experience.saturday_unease
func _ready() -> void:
	if int(Session.campaign.night)!=1:return
	car=world.street.get_node("ParkedSedan")
	for body in car.find_children("*","CollisionObject3D",true,false):car_bodies.append(body.get_rid())
	for body in world.saturday.board.find_children("*","CollisionObject3D",true,false):board_bodies.append(body.get_rid())
	var lamp:=OmniLight3D.new();lamp.name="SedanDashboardGlow";car.add_child(lamp);lamp.position=Vector3(.35,1.25,.84);lamp.omni_range=.95;lamp.light_energy=.4;lamp.light_color=Color("b9c1a6");lamp.shadow_enabled=false;lamp.light_cull_mask=8
	var dirt:=Geo.material(Color(.17,.13,.08,.48));dirt.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;dirt.roughness=1
	for index in 3:mark(Vector3(4.62+index*.07,.009,-15.68+index*.29),.15+index*.13,dirt)
	extra_marks=Node3D.new();add_child(extra_marks)
	for index in 3:mark(Vector3(3.85-index*.38,.009,-15.0+index*.06),-.55,dirt,extra_marks)
	extra_marks.visible=bool(state().shifted)
	if bool(state().shifted):apply_board_shift()
	Session.saving.connect(capture)
	var data: Dictionary=state().get("face",{})
	if not data.is_empty():spawn_face(data)
func mark(at: Vector3,angle: float,material: Material,parent: Node3D=null) -> void:
	var root:=Node3D.new();(parent if parent!=null else self).add_child(root);root.position=at;root.rotation.y=angle
	for item in [[Vector3(0,0,-.07),Vector3(.075,.002,.08)],[Vector3(.006,0,.045),Vector3(.105,.002,.14)],[Vector3(-.04,0,.13),Vector3(.035,.002,.045)]]:
		var mesh:=Geo.box(root,item[0],item[1],material,false);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func save() -> void:Session.save_shift(world.player.position)
func capture() -> void:
	if int(Session.campaign.night)!=1:return
	state().face=figure.snapshot() if is_instance_valid(figure) and figure.phase!="done" else {}
func base_safe() -> bool:
	return world.active and not world.is_queued_for_deletion() and not Dialogue.active and not world.cashier_open and not world.surveillance_open and not world.sunday.desk_open and not world.friday.finishing
func blocks_watching() -> bool:
	return is_instance_valid(figure) or not cue.is_empty() or Session.world_seconds<float(state().quiet_until)
func visible(point: Vector3,excluded: Array[RID]=[]) -> bool:
	var camera:=world.player.camera_rig.camera
	return camera.is_position_in_frustum(point) and world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1,excluded)).is_empty()
func apply_board_shift() -> void:
	var board: Node3D=world.saturday.board
	for child in board.get_children():
		if child.has_meta("stationary_dust"):child.reparent(world.depot,true)
	board.position=Vector3(-1.15,0,-14.8)+SHIFT;board.rotation.y=-.12;extra_marks.show()
	var index:=world.depot.blockers.find(OLD_BOARD)
	if index>=0:world.depot.blockers[index]=Rect2(OLD_BOARD.position+Vector2(SHIFT.x,SHIFT.z),OLD_BOARD.size)
	world.navigation.configure(world.depot.blockers+world.street.blockers,Street.surface_height)
func can_shift() -> bool:
	var at: Vector3=world.saturday.board.global_position
	for person in world.characters.values():
		if person.position.distance_to(at)<4:return false
	for point in [at+Vector3.UP*.3,at+Vector3(.35,.3,.25),Vector3(3.3,.04,-14.9)]:
		if visible(point,board_bodies):return false
	return true
func window_point() -> Vector3:return car.to_global(Vector3(.35,1.28,.62))
func near_window() -> bool:
	var local:=car.to_local(world.player.global_position)
	return local.x>-.65 and local.x<1.1 and local.z>1.12 and local.z<3.8
func window_visible() -> bool:
	var local:=car.to_local(world.player.camera_rig.camera.global_position)
	return local.z>1.0 and absf(local.x-.35)<2.2 and visible(window_point(),car_bodies)
func private_window() -> bool:
	for person in world.characters.values():
		if person!=world.player and person.global_position.distance_to(window_point())<5:return false
	if is_instance_valid(world.customer) and world.customer.global_position.distance_to(window_point())<6:return false
	return true
func spawn_face(data: Dictionary={}) -> void:
	figure=CarWindowPresence.new();figure.world=world;figure.owner_event=self;figure.resume=data;car.add_child(figure);figure.position=Vector3(.35,0,.62)
	figure.finished.connect(func():figure=null;state().face={};state().quiet_until=Session.world_seconds+35;save())
func _physics_process(delta: float) -> void:
	if int(Session.campaign.night)!=1 or not world.active or world.is_queued_for_deletion():return
	var now:=Session.world_seconds
	if not cue.is_empty():
		cue_age+=delta
		if cue=="steps" and cue_age>.48 and not second_step:second_step=true;world.sound.play_spatial("res://assets/audio/step_tile.wav",FOOT_B,-18,true)
		if cue_age>1.2:cue=""
	if Dialogue.active or world.cashier_open or world.surveillance_open:state().quiet_until=maxf(float(state().quiet_until),now+12)
	if world.presence!=null and is_instance_valid(world.presence.watcher) and world.presence.watcher.started:state().head_quiet=now+18
	if Session.flag("door_attempt") and not bool(state().rattle_seen):state().rattle_seen=true;state().quiet_until=maxf(float(state().quiet_until),now+25)
	if Session.campaign.phase not in ["saturday_investigation","saturday_decisions","closing"]:return
	if float(state().entered)<0:state().entered=now
	if bool(Session.campaign.clues.get("moved_boxes",false)) and float(state().inspected)<0:state().inspected=now
	if not base_safe() or now<float(state().quiet_until) or now<float(state().head_quiet) or is_instance_valid(figure):return
	if world.presence!=null and is_instance_valid(world.presence.watcher):return
	if not bool(state().shifted) and float(state().inspected)>=0 and now-float(state().inspected)>32 and can_shift():
		state().shifted=true;apply_board_shift();state().quiet_until=now+20;save();return
	var in_stock: bool=world.player.position.z< -11.6 and world.player.position.z> -15.6
	if not bool(state().steps) and in_stock and now-float(state().entered)>20 and not visible(FOOT_A):
		state().steps=true;state().last_sound=now;state().quiet_until=now+24;cue="steps";cue_age=0;second_step=false;world.sound.play_spatial("res://assets/audio/step_tile.wav",FOOT_A,-18,true);save();return
	if bool(state().steps) and not bool(state().cloth) and in_stock and now-float(state().last_sound)>34 and not visible(CLOTH):
		state().cloth=true;state().last_sound=now;state().quiet_until=now+25;cue="cloth";cue_age=0;world.sound.play_spatial("res://assets/audio/saturday/cloth_brush.ogg",CLOTH,-17,true);save();return
	if bool(state().face_used) or not bool(state().shifted) or not bool(state().cloth) or now-float(state().entered)<90 or now-float(state().last_sound)<35:return
	if not near_window() or not private_window():state().turn_wait=0.0;return
	if not window_visible():state().turn_wait=float(state().turn_wait)+delta
	if float(state().turn_wait)>.65:
		state().face_used=true;state().quiet_until=now+35;spawn_face();save()
