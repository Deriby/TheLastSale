class_name SupplyGuide
extends Node3D
## Diegetic labels plus one native-resolution HUD destination; no lights or extra viewport.
var world: ShiftWorld
var boards: Dictionary={}
var delivery: Node3D
var wait:=0.0
const DELIVERY_POINT:=Vector3(-4.12,1.14,-1.90)
func _ready() -> void:
	name="SupplyGuide"
	if int(Session.campaign.night)==0:
		boards.G1=tag(world.depot.fridge_target,"G1 • REPOSIÇÃO",Vector3(.70,2.35,0),Color("b9d4c0"))
		boards.P1=tag(world.depot.shelf_target,"P1 • REPOSIÇÃO",Vector3(-.66,1.92,0),Color("b9d4c0"))
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
	var label:=tag(crate,text,Vector3(0,.73,0),color.lightened(.2));label.name="SupplyLabel";label.font_size=22;label.pixel_size=.0028
func refresh() -> void:
	for id in world.depot.crates:
		if not is_instance_valid(world.depot.crates[id]):continue
		var crate: Node3D=world.depot.crates[id]
		if not is_instance_valid(crate) or crate.is_queued_for_deletion():continue
		identify_crate(crate,id)
		crate.get_node("SupplyLabel").visible=not (world.characters.Dery.carried==crate or world.characters.Felps.carried==crate)
	if boards.has("G1"):
		var missing:=2-StockTasks.required_count()
		boards.G1.text="G1 • FALTAM %d CAIXA(S)\nRETORNÁVEIS • R1 / R2"%missing if missing>0 else "G1 • ABASTECIDA"
		boards.G1.modulate=Color("b9d4c0") if missing>0 else Color("78847b")
	if boards.has("P1"):boards.P1.text="P1 • FALTAM SALGADINHOS\nCAIXA R3 • REPOSIÇÃO EXTRA" if "stock_shelf" not in Session.stocked else "P1 • ABASTECIDA"
	delivery.visible=active_order() or world.sale!=null and world.characters.Dery.carried_id==world.sale.supply_id() and not world.sale.bulk_supplied
func goal() -> Dictionary:
	var actor:=world.player
	if actor==null or int(Session.campaign.night)==2 or actor.identity!="Dery":return {}
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
