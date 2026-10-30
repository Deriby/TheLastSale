class_name SundayShift
extends Node3D
## Complete third night. All positions, evidence and pursuit memory share one save.
var world: ShiftWorld
var killer: KillerAgent
var desk_open:=false
var stopped:=false
var caught_identity:=""
var update_wait:=0.0
var autosave_wait:=5.0
var release: Node3D
var crank: Node3D
var helper: Node3D
var exits: Array[Node3D]=[]
var covers: Dictionary={"counter":CheckoutFixture.STAFF_POSITION,"stock":Vector3(-2.7,0,-11.8),"freezer":Vector3(5.15,0,-7.95)}
func phase() -> String:return str(Session.campaign.phase)
func state() -> Dictionary:return Session.campaign.sunday
func threat_active() -> bool:return int(Session.campaign.night)==2 and phase()=="sunday_escape" and world.active and not stopped
func _ready() -> void:
	if int(Session.campaign.night)!=2:return
	state().merge({"orders":{"Dery":"hold","Felps":"hold"},"doors":{"stock":false,"service":false,"old":false},"generator_mode":"off","proof":"recorder","killer":{},"crank_actor":"","crank_time":0.0},false)
	Session.stage=7 if phase()=="campaign_complete" else 6 if phase()=="sunday_escape" else 0
	build_controls()
	world.characters.Dery.add_collision_exception_with(world.characters.Felps)
	world.characters.Felps.add_collision_exception_with(world.characters.Dery)
	for actor in world.characters.values():actor.made_noise.connect(on_noise)
	world.depot.interact(world.depot.access.evidence,"sunday","module")
	if phase()=="sunday_escape":spawn_killer()
	Preferences.changed.connect(apply_scene);apply_scene()
func control(at: Vector3,title: String,id: String) -> Node3D:
	var node:=Node3D.new();add_child(node);node.position=at
	Geo.box(node,Vector3(0,1.1,0),Vector3(.22,.30,.10),Geo.material(Color("626f60")),false)
	var label:=Geo.sign_text(node,title,Vector3(0,1.4,.07),20);label.pixel_size=.0025
	world.depot.interact(node,"sunday",id);return node
func build_controls() -> void:
	release=control(Vector3(3.65,0,-10.85),"DESTRAVAR ESTOQUE","release")
	crank=control(Vector3(5.65,0,-.35),"SAÍDA MANUAL","shutter")
	for id in covers:
		var at: Vector3=covers[id]
		var node:=Node3D.new();add_child(node);node.position=at;node.name="Cover_"+id
		world.depot.interact(node,"sunday","hide_"+id)
	for x in [10.0,18.0]:
		var node:=control(Vector3(x,Street.surface_height(x,1.8),1.8),"ENCONTRO / SAÍDA","escape")
		exits.append(node)
	helper=Node3D.new();helper.name="ZiricoWaiting";add_child(helper)
	helper.position=Vector3(10.5,Street.surface_height(10.5,1.85),1.85)
	var visual:=CharacterModels.create("Zirico");helper.add_child(visual);visual.rotation.y=-PI/2
	var motion:=LivingMotion.new();helper.add_child(motion);motion.setup(visual,helper)
	# A real stock cabinet shelters a crouched companion, without occupying the exit.
	Geo.box(world.depot,Vector3(-2.5,.87,-12.8),Vector3(1.0,1.74,.7),SurfaceMaterials.make("painted_metal",Color("53615b")))
	for y in [.4,.9,1.4]:Geo.box(world.depot,Vector3(-2.5,y,-12.44),Vector3(.92,.025,.025),Geo.material(Color("848c7f")),false)
	world.depot.blockers.append(Rect2(-3,-13.15,1,.7))
	world.navigation.configure(world.depot.blockers+world.street.blockers,Street.surface_height)
func capture() -> void:
	if int(Session.campaign.night)!=2:return
	if is_instance_valid(killer):state().killer=killer.snapshot()
	for actor in world.characters.values():
		if Session.character_states.has(actor.identity):Session.character_states[actor.identity].concealed=actor.concealed
func save() -> void:
	Session.changed.emit();apply_scene();Session.save_shift(world.player.global_position)
func spawn_killer() -> void:
	killer=KillerAgent.new();killer.name="Killer";killer.chapter=self;killer.visual=world.enemy_visual
	world.add_child(killer);killer.restore(state().get("killer",{}))
func introduce(actor: DepotPlayer) -> bool:
	if Dialogue.active or phase()!="sunday_intro":return false
	Session.campaign.phase="sunday_investigation";Session.stocked.assign(["stock_1","stock_2"]);Session.organized=true
	for id in ["stock_1","stock_2"]:
		if is_instance_valid(world.depot.crates.get(id)):world.depot.crates[id].queue_free()
	if is_instance_valid(world.depot.crates.get("loose")):world.depot.crates.loose.position=Vector3(-3.8,.23,-13.8)
	Session.campaign.flags.help_notified=Session.campaign.decisions.get("help","")=="contact"
	save();Session.checkpoint()
	Dialogue.play("sunday_intro",[["Felps","Hoje não abre. O responsável pediu pra recuperar o arquivo antigo e esperar ele na frente."],["Dery","A gente guardou os registros de ontem." if not Session.campaign.evidence_archive.is_empty() else "Ainda tá tudo só no gravador. Vamos preservar o que der."],["Felps","O índice de quarta tá faltando. Confere a caixa de manutenção atrás daquela porta velha. Eu fico no terminal."],["Dery","Sem se separar de vez. Se acontecer qualquer coisa, a gente se chama."]])
	return true
func can_open(actor: DepotPlayer) -> bool:
	return int(Session.campaign.night)==2 and phase() in ["sunday_investigation","sunday_prepare","sunday_escape"] and actor.identity=="Felps" and actor.global_position.distance_to(CheckoutFixture.STAFF_POSITION)<1.4 and not Dialogue.active and not stopped
func review_recording() -> bool:
	if not desk_open or not Session.flag("module_delivered") or phase()!="sunday_investigation":return false
	Session.campaign.flags.clip_reviewed=true;Session.campaign.phase="sunday_prepare"
	Session.campaign.clues.maintenance_access=true;save()
	return true
func desk_action(action: String) -> bool:
	if not desk_open or not can_open(world.player):return false
	match action:
		"release":
			if phase()!="sunday_escape" or state().generator_mode!="stock" or Session.flag("stock_released"):return false
			Session.campaign.flags.stock_released=true;change_door("stock",true);save()
			world.notice.emit("Felps: destravei pelo terminal! H chama o companheiro. Vamos sair pela frente.");return true
		"copy":
			if not Session.flag("clip_reviewed") or Session.flag("proof_destroyed"):return false
			if state().proof!="offsite":state().proof="carried"
			state().proof_carrier="Felps";save();return true
		"send":
			if not Session.flag("clip_reviewed") or not Session.flag("help_notified") or Session.flag("proof_destroyed"):return false
			state().proof="offsite";save();return true
		"leave":
			if not Session.flag("clip_reviewed") or state().proof=="offsite":return false
			state().proof="recorder";state().erase("proof_carrier");save();return true
		"contact":
			Session.campaign.flags.help_notified=true;save();return true
	return false
func actor_lit(actor: DepotPlayer) -> bool:
	if phase()!="sunday_escape":return true
	return actor.position.z>=0 or (actor.position.z< -11 and state().generator_mode=="stock") or (actor.position.z>=-11 and state().generator_mode=="salon")
func door_interaction(door: Node3D) -> Interaction:
	for item in door.get_children():
		if item is Interaction:return item
	return null
func door_open(id: String) -> bool:return bool(state().doors.get(id,false))
func change_door(id: String,value: bool) -> void:
	state().doors[id]=value;apply_doors()
func apply_doors() -> void:
	for id in ["stock","service","old"]:
		var door: Node3D=world.depot.stock_door if id=="stock" else world.depot.service_door if id=="service" else world.depot.old_door
		door.rotation.y=(-1.45 if id=="stock" else 1.45) if door_open(id) else 0.0
		var interaction:=door_interaction(door)
		if interaction!=null:interaction.open=door_open(id);interaction.busy=false
func obstacles() -> Array[Rect2]:
	var result: Array[Rect2]=[]
	result.append(Rect2(3.65,-11.12,2.05,.18) if not door_open("stock") else Rect2(3.65,-11.0,.38,1.8))
	result.append(Rect2(3.65,-16.10,2.1,.18) if not door_open("service") else Rect2(3.65,-17.85,.38,1.85))
	result.append(Rect2(-.78,-15.9,1.56,.18) if not door_open("old") else Rect2(-.85,-17.25,.30,1.5))
	if phase()=="sunday_escape" and not Session.flag("front_open"):result.append(Rect2(-5.9,-.06,11.8,.15))
	return result
func route(from: Vector3,to: Vector3) -> PackedVector3Array:return world.navigation.path_with_obstacles(from,to,obstacles())
func door_approach(from: Vector3,to: Vector3) -> Vector3:
	if from.z< -16 and absf(from.x)<1.1 and to.z> -16 and not door_open("old"):return Vector3(.2,0,-17.0)
	if (from.z< -11)!=(to.z< -11) and not door_open("stock"):return Vector3(4.85,0,-12.1 if from.z< -11 else -9.9)
	if (from.z< -16)!=(to.z< -16) and not door_open("service"):return Vector3(4.85,0,-17.2 if from.z< -16 else -14.8)
	return Vector3.INF
func open_nearby_doors(actor: Node3D) -> void:
	for id in ["old","service","stock"]:
		if door_open(id) or id=="stock" and not Session.flag("stock_released"):continue
		var door: Node3D=world.depot.old_door if id=="old" else world.depot.service_door if id=="service" else world.depot.stock_door
		if actor.global_position.distance_to(door.global_position+Vector3(.8,0,0))<1.65:change_door(id,true)
func prompt(action: String,actor: DepotPlayer) -> String:
	match action:
		"counter":return "Entregar módulo do DVR" if actor.identity=="Dery" and Session.flag("module_found") and not Session.flag("module_delivered") else "Terminal do DVR [C] • Felps"
		"old":return "Fechar acesso antigo" if door_open("old") else "Examinar e abrir acesso antigo"
		"module":return "Módulo recolhido" if Session.flag("module_found") else "Recolher módulo e cadastro de manutenção • Deryk"
		"key":return "Conferir quadro e liberar saída • Deryk / Felps no caixa" if phase()=="sunday_prepare" else "Quadro do estoque"
		"generator":return "Gerador: "+str({"off":"DESLIGADO","stock":"ESTOQUE","salon":"SALÃO"}[state().generator_mode])+" • E alterna ESTOQUE / SALÃO / DESLIGADO"
		"release":return "Destravar porta do estoque • Felps"
		"shutter":return "Saída aberta" if Session.flag("front_open") else "Manter-se junto ao comando para abrir saída"
		"escape":return "Fuga: reunir a dupla / decidir sair"
	if action.begins_with("hide_"):return "Sair da cobertura" if actor.concealed else "Abaixar e se esconder nesta cobertura"
	return "Interagir"
func activate(action: String,actor: DepotPlayer) -> bool:
	if stopped or Dialogue.active or actor.carried!=null or phase()=="sunday_intro":return false
	var points: Dictionary={"old":world.depot.old_door.position,"module":world.depot.access.evidence.global_position,"counter":CheckoutFixture.POSITION,"key":world.friday.key_hook.global_position,"generator":world.depot.yard.generator.global_position,"release":release.global_position,"shutter":crank.global_position}
	if points.has(action) and actor.position.distance_to(points[action])>2.65:return false
	match action:
		"old":
			if actor.identity!="Dery":return false
			change_door("old",not door_open("old"));Session.campaign.clues.maintenance_access=true;save()
			if not Session.flag("module_found"):Dialogue.play("old_access",[["Dery","A trava já tava solta. Tem uma passagem pro pátio aqui atrás... e um módulo do gravador."],["Felps","Então ele não precisava entrar pela frente. Traz o módulo pro balcão."]])
			return true
		"module":
			if actor.identity!="Dery" or Session.flag("module_found"):return false
			Session.campaign.flags.module_found=true;save();world.notice.emit("Módulo e cadastro de manutenção recolhidos. Deryk precisa levá-los ao balcão.");return true
		"counter":
			if actor.identity=="Dery" and Session.flag("module_found") and not Session.flag("module_delivered"):
				Session.campaign.flags.module_delivered=true;save();world.notice.emit("Módulo entregue. [Tab] Felps • C para recuperar a gravação.");return true
			return world.try_surveillance()
		"key":
			if phase()!="sunday_prepare" or actor.identity!="Dery" or actor.position.z> -11.7:return false
			if world.characters.Felps.position.distance_to(CheckoutFixture.STAFF_POSITION)>1.4:world.notice.emit("Felps precisa ficar no terminal para acompanhar a liberação.");return false
			begin_escape();return true
		"generator":
			if phase()!="sunday_escape" or actor.identity!="Dery":return false
			state().generator_mode={"off":"stock","stock":"salon","salon":"off"}[state().generator_mode]
			Session.campaign.flags.generator_running=state().generator_mode!="off";actor.motion.action("place");save()
			killer.hear(actor.global_position,14);world.notice.emit("Circuito do gerador: "+str({"off":"DESLIGADO","stock":"ESTOQUE","salon":"SALÃO"}[state().generator_mode]));return true
		"release":
			if phase()!="sunday_escape" or actor.identity!="Felps" or Session.flag("stock_released"):return false
			if state().generator_mode!="stock":world.notice.emit("Sem energia no circuito do estoque. Deryk precisa selecionar ESTOQUE no gerador.");return false
			Session.campaign.flags.stock_released=true;change_door("stock",true);save();world.notice.emit("Felps: porta livre! H chama o companheiro. A saída manual fica na frente.");return true
		"shutter":
			if phase()!="sunday_escape" or Session.flag("front_open"):return false
			state().crank_actor=actor.identity;state().crank_time=.7 if Session.campaign.decisions.get("exit","")=="prepared" else (2.0 if state().generator_mode=="salon" else 4.0)
			world.notice.emit("Abrindo a saída. Fique junto ao comando; afastar-se interrompe a abertura.");return true
		"escape":
			if phase()!="sunday_escape" or not Session.flag("front_open") or not at_exit(actor):return false
			world.campaign_event.emit("escape");return true
	if action.begins_with("hide_") and phase()=="sunday_escape":
		var id:=action.trim_prefix("hide_")
		if not covers.has(id) or actor.position.distance_to(covers[id])>1.0:return false
		actor.concealed=not actor.concealed;actor.crouching=actor.concealed
		if actor.concealed:actor.torch.hide()
		save();return true
	return false
func begin_escape() -> void:
	Session.campaign.phase="sunday_escape";Session.stage=6
	state().doors.stock=false;state().generator_mode="off";state().orders={"Dery":"hold","Felps":"hold"}
	for actor in world.characters.values():actor.torch.show()
	spawn_killer();apply_scene();save();Session.checkpoint()
	Dialogue.play("sunday_trap",[["","O DISJUNTOR CAI. A PORTA DO ESTOQUE TRAVA."],["Dery","Felps! Fechou atrás de mim. Tem alguém naquela passagem."],["Felps","Tô no salão. Liga o circuito do estoque no gerador; eu destravo daqui. Não corre sem olhar!"],["","F lanterna • agachar reduz ruído • E nas coberturas • Tab troca • H acompanhar/aguardar."]])
func on_noise(at: Vector3,strength: float) -> void:
	if is_instance_valid(killer):killer.hear(at,strength)
func command_companion() -> bool:
	if not threat_active() or Dialogue.active:return false
	var actor: DepotPlayer=world.characters.Felps if world.player.identity=="Dery" else world.characters.Dery
	state().orders[actor.identity]="hold" if state().orders[actor.identity]=="follow" else "follow"
	actor.concealed=false;world.notice.emit(actor.display_name()+": "+("vou te acompanhar." if state().orders[actor.identity]=="follow" else "vou esperar em cobertura."))
	on_noise(world.player.position,7);save();return true
func companion_route(from: Vector3,to: Vector3) -> PackedVector3Array:
	var avoid:=obstacles()
	avoid.append(Rect2(killer.position.x-.8,killer.position.z-.8,1.6,1.6))
	var safe:=world.navigation.path_with_obstacles(from,to,avoid)
	# If a threat fills the only doorway, keep moving along the escape route.
	# A hard exclusion must not strand the companion against the corridor wall.
	if safe.is_empty():safe=route(from,to)
	if safe.size()>1 and Vector2(safe[0].x-from.x,safe[0].z-from.z).length()<.22:safe.remove_at(0)
	return safe
func evade_destination(actor: DepotPlayer) -> Vector3:
	var best:=actor.position;var best_score:=actor.position.distance_to(killer.position)*2.0-actor.position.distance_to(world.player.position)*.4
	for radius in [1.6,2.8]:
		for step in 8:
			var direction:=Vector3(sin(step*TAU/8.0),0,cos(step*TAU/8.0))
			var candidate:=world.navigation.nearest_walkable(actor.position+direction*radius)
			var path:=companion_route(actor.position,candidate)
			if path.is_empty():continue
			var length:=0.0;var previous:=actor.position
			for point in path:length+=previous.distance_to(point);previous=point
			if length>4.5:continue
			var score:=candidate.distance_to(killer.position)*2.0-candidate.distance_to(world.player.position)*.4
			if score>best_score+.25:best=candidate;best_score=score
	return best
func companion_tick() -> void:
	var actor: DepotPlayer=world.characters.Felps if world.player.identity=="Dery" else world.characters.Dery
	actor.assisted_speed=3.65;open_nearby_doors(actor)
	var destination:=actor.position
	var following: bool=state().orders[actor.identity]=="follow"
	if following and actor.position.distance_to(world.player.position)>1.45:
		var requested:=world.navigation.nearest_walkable(world.player.position-world.player.visual.global_basis.z*1.1+world.player.visual.global_basis.x*.3)
		if not companion_route(actor.position,requested).is_empty():destination=requested
	if not following or destination==actor.position and actor.position.distance_to(world.player.position)>2.5:
		var best:=INF
		for point in covers.values():
			var path:=companion_route(actor.position,point)
			if path.is_empty():continue
			var score: float=actor.position.distance_squared_to(point)+(30.0 if killer.clear_line(point+Vector3.UP*.92) else 0.0)
			if score<best:destination=point;best=score
	# Do not stand beside the player waiting to be struck while a shutter opens.
	if actor.position.distance_to(killer.position)<2.4 and killer.clear_line(actor.position+Vector3.UP*.92) and (not following or actor.position.distance_to(world.player.position)<2.2):
		var escape:=evade_destination(actor)
		if escape!=actor.position:destination=escape
	if destination.distance_to(actor.position)>.3:
		actor.concealed=false;actor.assisted_path=companion_route(actor.position,destination)
	else:
		actor.assisted_path.clear();actor.concealed=not following or actor.position.distance_to(world.player.position)>2.5
		if actor.concealed:actor.torch.hide()
func at_exit(actor: DepotPlayer) -> bool:
	for node in exits:
		if node.visible and actor.position.distance_to(node.position)<2.2:return true
	return false
func together_at_exit() -> bool:
	for node in exits:
		if not node.visible:continue
		if world.characters.Dery.position.distance_to(node.position)<2.2 and world.characters.Felps.position.distance_to(node.position)<2.2:return true
	return false
func proof_preserved(survivors: Array[String]) -> bool:
	return state().proof=="offsite" or state().proof=="carried" and str(state().get("proof_carrier","")) in survivors
func finish(alone: bool) -> bool:
	if not threat_active() or not at_exit(world.player) or not alone and not together_at_exit():return false
	var survivors: Array[String]=[]
	survivors.assign([world.player.identity] if alone else ["Dery","Felps"])
	var proof:=proof_preserved(survivors)
	var id:="alone" if alone else "resolved" if proof else "unresolved"
	Session.campaign.ending={"id":id,"survivors":survivors,"proof":proof,"help":Session.flag("help_notified"),"exit_prepared":Session.campaign.decisions.get("exit","")=="prepared"}
	Session.campaign.phase="campaign_complete";Session.stage=7;Session.finale_seen=true
	if 2 not in Session.campaign.completed_nights:Session.campaign.completed_nights.append(2)
	Session.campaign.reports.sunday=Session.campaign.ending.duplicate(true)
	stopped=true;world.active=false
	for actor in world.characters.values():actor.input_locked=true;actor.assisted_path.clear()
	save();world.campaign_event.emit("ending");return true
func caught(identity: String) -> void:
	if not threat_active():return
	caught_identity=identity;stopped=true;world.active=false
	for actor in world.characters.values():actor.input_locked=true;actor.assisted_path.clear()
	Session.save_retry();world.notice.emit(("Deryk" if identity=="Dery" else "Felps")+" foi alcançado.")
	world.campaign_event.emit("defeat")
func apply_scene() -> void:
	if int(Session.campaign.night)!=2:return
	apply_doors();world.depot.access.evidence.visible=not Session.flag("module_found")
	helper.visible=Session.flag("help_notified");helper.process_mode=Node.PROCESS_MODE_INHERIT if helper.visible else Node.PROCESS_MODE_DISABLED
	exits[0].visible=Session.flag("help_notified")
	world.friday.apply_power()
	var danger: bool=phase() in ["sunday_escape","campaign_complete"]
	var stock_on: bool=not danger or state().generator_mode=="stock"
	var shop_on: bool=not danger or state().generator_mode=="salon"
	for light in world.friday.lights:
		var powered: bool=stock_on if light.global_position.z< -11 else shop_on
		light.set_meta("circuit_on",powered);light.visible=powered and (not light.get_meta("detail_light",false) or Preferences.pixel_scale<3)
	for material in world.friday.emitters:material.emission_enabled=shop_on
	for light in world.friday.batteries:light.visible=not stock_on or not shop_on
	world.sound.set_store_power(stock_on or shop_on,false)
	world.depot.counter.screen_text.text="DOMINGO • LOJA FECHADA\nDVR / RECUPERAÇÃO" if not Session.flag("proof_destroyed") else "DVR DESTRUÍDO\nSEM SINAL"
	for shutter in world.friday.shutters:
		shutter.visible=danger and not Session.flag("front_open")
		shutter.position.y=1.7
		for shape in shutter.find_children("*","CollisionShape3D",true,false):shape.set_deferred("disabled",not shutter.visible)
func tick(delta: float) -> void:
	if int(Session.campaign.night)!=2 or not threat_active() or Dialogue.active:return
	if desk_open and killer.position.distance_to(world.player.position)<4.5:world.desk_closed.emit();world.notice.emit("Ele está perto! Saia do terminal.")
	if not str(state().crank_actor).is_empty():
		var actor: DepotPlayer=world.characters[state().crank_actor]
		if actor.position.distance_to(crank.position)>2.65:state().crank_actor="";world.notice.emit("Abertura interrompida. Volte ao comando da saída.")
		else:
			state().crank_time-=delta
			if state().crank_time<=0:
				Session.campaign.flags.front_open=true;state().crank_actor="";save();world.notice.emit("Saída aberta. Vá pela calçada à direita; reúna os dois no ponto de encontro.")
	if state().proof=="recorder" and not Session.flag("proof_destroyed") and killer.position.distance_to(CheckoutFixture.CUSTOMER_POSITION)<1.5:
		Session.campaign.flags.proof_destroyed=true;save();world.notice.emit("Ele destruiu o gravador. A cópia fora dele ainda pode estar segura.")
	update_wait-=delta;autosave_wait-=delta
	if update_wait<=0:
		var partner: DepotPlayer=world.characters.Felps if world.player.identity=="Dery" else world.characters.Dery
		update_wait=.18 if killer.position.distance_to(partner.position)<5 else .6
		companion_tick()
	if autosave_wait<=0:
		autosave_wait=5
		if not stopped:Session.save_shift(world.player.position)
