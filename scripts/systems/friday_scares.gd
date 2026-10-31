class_name FridayScares
extends Node
## Position-driven, persistent scares. No camera writes or mandatory new tasks.
var world: ShiftWorld
var handle: Node3D
var drag: AudioStreamPlayer3D
var intruder: FrightIntruder
var bryan: FamiliarNPC
var ceiling: Array[Dictionary]=[]
var dim_remaining:=0.0
const WINDOW:=Vector3(-3.0,0,.80)
const START:=Vector3(-4.35,0,-8.5)
const CROSS_POINT:=Vector3(4.2,1.4,-8.5)
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
	for light in world.friday.lights:
		if light.name in ["CeilingFill","CeilingPool"]:ceiling.append({"light":light,"energy":light.light_energy})
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		if friend.identity=="Bryan" and not friend.is_queued_for_deletion():bryan=friend
	if int(Session.campaign.night)!=0:return
	dim_remaining=float(state().dim_time)
	if done("bryan_left") and is_instance_valid(bryan):bryan.queue_free();bryan=null
	elif is_instance_valid(bryan) and state().prank.get("phase","") in ["walking","waiting","returning"]:
		bryan.position=world.navigation.restore_position(Session.read_position(state().prank.get("position"),bryan.position));bryan.reset_physics_interpolation()
		if state().prank.phase!="waiting":move_bryan(WINDOW if state().prank.phase=="walking" else Vector3(-2.8,0,-.1))
		else:bryan.scare_pose="talk" if done("bryan_prank") else "idle"
	if state().intruder.get("state","") in ["crossing","hiding","leaving"]:spawn_intruder(state().intruder)
	if Session.flag("generator_running") and Session.campaign.phase=="restored" and not done("return_crossing"):state().return_armed=true
func refresh_volume() -> void:
	if drag!=null:drag.volume_db=-13+linear_to_db(maxf(.001,Preferences.effects_volume))
func blocks_ambient() -> bool:
	return state().door_phase in ["dragging","quiet","handle"] and world.player.position.z< -11.5 or state().prank.get("phase","")=="waiting" and done("bryan_prank") or is_instance_valid(intruder) and intruder.state=="crossing"
func safe() -> bool:
	if Dialogue.active or world.cashier_open or world.surveillance_open or world.sunday.desk_open or world.friday.finishing:return false
	for actor in world.characters.values():
		if actor.motion.action_active or actor.handling.busy:return false
	return true
func can_see(point: Vector3) -> bool:
	var camera:=world.player.camera_rig.camera
	if not camera.is_position_in_frustum(point):return false
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1)).is_empty()
func tick(delta: float) -> void:
	if not world.active or int(Session.campaign.night)!=0 or drag.stream==null:return
	update_dim(delta)
	if Session.campaign.phase!="routine":
		drag.stop()
		if state().door_phase in ["dragging","quiet","handle"]:state().door_phase="done";handle.rotation.z=0
	else:
		tick_stock(delta);tick_prank(delta)
	if bool(state().return_armed) and Session.campaign.phase in ["restored","closing"]:tick_return()
	if is_instance_valid(intruder):
		if not done("return_intruder") and safe() and can_see(intruder.global_position+Vector3.UP*1.5):mark("return_intruder","Vi uma pessoa atravessar o salão depois de ligar o gerador. Ela seguiu em direção ao estoque.")
		# The door opens into the yard: clear its full sweep before closing it.
		if intruder.position.z< -18.15 and not done("yard_slam"):try_slam()
		if done("return_intruder") and intruder.state in ["hiding","leaving"] and not done("return_aftermath") and safe():
			mark("return_aftermath");Dialogue.play("friday_return_aftermath",[["Dery","Felps! Quem era aquele cara?"],["Felps","Que cara?"],["Dery","Passou aqui. Foi pros fundos."],["Felps","Não vi ninguém passar pela frente. Volta pra cá. Não vai atrás sozinho."]])
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
	if int(Session.campaign.night)==0 and not done("return_crossing"):state().return_armed=true
func tick_return() -> void:
	if done("return_crossing") or not safe() or world.player.identity!="Dery" or world.player.carried!=null:return
	if Session.world_seconds-float(state().last_scare)<25:return
	var at:=world.player.position
	if at.z< -9.15 or at.z> -5.5:return
	if not done("return_cue"):world.sound.play_spatial("res://assets/audio/everyday/stock_steps.ogg",Vector3(-2.7,.1,-9.2),-15,true);mark("return_cue")
	# The actor enters from outside the clear view and crosses a visible aisle.
	if not can_see(CROSS_POINT) or can_see(START+Vector3.UP*1.5):return
	mark("return_crossing");state().return_armed=false;spawn_intruder();dim_remaining=3.4;Session.save_shift(world.player.position)
func spawn_intruder(saved: Dictionary={}) -> void:
	if is_instance_valid(intruder):return
	intruder=FrightIntruder.new();intruder.world=world;intruder.name="FridayIntruder";intruder.position=world.navigation.nearest_walkable(START);world.add_child(intruder)
	if not saved.is_empty():intruder.restore(saved)
	intruder.departed.connect(func():state().intruder={"state":"gone"};mark("intruder_gone"))
	capture()
func try_slam() -> void:
	var door:=world.depot.service_door
	for actor in world.characters.values():
		if actor.position.distance_to(door.global_position+Vector3(.85,0,0))<2.5:return
	if is_instance_valid(world.customer) and world.customer.position.distance_to(door.global_position)<2:return
	for child in door.get_children():
		if child is Interaction and child.kind=="door" and not child.busy:
			if child.open and not child.activate(intruder):return
			world.sound.play_spatial("res://assets/audio/scares/door_slam.ogg",door.global_position+Vector3.UP,3);mark("yard_slam");return
func update_dim(delta: float) -> void:
	dim_remaining=maxf(0,dim_remaining-delta)
	var factor:=.28 if dim_remaining>.7 else lerpf(1.0,.28,dim_remaining/.7)
	for data in ceiling:
		if is_instance_valid(data.light):data.light.light_energy=float(data.energy)*factor
func capture() -> void:
	state().dim_time=dim_remaining
	if done("intruder_gone"):state().intruder={"state":"gone"}
	elif is_instance_valid(intruder):state().intruder=intruder.snapshot()
	if is_instance_valid(bryan) and state().prank.get("phase","") in ["walking","waiting","returning"]:state().prank.position=[bryan.position.x,bryan.position.y,bryan.position.z]
func on_completed(id: String) -> void:
	if id=="familiar_Bryan" and done("bryan_prank") and not done("bryan_left"):
		mark("bryan_left")
		if is_instance_valid(bryan):bryan.scare_moving=false;bryan.depart(world.navigation.path(bryan.position,Vector3(18,0,1.8)))
func stop_all() -> void:
	if is_instance_valid(drag):drag.stop();drag.stream=null
	dim_remaining=0;update_dim(0)
func _exit_tree() -> void:stop_all()
