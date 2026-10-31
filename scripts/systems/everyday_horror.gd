class_name EverydayHorror
extends Node
## Optional, persistent environmental beats. Sales, power and investigation remain
## action-driven; an observed person always leaves through the actual street.
const ROUTINE_SECONDS:=300.0
var world: ShiftWorld
var observer: QuietObserver
var scan_wait:=0.0
var scan_elapsed:=0.0
var present_time:=0.0
var unseen_time:=0.0
var watched_camera: Camera3D
func state() -> Dictionary:return Session.campaign.experience
func done(id: String) -> bool:return bool(state().events.get(id,false))
func _ready() -> void:
	Dialogue.spoken.connect(on_spoken)
	if int(Session.campaign.night)<2 and state().observer.get("state","") in ["standing","leaving"]:spawn_observer(state().observer)
	world.sound.set_engine_active(done("car_waiting") and Session.campaign.phase in ["routine","saturday_routine"])
func record(id: String,text: String="") -> bool:
	if done(id):return false
	state().events[id]=true
	state().event_times[id]=Session.world_seconds
	if world.story!=null:world.story.remember(id)
	if not text.is_empty():state().notes.append({"id":str(Session.campaign.night)+":"+id,"night":int(Session.campaign.night),"time":Session.clock_text(),"text":text})
	Session.changed.emit()
	if world.active:Session.save_shift(world.player.global_position)
	return true
func warning_ready() -> bool:return Session.world_seconds>=ROUTINE_SECONDS
func safe_to_speak() -> bool:
	if world.scary!=null and world.scary.blocks_ambient():return false
	if Dialogue.active or world.cashier_open or world.surveillance_open or world.sunday.desk_open:return false
	for actor in world.characters.values():
		if actor.motion.action_active or actor.handling.busy:return false
	return true
func tick(delta: float) -> void:
	if not world.active:return
	var routine: bool=int(Session.campaign.night)<2 and Session.campaign.phase in ["routine","saturday_routine","saturday_investigation"]
	if not routine:
		world.sound.set_engine_active(false)
		if is_instance_valid(observer):observer.depart()
		return
	scan_wait-=delta;scan_elapsed+=delta
	if scan_wait>0:return
	var elapsed:=scan_elapsed;scan_elapsed=0;scan_wait=.2
	var seconds:=Session.world_seconds
	if Session.stage>0 and seconds>=85 and not done("car_waiting"):
		record("car_waiting");world.sound.set_engine_active(true)
	if done("car_waiting") and not done("car_noticed") and seconds-float(state().event_times.get("car_waiting",seconds))>=40 and world.player.position.z>-.5 and world.player.position.distance_to(Vector3(3,1,9.55))<16:
		record("car_noticed","Um carro ficou ligado em frente ao depósito por bastante tempo.")
	if int(Session.campaign.night)==0 and seconds>=150 and Session.stage in [1,2,3,4] and not done("empty_chime") and safe_to_speak():
		var dery: DepotPlayer=world.characters.Dery;var felps: DepotPlayer=world.characters.Felps
		var no_arrival:=not is_instance_valid(world.customer) or world.customer.state in [Customer.State.WAITING,Customer.State.PAYING]
		if dery.position.z< -11.5 and felps.position.distance_to(CheckoutFixture.STAFF_POSITION)<1.5 and no_arrival:
			record("empty_chime","O sino tocou com Deryk no estoque. Felps achou que ele tinha voltado.")
			world.sound.play_spatial("res://assets/audio/everyday/entry_chime.ogg",Vector3(.7,2.1,.1),-8)
			Dialogue.play("everyday_empty_chime",[["Felps","Já voltou?"],["Dery","Tô no estoque ainda."],["Felps","... Tá. Achei que tinha entrado alguém."]])
	if seconds>=215 and not done("stock_steps") and safe_to_speak() and world.player.position.z> -8 and world.player.position.z< -2:
		record("stock_steps","Ouvi passos curtos vindos dos fundos do depósito.")
		world.sound.play_spatial("res://assets/audio/everyday/stock_steps.ogg",Vector3(-.8,.15,-14.4),-13,true)
	if seconds>=225 and Session.customers_served>0 and not done("observer_arrived") and safe_to_speak():
		# Introduce him while the active view faces the shop, rather than creating
		# a visible person in the middle of an already watched street.
		if can_introduce_observer():
			spawn_observer();record("observer_arrived")
	if is_instance_valid(observer):
		present_time+=elapsed
		var feed_active:=world.surveillance_open and is_instance_valid(watched_camera)
		var camera: Camera3D=watched_camera if feed_active else world.player.camera_rig.camera
		var visible:=not world.cashier_open and (feed_active or not world.surveillance_open and world.player.position.z> -3.5) and can_see(camera)
		if visible:observe_view(camera)
		unseen_time=0.0 if visible else unseen_time+elapsed
		if done("observer_seen") and present_time>18 and (unseen_time>2 or present_time>38 or world.player.position.distance_to(observer.position)<7):
			if not observer.leaving:observer.depart();record("observer_leaving")
	state().tension=maxf(float(state().tension),.45 if done("observer_seen") else .3 if done("empty_chime") else .12 if done("car_noticed") else 0.0)
func spawn_observer(saved: Dictionary={}) -> void:
	if is_instance_valid(observer) or int(Session.campaign.night)>1:return
	observer=QuietObserver.new();observer.name="PersonAcrossStreet";observer.navigation=world.navigation
	observer.position=world.navigation.nearest_walkable(Vector3(5.4,0,11.4));world.add_child(observer)
	if not saved.is_empty():observer.restore(saved)
	present_time=float(saved.get("present_time",0));unseen_time=float(saved.get("unseen_time",0))
	observer.left.connect(func():state().observer={"state":"gone"};record("observer_gone"))
	capture()
func can_see(camera: Camera3D) -> bool:
	if not is_instance_valid(observer) or camera==null:return false
	var at:=observer.global_position+Vector3.UP*1.65
	if not camera.is_position_in_frustum(at):return false
	var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,at,1)
	return world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func can_introduce_observer() -> bool:
	var at:=world.navigation.nearest_walkable(Vector3(5.4,0,11.4))+Vector3.UP*1.65
	var camera:=world.player.camera_rig.camera
	if not camera.is_position_in_frustum(at):return true
	return not world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,at,1)).is_empty()
func observe_view(camera: Camera3D) -> void:
	if not can_see(camera) or done("observer_seen"):return
	var feed:=world.surveillance_open
	record("observer_seen","No canal da fachada, vi alguém parado do outro lado da rua." if feed else "Vi uma pessoa parada do outro lado da rua, olhando na direção da loja.")
func capture() -> void:
	if done("observer_gone"):state().observer={"state":"gone"}
	elif is_instance_valid(observer):
		state().observer=observer.snapshot();state().observer.present_time=present_time;state().observer.unseen_time=unseen_time
func on_spoken(who: String,_text: String) -> void:
	var person: Node3D=world.characters.get("Dery" if who=="Deryk" else who)
	if (who.begins_with("Cliente") or who=="Senhora") and is_instance_valid(world.customer):person=world.customer
	if who in ["Bryan","Zirico"]:
		for friend in get_tree().get_nodes_in_group("familiar_npcs"):
			if friend.identity==who:person=friend;break
	for actor in world.characters.values():
		actor.social_focus_enabled=is_instance_valid(person) and person!=actor and actor.position.distance_to(person.position)<5
		if actor.social_focus_enabled:actor.social_focus=person.global_position+Vector3.UP*1.55
