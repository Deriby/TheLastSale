class_name ShiftWorld
extends Node3D
signal slice_finished
signal player_changed(actor: DepotPlayer)
signal notice(text: String)
var characters: Dictionary={}
var depot: Depot
var street: Street
var player: DepotPlayer
var navigation: AisleNavigation
var sound: Soundscape
var customer: Customer
var spawn_wait:=9.0
var active:=false
var warning_started:=false
var noise_pending:=false
var enemy_visual: Node3D
func _ready() -> void:
	add_to_group("shift_world")
	var legacy_carried:=Session.carried_id
	var env:=WorldEnvironment.new();env.name="Atmosphere";env.environment=Environment.new()
	NightAtmosphere.configure(env.environment)
	add_child(env)
	var moon:=DirectionalLight3D.new();moon.name="MoonFill";add_child(moon);moon.rotation_degrees=Vector3(-43,-24,0);moon.light_color=Color("8c9fb7");moon.light_energy=.055
	street=Street.new();street.name="Street";add_child(street)
	depot=Depot.new();depot.name="Depot";add_child(depot)
	var reflection:=ReflectionProbe.new();reflection.name="StreetReflection";reflection.position=Vector3(3,1.3,6.6);reflection.size=Vector3(27,9,24);reflection.max_distance=48;reflection.box_projection=true;reflection.cull_mask=6;reflection.reflection_mask=8;add_child(reflection)
	var cabinet_reflection:=ReflectionProbe.new();cabinet_reflection.name="CabinetReflection"
	cabinet_reflection.position=Vector3(-1.1,1.55,-7.5);cabinet_reflection.size=Vector3(11.3,3.4,8.4);cabinet_reflection.max_distance=16
	cabinet_reflection.box_projection=true;cabinet_reflection.interior=true
	cabinet_reflection.ambient_mode=ReflectionProbe.AMBIENT_DISABLED;cabinet_reflection.intensity=.45
	cabinet_reflection.cull_mask=1;cabinet_reflection.reflection_mask=16;cabinet_reflection.update_mode=ReflectionProbe.UPDATE_ONCE
	add_child(cabinet_reflection);cabinet_reflection.add_to_group("detail_reflections")
	var mood:=NightAtmosphere.new();mood.name="NightMood";mood.environment=env.environment;mood.moon=moon;add_child(mood)
	navigation=AisleNavigation.new();navigation.configure(depot.blockers+street.blockers,Street.surface_height)
	player=DepotPlayer.new();player.name="Dery";add_child(player)
	characters={"Dery":player,"Felps":depot.felps}
	for identity in characters:
		var actor: DepotPlayer=characters[identity]
		var state: Dictionary=Session.character_states.get(identity,{})
		var fallback:=Session.saved_position if identity=="Dery" else CheckoutFixture.STAFF_POSITION
		actor.global_position=navigation.restore_position(Session.read_position(state.get("position"),fallback))
		actor.visual.rotation.y=float(state.get("facing",PI if identity=="Dery" else PI/2))
		actor.camera_rig.yaw=float(state.get("yaw",0 if identity=="Dery" else -PI/2))
		actor.camera_rig.pitch=float(state.get("pitch",-.12))
		actor.camera_rig.target_distance=float(state.get("camera_distance",Preferences.camera_distance));actor.camera_rig.distance=actor.camera_rig.target_distance
		actor.torch.visible=bool(state.get("torch",false)) and Session.stage>=6
		actor.reset_physics_interpolation()
		actor.handling.completed.connect(on_handling_completed)
		actor.handling.feedback.connect(func(text: String):notice.emit(text))
		actor.set_controlled(false)
	var talk:=depot.interact(characters.Dery,"talk","Dery");characters.Dery.set_meta("interaction",talk)
	select_player(Session.active_character)
	sound=Soundscape.new();add_child(sound)
	depot.restore_state(player)
	for identity in characters:
		var actor: DepotPlayer=characters[identity]
		var state: Dictionary=Session.character_states.get(identity,{})
		var carried: String=str(state.get("carried",legacy_carried if identity==Session.active_character else ""))
		if depot.crates.has(carried) and carried not in Session.stocked and not (carried=="loose" and Session.organized):actor.pick_up(depot.crates[carried],carried,true)
	Session.saving.connect(capture_state)
	for identity in ["Bryan","Zirico"]:
		var friend:=FamiliarNPC.new();friend.identity=identity;friend.name=identity;add_child(friend)
		var at:=Vector3(-2.8,0,-.1) if identity=="Bryan" else Vector3(5.1,0,1.65)
		friend.position=navigation.nearest_walkable(at);friend.visual.rotation.y=PI/2 if identity=="Bryan" else -PI/2
		friend.reset_physics_interpolation()
	Session.event_triggered.connect(on_event)
	Dialogue.completed.connect(on_dialogue_completed)
	# Enemy is present only for a later, spatially continuous glimpse; no early chase.
	enemy_visual=CharacterModels.create("Enemy");add_child(enemy_visual);enemy_visual.position=Vector3(10,0,15);enemy_visual.visible=false
	enemy_visual.visibility_changed.connect(update_enemy_visibility);update_enemy_visibility()
	var anim: AnimationPlayer=enemy_visual.find_child("AnimationPlayer",true,false)
	if anim:
		for key in anim.get_animation_list():
			if key.contains("idle"):anim.get_animation(key).loop_mode=Animation.LOOP_LINEAR;anim.play(key)
func update_enemy_visibility() -> void:
	enemy_visual.process_mode=Node.PROCESS_MODE_INHERIT if enemy_visual.is_visible_in_tree() else Node.PROCESS_MODE_DISABLED
func select_player(identity: String) -> void:
	for actor in characters.values():actor.set_controlled(false)
	player=characters.get(identity,characters.Dery);player.set_controlled(true)
	Session.active_character=player.identity;Session.carried_id=player.carried_id
	depot.set_counter_role(player.identity);player_changed.emit(player)
func switch_player() -> bool:
	if not active or get_tree().paused:return false
	if Dialogue.active:
		notice.emit("Termine a conversa antes de trocar de personagem.");return false
	for actor in characters.values():
		if actor.motion.action_active or actor.handling.busy:
			notice.emit("Espere terminar de movimentar a caixa.");return false
	capture_state();select_player("Felps" if player.identity=="Dery" else "Dery")
	Session.save_shift(player.global_position)
	return true
func capture_state() -> void:
	for identity in characters:
		var actor: DepotPlayer=characters[identity]
		var at:=actor.global_position
		Session.character_states[identity]={"position":[at.x,at.y,at.z],"facing":actor.visual.rotation.y,"yaw":actor.camera_rig.yaw,"pitch":actor.camera_rig.pitch,"camera_distance":actor.camera_rig.target_distance,"torch":actor.torch.visible,"carried":actor.carried_id}
	Session.active_character=player.identity;Session.carried_id=player.carried_id
	Session.crate_states.clear()
	for id in depot.crates:
		if not is_instance_valid(depot.crates[id]) or id in Session.stocked:continue
		var item: Node3D=depot.crates[id]
		var at:=item.global_position
		Session.crate_states[id]={"position":[at.x,at.y,at.z],"yaw":item.global_rotation.y}
func on_handling_completed() -> void:
	if active:Session.save_shift(player.global_position)
func can_checkout(actor: DepotPlayer) -> bool:
	return actor.identity=="Felps" and actor.global_position.distance_to(CheckoutFixture.STAFF_POSITION)<1.4 and customer!=null and customer.state==Customer.State.WAITING and not customer.service_started
func try_checkout(actor: DepotPlayer) -> bool:
	if not can_checkout(actor) or Dialogue.active:return false
	customer.service_started=true
	begin_checkout(customer)
	return true
func _physics_process(delta: float) -> void:
	if not active:return
	Session.world_seconds+=delta
	if customer==null and Session.stage>0 and Session.stage<6 and not Dialogue.active:
		spawn_wait-=delta
		if spawn_wait<=0:spawn_customer(Session.can_warn())
	if noise_pending and player.position.z> -8.0 and not Dialogue.active:
		noise_pending=false
		sound.play_at("knock",Vector3(0,1,-15.8))
		Dialogue.play("noise",[["Dery","Cê ouviu isso? Veio lá do fundo."],["Felps","Deve ter caído alguma caixa. Dá uma olhada? Eu fico aqui."]])
		var tween:=create_tween();var light:=depot.fluorescent
		for i in 3:
			tween.tween_property(light,"light_energy",float(light.get_meta("normal_energy",.16))*.20,.1)
			tween.tween_property(light,"light_energy",float(light.get_meta("normal_energy",1.8)),.22)
func spawn_customer(warning: bool) -> void:
	customer=Customer.new();customer.navigation=navigation;customer.warned=warning;customer.appearance=Session.customers_served%3
	add_child(customer);customer.global_position=Vector3(-18,Street.surface_height(-18,1.8)+.01,1.8);customer.reset_physics_interpolation()
	# _ready initially computes from local origin; recompute after spawn position.
	customer.go_to(Vector3(0,0,-1.5))
	customer.checked_out.connect(on_checkout)
	customer.departed.connect(on_departure)
func on_checkout(who: Customer) -> void:
	notice.emit("Felps, tem cliente esperando no caixa. [Tab] trocar personagem.")
func begin_checkout(who: Customer) -> void:
	sound.play_at("register",CheckoutFixture.POSITION+Vector3.UP)
	if who.warned and Session.can_warn():
		warning_started=true
		Session.stage=5;Session.changed.emit()
		var lines: Array=JSON.parse_string(FileAccess.get_file_as_string("res://resources/warning.json"))
		Dialogue.play("warning",lines)
	else:
		Dialogue.play("purchase",[["Cliente","Boa noite! Só essa aqui mesmo."],["Felps","Fechou. Boa noite, vai com Deus!"]])
func on_departure(who: Customer) -> void:
	if who.warned and warning_started:
		Session.stage=4
		Session.finish_warning()
		Dialogue.play("after_warning",[["Felps","Daqui a pouco o cara pede emprego de vigia, cê vai ver."],["Dery","Sei não, mano. Ficar atrás do depósito a essa hora?"]])
	customer=null;spawn_wait=8
	Session.save_shift(player.global_position)
func on_dialogue_completed(id: String) -> void:
	if id=="after_warning":noise_pending=true
func on_event(id: String) -> void:
	match id:
		"stocked":sound.play_at("crate",player.global_position)
		"organized":Dialogue.play("organized",[["Dery","Pronto, corredor livre. Agora dá pra respirar."],["Felps","Aí sim. Já já dá uma sossegada."]])
		"warning":sound.unease()
		"finale":
			sound.play_at("knock",depot.old_door.global_position)
			Dialogue.play("finale",[["Dery","Felps... tem alguém do outro lado."],["Felps","Como assim? Essa porta tá trancada por fora."],["", "DO OUTRO LADO, ALGUÉM PRENDE A RESPIRAÇÃO."]])
			Session.save_shift(player.global_position)
			slice_finished.emit()
	if id in ["greeted","stocked","organized","warning"]:Session.save_shift(player.global_position)
func restore_transient() -> void:
	# A saved warning conversation safely restarts at the customer arrival.
	if Session.stage==5:Session.stage=4
	noise_pending=Session.stage==6
