extends "res://tests/friday_integration.gd"
## Reproduce user actions through E/focus, including early stocking, wrong crates and a full sale.
func handled() -> void:
	for i in 160:
		await ticks(1)
		if not world.player.motion.action_active and not world.player.handling.busy:break
	await ticks(3)
func stand(at: Vector3,yaw: float) -> void:
	world.player.position=at;world.player.velocity=Vector3.ZERO;world.player.camera_rig.yaw=yaw;world.player.camera_rig.pitch=-.1;world.player.reset_physics_interpolation();await ticks(5)
func take(id: String) -> void:
	var crate: Node3D=world.depot.crates[id]
	await stand(crate.global_position+Vector3(0,0,.7),0)
	check(find_interaction(crate,"crate").activate(world.player),"pega caixa identificada "+id)
	await handled()
func run() -> void:
	Engine.physics_ticks_per_second=120;Engine.time_scale=2;Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await ticks(2)
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;player=world.player
	check(world.depot.crates.stock_1.get_node("SupplyLabel").text.contains("R1") and world.depot.crates.loose.get_node("SupplyLabel").text.contains("CASCOS VAZIOS"),"caixas distinguem reposição e cascos vazios antes de qualquer coleta")
	check(world.supplies.boards.G1.text.contains("FALTAM 2") and world.supplies.boards.P1.text.contains("R3"),"geladeira G1 e prateleira P1 mostram falta e caixa necessária")
	await take("stock_1")
	check(world.supplies.goal().text.contains("REPOR G1") and app.interface.objective.text.contains("R1"),"pegar R1 troca objetivo de busca pelo destino correto")
	await stand(Vector3(-4.10,0,-4.8),-PI/2)
	check(world.player.target==find_interaction(world.depot.fridge_target,"fridge"),"caixa carregada não oculta o foco da geladeira mesmo com câmera de ombro")
	await key_press(KEY_E);await ticks(30)
	check(world.depot.fridge_target.opened and world.player.carried_id=="stock_1","primeiro E abre a geladeira sem consumir a caixa")
	await key_press(KEY_E);await handled()
	check("stock_1" in Session.stocked and world.player.carried==null and Session.stage==0,"segundo E repõe antes da conversa inicial sem bloqueio silencioso da etapa")
	check(world.supplies.boards.G1.text.contains("FALTAM 1"),"necessidade de G1 diminui após entrega")
	world.depot.staff_talk.activate(world.player);clear_dialogue()
	# Conversation still requires the physical counter; move there explicitly.
	if Session.stage==0:
		await stand(CheckoutFixture.CUSTOMER_POSITION,PI/2);world.depot.staff_talk.activate(world.player);clear_dialogue()
	check(Session.stage==2,"conversa reconhece reposição antecipada e mantém somente a caixa restante")
	var shelf_initial: int=world.depot.shelf_target.products.groups["snack_0"].baked_count
	await take("stock_shelf")
	await stand(Vector3(-4.1,0,-4.8),-PI/2)
	check(not find_interaction(world.depot.fridge_target,"fridge").activate(world.player) and world.player.carried_id=="stock_shelf" and app.interface.notice_label.text.contains("P1"),"caixa R3 na geladeira informa destino P1 e preserva mercadoria")
	await stand(Vector3(-3.1,0,-4.7),-PI/2)
	check(world.player.target!=null and world.player.target.kind=="shelf","prateleira correta tem foco alcançável com a caixa")
	await key_press(KEY_E);await handled()
	check("stock_shelf" in Session.stocked and Session.stage==2 and world.depot.shelf_target.products.groups["snack_0"].baked_count==shelf_initial+3,"R3 preenche lacuna visível da prateleira sem contar como reposição obrigatória de G1")
	Session.save_shift(world.player.position);app.start_saved();world=app.world;player=world.player;await ticks(5)
	check(world.depot.shelf_target.restock_count==1 and world.depot.fridge_target.restock_count==1 and not is_instance_valid(world.depot.crates.get("stock_shelf")),"continuar restaura destinos separados e não recria caixa já usada")
	await take("stock_2");await stand(Vector3(-4.10,0,-4.8),-PI/2)
	await key_press(KEY_E);await ticks(30);await key_press(KEY_E);await handled()
	check(Session.stage==3 and StockTasks.required_count()==2 and world.depot.fridge_target.restock_count==2,"R2 completa G1 mesmo após a reposição extra e a retomada")
	await take("loose");await stand(Vector3(-4.10,0,-4.8),-PI/2)
	check(not find_interaction(world.depot.fridge_target,"fridge").activate(world.player) and world.player.carried_id=="loose" and app.interface.notice_label.text.contains("DEVOLUÇÕES"),"cascos vazios não viram mercadoria de geladeira nem desaparecem")
	await stand(Vector3(-3.8,0,-12.8),0);await key_press(KEY_E);await handled()
	check(Session.organized and world.player.carried==null,"marcação de devoluções recebe a caixa vazia por E");clear_dialogue()
	if is_instance_valid(world.customer):world.customer.free();world.customer=null
	world.sale=ShopSale.create(2);world.ensure_order_crate();world.spawn_customer(false,{"position":[-3.1,0,-2.7],"state":int(Customer.State.WAITING),"service_started":true,"identity":"ClienteTrabalho","appearance":4})
	world.select_player("Felps");app.interface.open_checkout(world);await ticks(3)
	check(app.interface.checkout!=null and app.interface.checkout.find_child("CallDeryk",true,false)!=null,"pedido de caixa fechada oferece chamada real de Deryk")
	app.interface.checkout.find_child("CallDeryk",true,false).pressed.emit();await ticks(4)
	check(world.player.identity=="Dery" and world.supplies.goal().id==world.sale.supply_id(),"chamada marca a caixa laranja daquele pedido")
	world.supplies.refresh()
	check(world.depot.crates[world.sale.supply_id()].get_node("SupplyLabel").text.contains("VENDA #002"),"caixa de venda tem número diferente das caixas de reposição")
	await take(world.sale.supply_id());await stand(Vector3(-4.1,0,-4.8),-PI/2)
	check(not find_interaction(world.depot.fridge_target,"fridge").activate(world.player) and world.player.carried_id=="order_2" and app.interface.notice_label.text.contains("balcão"),"caixa de venda não abastece geladeira e avisa onde entregar")
	check(world.supplies.goal().text.contains("ENTREGAR PEDIDO #002") and world.supplies.delivery.visible,"transportar pedido mostra ponto físico e indicação de entrega no balcão")
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=false;Preferences.changed.emit();await get_tree().process_frame;await get_tree().process_frame
	check(app.interface.supply_marker.visible and Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.supply_marker.get_global_rect()),"marcador de destino permanece legível e dentro da interface em PS1 320x240")
	Preferences.ps1_high_resolution=true;Preferences.changed.emit();await get_tree().process_frame;await get_tree().process_frame
	check(app.interface.supply_marker.visible and Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.supply_marker.get_global_rect()),"PS1/2 640x480 mantém marcador na interface nativa")
	await stand(CheckoutFixture.CUSTOMER_POSITION+Vector3(.55,0,0),PI/2)
	check(world.player.target==world.depot.checkout,"E no balcão prioriza entrega de Deryk em vez de conversa com Felps")
	await key_press(KEY_E);await handled()
	check(world.sale.bulk_supplied and world.player.carried==null and not world.can_supply_order(world.player),"entrega no balcão consome uma caixa e libera o pedido uma única vez")
	world.select_player("Felps");check(world.try_checkout(world.player),"Felps retoma a venda depois da entrega de Deryk")
	clear_dialogue()
	world.register_product("case_returnable",1);check(world.checkout_step("confirm"),"mercadoria entregue permite conferir e cobrar")
	world.checkout_step("receive");world.checkout_step("coin",2000);world.checkout_step("coin",500);world.checkout_step("coin",200);world.checkout_step("coin",100);world.checkout_step("change")
	check(world.checkout_step("deliver") and Session.sales_cents==7200 and Session.receipts.size()==1,"Felps finaliza venda de retornáveis e registra um único recibo")
	world.supplies.refresh();check(not world.supplies.delivery.visible,"marcação da entrega some após receber a mercadoria")
	Session.advance_to_saturday();app.build_world();world=app.world;world.active=true;await ticks(3)
	# These last two transitions are staged within milliseconds by the test.
	# Give each new viewport listener a real mixer cycle before replacing it.
	await get_tree().create_timer(.15,true,false,true).timeout
	check(not world.depot.crates.has("stock_1") and not world.depot.fridge_target.needs_restock and world.supplies.boards.is_empty(),"sábado não recria caixas de reposição da sexta nem sinaliza falta inexistente")
	Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;await ticks(3)
	await get_tree().create_timer(.15,true,false,true).timeout
	check(not world.depot.crates.has("stock_1") and not app.interface.supply_marker.visible,"domingo de investigação não oferece caixas de trabalho sem destino")
	print("SUPPLY RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	# Retire spatial voices before freeing their listener's viewport.
	app.world.sound.stop_all()
	await get_tree().create_timer(.25,true,false,true).timeout
	app.queue_free();await get_tree().process_frame
	Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear();get_tree().quit(0 if failures.is_empty() else 1)
