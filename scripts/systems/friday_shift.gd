class_name FridayShift
extends Node3D
## Friday's recoverable outage and cooperative close; campaign state lives in Session.
signal night_completed
var world: ShiftWorld
var lights: Array[Light3D]=[]
var emitters: Array[StandardMaterial3D]=[]
var batteries: Array[Light3D]=[]
var key_hook: Node3D
var key_mesh: MeshInstance3D
var exit_control: Node3D
var shutters: Array[MeshInstance3D]=[]
var generator_hum: AudioStreamPlayer3D
var following_wait:=0.0
var finishing:=false
func _ready() -> void:
	for light in world.depot.find_children("*","Light3D",true,false):
		if light is SpotLight3D and light.get_parent() is Camera3D or light.get_meta("battery_light",false):continue
		lights.append(light)
	var copies: Dictionary={}
	for mesh in world.depot.find_children("*","MeshInstance3D",true,false):
		if world.depot.yard.is_ancestor_of(mesh):continue
		for surface in mesh.mesh.get_surface_count():
			var material: Material=mesh.material_override if mesh.material_override!=null else mesh.get_active_material(surface)
			if not material is StandardMaterial3D or not material.emission_enabled:continue
			var id:=material.get_instance_id()
			if not copies.has(id):copies[id]=material.duplicate();emitters.append(copies[id])
			if mesh.material_override!=null:mesh.material_override=copies[id]
			else:mesh.set_surface_override_material(surface,copies[id])
	build_controls();build_batteries();build_shutters()
	generator_hum=world.sound.loop_sound("hum",Vector3(5.5,.7,-19.5),-13,7);generator_hum.pitch_scale=.65;generator_hum.stop()
	Preferences.changed.connect(apply_power)
	apply_power()
	if phase() in ["closing","complete"]:
		for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.queue_free()
func build_controls() -> void:
	key_hook=Node3D.new();key_hook.name="GeneratorKeyAndLights";world.depot.add_child(key_hook);key_hook.position=Vector3(3.1,0,-11.3)
	Geo.box(key_hook,Vector3(0,1.35,0),Vector3(.44,.50,.10),Geo.material(Color("697265")))
	var label:=Geo.sign_text(key_hook,"CHAVE / LUZES",Vector3(0,1.72,-.08),19);label.rotation.y=PI;label.pixel_size=.003
	key_mesh=Geo.box(key_hook,Vector3(0,1.37,-.09),Vector3(.035,.18,.025),Geo.material(Color("c2ae71")),false)
	Geo.box(key_mesh,Vector3(.027,-.05,0),Vector3(.06,.022,.025),Geo.material(Color("c2ae71")),false)
	world.depot.interact(key_hook,"campaign","key")
	world.depot.interact(world.depot.yard.generator,"campaign","generator")
	exit_control=Node3D.new();exit_control.name="ClosingControl";world.depot.add_child(exit_control);exit_control.position=Vector3(5.72,0,.55)
	Geo.box(exit_control,Vector3(0,1.2,0),Vector3(.18,.32,.14),Geo.material(Color("696d62")))
	var sign:=Geo.sign_text(exit_control,"PORTAS",Vector3(0,1.52,.09),20);sign.pixel_size=.003
	world.depot.interact(exit_control,"campaign","exit")
func build_batteries() -> void:
	for at in [Vector3(-3.6,2.7,-1.8),Vector3(3.1,2.8,-9.6),Vector3(.2,2.7,-13.3)]:
		var fixture:=Node3D.new();world.depot.add_child(fixture);fixture.position=at
		Geo.box(fixture,Vector3.ZERO,Vector3(.42,.10,.13),Geo.material(Color("a3ada0")),false)
		var light:=Geo.light(fixture,Vector3(0,-.12,0),Color("ceddb9"),.75,4.7)
		light.name="EmergencyBattery";light.omni_attenuation=1.1;batteries.append(light)
func build_shutters() -> void:
	for data in [Vector3(-4.05,3.65,3.6),Vector3(0,3.52,3.8),Vector3(4.05,3.52,3.5)]:
		var mesh:=Geo.box(world.depot,Vector3(data.x,3.4,.03),Vector3(data.z,3.4,.10),Geo.material(Color("424a45"),"res://assets/textures/metal.png"))
		mesh.name="ClosingShutter";mesh.visible=false;shutters.append(mesh)
		for shape in mesh.find_children("*","CollisionShape3D",true,false):shape.disabled=true
func phase() -> String:return str(Session.campaign.phase)
func is_outage() -> bool:return phase()=="outage" or int(Session.campaign.night)==2 and phase()=="sunday_escape" and not Session.flag("generator_running")
func can_spawn() -> bool:
	return int(Session.campaign.night)==0 and phase() in ["routine","restored"]
func save() -> void:
	Session.changed.emit();apply_power();Session.save_shift(world.player.global_position)
func prompt(action: String,actor: DepotPlayer) -> String:
	match action:
		"key":
			if phase()=="closing":return "Apagar iluminação do salão" if not Session.flag("lights_off") else "Iluminação do salão desligada"
			return "Chave do gerador • Deryk" if not Session.flag("generator_key") else "Chave do gerador com Deryk"
		"generator":return "Ligar gerador de reserva" if is_outage() else "Gerador funcionando" if Session.flag("generator_running") else "Gerador de reserva • desligado"
		"counter":
			if is_outage():return "Suspender atendimento e orientar o salão" if actor.identity=="Felps" else "[Tab] Felps precisa desligar o caixa"
			return "Conferir e fechar o caixa" if not Session.flag("till_closed") else "Caixa conferido e fechado"
		"stock":return "Verificar estoque e porta antiga"
		"exit":
			if phase()!="closing":return "Portas • fechar ao encerrar o expediente"
			if not ready_to_leave():return "Conclua caixa, estoque e iluminação antes de sair"
			if not Session.flag("reunite"):return "Chamar companheiro para fechar juntos"
			return "Baixar portas e encerrar a noite" if both_outside() else "Aguarde o companheiro chegar à calçada"
	return "Interagir"
func activate(action: String,actor: DepotPlayer) -> bool:
	if Dialogue.active or finishing:return false
	if int(Session.campaign.night)!=0 and phase()!="closing":return false
	if action=="counter" and actor.global_position.distance_to(CheckoutFixture.STAFF_POSITION)>1.4:return false
	if action=="stock" and actor.global_position.distance_to(world.depot.old_door.global_position)>2.65:return false
	if action=="exit" and actor.global_position.distance_to(exit_control.global_position)>2.65:return false
	match action:
		"key":
			if phase()=="closing":
				if not Session.flag("till_closed") or not Session.flag("stock_checked") or Session.flag("lights_off"):return false
				Session.campaign.flags.lights_off=true;save();world.notice.emit("Salão apagado. Reúnam-se na calçada antes de baixar as portas.");return true
			if not is_outage() or actor.identity!="Dery" or Session.flag("generator_key"):return false
			Session.campaign.flags.generator_key=true;save();world.notice.emit("Chave recolhida. O gerador fica no pátio, pela porta dos fundos do estoque.");return true
		"generator":
			if not is_outage() or actor.identity!="Dery" or not Session.flag("generator_key") or not Session.flag("counter_secured"):return false
			Session.campaign.flags.generator_running=true;Session.campaign.phase="restored";Session.campaign.clues.local_outage=true
			actor.motion.action("place");save()
			Dialogue.play("power_restored",[["Dery","Pegou! Felps, voltou aí?"],["Felps","Voltou. Termina aí que eu confiro o atendimento. Depois a gente fecha."],["Zirico","Engraçado... a rua toda continuou acesa, viu?"]])
			return true
		"counter":
			if actor.identity!="Felps":return false
			if is_outage() and not Session.flag("counter_secured"):
				Session.campaign.flags.counter_secured=true;save()
				Dialogue.play("counter_secured",[["Felps","Desliguei o caixa. Vou ficar aqui na frente. A chave tá no suporte, dentro do estoque."],["Dery","Tô indo. Me chama se ouvir alguma coisa."]]);return true
			if phase()=="closing" and not Session.flag("till_closed") and not is_instance_valid(world.customer):
				Session.campaign.flags.till_closed=true;save();world.notice.emit("Felps: caixa conferido. Vendas do turno: "+ShopSale.money(Session.sales_cents));return true
		"stock":
			if phase()!="closing" or actor.identity!="Dery" or Session.flag("stock_checked"):return false
			Session.campaign.flags.stock_checked=true;save()
			if int(Session.campaign.night)==1:Dialogue.play("stock_checked",[["Dery","A porta antiga tá trancada, e conferi a trava do pátio. Não vou abrir."],["Felps","Vem pra frente. Amanhã a gente volta com luz e ajuda."]])
			else:Dialogue.play("stock_checked",[["Dery","Estoque conferido. Essa porta antiga continua trancada."],["Felps","Amanhã a gente pede pra olharem a energia. Vamos fechar juntos."]])
			return true
		"exit":
			if phase()!="closing" or not ready_to_leave():return false
			if not Session.flag("reunite"):
				Session.campaign.flags.reunite=true;save();world.notice.emit(actor.display_name()+": vem pra frente, vamos sair juntos.");return true
			if not both_outside():return false
			if world.story.begin_closing_hook():return true
			finish_friday();return true
	return false
func begin_outage() -> bool:
	if int(Session.campaign.night)!=0 or phase()!="routine":return false
	Session.campaign.phase="outage";Session.stage=6;world.checkout_closed.emit()
	for actor in world.characters.values():
		actor.torch.show()
		if actor.carried==null and not actor.handling.busy:actor.motion.action("startled")
	save()
	Dialogue.play("blackout",[["Felps","Ô! Que que foi isso? Dery, cê tá aí?"],["Dery","Tô. Calma... acende a lanterna. O gerador fica lá atrás."],["Felps","Vou suspender o caixa. Pega a chave dentro do estoque e liga ele pra nós."]])
	return true
func begin_closing() -> void:
	if phase()!="restored" or is_instance_valid(world.customer):return
	Session.campaign.phase="closing";save()
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		friend.depart(world.navigation.path(friend.global_position,Vector3(18,0,1.8)))
	Dialogue.play("closing",[["Felps","Por hoje deu. Vou conferir o caixa. Dá uma última olhada no estoque?"],["Dery","Dou sim. Depois eu apago as luzes e a gente baixa as portas."]])
func ready_to_leave() -> bool:return Session.flag("till_closed") and Session.flag("stock_checked") and Session.flag("lights_off")
func both_outside() -> bool:
	for actor in world.characters.values():
		if actor.global_position.z<.65 or absf(actor.global_position.x)>6:return false
	return true
func finish_friday() -> void:
	finishing=true
	for mesh in shutters:
		mesh.show();mesh.position.y=4.9
		create_tween().tween_property(mesh,"position:y",1.7,1.5)
	for actor in world.characters.values():actor.input_locked=true
	get_tree().create_timer(1.6,false).timeout.connect(func():
		if not is_inside_tree():return
		Session.campaign.phase="complete";Session.stage=7;Session.finale_seen=true
		var night:=int(Session.campaign.night)
		if night not in Session.campaign.completed_nights:Session.campaign.completed_nights.append(night)
		Session.campaign.reports["friday" if night==0 else "saturday"]={"sales_cents":Session.sales_cents,"receipts":Session.receipts.duplicate(true),"customers":Session.customers_served,"decisions":Session.campaign.decisions.duplicate(true),"records":Session.campaign.records.duplicate(true)}
		save();night_completed.emit())
func apply_power() -> void:
	var mains:=not is_outage();var shop_on:=mains and not Session.flag("lights_off")
	for light in lights:
		var powered:=mains if light.name=="CabinetLight" else shop_on
		light.set_meta("circuit_on",powered);light.visible=powered and (not light.get_meta("detail_light",false) or Preferences.pixel_scale<3)
	for material in emitters:material.emission_enabled=shop_on
	for light in batteries:light.visible=not shop_on
	key_mesh.visible=not Session.flag("generator_key")
	if Session.flag("generator_running"):
		world.depot.yard.status.text="GERADOR • EM OPERAÇÃO"
		world.depot.yard.indicator.material_override=Geo.material(Color("79b570"),"",.45)
		if not generator_hum.playing:generator_hum.play()
	else:generator_hum.stop()
	world.sound.set_store_power(mains,shop_on)
	if is_outage():world.depot.counter.screen_text.text="SEM ENERGIA\nATENDIMENTO SUSPENSO"
	elif Session.flag("till_closed"):world.depot.counter.screen_text.text="CAIXA ENCERRADO\nVENDAS "+ShopSale.money(Session.sales_cents)
	var probe: ReflectionProbe=world.get_node("CabinetReflection");probe.set_meta("circuit_on",mains);probe.visible=mains and Preferences.pixel_scale<3
	if phase()=="complete":
		for mesh in shutters:
			mesh.show();mesh.position.y=1.7
			for shape in mesh.find_children("*","CollisionShape3D",true,false):shape.set_deferred("disabled",false)
func tick(delta: float) -> void:
	if phase()!="closing" or not Session.flag("reunite") or finishing:return
	following_wait-=delta
	if following_wait>0:return
	following_wait=.6
	var actor: DepotPlayer=world.characters.Felps if world.player.identity=="Dery" else world.characters.Dery
	var destination:=Vector3(3.3 if actor.identity=="Dery" else 4.3,.01,1.4)
	for door in [world.depot.stock_door,world.depot.service_door]:
		var interaction: Interaction
		for child in door.get_children():
			if child is Interaction:interaction=child
		if interaction!=null and not interaction.open and not interaction.busy and actor.position.distance_to(door.position+Vector3(.8,0,0))<2.5:interaction.activate(actor)
	actor.assisted_path=world.navigation.path(actor.global_position,destination)
