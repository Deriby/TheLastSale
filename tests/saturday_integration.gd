extends "res://tests/friday_integration.gd"
## Saturday: actual counter input, both full customer routes, physical evidence and saves.
func wait_customer() -> bool:
	for i in 3200:
		await ticks(1)
		if is_instance_valid(world.customer) and world.customer.state==Customer.State.WAITING and not world.customer.purchase_complete:return true
	print("SATURDAY_CUSTOMER_BLOCKED phase=",Session.campaign.phase," customer=",world.customer.position if is_instance_valid(world.customer) else Vector3.ZERO," Dery=",world.characters.Dery.position)
	return false
func serve() -> bool:
	if not world.try_checkout(world.player):return false
	clear_dialogue();await ticks(2)
	for sku in world.sale.order:
		for i in int(world.sale.order[sku]):
			if not world.register_product(sku):return false
	if not world.checkout_step("confirm") or not world.checkout_step("receive"):return false
	var due:=world.sale.change_due()
	for coin in ShopSale.COINS:
		while due>=coin:
			if not world.checkout_step("coin",coin):return false
			due-=coin
	if not world.checkout_step("change"):return false
	return world.checkout_step("deliver")
func run() -> void:
	Engine.time_scale=4;Session.new_shift();Session.campaign.clues.local_outage=true;Session.campaign.completed_nights=[0]
	Session.advance_to_saturday()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await ticks(2)
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;player=world.player
	check(not world.try_surveillance(),"Deryk não pode operar o monitor e a abertura exige conversa")
	check(await approach(CheckoutFixture.CUSTOMER_POSITION) and world.depot.staff_talk.activate(world.player),"Deryk alcança Felps e começa o sábado pelo diálogo físico")
	clear_dialogue();world.switch_player();await ticks(3)
	await key_press(KEY_C)
	var panel: SurveillancePanel=app.interface.surveillance
	check(panel!=null and world.surveillance_open and world.player.input_locked,"C no caixa abre o monitor real e bloqueia locomoção de Felps")
	if panel==null:get_tree().quit(1);return
	check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(panel.get_global_rect()),"monitor cabe na janela e mantém interface independente da resolução PS1")
	check((panel.camera.cull_mask & 32)==0,"lente do CCTV exclui a própria carcaça física da imagem")
	check(panel.feed.world_3d==world.get_world_3d() and panel.feed.size==Vector2i(384,216),"câmera compartilha o mundo existente em resolução limitada")
	check(app.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED and panel.find_children("*","SubViewport",true,false).size()==1,"monitor usa um único viewport adicional e suspende a renderização encoberta")
	var camera_id:=panel.camera.get_instance_id();var player_camera:=world.player.camera_rig.camera
	for i in 3:panel.find_child("Camera"+str(i),true,false).pressed.emit()
	check(panel.camera.get_instance_id()==camera_id and panel.channel==2 and player_camera.current and panel.camera.current,"trocar os três canais reutiliza câmera e preserva a câmera do protagonista no viewport original")
	panel.show_page(1);await ticks(2)
	check(panel.feed.render_target_update_mode==SubViewport.UPDATE_DISABLED and panel.archive.text.contains("SEM REPRODUÇÃO DE VÍDEO"),"eventos são identificados como texto e param a renderização do canal")
	check(not world.saturday.console_action("review_events") and not world.saturday.decide("evidence","copy"),"monitor bloqueia pistas inexistentes e decisões prematuras")
	check(not world.switch_player() and not world.try_checkout(world.player),"troca e atendimento não vazam por baixo do monitor aberto")
	await key_press(KEY_ESCAPE)
	check(app.interface.surveillance==null and not world.surveillance_open and not world.player.input_locked and app.viewport.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"Esc libera movimento, mouse e renderização normal")
	await key_press(KEY_C);await key_press(KEY_C)
	check(app.interface.surveillance==null and not world.surveillance_open,"C fecha o monitor sem deixar um viewport ativo")
	await key_press(KEY_C);await key_press(KEY_TAB)
	check(app.interface.surveillance==null and world.player.identity=="Dery" and not world.characters.Felps.input_locked,"Tab sai do monitor e entrega controle a Deryk sem travar Felps")
	await key_press(KEY_TAB);await key_press(KEY_C);app.interface.set_paused(true)
	check(app.interface.surveillance==null and get_tree().paused,"pausa externa fecha e desativa o canal de segurança")
	app.interface.set_paused(false)
	check(await wait_customer() and world.customer.identity=="ClienteTrabalho","primeiro cliente percorre loja e espera com o novo pedido de sábado")
	check(await serve(),"Felps registra e entrega o primeiro pedido pela operação normal de caixa")
	if Session.receipts.is_empty():get_tree().quit(1);return
	check(await wait_customer() and world.customer.identity=="ClienteBone","cliente de boné da sexta volta como a mesma identidade substituível")
	check(await serve(),"cliente recorrente conclui compra após mencionar a porta interna")
	if Session.receipts.size()<2:get_tree().quit(1);return
	for i in 2200:
		await ticks(1)
		if Session.campaign.phase=="saturday_investigation":break
	clear_dialogue()
	check(Session.customers_served==2 and Session.campaign.phase=="saturday_investigation" and not is_instance_valid(world.customer),"investigação só começa após a saída física do segundo cliente")
	check(Session.receipts.size()==2 and Session.receipts[1].customer=="ClienteBone" and Session.receipts[1].night==1 and Session.receipts[1].has("time"),"recibo persistente identifica visita, noite e horário sem duplicar receita")
	for i in 400:await ticks(1)
	var child_present:=false
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		if friend.identity=="Bryan" and not friend.leaving:child_present=true
	check(not child_present and not Session.campaign.clues.has("witness_Bryan"),"Bryan sai antes da ameaça mesmo sem conversa opcional")
	await key_press(KEY_C);panel=app.interface.surveillance;panel.select_channel(2)
	check(Session.flag("camera_movement") and Session.campaign.records.size()==2,"consulta ao pátio mostra movimento físico na porta e registra observação uma única vez")
	panel.select_channel(0);panel.select_channel(2)
	check(Session.campaign.records.size()==2,"voltar ao canal não repete o movimento nem duplica o registro")
	panel.show_page(1)
	panel.find_child("ReviewEvents",true,false).pressed.emit();panel.find_child("CompareReceipt",true,false).pressed.emit()
	check(Session.campaign.clues.get("dvr_service",false) and Session.campaign.clues.get("visitor_receipt",false),"botões reais anotam evento e separam o recibo sem acusação conclusiva")
	check(not world.saturday.complete_clues() and not world.saturday.decide("help","contact"),"DVR e recibo não substituem a inspeção física de Deryk")
	Session.save_shift(world.player.global_position);await reload_world()
	check(app.interface.surveillance==null and not world.surveillance_open and not world.player.input_locked and Session.receipts.size()==2 and Session.campaign.records.size()==2,"continuar com monitor aberto fecha a interface e preserva recibos e registros")
	world.switch_player();player=world.player
	check(not world.saturday.inspect("door",player),"inspeção não pode ser ativada à distância")
	check(await approach(Vector3(4.85,0,-10.35)),"Deryk chega ao estoque pelo corredor real")
	var door:=find_interaction(world.depot.stock_door,"door");door.activate(player);await ticks(12)
	check(await approach(Vector3(4.9,0,-12.0)) and await approach(Vector3(.2,0,-14.75)),"percurso físico até os vestígios respeita porta e obstáculos")
	check(find_interaction(world.depot.old_door,"note").activate(player),"Deryk examina a tinta riscada da porta antiga")
	clear_dialogue()
	check(find_interaction(world.saturday.board,"investigation").activate(player),"caixa deslocada tem interação própria e vestígios no chão")
	clear_dialogue()
	check(world.saturday.complete_clues() and Session.campaign.phase=="saturday_decisions" and not Session.campaign.clues.has("witness_Zirico"),"todas as pistas podem ser reunidas sem testemunhas opcionais")
	Session.save_shift(player.global_position);await reload_world()
	check(world.saturday.complete_clues() and Session.campaign.phase=="saturday_decisions","checkpoint de investigação preserva as quatro pistas e a etapa")
	world.switch_player();await key_press(KEY_C);panel=app.interface.surveillance;panel.show_page(2)
	panel.find_child("LeaveEvidence",true,false).pressed.emit();panel.find_child("WaitHelp",true,false).pressed.emit()
	check(Session.campaign.decisions.evidence=="recorder" and Session.campaign.decisions.help=="wait","decisões de esperar e não copiar são escolhas válidas e persistentes")
	panel.find_child("CopyEvidence",true,false).pressed.emit();panel.find_child("ContactHelp",true,false).pressed.emit()
	check(Session.campaign.decisions.evidence=="copy" and Session.campaign.decisions.help=="contact" and panel.feedback.text.contains("responsável"),"jogador revisa decisões antes de sair e recebe confirmação visível")
	await key_press(KEY_ESCAPE)
	check(await approach(Vector3(5.1,0,1.4)) and find_interaction(world.friday.exit_control,"campaign").activate(world.player),"Felps prepara a saída fisicamente no comando das portas")
	await ticks(3);clear_dialogue()
	check(Session.campaign.decisions.exit=="prepared" and Session.flag("door_attempt") and Session.campaign.phase=="closing","três decisões iniciam tentativa na porta e fechamento tenso")
	check(not find_interaction(world.depot.service_door,"door").activate(world.characters.Dery) and not world.friday.activate("exit",world.player),"pátio permanece trancado e saída exige conferência da dupla")
	Session.save_shift(world.player.global_position);await reload_world();clear_dialogue()
	check(Session.flag("door_attempt") and Session.campaign.decisions.evidence=="copy" and Session.campaign.phase=="closing","retomada após tentativa conserva perigo e escolhas sem repetir evento")
	check(await approach(CheckoutFixture.STAFF_POSITION) and world.depot.checkout.activate(world.player),"Felps retorna ao posto e fecha o caixa de sábado")
	world.switch_player();player=world.player
	check(find_interaction(world.depot.old_door,"note").activate(player),"Deryk confere a trava e encerra a inspeção antes de sair")
	clear_dialogue()
	check(await approach(Vector3(3.1,0,-12.1)) and find_interaction(world.friday.key_hook,"campaign").activate(player),"quadro apaga o salão após as duas conferências")
	door=find_interaction(world.depot.stock_door,"door")
	if not door.open:door.activate(player);await ticks(12)
	check(await approach(Vector3(4.9,0,-12)) and await approach(Vector3(4.9,0,-9)) and await approach(Vector3(5.1,0,1.4)),"Deryk deixa o estoque e alcança a frente por rota contínua")
	check(find_interaction(world.friday.exit_control,"campaign").activate(player),"chamada reúne a dupla para fechar sábado")
	for i in 1400:
		await ticks(1)
		if world.friday.both_outside():break
	check(world.friday.both_outside() and find_interaction(world.friday.exit_control,"campaign").activate(player),"ambos precisam chegar à calçada antes de baixar portas")
	await ticks(110)
	check(Session.campaign.phase=="complete" and 1 in Session.campaign.completed_nights and app.interface.night_panel!=null,"sábado termina com relatório e campanha salva")
	check(Session.campaign.reports.saturday.decisions.evidence=="copy" and Session.campaign.reports.saturday.receipts.size()==2,"resumo da segunda noite preserva suas decisões e os dois recibos")
	app.interface.night_panel.find_child("NextNight",true,false).pressed.emit();world=app.world;await ticks(3)
	check(int(Session.campaign.night)==2 and Session.campaign.phase=="sunday_intro" and Session.campaign.decisions.exit=="prepared" and Session.campaign.clues.door_marks,"passagem ao domingo conserva pistas e preparação e reinicia dados diários")
	check(Session.campaign.evidence_archive.receipts.size()==2 and Session.campaign.evidence_archive.records.size()==2,"cópia guarda dados reais de recibos e registros através da passagem de dia")
	check(Session.sales_cents==0 and Session.receipts.is_empty() and 0 in Session.campaign.completed_nights and 1 in Session.campaign.completed_nights,"histórico das noites concluídas permanece separado das vendas de domingo")
	Session.save_shift(world.player.global_position);await reload_world()
	check(int(Session.campaign.night)==2 and Session.campaign.decisions.help=="contact","retomada de domingo mantém o contato combinado no sábado")
	# Migration of published preview saves, including additive fields absent in v4.
	Session.campaign.night=1;Session.campaign.phase="saturday_preview_done";Session.campaign.erase("decisions");Session.campaign.erase("records")
	Session.save_shift(world.player.global_position);await reload_world()
	check(Session.campaign.phase=="saturday_intro" and Session.campaign.decisions.is_empty() and Session.campaign.records.is_empty(),"save da antiga prévia migra para sábado jogável com campos novos seguros")
	clear_dialogue();print("SATURDAY RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	# Retire spatial voices before freeing their listener's viewport.
	# The last checkpoint was loaded only a few accelerated physics ticks ago;
	# let the real-time mixer consume its pending starts before issuing stops.
	await get_tree().create_timer(.15,true,false,true).timeout
	app.world.sound.stop_all()
	await get_tree().create_timer(.25,true,false,true).timeout
	app.queue_free();await get_tree().process_frame
	Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear();await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
