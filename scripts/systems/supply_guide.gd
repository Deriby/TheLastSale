class_name SupplyGuide
extends Node3D
## Diegetic labels plus one native-resolution HUD destination; no lights or extra viewport.
var world: ShiftWorld
var boards: Dictionary={}
var delivery: Node3D
var shift_sheet: Node3D
var sheet_interaction: Interaction
var wait:=0.0
const DELIVERY_POINT:=Vector3(-4.12,1.14,-1.90)
func _ready() -> void:
	name="SupplyGuide"
	if int(Session.campaign.night)==0:
		boards.G1=tag(world.depot.fridge_target,"G1 • REPOSIÇÃO",Vector3(.70,2.35,0),Color("b9d4c0"))
		boards.P1=tag(world.depot.shelf_target,"P1 • REPOSIÇÃO",Vector3(-.66,1.92,0),Color("b9d4c0"))
		build_physical_boards()
		build_shift_sheet()
	delivery=Node3D.new();add_child(delivery);delivery.name="OrderDelivery";delivery.position=DELIVERY_POINT
	var mat:=Geo.material(Color("bd9e56"),"",.12)
	for x in [-.28,.28]:Geo.box(delivery,Vector3(x,.008,0),Vector3(.012,.009,.42),mat,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z in [-.21,.21]:Geo.box(delivery,Vector3(0,.008,z),Vector3(.56,.009,.012),mat,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sign:=tag(delivery,"ENTREGA DE PEDIDOS\n[E] DEIXAR PARA FELPS",Vector3(0,.48,0),Color("e7c980"));sign.font_size=24
	refresh()
func tag(parent: Node3D,value: String,at: Vector3,color: Color) -> Label3D:
	var item:=Geo.sign_text(parent,value,at,25,color);item.pixel_size=.0035;item.billboard=BaseMaterial3D.BILLBOARD_ENABLED;item.outline_size=4;item.outline_modulate=Color("17221d");item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return item
func active_order() -> bool:
	return world.sale!=null and world.sale.needs_bulk() and not world.sale.bulk_supplied and is_instance_valid(world.customer) and world.customer.service_started
func identify_crate(crate: Node3D,id: String) -> void:
	if crate.has_node("SupplyLabel"):return
	var sale_box:=id.begins_with("order_")
	var color:=Color("d8b268") if sale_box else Color("8dba9d") if StockTasks.JOBS.has(id) else Color("b4ada0")
	# A fixed band is readable at close range; the larger name follows the camera.
	var band:=Geo.box(crate,Vector3(0,.29,.228),Vector3(.59,.14,.008),Geo.material(color),false);band.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var text:=""
	if StockTasks.JOBS.has(id):text=str(StockTasks.JOBS[id].code)+" • REPOSIÇÃO"+(" EXTRA" if id=="stock_shelf" else "")+"\n"+str(StockTasks.JOBS[id].product)+"\n→ "+str(StockTasks.JOBS[id].target)
	elif sale_box:text="VENDA #%03d\nRETORNÁVEIS • 12 UN\n→ BALCÃO"%int(id.trim_prefix("order_"))
	else:text="CASCOS VAZIOS\n→ DEVOLUÇÕES"
	var label:=tag(crate,text,Vector3(0,.73,0),color.lightened(.2));label.name="SupplyLabel";label.font_size=22;label.pixel_size=.0028;label.set_meta("assist_color",color.lightened(.2))
	var paper:=Geo.box(crate,Vector3(0,.29,.234),Vector3(.59,.18,.002),Geo.material(Color("dfdbc4")),false);paper.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func refresh() -> void:
	for id in world.depot.crates:
		if not is_instance_valid(world.depot.crates[id]):continue
		var crate: Node3D=world.depot.crates[id]
		if not is_instance_valid(crate) or crate.is_queued_for_deletion():continue
		identify_crate(crate,id)
		style_crate_label(crate.get_node("SupplyLabel"))
		crate.get_node("SupplyLabel").visible=not (world.characters.Dery.carried==crate or world.characters.Felps.carried==crate)
	if boards.has("G1"):
		var missing:=2-StockTasks.required_count()
		boards.G1.text="G1 • FALTAM %d CAIXA(S)\nRETORNÁVEIS • R1 / R2"%missing if missing>0 else "G1 • ABASTECIDA"
		boards.G1.modulate=Color("0e130f") if missing>0 else Color("687565")
	if boards.has("P1"):boards.P1.text="P1 • FALTAM SALGADINHOS\nCAIXA R3 • REPOSIÇÃO EXTRA" if "stock_shelf" not in Session.stocked else "P1 • ABASTECIDA"
	delivery.visible=active_order() or world.sale!=null and world.characters.Dery.carried_id==world.sale.supply_id() and not world.sale.bulk_supplied
func goal() -> Dictionary:
	var actor:=world.player
	if actor==null or int(Session.campaign.night)==2 or actor.identity!="Dery":return {}
	if int(Session.campaign.night)==0 and Session.campaign.phase not in ["routine","restored"]:return {}
	var id:=actor.carried_id
	if StockTasks.JOBS.has(id):
		var target: Node3D=world.depot.fridge_target if StockTasks.JOBS[id].target=="G1" else world.depot.shelf_target
		return {"id":id,"at":target.global_position+Vector3(0,1.7,0),"text":"REPOR "+str(StockTasks.JOBS[id].target)+" • "+str(StockTasks.JOBS[id].product),"hint":"[E] abrir e repor" if StockTasks.JOBS[id].target=="G1" else "[E] repor"}
	if id.begins_with("order_"):
		return {"id":id,"at":DELIVERY_POINT+Vector3.UP*.35,"text":"BALCÃO • ENTREGAR PEDIDO #%03d"%int(id.trim_prefix("order_")),"hint":"[E] deixar para Felps"} if world.sale!=null and not world.sale.bulk_supplied and id==world.sale.supply_id() else {}
	if id=="loose":return {"id":id,"at":Vector3(-3.8,1.3,-13.8),"text":"DEVOLUÇÕES • CASCOS VAZIOS","hint":"[E] guardar no palete"}
	if actor.carried!=null:return {}
	if active_order():id=world.sale.supply_id()
	elif int(Session.campaign.night)==0 and Session.stage==0:return {"id":"greet","at":CheckoutFixture.CUSTOMER_POSITION+Vector3.UP*1.5,"text":"BALCÃO • CONVERSAR COM FELPS","hint":"[E] conversar"}
	elif int(Session.campaign.night)==0 and Session.campaign.phase=="routine":
		id=StockTasks.pending()
		if id.is_empty():id="loose" if not Session.organized else "stock_shelf" if "stock_shelf" not in Session.stocked else ""
	if id.is_empty() or not is_instance_valid(world.depot.crates.get(id)):return {}
	var crate: Node3D=world.depot.crates[id]
	return {"id":id,"at":crate.global_position+Vector3.UP*.7,"text":"ESTOQUE • PEGAR "+StockTasks.crate_name(id),"hint":"[E] pegar • "+(str(StockTasks.JOBS[id].target) if StockTasks.JOBS.has(id) else "BALCÃO" if id.begins_with("order_") else "DEVOLUÇÕES")}
func _process(delta: float) -> void:
	wait-=delta
	if wait<=0:wait=.2;refresh()

func priority_focus(actor: DepotPlayer) -> Interaction:
	if actor.identity!="Dery":return null
	var target: Node3D
	if StockTasks.JOBS.has(actor.carried_id):target=world.depot.fridge_target if StockTasks.JOBS[actor.carried_id].target=="G1" else world.depot.shelf_target
	elif actor.carried_id=="loose":
		for item in get_tree().get_nodes_in_group("interactables"):
			if item.kind=="pallet" and item.global_position.distance_to(actor.position)<1.8:return item
	if target==null or target.global_position.distance_to(actor.position)>1.8:return null
	var aim:=target.global_position+Vector3.UP*.95
	var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.2,aim,1,[actor.get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and not target.is_ancestor_of(hit.collider):return null
	for item in target.get_children():
		if item is Interaction:return item
	return null

func quiet_routine() -> bool:
	return Preferences.immersive_hud and int(Session.campaign.night)==0 and Session.campaign.phase=="routine"
func style_crate_label(label: Label3D) -> void:
	var quiet:=Preferences.immersive_hud and int(Session.campaign.night)==0
	if bool(label.get_meta("physical_label",false))==quiet:return
	label.set_meta("physical_label",quiet)
	label.billboard=BaseMaterial3D.BILLBOARD_DISABLED if quiet else BaseMaterial3D.BILLBOARD_ENABLED
	label.position=Vector3(0,.29,.238) if quiet else Vector3(0,.73,0)
	label.pixel_size=.0020 if quiet else .0028;label.outline_size=0 if quiet else 4
	label.modulate=Color("0e130f") if quiet else label.get_meta("assist_color",Color.WHITE)
func build_physical_boards() -> void:
	var paper:=Geo.material(Color("d7d5bd"));var clip:=Geo.material(Color("48574a"))
	var fridge: Node3D=world.depot.fridge_target
	Geo.box(fridge,Vector3(0,2.27,.39),Vector3(.70,.18,.018),paper,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.box(fridge,Vector3(0,2.16,.375),Vector3(.035,.12,.025),clip,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	boards.G1.position=Vector3(0,2.27,.405);boards.G1.pixel_size=.0016;boards.G1.font_size=20;boards.G1.billboard=BaseMaterial3D.BILLBOARD_DISABLED;boards.G1.outline_size=0
	var shelf: Node3D=world.depot.shelf_target
	Geo.box(shelf,Vector3(-.595,1.43,-.60),Vector3(.014,.20,.65),paper,false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	boards.P1.position=Vector3(-.606,1.43,-.60);boards.P1.rotation.y=-PI/2;boards.P1.pixel_size=.0015;boards.P1.font_size=20;boards.P1.billboard=BaseMaterial3D.BILLBOARD_DISABLED;boards.P1.outline_size=0;boards.P1.modulate=Color("0e130f")
func build_shift_sheet() -> void:
	shift_sheet=Node3D.new();shift_sheet.name="ShiftSheet";add_child(shift_sheet);shift_sheet.position=Vector3(-3.807,.88,-2.12);shift_sheet.rotation.y=PI/2
	Geo.box(shift_sheet,Vector3.ZERO,Vector3(.43,.30,.012),Geo.material(Color("d9d4b9")),false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.box(shift_sheet,Vector3(0,.15,.008),Vector3(.09,.025,.016),Geo.material(Color("47544b")),false).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var writing:=Geo.sign_text(shift_sheet,"TURNO • REPOSIÇÃO\nR1 / R2  →  G1\nR3  →  P1 (extra)\nCASCOS  →  DEVOLUÇÕES",Vector3(0,0,.009),18,Color("0e130f"));writing.pixel_size=.0020;writing.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body:=StaticBody3D.new();body.collision_layer=4;body.collision_mask=0;shift_sheet.add_child(body)
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.43,.30,.03);shape.shape=box;body.add_child(shape)
	sheet_interaction=world.depot.interact(shift_sheet,"guidance")
func work_line(actor: DepotPlayer) -> String:
	if actor.identity=="Felps":
		if Session.campaign.phase=="outage":return "Suspende o atendimento no caixa, Felps. Depois eu pego a chave no estoque e cuido do gerador no pátio." if not Session.flag("counter_secured") else "Eu cuido do gerador no pátio, pela porta dos fundos. Fica de olho no caixa."
		if Session.campaign.phase=="closing":return "Confere o caixa, que eu olho a porta antiga. Depois a gente apaga o salão no quadro e se encontra na frente."
		if active_order():return "Eu trago a caixa laranja VENDA #%03d pro balcão. O atendimento é contigo."%world.sale.id
		return "Eu cuido das R1 e R2 na G1 e dos cascos no estoque. O atendimento é contigo, Felps." if StockTasks.required_count()<2 or not Session.organized else "A reposição tá pronta. Continua no caixa que eu fico por aqui."
	if Session.campaign.phase=="outage":
		if not Session.flag("counter_secured"):return "Eu preciso suspender o atendimento no caixa. Depois tu pega a chave do gerador no suporte do estoque."
		return "A chave tá no suporte junto à porta do estoque. O gerador fica no pátio, pela porta dos fundos." if not Session.flag("generator_key") else "Liga o gerador no pátio. Eu fico de olho no caixa."
	if Session.campaign.phase=="closing":return "Eu confiro o caixa, tu olha a porta antiga. Depois a gente apaga o salão no quadro e se encontra na frente."
	if StockTasks.JOBS.has(actor.carried_id):return "Essa "+str(StockTasks.JOBS[actor.carried_id].code)+" vai na "+StockTasks.destination(actor.carried_id)+". O código tá na etiqueta."
	if actor.carried_id=="loose":return "Os cascos vão no palete DEVOLUÇÕES, encostado no fundo esquerdo do estoque."
	if active_order():return "A caixa laranja VENDA #%03d é desse cliente. Traz pro balcão; as verdes são da reposição."%world.sale.id
	if StockTasks.required_count()==1:return "Falta só a "+str(StockTasks.JOBS[StockTasks.pending()].code)+" pra G1, a primeira geladeira da parede esquerda."
	if StockTasks.required_count()<2:return "As R1 e R2 estão no estoque, pela porta no fundo do corredor. São pra G1, a primeira geladeira da parede esquerda."
	if not Session.organized:return "Só falta tirar os cascos vazios do caminho e pôr no palete DEVOLUÇÕES, no estoque."
	return "A reposição tá pronta. Eu seguro o atendimento no caixa. O resto ficou anotado no caderno."
func read_shift_sheet(actor: DepotPlayer) -> bool:
	if int(Session.campaign.night)!=0 or not world.active or Dialogue.active or world.cashier_open or world.surveillance_open or world.sunday.desk_open or actor.global_position.distance_to(shift_sheet.global_position)>2.2:return false
	return Dialogue.play("shift_sheet",[[actor.identity,"Deixa eu conferir o que falta."],["Felps" if actor.identity=="Dery" else "Dery",work_line(actor)]])
