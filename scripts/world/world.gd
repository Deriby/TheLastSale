class_name ShiftWorld
extends Node3D
signal slice_finished
signal player_changed(actor: DepotPlayer)
signal notice(text: String)
signal checkout_requested
signal checkout_changed
signal checkout_closed
signal terminal_requested
signal desk_closed
signal campaign_event(kind: String)
signal surveillance_requested
var sale: ShopSale
var cashier_open:=false
var sale_save_wait:=-1.0
var checkout_goods: Node3D
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
var friday: FridayShift
var sunday: SundayShift
var saturday: SaturdayShift
var surveillance_open:=false
var supplies: SupplyGuide
var everyday: EverydayHorror
var story: FridayStory
func _ready() -> void:
	add_to_group("shift_world")
	var legacy_carried:=Session.carried_id
	if not Session.sale_state.is_empty():sale=ShopSale.restore(Session.sale_state)
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
		actor.concealed=bool(state.get("concealed",false));actor.crouching=actor.concealed
		actor.reset_physics_interpolation()
		actor.handling.completed.connect(on_handling_completed)
		actor.handling.feedback.connect(func(text: String):notice.emit(text))
		actor.set_controlled(false)
	var talk:=depot.interact(characters.Dery,"talk","Dery");characters.Dery.set_meta("interaction",talk)
	select_player(Session.active_character)
	sound=Soundscape.new();add_child(sound)
	ensure_order_crate()
	depot.restore_state(player)
	for identity in characters:
		var actor: DepotPlayer=characters[identity]
		var state: Dictionary=Session.character_states.get(identity,{})
		var carried: String=str(state.get("carried",legacy_carried if identity==Session.active_character else ""))
		if depot.crates.has(carried) and carried not in Session.stocked and not (carried=="loose" and Session.organized):actor.pick_up(depot.crates[carried],carried,true)
	Session.saving.connect(capture_state)
	for identity in ([] if int(Session.campaign.night)==2 else ["Bryan","Zirico"]):
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
	friday=FridayShift.new();friday.world=self;add_child(friday)
	friday.night_completed.connect(func():slice_finished.emit())
	saturday=SaturdayShift.new();saturday.world=self;add_child(saturday)
	sunday=SundayShift.new();sunday.world=self;add_child(sunday)
	supplies=SupplyGuide.new();supplies.world=self;add_child(supplies)
	everyday=EverydayHorror.new();everyday.world=self;add_child(everyday)
	story=FridayStory.new();story.world=self;add_child(story)
func update_enemy_visibility() -> void:
	enemy_visual.process_mode=Node.PROCESS_MODE_INHERIT if enemy_visual.is_visible_in_tree() else Node.PROCESS_MODE_DISABLED
func select_player(identity: String) -> void:
	for actor in characters.values():actor.set_controlled(false)
	player=characters.get(identity,characters.Dery);player.set_controlled(true)
	Session.active_character=player.identity;Session.carried_id=player.carried_id
	depot.set_counter_role(player.identity);player_changed.emit(player)
func switch_player() -> bool:
	if not active or get_tree().paused or surveillance_open or sunday!=null and sunday.desk_open:return false
	if Dialogue.active:
		notice.emit("Termine a conversa antes de trocar de personagem.");return false
	for actor in characters.values():
		if actor.motion.action_active or actor.handling.busy:
			notice.emit("Espere terminar de movimentar a caixa.");return false
	checkout_closed.emit()
	capture_state();select_player("Felps" if player.identity=="Dery" else "Dery")
	Session.save_shift(player.global_position)
	return true
func capture_state() -> void:
	Session.saved_position=player.global_position
	Session.sale_state=sale.snapshot() if sale!=null else {}
	Session.customer_state=customer.snapshot() if is_instance_valid(customer) else {}
	for identity in characters:
		var actor: DepotPlayer=characters[identity]
		var at:=actor.global_position
		Session.character_states[identity]={"position":[at.x,at.y,at.z],"facing":actor.visual.rotation.y,"yaw":actor.camera_rig.yaw,"pitch":actor.camera_rig.pitch,"camera_distance":actor.camera_rig.target_distance,"torch":actor.torch.visible,"carried":actor.carried_id}
	Session.active_character=player.identity;Session.carried_id=player.carried_id
	Session.crate_states.clear()
	for id in depot.crates:
		if not is_instance_valid(depot.crates[id]) or id in Session.stocked:continue
		if sale!=null and id==sale.supply_id() and sale.bulk_supplied:continue
		var item: Node3D=depot.crates[id]
		var at:=item.global_position
		Session.crate_states[id]={"position":[at.x,at.y,at.z],"yaw":item.global_rotation.y}
	if sunday!=null:sunday.capture()
	if everyday!=null:everyday.capture()
func on_handling_completed() -> void:
	if active:Session.changed.emit();Session.save_shift(player.global_position)
func can_checkout(actor: DepotPlayer) -> bool:
	return not surveillance_open and (friday==null or not friday.is_outage() and friday.phase() not in ["closing","complete"]) and actor.identity=="Felps" and actor.global_position.distance_to(CheckoutFixture.STAFF_POSITION)<1.4 and is_instance_valid(customer) and customer.state==Customer.State.WAITING and not customer.purchase_complete
func try_surveillance() -> bool:
	if int(Session.campaign.night)==2:
		if sunday==null or sunday.desk_open or not sunday.can_open(player):return false
		terminal_requested.emit();return sunday.desk_open
	if surveillance_open or cashier_open or saturday==null or not saturday.can_open(player):return false
	surveillance_requested.emit();return surveillance_open
func set_surveillance_open(value: bool) -> void:
	surveillance_open=value;characters.Felps.input_locked=value
func try_checkout(actor: DepotPlayer) -> bool:
	if not can_checkout(actor) or Dialogue.active or sale==null:return false
	if not customer.service_started:
		customer.service_started=true;begin_checkout(customer)
	else:checkout_requested.emit()
	return true
func set_register_open(value: bool) -> void:
	cashier_open=value;characters.Felps.input_locked=value
func can_operate_register() -> bool:
	return sale!=null and can_checkout(player) and customer.service_started and not Dialogue.active
func update_sale(sound_id := "") -> void:
	update_checkout_scene();checkout_changed.emit();sale_save_wait=.25
	if not sound_id.is_empty():sound.play_at(sound_id,CheckoutFixture.POSITION+Vector3.UP)
func register_product(sku: String,quantity := 1) -> bool:
	if not can_operate_register():return false
	var result:=sale.register(sku,quantity)
	update_sale("scanner" if result else "");return result
func checkout_step(action: String,value := 0) -> bool:
	if not can_operate_register():return false
	var result:=false
	match action:
		"confirm":result=sale.confirm_items()
		"receive":result=sale.receive_cash()
		"coin":result=sale.add_coin(value)
		"undo":result=sale.undo_coin()
		"clear":result=sale.clear_change()
		"change":result=sale.confirm_change()
		"deliver":
			if sale.phase!=ShopSale.Phase.READY:return false
			sale.phase=ShopSale.Phase.COMPLETE
			var receipt:=sale.receipt();receipt.customer=customer.identity;receipt.night=int(Session.campaign.night);receipt.time=Session.clock_text()
			Session.record_sale(receipt)
			customer.purchase_complete=true;customer.product.hide();customer.bag.show()
			if customer.warned and Session.can_warn():
				warning_started=true;Session.stage=5;Session.changed.emit()
				Dialogue.play("warning",story.warning_lines())
			notice.emit("Compra entregue • "+ShopSale.money(sale.total())+" • Troco "+ShopSale.money(sale.selected_change()))
			checkout_closed.emit();result=true
	update_sale("register" if result and action=="receive" else ("cash" if result and action=="change" else ("bag" if result and action=="deliver" else "")))
	if result and action=="deliver":Session.save_shift(player.global_position)
	return result
func ensure_order_crate() -> void:
	if sale==null or not sale.needs_bulk() or sale.bulk_supplied:return
	var id:=sale.supply_id()
	if not depot.crates.has(id):depot.add_crate(id,Vector3(-.5,0,-13.35))
func request_stock() -> bool:
	if not can_operate_register() or not sale.needs_bulk() or sale.bulk_supplied:return false
	notice.emit("Felps: pegue a caixa laranja VENDA #%03d no estoque e entregue na área marcada do balcão. As R1/R2 são de reposição."%sale.id)
	checkout_closed.emit();return switch_player()
func can_supply_order(actor: DepotPlayer) -> bool:
	return sale!=null and sale.needs_bulk() and not sale.bulk_supplied and actor.identity=="Dery" and actor.carried!=null and actor.carried_id==sale.supply_id() and actor.global_position.distance_to(CheckoutFixture.CUSTOMER_POSITION)<2.5
func supply_order(actor: DepotPlayer) -> bool:
	if not can_supply_order(actor) or actor.handling.busy or actor.motion.action_active:return false
	actor.consume_carried(SupplyGuide.DELIVERY_POINT,func():
		sale.bulk_supplied=true;update_sale("crate");notice.emit("Caixa entregue. [Tab] Felps: registre os produtos, receba o dinheiro e finalize a venda no caixa."))
	return true
func update_checkout_scene() -> void:
	if sale==null:return
	if is_instance_valid(customer) and customer.service_started:depot.counter.show_sale(sale)
	else:depot.counter.screen_text.text="JA • FRENTE DE CAIXA\n\nCAIXA DISPONÍVEL"
	if checkout_goods!=null:checkout_goods.queue_free();checkout_goods=null
	if sale.phase==ShopSale.Phase.COMPLETE or not is_instance_valid(customer) or not customer.service_started:return
	checkout_goods=Node3D.new();checkout_goods.name="PurchaseGoods";add_child(checkout_goods)
	var index:=0
	for sku in sale.order:
		if sku=="case_returnable":
			if sale.bulk_supplied:
				var box:=depot.prop("crate",Vector3(-4.17,1.13,-1.85));box.scale=Vector3.ONE*.65;box.reparent(checkout_goods)
				for col in box.find_children("*","CollisionShape3D",true,false):col.disabled=true
			continue
		for i in mini(6-index,int(sale.order[sku])):
			var item:=MeshInstance3D.new();checkout_goods.add_child(item);item.mesh=ProductLibrary.mesh(sku);item.material_override=ProductLibrary.material(sku)
			item.position=Vector3(-4.32+(index%2)*.16,1.13,-1.6-floori(index/2.0)*.24);index+=1
func _physics_process(delta: float) -> void:
	if not active:return
	Session.world_seconds+=delta
	if Session.stage==6 and friday!=null and friday.phase()=="routine" and not Dialogue.active:friday.begin_outage()
	if friday!=null:friday.tick(delta)
	if saturday!=null:saturday.tick()
	if sunday!=null:sunday.tick(delta)
	if everyday!=null:everyday.tick(delta)
	if sale_save_wait>=0:
		sale_save_wait-=delta
		if sale_save_wait<0:Session.save_shift(player.global_position)
	if customer==null and Session.stage>0 and (friday.can_spawn() or saturday.can_spawn()) and not Dialogue.active:
		spawn_wait-=delta
		if spawn_wait<=0:spawn_customer(Session.can_warn() and (everyday==null or everyday.warning_ready()))
	if noise_pending and player.position.z> -8.0 and not Dialogue.active:
		noise_pending=false
		sound.play_at("knock",Vector3(0,1,-15.8))
		Dialogue.play("noise",[["Dery","Cê ouviu isso? Veio lá do fundo."],["Felps","Deve ter caído alguma caixa. Dá uma olhada? Eu fico aqui."]])
		var tween:=create_tween();var light:=depot.fluorescent
		for i in 3:
			tween.tween_property(light,"light_energy",float(light.get_meta("normal_energy",.16))*.20,.1)
			tween.tween_property(light,"light_energy",float(light.get_meta("normal_energy",1.8)),.22)
func spawn_customer(warning: bool,snapshot: Dictionary={}) -> void:
	if is_instance_valid(customer):return
	if snapshot.is_empty():
		sale=saturday.order(Session.next_sale_id) if int(Session.campaign.night)==1 else ShopSale.create(Session.next_sale_id,warning);Session.next_sale_id+=1
	ensure_order_crate()
	customer=Customer.new();customer.navigation=navigation;customer.warned=warning
	customer.appearance=int(snapshot.get("appearance",Session.customers_served))
	customer.identity=NPCCast.arrival_identity(Session.customers_served) if snapshot.is_empty() else str(snapshot.get("identity",""))
	if snapshot.is_empty() and int(Session.campaign.night)==1:customer.identity=saturday.next_identity()
	customer.empty_handed=sale!=null and sale.needs_bulk() and sale.order.size()==1
	if sale!=null:
		for sku in sale.order:
			if sku!="case_returnable":customer.basket_sku=sku;break
	add_child(customer);customer.global_position=Vector3(-18,Street.surface_height(-18,1.8)+.01,1.8);customer.reset_physics_interpolation()
	# _ready initially computes from local origin; recompute after spawn position.
	customer.go_to(Vector3(0,0,-1.5))
	customer.checked_out.connect(on_checkout)
	customer.departed.connect(on_departure)
	customer.impatient.connect(func(text: String):notice.emit(text))
	if not snapshot.is_empty():customer.restore(snapshot)
	update_checkout_scene()
	if active:Session.changed.emit();Session.save_shift(player.global_position)
func on_checkout(who: Customer) -> void:
	notice.emit("Felps, tem cliente esperando no caixa. [Tab] trocar personagem.")
func begin_checkout(who: Customer) -> void:
	update_checkout_scene()
	if int(Session.campaign.night)==1:
		Dialogue.play("sale_order_"+str(sale.id),saturday.order_lines(who));return
	var request: String="Boa noite! Vou levar: "+sale.describe().replace("\n",", ")+"."
	if sale.needs_bulk():request="Boa noite! Separa uma caixa fechada de retornável pra mim?"
	Dialogue.play("sale_order_"+str(sale.id),story.order_lines(who,request))
func on_departure(who: Customer) -> void:
	if who.warned and warning_started:
		Session.stage=4
		Session.finish_warning()
		Dialogue.play("after_warning",[["Felps","Daqui a pouco o cara pede emprego de vigia, cê vai ver."],["Dery","Sei não, mano. Ficar atrás do depósito a essa hora?"]])
	customer=null;spawn_wait=8
	if saturday!=null:saturday.on_departure()
	if friday!=null and friday.phase()=="restored":friday.begin_closing()
	Session.save_shift(player.global_position)
func on_dialogue_completed(id: String) -> void:
	if id=="after_warning" and friday!=null:friday.begin_outage()
	if sale!=null and id=="sale_order_"+str(sale.id) and can_checkout(player):checkout_requested.emit()
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
	if sale!=null and not Session.customer_state.is_empty():
		var state:=Session.customer_state.duplicate(true)
		spawn_customer(bool(state.get("warned",false)),state)
		if Session.stage==5 and customer!=null and customer.warned:
			warning_started=true
			Dialogue.play("warning",story.warning_lines())
	elif Session.stage==5:Session.stage=4
	noise_pending=false
	if friday!=null and Session.stage==6 and friday.phase()=="routine" and not Dialogue.active:friday.begin_outage()
	if int(Session.campaign.night)==0 and friday!=null and friday.is_outage():
		for actor in characters.values():actor.torch.show()
	if saturday!=null:saturday.tick()
	if Session.campaign.phase=="complete":call_deferred("emit_night_completed")
	if Session.campaign.phase=="campaign_complete":call_deferred("emit_campaign_ending")
func emit_night_completed() -> void:slice_finished.emit()

func emit_campaign_ending() -> void:campaign_event.emit("ending")
