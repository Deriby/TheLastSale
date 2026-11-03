class_name FridayScares
extends Node
## Position-driven, persistent scares with short, nearby camera beats.
var world: ShiftWorld
var handle: Node3D
var drag: AudioStreamPlayer3D
var intruder: FrightIntruder
var bryan: FamiliarNPC
var pop_pose: ContactThreatPose
const BRYAN_HIDE:=Vector3(-5.25,0,-15.5)
const BRYAN_REVEAL:=Vector3(-5.25,0,-14.05)
const BRYAN_HOME:=Vector3(-2.8,0,-.1)
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
	elif is_instance_valid(bryan) and not state().prank.is_empty():
		bryan.position=world.navigation.restore_position(Session.read_position(state().prank.get("position"),bryan.position));bryan.reset_physics_interpolation()
		var phase:=str(state().prank.get("phase",""))
		if done("bryan_prank"):
			state().prank.phase="returning";move_bryan(BRYAN_HOME)
		else:
			# Older prank checkpoints resume by walking to the rear hiding place.
			if int(state().prank.get("revision",0))<38:phase="walking";state().prank.phase=phase
			state().prank.revision=41
			if phase=="walking":move_bryan(BRYAN_HIDE)
			elif phase=="emerging":move_bryan(BRYAN_REVEAL,4.0)
			elif phase=="rushing":move_bryan(Session.read_position(state().prank.get("goal"),BRYAN_REVEAL),4.4)
			else:state().prank.phase="hidden";bryan.scare_pose="crouch_idle"

	# Saves from the old public crossing must not recreate that staging.
	if state().intruder.get("state","") in ["crossing","hiding","leaving","emerging","waiting","retreating"]:
		state().intruder={"state":"gone","kind":"legacy_crossing"};state().events.intruder_gone=true;state().events.return_crossing=true;state().return_armed=false
	state().dim_time=0.0
	state().return_armed=false
func refresh_volume() -> void:
	if drag!=null:drag.volume_db=-13+linear_to_db(maxf(.00001,Preferences.effects_volume))
func blocks_ambient() -> bool:
	return state().door_phase in ["dragging","quiet","handle"] and world.player.position.z< -11.5 or state().prank.get("phase","") in ["cue","emerging","rushing","startled"] or is_instance_valid(intruder)
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
		tick_stock(delta)
	if Session.campaign.phase!="complete":tick_prank(delta)
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
			var point:=handle.global_position+Vector3(0,.04,.08)
			if not world.horror.focus("stock_handle",point,1.75,3.0):return
			state().door_phase="handle";state().door_time=0.0
			world.sound.play_spatial("res://assets/audio/scares/handle_rattle.ogg",handle.global_position,-3)
			mark("stock_handle","A maçaneta da porta antiga mexeu quando me aproximei. O arrasto do outro lado tinha acabado de parar.")
	elif state().door_phase=="handle":
		state().door_time+=delta
		handle.rotation.z=sin(float(state().door_time)*13)*.38*maxf(0,1-float(state().door_time)/2.0)
		if float(state().door_time)>2:state().door_phase="done";handle.rotation.z=0
func move_bryan(goal: Vector3,speed: float=1.45) -> void:
	if is_instance_valid(bryan):
		bryan.scare_pose="";bryan.scare_speed=speed
		bryan.motion.look_at_position(Vector3.ZERO,false)
		bryan.motion.attention.pitch_limit=.18;bryan.scare_look_at=Vector3.INF
		bryan.scare_goal=goal;bryan.scare_blocked=0.0
		var obstacles: Array[Rect2]=[Rect2(3.65,-11.0,.38,1.8),Rect2(-4.5,-14.35,1.4,1.1)]
		for crate in world.depot.crates.values():
			if is_instance_valid(crate) and crate!=world.player.carried:obstacles.append(Rect2(Vector2(crate.position.x-.29,crate.position.z-.24),Vector2(.58,.48)))
		for actor in world.characters.values():
			obstacles.append(Rect2(Vector2(actor.position.x-.25,actor.position.z-.25),Vector2(.5,.5)))
		var points: Array=[]
		if (bryan.position.z< -11)!=(goal.z< -11):
			points=[Vector3(4.85,0,-12.2),Vector3(4.85,0,-9.8)] if bryan.position.z< -11 else [Vector3(4.85,0,-9.8),Vector3(4.85,0,-12.2)]
		points.append(goal);bryan.scare_path.clear()
		var from:=bryan.position
		for point in points:
			bryan.scare_path.append_array(world.navigation.path_with_obstacles(from,point,obstacles));from=point
		bryan.scare_moving=true
func open_bryan_door() -> void:
	if bryan.position.distance_to(world.depot.stock_door.position+Vector3(.85,0,0))>2.8:return
	for child in world.depot.stock_door.get_children():
		if child is Interaction and child.kind=="door" and not child.open and not child.busy:child.activate(world.player)
func bryan_visible() -> bool:
	var head:=bryan.global_position+Vector3.UP*1.0
	return can_see(head) or can_see(bryan.global_position+Vector3.UP*.7)
func rush_bryan() -> bool:
	var player: DepotPlayer=world.characters.Dery
	var front:=(-player.camera_rig.global_basis.z*Vector3(1,0,1)).normalized()
	for radius in [1.60,1.45,1.80,1.10,.95,1.28]:
		for angle in [-.6,.6,0.0,-1.0,1.0]:
			var goal: Vector3=player.position+Basis(Vector3.UP,angle)*front*radius
			move_bryan(goal,4.4)
			if bryan.scare_path.is_empty():continue
			var end:=bryan.scare_path[-1]
			var distance:=end.distance_to(player.position)
			if distance<.78 or distance>1.90 or not player.camera_rig.camera.is_position_in_frustum(end+Vector3.UP*1.03) or not world.horror.clear_view(end+Vector3.UP*1.03):continue
			bryan.scare_goal=end;state().prank.goal=[end.x,end.y,end.z];return true
	bryan.scare_moving=false
	return false
func lunge_bryan() -> void:
	var player: DepotPlayer=world.characters.Dery
	var away:=((bryan.position-player.position)*Vector3(1,0,1)).normalized()
	var best:=PackedVector3Array();var score:=INF
	for radius in [.90,1.05,1.20]:
		for angle in [0.0,.5,-.5]:
			move_bryan(player.position+Basis(Vector3.UP,angle)*away*radius,4.4)
			if bryan.scare_path.is_empty():continue
			var end:=bryan.scare_path[-1];var distance:=end.distance_to(player.position)
			var length:=0.0;var previous:=bryan.position
			for point in bryan.scare_path:length+=previous.distance_to(point);previous=point
			if distance<.70 or distance>1.35 or length>1.25 or not world.horror.clear_view(end+Vector3.UP*1.03):continue
			if distance+length*.15<score:score=distance+length*.15;best=bryan.scare_path
	bryan.scare_path=best;bryan.scare_moving=not best.is_empty()
	if bryan.scare_moving:bryan.scare_goal=best[-1]
func tick_prank(delta: float) -> void:
	if not is_instance_valid(bryan) or bryan.leaving:return
	var phase: String=str(state().prank.get("phase",""))
	if phase=="" and Session.campaign.phase in ["routine","restored"] and done("stock_handle") and Session.world_seconds-float(state().last_event)>35 and safe() and world.player.position.z> -10:
		state().prank={"phase":"walking","time":0.0,"revision":41};move_bryan(BRYAN_HIDE);capture();Session.save_shift(world.player.position)
	elif phase=="walking":
		open_bryan_door()
		if not bryan.scare_moving:
			if bryan.position.distance_to(BRYAN_HIDE)>.25:move_bryan(BRYAN_HIDE)
			else:
				state().prank.phase="hidden";bryan.scare_pose="crouch_idle";capture();Session.save_shift(world.player.position)
	elif phase=="hidden":
		if world.player.identity!="Dery" or not safe() or not world.horror.ready_for(BRYAN_REVEAL+Vector3.UP,4.1):return
		if world.player.position.z> -12.1:return
		# A short scuff comes from cover; the camera does not announce the hiding place.
		var point:=BRYAN_REVEAL+Vector3.UP*.9
		if not world.horror.clear_view(point):return
		state().prank.phase="cue";state().prank.time=0.0
		world.sound.play_spatial("res://assets/audio/saturday/cloth_brush.ogg",BRYAN_HIDE,-9,true)
	elif phase=="cue":
		state().prank.time=float(state().prank.get("time",0))+delta
		if float(state().prank.time)>.18:state().prank.phase="emerging";state().prank.time=0.0;move_bryan(BRYAN_REVEAL,4.0)
	elif phase=="emerging":
		state().prank.time=float(state().prank.get("time",0))+delta
		if bryan.position.distance_to(BRYAN_REVEAL)<.35 and world.player.identity=="Dery" and world.player.position.distance_to(bryan.position)<4.4 and not world.horror.busy():
			if rush_bryan():state().prank.phase="rushing";state().prank.time=0.0
		elif float(state().prank.time)>5.0:state().prank.phase="walking";move_bryan(BRYAN_HIDE)
	elif phase=="rushing":
		state().prank.time=float(state().prank.get("time",0))+delta
		if world.player.identity=="Dery" and bryan.position.distance_to(world.player.position)<1.78 and bryan_visible() and not world.horror.busy():
			if not world.horror.focus("bryan_jump",bryan.position+Vector3.UP*1.03,1.25,2.1):return
			lunge_bryan();bryan.scare_pose="talk"
			var toward:=world.player.position-bryan.position;bryan.visual.rotation.y=atan2(toward.x,toward.z)
			state().prank.phase="startled";state().prank.time=0.0;state().prank.hit=false
			pop_pose=ContactThreatPose.new();pop_pose.pose_enabled=false;bryan.motion.skeleton.add_child(pop_pose)
			bryan.scare_look_at=world.player.position;bryan.motion.attention.pitch_limit=.50
			bryan.motion.look_at_position(world.player.camera_rig.camera.global_position)
			var local:=bryan.visual.global_basis.inverse()*(world.player.camera_rig.camera.global_position-(bryan.visual.global_position+Vector3.UP*bryan.motion.attention.eye_height))
			bryan.motion.attention.pitch=clampf(-atan2(local.y,maxf(.1,Vector2(local.x,local.z).length())),-.50,.50)
			bryan.motion.attention.yaw=clampf(atan2(local.x,local.z),-.65,.65)
			world.horror.follow_contact(bryan.motion.skeleton,pop_pose)
			mark("bryan_prank","Bryan se escondeu atrás das caixas nos fundos para dar um susto em Deryk.")
		elif float(state().prank.time)>5.0:
			# An interrupted approach may be retried; do not consume an unseen joke.
			state().prank.phase="walking";move_bryan(BRYAN_HIDE)
	elif phase=="startled":
		state().prank.time=float(state().prank.get("time",0))+delta
		var age: float=state().prank.time
		bryan.scare_look_at=world.player.position
		if age>.28 or bryan.position.distance_to(world.player.position)<1.30:bryan.scare_moving=false;bryan.velocity=Vector3.ZERO
		if age>.10 and not bool(state().prank.get("hit",false)):
			state().prank.hit=true;world.horror.contact_hit(.72,.10);world.sound.play_spatial("res://assets/audio/scares/bryan_pop.ogg",bryan.position+Vector3.UP*.7,0)
		if is_instance_valid(pop_pose):
			bryan.motion.look_at_position(world.player.camera_rig.camera.global_position)
			pop_pose.amount=smoothstep(0,.08,age)*(1.0-smoothstep(.32,.68,age))*.85
			if age>1.30:pop_pose.queue_free()
		if age>.68 and not bool(state().prank.get("relief",false)):
			state().prank.relief=true;world.notice.emit("Bryan: BU! Hahaha! Te peguei, Deryk!")
		if float(state().prank.time)>3.5:state().prank.phase="returning";move_bryan(BRYAN_HOME)
	elif phase=="returning":
		open_bryan_door()
		if not bryan.scare_moving:state().prank.phase="done"
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
	if is_instance_valid(bryan) and state().prank.get("phase","") in ["walking","hidden","cue","emerging","rushing","startled","returning"]:state().prank.position=[bryan.position.x,bryan.position.y,bryan.position.z]
func on_completed(id: String) -> void:
	if id=="familiar_Bryan" and done("bryan_prank") and not done("bryan_left"):
		mark("bryan_left")
		if is_instance_valid(bryan):bryan.scare_moving=false;bryan.depart(world.navigation.path(bryan.position,Vector3(18,0,1.8)))
func stop_all() -> void:
	if is_instance_valid(drag):drag.stop();drag.stream=null
func _exit_tree() -> void:stop_all()
