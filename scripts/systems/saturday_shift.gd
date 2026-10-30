class_name SaturdayShift
extends Node3D
## Saturday owns investigation; FridayShift supplies the shared physical closing.
var world: ShiftWorld
var board: Node3D
var latch: Node3D
const REQUIRED: Array[String]=["dvr_service","door_marks","moved_boxes","visitor_receipt"]
const CAMERAS: Array[Dictionary]=[
	{"name":"01 • FACHADA","at":Vector3(-5.55,3.1,-.15),"target":Vector3(1,.8,4.5)},
	{"name":"02 • ESTOQUE","at":Vector3(2.8,3,-11.8),"target":Vector3(-.3,1,-15.5)},
	{"name":"03 • PÁTIO","at":Vector3(6.0,2.6,-20.3),"target":Vector3(4.65,1,-16.4)}]
func _ready() -> void:
	if int(Session.campaign.night)!=1:return
	# No extra shadow lights, camera viewports, or model instances at rest.
	for data in CAMERAS:
		var fixture:=Node3D.new();world.depot.add_child(fixture);fixture.position=data.at;fixture.look_at(data.target)
		Geo.box(fixture,Vector3.ZERO,Vector3(.14,.11,.25),Geo.material(Color("92988a")),false)
		Geo.box(fixture,Vector3(0,0,-.135),Vector3(.08,.06,.018),Geo.material(Color("202c28")),false)
		Geo.box(fixture,Vector3(0,.12,.03),Vector3(.035,.17,.035),Geo.material(Color("5b625a")),false)
		for mesh in fixture.find_children("*","MeshInstance3D",true,false):
			mesh.layers=32;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	board=Node3D.new();board.name="DisplacedReturns";world.depot.add_child(board);board.position=Vector3(-1.15,0,-14.8)
	# A shifted return crate, plus its old dusty outline, leaves the aisle free.
	RetailDetails.plastic_crate(board,Vector3(0,.0,0),Color("34556b"),1)
	board.rotation.y=.22
	world.depot.blockers.append(Rect2(-1.52,-15.07,.74,.55))
	world.navigation.configure(world.depot.blockers+world.street.blockers,Street.surface_height)
	var dust:=Geo.material(Color("77796b"))
	for x in [-.35,.35]:Geo.box(board,Vector3(x,.006,.42),Vector3(.025,.009,.65),dust,false)
	Geo.box(board,Vector3(0,.006,.74),Vector3(.72,.009,.025),dust,false)
	world.depot.interact(board,"investigation","boxes")
	var yard_light: OmniLight3D=world.depot.yard.get_node("YardBatteryLight")
	yard_light.omni_range=5.5;yard_light.light_energy=.65
	latch=Node3D.new();world.depot.service_door.add_child(latch);latch.position=Vector3(1.55,1.12,0)
	for side in [-1,1]:
		Geo.box(latch,Vector3(0,0,side*.09),Vector3(.19,.035,.035),Geo.material(Color("b8b7a8")),false)
		Geo.box(world.depot.service_door,Vector3(1.55,1.12,side*.067),Vector3(.10,.24,.01),Geo.material(Color("979d90")),false)
	for i in 4:
		var mark:=Geo.box(world.depot.old_door,Vector3(.48+i*.025,1.0+i*.023,.067),Vector3(.008,.18,.003),Geo.material(Color("b2ab88")),false)
		mark.rotation.z=-.25
	if phase() in ["saturday_investigation","saturday_decisions","closing","complete"]:
		for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.queue_free()
func phase() -> String:return str(Session.campaign.phase)
func save() -> void:
	Session.changed.emit();Session.save_shift(world.player.global_position)
func introduce(actor: DepotPlayer) -> bool:
	if Dialogue.active or phase()!="saturday_intro":return false
	Session.campaign.phase="saturday_routine";Session.stage=4
	# The Friday tutorial stock is already put away; Saturday has a different routine.
	Session.stocked.assign(["stock_1","stock_2"]);Session.organized=true
	for id in ["stock_1","stock_2"]:
		if is_instance_valid(world.depot.crates.get(id)):world.depot.crates[id].queue_free()
	if is_instance_valid(world.depot.crates.get("loose")):world.depot.crates.loose.position=Vector3(-3.8,.23,-13.8)
	save()
	Dialogue.play("saturday_intro",[["Felps","Avisei o responsável sobre a pane. Mandou a gente conferir o gravador e não mexer na instalação."],["Dery","Beleza. Eu olho o estoque. A rua não apagou ontem, aquilo foi só aqui."],["Felps","Tem dois pedidos antes de fechar. Aqui no caixa, C abre as câmeras e o caderno. A gente compara tudo depois."]])
	return true
func can_spawn() -> bool:return int(Session.campaign.night)==1 and phase()=="saturday_routine" and Session.customers_served<2
func next_identity() -> String:return "ClienteTrabalho" if Session.customers_served==0 else "ClienteBone"
func order(number: int) -> ShopSale:
	var result:=ShopSale.create(number)
	result.order={"water":1,"snack_0":2} if Session.customers_served==0 else {"beer_0":1}
	return result
func order_lines(who: Customer) -> Array:
	if who.identity=="ClienteBone":
		return [["Cliente de boné","Uma retornável. De novo até meia-noite?"],["Felps","A gente já vai fechar. Você veio ontem, né?"],["Cliente de boné","Vim. O gerador pegou? Aquela porta velha dos fundos emperra mesmo."],["Felps","Como você sabe da porta?"],["Cliente de boné","Conheço o bairro. Só isso."]]
	return [["Cliente de uniforme","Uma água e dois salgadinhos. A entrega de amanhã foi adiada, tá? Não abre o portão pra ninguém sem confirmar."],["Felps","Valeu por avisar. Vou deixar anotado."]]
func on_departure() -> void:
	if int(Session.campaign.night)==1 and Session.customers_served>=2 and phase()=="saturday_routine":begin_investigation()
func begin_investigation() -> void:
	Session.campaign.phase="saturday_investigation"
	Session.campaign.flags.visitor_left=true
	if Session.campaign.records.is_empty():
		Session.campaign.records.append({"id":"service_before_open","time":"21:32","text":"CAM 03 • Movimento no pátio antes da abertura. Nenhuma entrega autorizada. Arquivo de vídeo indisponível; evento textual preservado."})
	save()
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		if not friend.leaving:friend.depart(world.navigation.path(friend.global_position,Vector3(18,0,1.8)))
	if not Dialogue.active:
		Dialogue.play("saturday_investigate",[["Felps","O cara sabia da porta que nem dá pra ver da rua. Deixei o recibo separado."],["Dery","E essa caixa não tava aqui. Vou olhar os fundos. Você confere o gravador."],["Felps","Bryan já foi pra casa. Vamos conferir sem deixar ninguém entrar."]])
func can_open(actor: DepotPlayer) -> bool:
	return int(Session.campaign.night)==1 and phase() in ["saturday_routine","saturday_investigation","saturday_decisions"] and actor.identity=="Felps" and actor.global_position.distance_to(CheckoutFixture.STAFF_POSITION)<1.4 and not Dialogue.active and actor.carried==null
func at_console() -> bool:return world.surveillance_open and can_open(world.player)
func complete_clues() -> bool:
	for id in REQUIRED:
		if not Session.campaign.clues.get(id,false):return false
	return true
func discover(id: String) -> void:
	Session.campaign.clues[id]=true
	if complete_clues() and phase()=="saturday_investigation":Session.campaign.phase="saturday_decisions"
	save()
func console_action(action: String) -> bool:
	if not at_console():return false
	if action=="review_events":
		if not Session.flag("visitor_left"):return false
		discover("dvr_service");world.notice.emit("Evento registrado: houve movimento nos fundos antes da abertura. Não há identificação.");return true
	if action=="compare_receipt":
		if not Session.campaign.clues.get("dvr_service",false):return false
		for receipt in Session.receipts:
			if receipt.get("customer","")=="ClienteBone":
				discover("visitor_receipt");return true
	return false
func decide(key: String,value: String) -> bool:
	if not at_console() or not complete_clues() or phase()!="saturday_decisions":return false
	var allowed: Dictionary={"evidence":["copy","recorder"],"help":["contact","wait"],"exit":["unchanged"]}
	if not allowed.has(key) or value not in allowed[key]:return false
	Session.campaign.decisions[key]=value
	if key=="evidence":
		Session.campaign.evidence_archive={"records":Session.campaign.records.duplicate(true),"receipts":Session.receipts.duplicate(true),"night":1} if value=="copy" else {}
	save();return true
func prepare_exit(actor: DepotPlayer) -> bool:
	if int(Session.campaign.night)!=1 or not complete_clues() or phase()!="saturday_decisions" or Dialogue.active:return false
	if actor.global_position.distance_to(world.friday.exit_control.global_position)>2.65:return false
	Session.campaign.decisions.exit="prepared";save()
	world.notice.emit("Saída conferida: comando e passagem livres. Domingo, a dupla saberá por onde se reunir.")
	return true
func inspect(action: String,actor: DepotPlayer) -> bool:
	if int(Session.campaign.night)!=1 or phase() not in ["saturday_routine","saturday_investigation","saturday_decisions"] or Dialogue.active:return false
	if actor.identity!="Dery" or actor.carried!=null:
		world.notice.emit("Deryk precisa examinar os vestígios com as mãos livres.");return false
	var point: Vector3=world.depot.old_door.global_position if action=="door" else board.global_position
	if actor.global_position.distance_to(point)>2.65:return false
	if action=="door":
		discover("door_marks")
		Dialogue.play("saturday_door",[["Dery","A tinta tá riscada junto da fechadura. Isso aqui é recente."],["Felps","Não abre. Confere se tem outra marca no chão e volta pra cá."]])
	else:
		discover("moved_boxes")
		Dialogue.play("saturday_boxes",[["Dery","Tem uma marca limpa no pó. Arrastaram a caixa pra liberar essa porta."],["Felps","Então não foi só a luz. Anota isso junto com as imagens."]])
	return true
func familiar(identity: String,actor: DepotPlayer) -> bool:
	if int(Session.campaign.night)!=1 or Dialogue.active or phase() not in ["saturday_intro","saturday_routine"]:return false
	Session.campaign.clues["witness_"+identity]=true;save()
	if identity=="Bryan":
		Dialogue.play("familiar_Bryan",[["Bryan","Ontem eu vi um homem no portão quando vocês já tinham ido. Achei que trabalhava aqui."],[actor.identity,"Valeu por contar, Bryan. Vai pra casa agora, a gente resolve isso. Amanhã fala com a gente com calma."]])
		for friend in get_tree().get_nodes_in_group("familiar_npcs"):
			if friend.identity=="Bryan":friend.depart(world.navigation.path(friend.global_position,Vector3(18,0,1.8)))
	else:Dialogue.play("familiar_Zirico",[["Zirico","Ficou uma pessoa parada no corredor dos fundos. A rua acesa, só vocês sem luz."],[actor.identity,"Vou guardar isso. Se precisar, amanhã a gente combina de falar lá na frente."]])
	return true
func observe_channel(index: int) -> void:
	if index!=2 or not at_console() or not Session.flag("visitor_left") or Session.flag("camera_movement"):return
	Session.campaign.flags.camera_movement=true
	Session.campaign.records.append({"id":"live_door","time":Session.clock_text(),"text":"CAM 03 • A porta do pátio se moveu durante a consulta ao vivo. Ninguém identificado. Anotação de Felps."})
	var movement:=create_tween()
	for angle in [.045,0.0,.03,0.0]:movement.tween_property(world.depot.service_door,"rotation:y",angle,.45)
	world.sound.play_at("knock",world.depot.service_door.global_position)
	save()
func tick() -> void:
	if int(Session.campaign.night)!=1:return
	# An inactive Deryk must not occupy the customer's destination after the intro.
	var actor: DepotPlayer=world.characters.Dery
	if phase()=="saturday_routine" and not actor.controlled and not Dialogue.active and actor.assisted_path.is_empty() and actor.global_position.distance_to(CheckoutFixture.CUSTOMER_POSITION)<1.3:
		actor.assisted_path=world.navigation.path(actor.global_position,Vector3(3.1,0,-8.8))
	# Recover a checkpoint taken between sale completion and its departure callback.
	if phase()=="saturday_routine" and Session.customers_served>=2 and not is_instance_valid(world.customer) and not Dialogue.active:begin_investigation()
	if phase()!="saturday_decisions" or world.surveillance_open or Dialogue.active:return
	for key in ["evidence","help","exit"]:
		if not Session.campaign.decisions.has(key):return
	Session.campaign.flags.door_attempt=true;Session.campaign.phase="closing"
	var door:=world.depot.service_door
	# The visible handle rattles while the door remains physically shut and locked.
	door.rotation.y=0
	for child in door.get_children():
		if child is Interaction:child.open=false
	var rattle:=create_tween()
	for angle in [-.35,.18,-.25,0.0]:rattle.tween_property(latch,"rotation:z",angle,.14)
	world.sound.play_at("knock",door.global_position)
	save()
	Dialogue.play("saturday_attempt",[["","ALGUÉM FORÇA A PORTA DO PÁTIO."],["Dery","Felps. A maçaneta mexeu. Não era uma caixa caindo."],["Felps","Não vai atrás! Confere a trava daí. Eu fecho o caixa e a gente sai junto pela frente."]])
func journal() -> String:
	var lines: Array[String]=["CADERNO • SÁBADO",""]
	var labels: Dictionary={"local_outage":"Sexta: a falha atingiu só o depósito.","dvr_service":"DVR: movimento no pátio antes da abertura; rosto não identificado.","door_marks":"Tinta removida junto à fechadura antiga.","moved_boxes":"Caixa deslocada: o caminho até a porta foi liberado.","visitor_receipt":"Recibo do cliente de boné separado; ele conhece a área interna.","witness_Bryan":"Bryan viu alguém no portão fora do expediente.","witness_Zirico":"Zirico notou movimento na lateral."}
	for id in labels:
		if Session.campaign.clues.get(id,false):lines.append("• "+labels[id])
	lines.append("\nIsso confirma uma tentativa de acesso, não a identidade de quem estava lá.")
	lines.append("\nPREPARAÇÃO PARA DOMINGO")
	var choices: Dictionary={"copy":"Cópia dos registros e recibo guardada fora do gravador.","recorder":"Registros deixados somente no gravador.","contact":"Responsável avisado; contato combinado para domingo.","wait":"A dupla decidiu esperar antes de comunicar a suspeita.","prepared":"Saída da frente conferida; ponto de encontro combinado.","unchanged":"Saída ainda sem preparação."}
	for key in ["evidence","help","exit"]:
		lines.append("• "+str(choices.get(str(Session.campaign.decisions.get(key,"")),"Decisão pendente: "+str({"evidence":"registros","help":"contato","exit":"saída"}[key]))))
	return "\n".join(lines)
