class_name FridayScares
extends Node
## Position-driven, persistent scares. No camera writes or mandatory new tasks.
var world: ShiftWorld
var handle: Node3D
var drag: AudioStreamPlayer3D
var intruder: FrightIntruder
var bryan: FamiliarNPC
const WINDOW:=Vector3(-3.0,0,.80)
func state() -> Dictionary:return Session.campaign.friday_scares
func done(id: String) -> bool:return bool(state().events.get(id,false))
func mark(id: String,note: String="") -> void:
	if done(id):return
	state().events[id]=true;state().last_event=Session.world_seconds
	if id in ["stock_handle","bryan_prank","return_crossing"]:state().last_scare=Session.world_seconds
	if not note.is_empty():world.everyday.record(id,note)
	Session.changed.emit()
	if world.active:Session.save_shift(world.player.global_position)
func _ready() -> void:
	handle=Node3D.new();handle.name="OldDoorHandlePivot";world.depot.old_door.add_child(handle);handle.position=Vector3(.44+(.65 if int(Session.campaign.night)==2 else 0),1.05,.10)
	Geo.box(handle,Vector3.ZERO,Vector3(.055,.20,.025),Geo.material(Color("aaa88d")),false)
	Geo.box(handle,Vector3(-.075,0,.035),Vector3(.18,.032,.045),Geo.material(Color("aaa88d")),false)
	drag=AudioStreamPlayer3D.new();world.sound.add_child(drag);drag.set_meta("loop_base_db",-13);drag.set_meta("music_loop",false);world.sound.loop_players.append(drag);drag.position=world.depot.old_door.global_position+Vector3(0,.25,0);drag.max_distance=12;drag.unit_size=2.5
	var stream: AudioStreamOggVorbis=load("res://assets/audio/scares/stock_drag.ogg").duplicate();stream.loop=true;drag.stream=stream;drag.attenuation_filter_cutoff_hz=2100
	Preferences.changed.connect(refresh_volume);refresh_volume();Dialogue.completed.connect(on_completed)
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		if friend.identity=="Bryan" and not friend.is_queued_for_deletion():bryan=friend
	if int(Session.campaign.night)!=0:return
	restore_glimpse_doors()
	if done("bryan_left") and is_instance_valid(bryan):bryan.queue_free();bryan=null
	elif is_instance_valid(bryan) and state().prank.get("phase","") in ["walking","waiting","returning"]:
		bryan.position=world.navigation.restore_position(Session.read_position(state().prank.get("position"),bryan.position));bryan.reset_physics_interpolation()
		if state().prank.phase!="waiting":move_bryan(WINDOW if state().prank.phase=="walking" else Vector3(-2.8,0,-.1))
		else:bryan.scare_pose="talk" if done("bryan_prank") else "idle"
	# Saves from the old public crossing must not recreate that staging.
	if state().intruder.get("state","") in ["crossing","hiding","leaving","emerging","waiting","retreating"]:
		state().intruder={"state":"gone","kind":"legacy_crossing"};state().events.intruder_gone=true;state().events.return_crossing=true;state().return_armed=false
	state().dim_time=0.0
	state().return_armed=false
func refresh_volume() -> void:
	if drag!=null:drag.volume_db=-13+linear_to_db(maxf(.001,Preferences.effects_volume))
func blocks_ambient() -> bool:
	return state().door_phase in ["dragging","quiet","handle"] and world.player.position.z< -11.5 or state().prank.get("phase","")=="waiting" and done("bryan_prank") or is_instance_valid(intruder)
func safe() -> bool:
	if Dialogue.active or world.cashier_open or world.surveillance_open or world.sunday.desk_open or world.friday.finishing:return false
	for actor in world.characters.values():
		if actor.motion.action_active or actor.handling.busy:return false
	return true
func can_see(point: Vector3) -> bool:
	var camera:=world.player.camera_rig.camera
	if not camera.is_position_in_frustum(point):return false
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1)).is_empty()
func body_points(at: Vector3) -> Array[Vector3]:
	return [at+Vector3(0,1.7,0),at+Vector3(.38,1.4,0),at+Vector3(-.38,1.4,0),at+Vector3(.38,.75,0),at+Vector3(-.38,.75,0),at+Vector3(0,.25,0)]
func player_sees_body(at: Vector3) -> bool:
	for point in body_points(at):
		if can_see(point):return true
	return false
func other_witnesses(at: Vector3) -> bool:
	for group in ["protagonists","customers","familiar_npcs"]:
		for person in get_tree().get_nodes_in_group(group):
			if person==world.player or person.is_queued_for_deletion():continue
			if person.global_position.distance_to(at)<3.5:return true
			var toward: Vector3=((at-person.global_position)*Vector3(1,0,1)).normalized()
			# Body orientation provides a broad peripheral cone for background NPCs.
			if person.visual.global_basis.z.normalized().dot(toward)<.35:continue
			var eye: Vector3=person.global_position+Vector3.UP*(1.0 if person.get("identity")=="Bryan" else 1.55)
			for point in body_points(at):
				if world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,point,1)).is_empty():return true
	return false
func tick(delta: float) -> void:
	if not world.active or int(Session.campaign.night)!=0 or drag.stream==null:return
	if Session.campaign.phase!="routine":
		drag.stop()
		if state().door_phase in ["dragging","quiet","handle"]:state().door_phase="done";handle.rotation.z=0
	else:
		tick_stock(delta);tick_prank(delta)
func tick_stock(delta: float) -> void:
	var dery: DepotPlayer=world.characters.Dery
	if dery.position.z>=-11.5:drag.stop();return
	# Preserve the already published empty-entry chime when the first stock
	# visit happens late; the handle sequence can begin after that dialogue.
	if state().door_phase=="" and Session.world_seconds>=145 and not world.everyday.done("empty_chime"):return
	if state().door_phase=="" and Session.stage in [1,2,3,4] and Session.world_seconds>=55 and world.player==dery and dery.position.z< -11.7 and safe():
		state().door_phase="dragging";state().door_time=0.0;mark("stock_drag");drag.play()
	if state().door_phase=="dragging":
		if not drag.playing and dery.position.z< -11.5:drag.play()
		state().door_time+=delta
		if dery.position.distance_to(world.depot.old_door.global_position)<2.35 and float(state().door_time)>1.2:
			drag.stop();state().door_phase="quiet";state().door_time=0.0
	elif state().door_phase=="quiet":
		state().door_time+=delta
		if float(state().door_time)>.55:
			state().door_phase="handle";state().door_time=0.0
			world.sound.play_spatial("res://assets/audio/scares/handle_rattle.ogg",handle.global_position,-3)
			mark("stock_handle","A maçaneta da porta antiga mexeu quando me aproximei. O arrasto do outro lado tinha acabado de parar.")
	elif state().door_phase=="handle":
		state().door_time+=delta
		handle.rotation.z=sin(float(state().door_time)*13)*.38*maxf(0,1-float(state().door_time)/2.0)
		if float(state().door_time)>2:state().door_phase="done";handle.rotation.z=0
func move_bryan(goal: Vector3) -> void:
	if is_instance_valid(bryan):bryan.scare_pose="";bryan.scare_path=world.navigation.path(bryan.global_position,goal);bryan.scare_moving=true
func tick_prank(delta: float) -> void:
	if not is_instance_valid(bryan) or bryan.leaving:return
	var phase: String=str(state().prank.get("phase",""))
	if phase=="" and done("stock_handle") and Session.world_seconds-float(state().last_event)>35 and safe() and world.player.position.z> -5 and world.player.position.distance_to(WINDOW)<8:
		state().prank={"phase":"walking","time":0.0};move_bryan(WINDOW);capture();Session.save_shift(world.player.position)
	elif phase=="walking" and not bryan.scare_moving:
		if bryan.position.distance_to(WINDOW)>.55:move_bryan(WINDOW)
		else:state().prank.phase="waiting";state().prank.time=0.0;bryan.scare_pose="idle"
	elif phase=="waiting":
		if not done("bryan_prank") and safe() and world.player.position.distance_to(WINDOW)<8 and world.player.camera_rig.camera.is_position_in_frustum(bryan.position+Vector3.UP*1.0):
			bryan.visual.rotation.y=PI;bryan.scare_pose="talk";world.sound.play_spatial("res://assets/audio/scares/glass_tap.ogg",bryan.position+Vector3.UP,2)
			mark("bryan_prank","A batida na vitrine era Bryan fazendo uma brincadeira.");world.notice.emit("Bryan: hahaha! Cês tinham que ver a cara de vocês!")
		if done("bryan_prank"):
			state().prank.time=float(state().prank.get("time",0))+delta
			if float(state().prank.time)>4:state().prank.phase="returning";move_bryan(Vector3(-2.8,0,-.1))
	elif phase=="returning" and not bryan.scare_moving:state().prank.phase="done"
func arm_return() -> void:
	# The new watching opportunities have their own silent, non-narrative schedule.
	state().return_armed=false
func tick_return() -> void:
	if done("return_crossing") or not safe() or world.player.identity!="Dery" or world.player.carried!=null:return
	if Session.world_seconds-float(state().last_scare)<25:return
	var at:=world.player.position
	if at.z< -9.0 or at.z> -5.5 or at.x<2.7:return
	var open:=false
	for child in world.depot.stock_door.get_children():
		if child is Interaction and child.kind=="door":open=child.open and not child.busy
	if not open or other_witnesses(FrightIntruder.EDGE) or player_sees_body(FrightIntruder.HIDDEN):return
	var camera:=world.player.camera_rig.camera
	var point:=FrightIntruder.EDGE+Vector3(.2,1.5,0)
	if not can_see(point):return
	var screen: Vector2=camera.unproject_position(point)/camera.get_viewport().get_visible_rect().size
	# A chance glance at the edge of the view, rather than a centred reveal.
	if screen.x<.16 or screen.x>.84 or absf(screen.x-.5)<.14:return
	state().events.quiet_return=true;state().return_armed=false;spawn_intruder();mark("return_crossing")
func spawn_intruder(saved: Dictionary={}) -> void:
	if is_instance_valid(intruder):return
	intruder=FrightIntruder.new();intruder.world=world;intruder.name="FridayIntruder";intruder.position=FrightIntruder.HIDDEN;world.add_child(intruder)
	if not saved.is_empty():intruder.restore(saved)
	intruder.departed.connect(func():
		state().intruder={"state":"gone","kind":"stock_glimpse"}
		if done("return_intruder"):state().events.return_aftermath=true
		mark("intruder_gone"))
	capture()
func restore_glimpse_doors() -> void:
	var doors: Dictionary=state().get("quiet_doors",{})
	for door in [world.depot.stock_door,world.depot.service_door]:
		var data: Dictionary=doors.get(str(door.name),{})
		if data.is_empty():continue
		for child in door.get_children():
			if not child is Interaction or child.kind!="door":continue
			child.open=bool(data.get("open",false))
			var target: float=(1.45 if child.identity=="service" else -1.45) if child.open else 0.0
			door.rotation.y=clampf(float(data.get("angle",target)),-1.45,1.45)
			if absf(door.rotation.y-target)>.01:
				child.busy=true
				child.create_tween().tween_property(door,"rotation:y",target,.5*absf(door.rotation.y-target)/1.45).finished.connect(func():child.busy=false)
func capture() -> void:
	if done("quiet_return"):
		state().quiet_doors={}
		for door in [world.depot.stock_door,world.depot.service_door]:
			for child in door.get_children():
				if child is Interaction and child.kind=="door":state().quiet_doors[str(door.name)]={"open":child.open,"angle":door.rotation.y}
	if done("intruder_gone"):state().intruder={"state":"gone"}
	elif is_instance_valid(intruder):state().intruder=intruder.snapshot()
	if is_instance_valid(bryan) and state().prank.get("phase","") in ["walking","waiting","returning"]:state().prank.position=[bryan.position.x,bryan.position.y,bryan.position.z]
func on_completed(id: String) -> void:
	if id=="familiar_Bryan" and done("bryan_prank") and not done("bryan_left"):
		mark("bryan_left")
		if is_instance_valid(bryan):bryan.scare_moving=false;bryan.depart(world.navigation.path(bryan.position,Vector3(18,0,1.8)))
func stop_all() -> void:
	if is_instance_valid(drag):drag.stop();drag.stream=null
func _exit_tree() -> void:stop_all()
