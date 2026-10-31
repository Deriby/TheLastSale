extends "res://tests/integration.gd"
## Physical courier route, interrupted payment, recovery, companion and day boundary.
func reload_world() -> void:
	app.start_saved();world=app.world;player=world.player;await ticks(8)
func approach(at: Vector3) -> bool:
	var actor:=world.player
	var path:=world.navigation.path(actor.global_position,at)
	var result:=false
	for step in 1200:
		if Vector2(at.x-actor.position.x,at.z-actor.position.z).length()<.3:result=true;break
		while not path.is_empty() and Vector2(path[0].x-actor.position.x,path[0].z-actor.position.z).length()<.10:path.remove_at(0)
		if path.is_empty():path.append(at)
		var direction:=path[0]-actor.global_position;actor.camera_rig.yaw=atan2(-direction.x,-direction.z)
		Input.action_press("forward");await ticks(1)
	Input.action_release("forward");await ticks(2)
	if not result:print("FRIDAY_PATH_BLOCKED actor=",world.player.identity," at=",world.player.position," destination=",at)
	return result
func run() -> void:
	Engine.time_scale=4
	Session.new_shift();Session.stage=4;Session.stocked.assign(["stock_1","stock_2"]);Session.organized=true;Session.warning_delivered=true;Session.customers_served=3
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app)
	await get_tree().process_frame
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;player=world.player
	world.sale=ShopSale.create(1)
	for sku in world.sale.order:
		for i in int(world.sale.order[sku]):world.sale.register(sku)
	world.sale.confirm_items();world.sale.receive_cash();world.sale.add_coin(500)
	world.spawn_customer(false,{"position":[-3.1,0,-2.7],"state":int(Customer.State.WAITING),"service_started":true,"identity":"ClienteTrabalho","appearance":4})
	world.select_player("Felps");app.interface.open_checkout(world)
	var sale_id:=world.sale.id
	check(world.friday.begin_outage(),"sexta permite uma única pane recuperável durante atendimento em andamento")
	clear_dialogue();await ticks(90)
	check(not world.friday.begin_outage() and app.interface.checkout==null and not world.characters.Felps.input_locked,"pane fecha o painel sem prender Felps nem repetir o evento")
	check(not world.can_operate_register() and world.sale.selected_change()==500 and world.sale.phase==ShopSale.Phase.CHANGE,"sem energia a cobrança para e preserva troco e etapa da venda")
	var dark:=true
	for light in world.friday.lights:dark=dark and not light.visible
	check(dark and world.friday.batteries[0].visible and not world.sound.hum.playing and not world.sound.radio.playing,"pane apaga luzes comerciais e sons dos equipamentos, mantendo emergência")
	Preferences.pixel_scale=3;Preferences.changed.emit();await ticks(2)
	check(not world.depot.rear_fridges[0].get_node("CabinetLight").visible,"alterar qualidade durante apagão não religa geladeiras")
	Preferences.pixel_scale=1;Preferences.changed.emit()
	check(not world.friday.activate("generator",world.characters.Dery),"gerador exige chave e confirmação de Felps")
	check(world.depot.checkout.activate(world.player) and Session.flag("counter_secured"),"Felps suspende o atendimento fisicamente no posto do caixa")
	clear_dialogue();await ticks(2)
	check(not find_interaction(world.friday.key_hook,"campaign").activate(world.player),"Felps não recolhe a chave destinada a Deryk")
	world.switch_player();player=world.player
	check(await approach(Vector3(4.85,0,-10.35)),"Deryk alcança a porta do estoque durante o apagão")
	var door:=find_interaction(world.depot.stock_door,"door")
	if not door.open:door.activate(world.player)
	await ticks(12)
	check(await approach(Vector3(4.95,0,-11.8)) and await approach(Vector3(3.1,0,-12.1)),"Deryk atravessa a porta aberta e chega ao suporte da chave")
	check(find_interaction(world.friday.key_hook,"campaign").activate(world.player) and Session.flag("generator_key"),"chave é recolhida por interação e desaparece do suporte")
	Session.save_shift(world.player.global_position);await reload_world()
	check(Session.flag("generator_key") and Session.flag("counter_secured") and world.friday.is_outage() and not world.friday.key_mesh.visible,"continuar durante pane preserva chave, tarefa de Felps e luzes apagadas")
	check(world.sale.id==sale_id and world.sale.selected_change()==500 and world.customer.identity=="ClienteTrabalho","continuar mantém pedido, cliente provisório e troco interrompido")
	check(await approach(Vector3(4.8,0,-15.1)),"Deryk alcança a porta do pátio no fundo do estoque")
	door=find_interaction(world.depot.service_door,"door");door.activate(world.player);await ticks(12)
	check(await approach(Vector3(4.85,0,-17.2)) and await approach(Vector3(4.35,0,-19.4)),"Deryk sai por abertura real e caminha até o gerador externo")
	Session.save_shift(world.player.global_position);await reload_world()
	check(world.player.position.z< -18.5 and world.player.is_on_floor(),"checkpoint no pátio mantém posição e contato com o chão")
	check(find_interaction(world.depot.yard.generator,"campaign").activate(world.player) and Session.flag("generator_running"),"Deryk liga o gerador com a chave e a confirmação do salão")
	clear_dialogue();await ticks(90)
	check(world.friday.phase()=="restored" and world.sound.hum.playing and world.sound.radio.playing and world.friday.generator_hum.playing,"energia de reserva restaura equipamentos e inicia som local do gerador")
	check(Session.campaign.clues.get("local_outage",false) and world.sale.selected_change()==500,"observação da rua iluminada fica registrada e venda mantém o troco parcial")
	Session.save_shift(world.player.global_position);await reload_world()
	check(Session.flag("generator_running") and world.friday.generator_hum.playing and world.friday.phase()=="restored","continuar depois de ligar o gerador não exige repetir a tarefa")
	world.switch_player();clear_dialogue()
	check(world.try_checkout(world.player),"Felps retoma o atendimento interrompido quando a energia volta")
	world.checkout_step("coin",200);world.checkout_step("coin",100);world.checkout_step("coin",50);world.checkout_step("change")
	check(world.checkout_step("deliver") and Session.receipts.size()==1 and Session.sales_cents==1150,"atendimento retomado entrega compra e credita um único recibo")
	for i in 2200:
		await ticks(1)
		if world.friday.phase()=="closing":break
	clear_dialogue()
	check(world.friday.phase()=="closing" and not is_instance_valid(world.customer),"último cliente sai fisicamente antes de iniciar o fechamento")
	check(not world.friday.activate("exit",world.player),"saída é bloqueada enquanto faltam tarefas de fechamento")
	check(world.depot.checkout.activate(world.player) and Session.flag("till_closed"),"Felps confere e fecha o caixa após terminar todas as vendas")
	world.switch_player();player=world.player
	check(await approach(Vector3(4.8,0,-17.2)),"Deryk retorna do gerador pelo pátio")
	door=find_interaction(world.depot.service_door,"door")
	if not door.open:door.activate(world.player)
	await ticks(12)
	check(await approach(Vector3(4.85,0,-14.8)) and await approach(Vector3(0,0,-14.8)),"Deryk volta ao estoque e verifica a área antiga sem atravessar paredes")
	check(find_interaction(world.depot.old_door,"note").activate(world.player) and Session.flag("stock_checked"),"inspeção da porta antiga conclui a conferência do estoque")
	clear_dialogue()
	check(await approach(Vector3(3.1,0,-12.1)) and find_interaction(world.friday.key_hook,"campaign").activate(world.player),"quadro permite apagar o salão somente após caixa e estoque conferidos")
	check(Session.flag("lights_off") and not world.sound.radio.playing and world.sound.hum.playing,"fechamento silencia rádio e salão, preservando refrigeração")
	world.switch_player();player=world.player
	check(await approach(Vector3(5.1,0,1.4)),"Felps alcança o comando das portas pelo lado de fora")
	check(find_interaction(world.friday.exit_control,"campaign").activate(world.player),"chamar companheiro inicia encontro da dupla na calçada")
	var before: Vector3=world.characters.Dery.position;var no_teleport:=true
	for i in 1200:
		await ticks(1)
		var current: Vector3=world.characters.Dery.position
		no_teleport=no_teleport and current.distance_to(before)<.45;before=current
		if world.friday.both_outside():break
	check(no_teleport and world.friday.both_outside(),"companheiro percorre fisicamente o estoque e o salão até a calçada")
	if not world.friday.both_outside():
		print("COMPANION_BLOCKED ",world.characters.Dery.position," path=",world.characters.Dery.assisted_path)
		Engine.time_scale=1;get_tree().quit(1);return
	world.select_player("Dery");world.characters.Felps.position=CheckoutFixture.STAFF_POSITION;world.characters.Felps.reset_physics_interpolation()
	for i in 1200:
		await ticks(1)
		if world.friday.both_outside():break
	check(world.friday.both_outside(),"Felps também sai autonomamente do posto quando Deryk chama o companheiro")
	Session.save_shift(world.player.global_position);await reload_world()
	check(world.friday.phase()=="closing" and world.friday.ready_to_leave() and Session.flag("reunite") and world.friday.both_outside(),"retomada do fechamento preserva tarefas, encontro da dupla e posição na calçada")
	check(find_interaction(world.friday.exit_control,"campaign").activate(world.player),"portas só podem baixar com os dois protagonistas do lado de fora")
	clear_dialogue() # Finish the new shared closing exchange before the shutters.
	app.interface.set_paused(true);await get_tree().create_timer(2.0,true).timeout
	check(Session.campaign.phase=="closing" and app.interface.night_panel==null,"pausa congela o fechamento e impede que a noite termine com animação suspensa")
	app.interface.set_paused(false)
	await ticks(100)
	check(Session.campaign.phase=="complete" and 0 in Session.campaign.completed_nights and app.interface.night_panel!=null,"sexta conclui com resumo, salvamento e passagem de dia")
	check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.night_panel.get_global_rect()),"resumo e botão de transição cabem na janela com cenário PS1/PS1/2 independente")
	check(int(Session.campaign.reports.friday.sales_cents)==1150 and Session.campaign.reports.friday.receipts.size()==1,"resumo conserva vendas e recibos da sexta sem duplicação")
	Engine.time_scale=1
	app.interface.night_panel.find_child("NextNight",true,false).pressed.emit();world=app.world;player=world.player;await ticks(5)
	check(int(Session.campaign.night)==1 and app.interface.night_label.text.contains("SÁBADO") and Session.campaign.phase=="saturday_intro","transição prepara abertura de sábado e atualiza o dia no HUD")
	check(Session.campaign.clues.local_outage and 0 in Session.campaign.completed_nights and Session.sales_cents==0,"nova noite preserva pistas e histórico e reinicia o caixa diário")
	check(await approach(CheckoutFixture.CUSTOMER_POSITION) and world.depot.staff_talk.activate(world.player) and Session.campaign.phase=="saturday_routine","abertura de sábado reconhece sexta e libera a nova rotina após conversa no caixa")
	clear_dialogue();Session.save_shift(world.player.global_position);await reload_world()
	check(Session.campaign.phase=="saturday_routine" and world.saturday.can_spawn() and not world.friday.can_spawn(),"continuar no sábado retoma sua rotina sem reiniciar a sexta")
	var legacy:={"version":3,"stage":7,"stocked":["stock_1","stock_2"],"organized":true,"customers":3,"warning":true,"finale":true,"position":[0,0,-4]}
	var f:=FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close();await reload_world()
	check(Session.stage==6 and world.friday.is_outage() and not Session.finale_seen,"checkpoint completo da versão 3 migra para a pane e permite continuar a sexta")
	legacy.stage=6;legacy.finale=false
	f=FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close();await reload_world()
	check(Session.stage==6 and world.friday.is_outage(),"save antigo após o aviso e antes do fim da demonstração migra para a pane")
	Session.new_shift();Session.stage=6;Session.warning_delivered=true;Session.save_shift(world.player.global_position)
	var v4: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Session.SAVE_PATH));v4.version=4;v4.erase("retry")
	f=FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE);f.store_string(JSON.stringify(v4));f.close();await reload_world()
	check(world.friday.is_outage() and Dialogue.active,"save versão 4 na transição após o aviso retoma o apagão sem bloquear a noite")
	clear_dialogue()
	Session.campaign.phase="routine";Session.stage=6
	Dialogue.play("transition_resume",[["Felps","Vamos terminar essa conversa antes de conferir os fundos."]]);await ticks(3)
	var waited_for_dialogue:=world.friday.phase()=="routine"
	clear_dialogue();await ticks(3)
	check(waited_for_dialogue and world.friday.is_outage(),"transição em execução aguarda a conversa e retoma a pane mesmo sem callback anterior")
	clear_dialogue()
	print("FRIDAY RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	app.queue_free();await get_tree().process_frame;await get_tree().create_timer(.2).timeout
	Geo.materials.clear();CharacterModels.costume_materials.clear()
	get_tree().quit(0 if failures.is_empty() else 1)
