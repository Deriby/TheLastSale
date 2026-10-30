extends "res://tests/friday_integration.gd"
## Whole Sunday quest and physical cooperative escape, then perception and branches.
func walk(at: Vector3,sprint:=false) -> bool:
	var actor:=world.player
	var path:=world.sunday.route(actor.position,at)
	if path.size()>1 and actor.position.distance_to(path[0])<.22:path.remove_at(0)
	var refresh:=0
	for i in 1700:
		if Vector2(actor.position.x-at.x,actor.position.z-at.z).length()<.3:
			Input.action_release("forward");Input.action_release("sprint");await ticks(2);return true
		while not path.is_empty() and Vector2(path[0].x-actor.position.x,path[0].z-actor.position.z).length()<.1:path.remove_at(0)
		if path.is_empty():break
		var direction:=path[0]-actor.position;actor.camera_rig.yaw=atan2(-direction.x,-direction.z)
		Input.action_press("forward")
		if sprint:Input.action_press("sprint")
		await ticks(1);refresh+=1
		if refresh>=40:
			refresh=0;path=world.sunday.route(actor.position,at)
			if path.size()>1 and actor.position.distance_to(path[0])<.22:path.remove_at(0)
	Input.action_release("forward");Input.action_release("sprint")
	print("SUNDAY_ROUTE_BLOCKED ",actor.identity," at=",actor.position," to=",at," phase=",Session.campaign.phase," path=",path)
	return false
func interact(parent: Node,kind: String) -> bool:return find_interaction(parent,kind).activate(world.player)
func reload_sunday() -> void:
	app.start_saved();world=app.world;player=world.player;await ticks(5);clear_dialogue()
func reset_to_escape() -> void:
	app.interface.close_campaign(false);Session.save_retry();await reload_sunday();app.interface.set_paused(false)
func finish_test() -> void:
	if not failures.is_empty():print("SUNDAY_FAILURE_STATE Dery=",world.characters.Dery.position," Felps=",world.characters.Felps.position," caught=",world.sunday.caught_identity if world.sunday!=null else ""," killer=",world.sunday.killer.position if is_instance_valid(world.sunday.killer) else Vector3.ZERO)
	clear_dialogue();print("SUNDAY RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	app.queue_free();await get_tree().process_frame;await get_tree().create_timer(.2).timeout
	Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear()
	get_tree().quit(0 if failures.is_empty() else 1)
func run() -> void:
	# Keep the physical simulation at 60 steps per game second while accelerating the test.
	Engine.physics_ticks_per_second=240;Engine.time_scale=4;Session.new_shift();Session.campaign.completed_nights=[0,1]
	Session.campaign.decisions={"evidence":"recorder","help":"wait","exit":"prepared"};Session.campaign.evidence_archive={}
	Session.advance_to_sunday()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await ticks(2)
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;player=world.player
	check(Session.campaign.phase=="sunday_intro" and get_tree().get_nodes_in_group("familiar_npcs").is_empty(),"domingo inicia sem clientes ou criança no cenário de perigo")
	check(await walk(CheckoutFixture.CUSTOMER_POSITION) and interact(world.depot.felps,"talk"),"dupla inicia domingo por conversa no balcão")
	clear_dialogue();world.switch_player();await key_press(KEY_C)
	check(app.interface.sunday_desk!=null and app.interface.sunday_desk.find_child("RecoverRecording",true,false).disabled,"terminal exige recuperar e entregar o módulo físico antes do vídeo")
	await key_press(KEY_TAB)
	check(world.player.identity=="Dery" and app.interface.sunday_desk==null,"Tab fecha o DVR de domingo e devolve controle a Deryk")
	check(await walk(Vector3(4.85,0,-10.0)) and interact(world.depot.stock_door,"door"),"Deryk abre a porta do estoque fisicamente")
	check(await walk(Vector3(4.85,0,-12.0)) and await walk(Vector3(.2,0,-14.7)) and interact(world.depot.old_door,"note"),"porta antiga abre para uma sala real de manutenção")
	clear_dialogue()
	check(await walk(Vector3(.25,0,-18.8)),"acesso antigo possui piso, vão e navegação até o módulo sem atravessar paredes")
	check(interact(world.depot.access.evidence,"sunday") and Session.flag("module_found"),"módulo e cadastro são recolhidos pelo personagem presente")
	Session.save_shift(world.player.position);await reload_sunday()
	check(world.player.position.z< -18 and world.sunday.door_open("old") and not world.depot.access.evidence.visible,"save retoma dentro da manutenção com porta e módulo corretos")
	check(await walk(Vector3(.2,0,-14.7)) and await walk(Vector3(4.85,0,-12)) and await walk(Vector3(4.85,0,-9.8)) and await walk(CheckoutFixture.CUSTOMER_POSITION),"Deryk volta da sala antiga ao balcão por todo o percurso físico")
	check(interact(world.depot.counter,"checkout") and Session.flag("module_delivered"),"módulo precisa chegar ao balcão antes da recuperação")
	world.switch_player();await key_press(KEY_C)
	var desk: SundayDesk=app.interface.sunday_desk
	check(desk!=null and desk.video.stream is VideoStreamTheora,"arquivo recuperado é vídeo Theora real, separado da câmera ao vivo")
	if desk==null or desk.video.stream==null:await finish_test();return
	desk.find_child("RecoverRecording",true,false).pressed.emit();await ticks(150)
	check(desk.watched and not desk.analyze.disabled,"reprodução do fragmento libera análise sem depender de um temporizador de objetivo invisível")
	desk.find_child("AnalyzeRecording",true,false).pressed.emit()
	check(Session.campaign.phase=="sunday_prepare" and Dialogue.sequence=="sunday_reveal" and not is_instance_valid(world.sunday.killer),"gravação e cadastro revelam ligação do cliente antes de qualquer perseguição")
	clear_dialogue();await key_press(KEY_C);desk=app.interface.sunday_desk
	check(not Session.flag("help_notified"),"não preparar contato no sábado mantém a ajuda pendente no domingo")
	desk.find_child("TakeProof",true,false).pressed.emit()
	check(world.sunday.state().proof=="carried" and world.sunday.state().proof_carrier=="Felps","cópia do fragmento fica vinculada a Felps e pode sair com ele")
	desk.find_child("ContactSunday",true,false).pressed.emit();desk.find_child("SendProof",true,false).pressed.emit()
	check(Session.flag("help_notified") and world.sunday.state().proof=="offsite" and world.sunday.helper.visible,"contato e envio no domingo permitem preservar prova e obter ajuda mesmo sem preparo no sábado")
	check(not world.sunday.desk_action("leave"),"uma cópia enviada não desaparece ao escolher deixar o gravador")
	await key_press(KEY_TAB)
	check(await walk(Vector3(4.85,0,-9.8)) and await walk(Vector3(4.85,0,-12)) and await walk(Vector3(3.1,0,-12.1)),"Deryk retorna ao quadro enquanto Felps permanece no terminal")
	check(interact(world.friday.key_hook,"campaign") and Session.campaign.phase=="sunday_escape","conferência inicia separação física, apagão e checkpoint de fuga")
	clear_dialogue()
	check(not world.sunday.door_open("stock") and not interact(world.depot.stock_door,"door") and not Session.retry_state.is_empty(),"estoque fica realmente trancado e checkpoint precede a ameaça")
	check(is_instance_valid(world.sunday.killer) and world.sunday.killer.visual==world.enemy_visual,"modelo Killer fornecido é reutilizado como um único inimigo físico")
	# The quest route runs against the real pursuer, with both torches switched off.
	world.player.torch.hide();world.characters.Felps.torch.hide()
	check(await walk(Vector3(4.85,0,-14.8),true) and interact(world.depot.service_door,"door"),"Deryk alcança e abre o pátio enquanto o assassino está no mesmo mundo")
	check(await walk(Vector3(4.75,0,-17.2),true) and await walk(Vector3(4.4,0,-19.1),true),"rota até o gerador permanece física durante a fuga")
	check(interact(world.depot.yard.generator,"campaign") and world.sunday.state().generator_mode=="stock","gerador alimenta estoque e emite ruído no mundo da perseguição")
	for i in 80:
		await ticks(1)
		if not world.player.motion.action_active:break
	check(await walk(Vector3(4.85,0,-17.1),true) and await walk(Vector3(4.85,0,-14.8),true) and await walk(Vector3(4.85,0,-12.2),true),"Deryk consegue retornar ao estoque sob ameaça sem teleporte")
	world.switch_player();player=world.player
	await key_press(KEY_C);desk=app.interface.sunday_desk
	check(desk!=null and not desk.find_child("ReleaseStock",true,false).disabled,"Felps pode liberar a porta pelo terminal energizado sem abandonar seu posto")
	if desk==null:await finish_test();return
	desk.find_child("ReleaseStock",true,false).pressed.emit()
	check(Session.flag("stock_released") and app.interface.sunday_desk==null,"cooperação exige Deryk no gerador e Felps no terminal físico")
	await key_press(KEY_H)
	check(world.sunday.state().orders.Dery=="follow","H manda o companheiro acompanhar sem mover seu corpo instantaneamente")
	check(await walk(Vector3(3.3,0,-.8),true),"Felps conduz a fuga de volta à frente do depósito")
	check(interact(world.sunday.crank,"sunday"),"comando manual inicia abertura progressiva da saída")
	app.interface.set_paused(true);var timer: float=world.sunday.state().crank_time;await get_tree().create_timer(.4,true).timeout
	check(is_equal_approx(float(world.sunday.state().crank_time),timer),"pausa congela perseguição e mecanismo de saída")
	app.interface.set_paused(false);await ticks(70)
	check(Session.flag("front_open"),"preparar a saída no sábado reduz a duração de abertura no domingo")
	check(await walk(Vector3(4.8,0,1.5),true) and await walk(Vector3(10,Street.surface_height(10,1.8),1.8),true),"jogador deixa o prédio e alcança o contato pela calçada")
	for i in 1200:
		await ticks(1)
		if world.sunday.together_at_exit() or app.interface.campaign_panel!=null:break
	check(world.sunday.together_at_exit(),"companheiro sai do estoque, percorre o salão e chega ao mesmo encontro")
	if not world.sunday.together_at_exit():print("SUNDAY_COMPANION ",world.characters.Dery.position," killer=",world.sunday.killer.position);await finish_test();return
	check(interact(world.sunday.exits[0],"sunday") and app.interface.campaign_panel!=null,"saída abre confirmação contextual sem encerrar a história automaticamente")
	app.interface.campaign_panel.find_child("EscapeTogether",true,false).pressed.emit()
	check(Session.campaign.ending.id=="resolved" and app.interface.campaign_panel.kind=="ending" and 2 in Session.campaign.completed_nights,"dois sobreviventes com prova recebem o final do caso esclarecido")
	await reload_sunday();await ticks(3)
	check(app.interface.campaign_panel!=null and app.interface.campaign_panel.kind=="ending","continuar depois do fim reabre o epílogo salvo")
	# Subsequent tests stage positions explicitly to isolate AI memory, cover and branches.
	await reset_to_escape();world.select_player("Felps");world.player.position=Vector3(3.3,0,-.8);Session.campaign.decisions.exit="unchanged"
	check(interact(world.sunday.crank,"sunday") and float(world.sunday.state().crank_time)>3.8,"sem preparo no sábado, abertura manual exige permanecer por mais tempo")
	world.player.position=CheckoutFixture.STAFF_POSITION;await ticks(2)
	check(str(world.sunday.state().crank_actor).is_empty() and not Session.flag("front_open"),"afastar-se do comando interrompe a abertura em vez de liberar saída remotamente")
	await reset_to_escape();world.sunday.killer.grace=0
	var enemy:=world.sunday.killer
	enemy.position=Vector3(4.85,.01,-13.8);enemy.visual.rotation.y=0;world.characters.Dery.position=Vector3(4.85,.01,-12.1);world.characters.Dery.concealed=false;world.characters.Dery.crouching=false
	check(enemy.can_see(world.characters.Dery),"visão reconhece personagem exposto no cone sem consultar o personagem controlado")
	world.characters.Felps.position=Vector3(4.85,.01,-10.0)
	check(not enemy.can_see(world.characters.Felps),"porta e parede bloqueiam detecção e captura através da divisão")
	enemy.mode="patrol";enemy.hear(Vector3(4.85,0,-12.1),7)
	check(enemy.mode=="investigate" and enemy.goal.distance_to(Vector3(4.85,0,-12.1))<.1,"ruído muda busca para a posição ouvida")
	enemy.sense();var memory:=enemy.last_seen;world.switch_player()
	check(enemy.mode=="chase" and enemy.last_seen==memory,"Tab não reinicia nem teleporta o assassino ou apaga sua memória")
	world.sunday.state().generator_mode="off";world.characters.Dery.position=Vector3(4.85,0,-6);enemy.position=Vector3(4.85,.01,-11.8);world.sunday.change_door("stock",true);await ticks(2)
	world.characters.Dery.torch.hide();world.characters.Dery.crouching=false
	var dark:=enemy.can_see(world.characters.Dery);world.characters.Dery.torch.show()
	check(not dark and enemy.can_see(world.characters.Dery),"lanterna aumenta alcance de detecção em um corredor escuro")
	enemy.grace=2;enemy.mode="search";enemy.last_seen=Vector3(4.85,0,-8);enemy.goal=enemy.last_seen;enemy.search_time=2;world.sunday.save();await reload_sunday();app.interface.set_paused(false)
	check(world.sunday.killer.mode=="search" and world.sunday.killer.search_time>=2 and world.sunday.killer.goal.distance_to(Vector3(4.85,0,-8))<.1,"save conserva posição de busca, tempo, estado e último ponto conhecido")
	enemy=world.sunday.killer;enemy.mode="attack";enemy.target_identity="Felps";enemy.attack_time=.5;enemy.grace=2
	world.sunday.save();await reload_sunday();app.interface.set_paused(false);enemy=world.sunday.killer
	check(enemy.mode=="attack" and enemy.target_identity=="Felps" and is_equal_approx(enemy.attack_time,.5),"save preserva alvo e tempo restante do golpe em preparação")
	enemy.grace=0;enemy.position=world.characters.Felps.position+Vector3(0,0,-.65);enemy.attack_time=.2
	await ticks(25)
	check(app.interface.campaign_panel!=null and app.interface.campaign_panel.kind=="defeat" and Session.campaign.phase=="sunday_escape" and Session.campaign.ending.is_empty(),"captura abre derrota recuperável sem gravar final narrativo")
	app.interface.campaign_panel.find_child("RetrySunday",true,false).pressed.emit();world=app.world;await ticks(3)
	check(world.sunday.killer.grace>0 and not Session.flag("generator_running") and not Session.flag("stock_released"),"retomar derrota volta a um checkpoint viável anterior aos mecanismos e mantém breve proteção")
	world.select_player("Felps");await ticks(2)
	# An inactive partner can already be crouched in cover after retry.
	# Use the real exit/torch controls before testing a fresh entry.
	if world.player.concealed:await key_press(KEY_E)
	if not world.player.torch.visible:await key_press(KEY_F)
	var cover_position:=world.player.position
	Input.action_press("crouch");await ticks(3)
	await key_press(KEY_E);Input.action_release("crouch");await ticks(3)
	check(world.player.concealed and world.player.motion.current_clip=="crouch_idle" and not world.player.torch.visible and world.player.position.distance_to(cover_position)<.1,"E entra em cobertura agachada sem teleporte e apaga a lanterna")
	world.sunday.save();await reload_sunday();app.interface.set_paused(false)
	check(world.player.identity=="Felps" and world.player.concealed and world.player.crouching,"salvar e continuar mantém corpo, colisão agachada e cobertura")
	await key_press(KEY_W)
	check(not world.player.concealed,"mover-se sai da cobertura sem invisibilidade persistente")
	# Unresolved and solitary endings use real confirmation buttons with staged exits.
	world.sunday.state().proof="recorder";Session.campaign.flags.front_open=true
	for actor in world.characters.values():actor.position=Vector3(10 if actor.identity=="Dery" else 10.8,Street.surface_height(10,1.8),1.8)
	world.select_player("Felps");world.sunday.killer.grace=8
	interact(world.sunday.exits[0],"sunday");app.interface.campaign_panel.find_child("EscapeTogether",true,false).pressed.emit()
	check(Session.campaign.ending.id=="unresolved" and Session.campaign.ending.survivors.size()==2,"sair com os dois sem prova produz epílogo distinto do caso aberto")
	await reset_to_escape();Session.campaign.flags.front_open=true;world.select_player("Felps");world.player.position=Vector3(10,Street.surface_height(10,1.8),1.8);world.sunday.killer.grace=8
	interact(world.sunday.exits[0],"sunday")
	check(app.interface.campaign_panel.find_child("EscapeTogether",true,false).disabled and app.interface.campaign_panel.find_child("LeaveAlone",true,false)!=null,"separação na saída exige confirmação explícita para abandonar companheiro")
	app.interface.campaign_panel.find_child("CancelEscape",true,false).pressed.emit()
	check(Session.campaign.phase=="sunday_escape" and not get_tree().paused,"cancelar saída permite voltar para resgatar sem escolher final")
	interact(world.sunday.exits[0],"sunday");app.interface.campaign_panel.find_child("LeaveAlone",true,false).pressed.emit()
	check(Session.campaign.ending.id=="alone" and Session.campaign.ending.survivors==["Felps"],"confirmar saída sozinho registra apenas o sobrevivente que chegou")
	Session.save_shift(world.player.position);await reload_sunday();await ticks(3)
	check(Session.campaign.ending.id=="alone" and app.interface.campaign_panel.kind=="ending","final sozinho persiste e não inicia uma quarta noite")
	app.interface.campaign_panel.find_child("RestartCampaign",true,false).pressed.emit();world=app.world;await ticks(3)
	check(int(Session.campaign.night)==0 and Session.campaign.phase=="routine" and Session.campaign.ending.is_empty() and Session.retry_state.is_empty(),"reiniciar após o epílogo limpa ameaça, final e retry e volta à sexta")
	Session.advance_to_sunday();Session.campaign.phase="sunday_preview";Session.save_shift(world.player.position)
	var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Session.SAVE_PATH));legacy.version=4;legacy.erase("retry");legacy.campaign.erase("sunday");legacy.campaign.erase("ending")
	var file:=FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close();await reload_sunday();app.interface.set_paused(false)
	check(Session.campaign.phase=="sunday_intro" and world.sunday.state().generator_mode=="off" and not is_instance_valid(world.sunday.killer),"save 0.19 do domingo em prévia migra para abertura jogável sem iniciar perigo antes da hora")
	await finish_test()
