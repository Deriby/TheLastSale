extends Node
## Integration tests use actual physics, original assets and complete customer routes.
var failures: Array[String] = []
var checks:=0
var app: Node
var world: ShiftWorld
var player: DepotPlayer
var served_states: Dictionary = {}
var checkout_positions_valid:=true
var bulk_checkpoint_checked:=false
func check(condition: bool,description: String) -> void:
	checks+=1
	print("PASS " if condition else "FAIL ",description)
	if not condition:failures.append(description)
func ticks(count: int) -> void:
	for i in count:await get_tree().physics_frame
func key_press(code: Key) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events();await ticks(3)
	event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await ticks(2)
func find_interaction(parent: Node,kind: String) -> Interaction:
	for node in parent.get_children():
		if node is Interaction and node.kind==kind:return node
	return null
func clear_dialogue() -> void:
	while Dialogue.active:Dialogue.next_line()
func press_register(id: String) -> bool:
	await get_tree().process_frame
	if app.interface.checkout==null:return false
	var button:=app.interface.checkout.find_child(id,true,false) as Button
	if button==null:return false
	button.pressed.emit();await get_tree().process_frame
	return true
func walk_to(actor: DepotPlayer,destination: Vector3,reach := .35) -> bool:
	var path:=world.navigation.path(actor.global_position,destination)
	for step in 1000:
		var diff:=destination-actor.global_position;diff.y=0
		if diff.length()<reach:Input.action_release("forward");await ticks(2);return true
		while not path.is_empty() and Vector2(path[0].x-actor.position.x,path[0].z-actor.position.z).length()<.36:path.remove_at(0)
		if path.is_empty():path.append(destination)
		var direction:=path[0]-actor.global_position;actor.camera_rig.yaw=atan2(-direction.x,-direction.z)
		Input.action_press("forward");await ticks(1)
	Input.action_release("forward");return false
func fetch_order_box() -> bool:
	if app.interface.checkout!=null:await press_register("CallDeryk")
	if world.player.identity!="Dery":world.switch_player()
	var actor:=world.player
	var door:=find_interaction(world.depot.stock_door,"door")
	if not await walk_to(actor,Vector3(4.85,0,-10.35),.45):print("COURIER_FAIL door ",actor.position);return false
	if not door.open:door.activate(actor);await ticks(8)
	var box: Node3D=world.depot.crates[world.sale.supply_id()]
	if not await walk_to(actor,box.global_position+Vector3(0,0,.65),.28):print("COURIER_FAIL stock ",actor.position);return false
	if not find_interaction(box,"crate").activate(actor):print("COURIER_FAIL pickup ",actor.position," box=",box.global_position," carry=",actor.carried_id," action=",actor.motion.action_active);return false
	for step in 120:
		await ticks(1)
		if not actor.motion.action_active and not actor.handling.busy:break
	if not bulk_checkpoint_checked:
		var supply_id:=world.sale.supply_id();var old_total:=Session.sales_cents
		Session.save_shift(actor.global_position);app.start_saved();world=app.world;actor=world.characters.Dery;player=actor;await ticks(8)
		check(world.player==actor and actor.carried_id==supply_id and actor.carried==world.depot.crates[supply_id] and not world.sale.bulk_supplied and Session.sales_cents==old_total,"continuar com Deryk carregando a caixa do pedido preserva mercadoria, cliente e receita")
		bulk_checkpoint_checked=true;door=find_interaction(world.depot.stock_door,"door")
	# Clear the opened leaf before turning into the shop; the coarse A* grid is static.
	if not await walk_to(actor,Vector3(4.95,0,-11.7),.3):print("COURIER_FAIL inside door ",actor.position);return false
	if not door.open:door.activate(actor);await ticks(8)
	if not await walk_to(actor,Vector3(4.95,0,-8.8),.3):print("COURIER_FAIL outside door ",actor.position);return false
	if not await walk_to(actor,CheckoutFixture.CUSTOMER_POSITION+Vector3(.55,0,0),.4):print("COURIER_FAIL counter ",actor.position);return false
	if not world.supply_order(actor):print("COURIER_FAIL supply ",actor.position," carry=",actor.carried_id," action=",actor.motion.action_active," busy=",actor.handling.busy);return false
	for step in 120:
		await ticks(1)
		if world.sale.bulk_supplied and not actor.motion.action_active and not actor.handling.busy:break
	return world.sale.bulk_supplied and world.switch_player()
func shadow_light_count() -> int:
	var count:=0
	for light in world.find_children("*","Light3D",true,false):
		if light.shadow_enabled:count+=1
	return count
func display_bottles_supported() -> bool:
	var display: Node3D=get_tree().get_first_node_in_group("beverage_displays")
	var batch: PropBatch=display.find_child("CratesAndPallet",true,false)
	var support_boxes: Array[AABB]=[]
	var bottles: Array[Vector3]=[]
	for key in batch.groups:
		var data: Dictionary=batch.groups[key]
		for at in data.transforms:
			if str(key).begins_with("soda_"):bottles.append(at.origin)
			else:support_boxes.append(at*data.source_mesh.get_aabb())
	if bottles.size()<24:return false
	for bottle in bottles:
		var supported:=false
		for box in support_boxes:
			if absf(bottle.y-box.end.y)<.004 and bottle.x>box.position.x and bottle.x<box.end.x and bottle.z>box.position.z and bottle.z<box.end.z:supported=true;break
		if not supported:return false
	return true
func _ready() -> void:call_deferred("run")
func run() -> void:
	var totals: Array[int]=[]
	for id in range(1,6):totals.append(ShopSale.create(id).total())
	check(totals==[1150,7200,3200,4300,2000] and ShopSale.money(350)=="R$ 3,50","catálogo calcula pedidos variados em centavos e formata reais sem arredondamento")
	var exact:=ShopSale.create(5)
	for sku in exact.order:
		for i in int(exact.order[sku]):exact.register(sku)
	check(exact.confirm_items() and exact.receive_cash() and exact.change_due()==0 and exact.confirm_change(),"pagamento exato conclui a conferência sem exigir moeda de troco")
	check(not exact.receive_cash() and not exact.add_coin(-50) and exact.phase==ShopSale.Phase.READY,"pagamento e troco não podem ser repetidos fora da etapa correta")
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	await get_tree().process_frame
	check(get_tree().paused,"menu inicial pausa o mundo")
	var loaded_world_id: int=app.world.get_instance_id()
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	world=app.world;player=world.player
	var cabinet_lights:=world.find_children("CabinetLight","OmniLight3D",true,false)
	var local_cabinet_light:=cabinet_lights.size()==12
	for light in cabinet_lights:local_cabinet_light=local_cabinet_light and light.light_cull_mask==16 and not light.shadow_enabled
	check(local_cabinet_light and (world.depot.get_node("Architecture/DepotFloor").layers&16)==0,"luzes das doze geladeiras ficam restritas aos equipamentos sem iluminar o piso")
	check(shadow_light_count()==5,"nova iluminação preserva o orçamento de cinco luzes com sombras")
	var cabinet_probe: ReflectionProbe=world.get_node("CabinetReflection")
	check(cabinet_probe.update_mode==ReflectionProbe.UPDATE_ONCE and int(ProjectSettings.get_setting("rendering/reflections/reflection_atlas/reflection_size"))<=128 and cabinet_probe.reflection_mask==16,"reflexo das geladeiras captura uma vez em resolução limitada")
	var night_env: Environment=world.get_node("Atmosphere").environment
	check(night_env.fog_depth_begin>=16 and night_env.fog_depth_end<100 and night_env.fog_depth_end>60,"neblina distante preserva o primeiro plano e oculta o fim da rua")
	check(world.get_instance_id()==loaded_world_id,"primeiro início aproveita o cenário já carregado no menu")
	var original_window_size:=get_window().size
	app.interface.set_paused(true);app.interface.open_settings();await ticks(3)
	var resolution_select: OptionButton=app.interface.settings.find_child("RenderQuality",true,false)
	resolution_select.select(3);resolution_select.item_selected.emit(3);await ticks(6)
	check(Preferences.ps1_mode and app.viewport.size==Vector2i(320,240) and get_window().size==original_window_size,"PS1 renderiza em 320×240 sem reduzir a janela")
	var game_rect: Rect2=app.screen.get_global_rect();var full_size:=get_viewport().get_visible_rect().size
	check(absf(game_rect.size.x/game_rect.size.y-4.0/3.0)<.001 and game_rect.size.x>640 and game_rect.get_center().distance_to(full_size*.5)<1,"imagem PS1 é ampliada e centralizada em 4:3")
	var panel_rect: Rect2=app.interface.settings.get_global_rect()
	check(app.interface.root.size==full_size and panel_rect.size.x>=570 and Rect2(Vector2.ZERO,full_size).encloses(panel_rect),"menu e HUD preservam a resolução e cabem na janela grande")
	var saved_resolution:=ConfigFile.new();saved_resolution.load("user://settings.cfg")
	check(bool(saved_resolution.get_value("settings","ps1_mode",false)),"preferência PS1 é salva para a próxima abertura")
	get_window().size=Vector2i(1280,960);await ticks(6)
	check(app.viewport.size==Vector2i(320,240) and absf(app.screen.size.x/app.screen.size.y-4.0/3.0)<.001,"redimensionar a janela para 4:3 mantém 320×240 internos")
	get_window().size=Vector2i(1600,900);await ticks(6)
	check(app.viewport.size==Vector2i(320,240) and app.screen.stretch_shrink>=2 and app.screen.size==Vector2(320,240)*app.screen.stretch_shrink,"janela larga mantém a imagem PS1 sem esticar os personagens")
	get_window().size=original_window_size;await ticks(6)
	var ps1_display_rect: Rect2=app.screen.get_global_rect()
	resolution_select.select(4);resolution_select.item_selected.emit(4);await ticks(6)
	check(Preferences.ps1_mode and Preferences.ps1_high_resolution and app.viewport.size==Vector2i(640,480) and get_window().size==original_window_size,"PS1/2 renderiza em 640×480 sem alterar a janela")
	check(app.screen.get_global_rect().is_equal_approx(ps1_display_rect) and app.interface.root.size==full_size,"PS1/2 ocupa a mesma área 4:3 que PS1 e mantém o HUD em resolução normal")
	saved_resolution.load("user://settings.cfg")
	check(bool(saved_resolution.get_value("settings","ps1_mode",false)) and bool(saved_resolution.get_value("settings","ps1_high_resolution",false)),"preferência PS1/2 é salva separadamente da resolução de 320×240")
	app.interface.settings.closed.emit();await ticks(2);app.interface.open_settings();await ticks(2)
	resolution_select=app.interface.settings.find_child("RenderQuality",true,false)
	check(resolution_select.item_count==5 and resolution_select.get_selected_id()==5,"reabrir Configurações identifica o modo PS1/2 selecionado")
	get_window().size=Vector2i(1600,900);await ticks(6)
	game_rect=app.screen.get_global_rect()
	var resized_area:=get_viewport().get_visible_rect().size
	check(app.viewport.size==Vector2i(640,480) and absf(game_rect.size.x/game_rect.size.y-4.0/3.0)<.001 and (is_equal_approx(game_rect.size.x,resized_area.x) or is_equal_approx(game_rect.size.y,resized_area.y)) and game_rect.get_center().distance_to(resized_area*.5)<1,"PS1/2 mantém 640×480 internos e preenche a área 4:3 após redimensionar")
	resolution_select.select(3);resolution_select.item_selected.emit(3);await ticks(6)
	check(not Preferences.ps1_high_resolution and app.viewport.size==Vector2i(320,240) and app.screen.scale==Vector2.ONE,"voltar de PS1/2 para PS1 restaura 320×240 sem manter a escala anterior")
	resolution_select.select(4);resolution_select.item_selected.emit(4);await ticks(6)
	get_window().size=original_window_size;await ticks(6)
	resolution_select.select(0);resolution_select.item_selected.emit(0);await ticks(6)
	check(not Preferences.ps1_mode and app.screen.scale==Vector2.ONE and app.viewport.size==Vector2i(get_viewport().get_visible_rect().size) and app.retro.get_shader_parameter("game_bounds")==Vector4(0,0,1,1),"retorno a Nítida preenche a janela sem deixar barras ou escala antigas")
	check(world.get_instance_id()==loaded_world_id and Session.stage==0,"troca de resolução preserva o mundo e o progresso do turno")
	app.interface.settings.closed.emit();app.interface.set_paused(false)
	check(world.characters.size()==2 and get_tree().get_nodes_in_group("protagonists").size()==2 and get_tree().get_nodes_in_group("player").size()==1,"dois protagonistas físicos e apenas um controle ativo")
	var hud_bounds:=Rect2(Vector2.ZERO,app.interface.root.size)
	check(hud_bounds.encloses(app.interface.prompt.get_global_rect()) and hud_bounds.encloses(app.interface.carry_status.get_global_rect()) and hud_bounds.encloses(app.interface.notice_label.get_global_rect()),"comandos de interação, caixa e avisos ficam dentro da janela")
	check(hud_bounds.encloses(app.interface.hud.get_node("Subtitles").get_global_rect()) and hud_bounds.encloses(app.interface.hud.get_node("ControlsHint").get_global_rect()),"legendas e lembrete de controles permanecem visíveis na parte inferior")
	var dery_start:=player.global_position
	player.camera_rig.yaw=.3;player.camera_rig.target_distance=1.8
	await key_press(KEY_TAB)
	var felps: DepotPlayer=world.characters.Felps
	check(world.player==felps and felps.camera_rig.camera.current and not player.camera_rig.camera.current and app.interface.character_label.text.begins_with("FELPS"),"Tab entrega câmera, controle e HUD ao Felps")
	felps.camera_rig.yaw=0
	var felps_start:=felps.global_position
	Input.action_press("forward");await ticks(24);Input.action_release("forward");await ticks(10)
	check(felps.global_position.distance_to(felps_start)>.2 and Vector2(player.position.x,player.position.z).distance_to(Vector2(dery_start.x,dery_start.z))<.01,"WASD move só Felps enquanto Deryk mantém a posição")
	felps.camera_rig.target_distance=0;await ticks(40)
	check(felps.camera_rig.first_person and felps.visual.find_child("Felps_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"Felps também tem primeira pessoa com corpo e cabeça ocultada apenas da própria câmera")
	await key_press(KEY_TAB)
	check(world.player==player and is_equal_approx(player.camera_rig.yaw,.3) and is_equal_approx(player.camera_rig.target_distance,1.8) and felps.visual.find_child("Felps_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"retornar a Deryk restaura sua câmera e a cabeça visível de Felps")
	Dialogue.play("switch_test",[["Dery","Só um instante."]]);await key_press(KEY_TAB)
	check(world.player==player,"troca fica bloqueada durante conversa")
	clear_dialogue();app.interface.set_paused(true)
	check(not world.switch_player(),"pausa bloqueia troca de personagem")
	app.interface.set_paused(false)
	felps.position=CheckoutFixture.STAFF_POSITION;felps.velocity=Vector3.ZERO;felps.visual.rotation.y=PI/2;felps.camera_rig.yaw=-PI/2;felps.camera_rig.target_distance=2.2;felps.reset_physics_interpolation()
	player.camera_rig.yaw=0;player.camera_rig.target_distance=Preferences.camera_distance
	check(world.enemy_visual.process_mode==Node.PROCESS_MODE_DISABLED,"assassino oculto não atualiza animações")
	world.enemy_visual.show()
	check(world.enemy_visual.process_mode==Node.PROCESS_MODE_INHERIT,"assassino retoma processamento quando fica visível")
	world.enemy_visual.hide()
	await ticks(12)
	check(world.depot!=null and player.is_on_floor(),"cena principal e chão físico carregam")
	player.position=Vector3(4.2,.01,-2.0);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.reset_physics_interpolation()
	Input.action_press("forward");await ticks(75);Input.action_release("forward");await ticks(10)
	check(player.is_on_floor() and player.position.z< -3.3,"antigo caixa da direita está livre para circulação real")
	check(player.foot_audio.stream==player.tile_step,"passos no salão usam contato seco de piso cerâmico")
	var street_space:=world.get_world_3d().direct_space_state
	var annex_roof:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.7,2.8,-2.75),Vector3(-4.7,7,-2.75),1))
	check(not annex_roof.is_empty() and annex_roof.position.y>4.25 and annex_roof.position.y<4.6,"cobertura baixa fecha o teto sobre o caixa esquerdo")
	var rear_roof:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.7,2.8,-8),Vector3(-4.7,7,-8),1))
	check(not rear_roof.is_empty() and rear_roof.position.y>4.25 and rear_roof.position.y<4.6 and absf(rear_roof.position.y-annex_roof.position.y)<.02,"teto baixo esquerdo continua na mesma altura até os fundos")
	var side_riser:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-3.8,5.1,-2.2),Vector3(-1.8,5.1,-2.2),1))
	check(not side_riser.is_empty() and absf(side_riser.position.x+2.1)<.2,"encontro lateral entre os dois níveis do telhado não tem vão")
	var rear_riser:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.3,5,-4.5),Vector3(-4.3,5,-7.4),1))
	check(rear_riser.is_empty(),"antigo degrau transversal do teto foi removido")
	var deep_riser:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-3.8,5.1,-13),Vector3(-1.8,5.1,-13),1))
	check(not deep_riser.is_empty() and absf(deep_riser.position.x+2.1)<.2,"fechamento lateral entre os tetos continua até os fundos")
	var cables:=get_tree().get_nodes_in_group("non_shadow_cables")
	var cables_clear:=cables.size()>=7
	for cable in cables:cables_clear=cables_clear and cable.is_visible_in_tree() and cable.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	check(cables_clear and not world.street.wires.groups.is_empty(),"fiação da rua e cabos internos continuam visíveis sem projetar sombras")
	check(display_bottles_supported(),"todas as garrafas do expositor apoiam nas bases dos engradados")
	var shelf_back:=INF
	for shelf in world.depot.central_shelves:shelf_back=minf(shelf_back,shelf.position.z-shelf.shelf_length*.5)
	check(shelf_back-world.depot.rear_fridges[0].hinge.global_position.z>=2.0,"gôndolas deixam pelo menos dois metros até as portas fechadas das geladeiras")
	var sweeps_clear:=true
	for fridge in world.depot.rear_fridges:
		var sweep:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.98,1.90,.98)
		sweep.shape=shape;sweep.transform=Transform3D(Basis.IDENTITY,fridge.to_global(Vector3(0,1.065,.91)));sweep.collision_mask=1
		sweeps_clear=sweeps_clear and street_space.intersect_shape(sweep).is_empty()
		find_interaction(fridge,"fridge").activate(player)
	check(sweeps_clear,"giro das sete portas do fundo não invade gôndolas nem a geladeira do canto")
	await ticks(30)
	var door_front:=-INF
	for fridge in world.depot.rear_fridges:
		for piece in fridge.hinge.find_children("*","MeshInstance3D",true,false):
			var bounds: AABB=piece.global_transform*piece.get_aabb();door_front=maxf(door_front,bounds.end.z)
	check(shelf_back-door_front>=1.05,"portas abertas mantêm mais de um metro livre diante das gôndolas")
	player.position=Vector3(-3.4,.01,-8.6);player.velocity=Vector3.ZERO;player.camera_rig.yaw=-PI/2;player.reset_physics_interpolation()
	Input.action_press("forward");Input.action_press("sprint");await ticks(120);Input.action_release("forward");Input.action_release("sprint");player.velocity=Vector3.ZERO;await ticks(6)
	check(player.is_on_floor() and player.position.x>3.0,"jogador atravessa o corredor traseiro com as geladeiras abertas")
	player.position=Vector3(.1,.01,-8.6);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.camera_rig.pitch=-.10;player.reset_physics_interpolation();await ticks(30)
	check(player.target!=null and player.target.get_parent()==world.depot.rear_fridges[4],"porta do fundo é alcançável pela interação no corredor livre")
	var rear_key:=InputEventKey.new();rear_key.physical_keycode=KEY_E;rear_key.keycode=KEY_E;rear_key.pressed=true;Input.parse_input_event(rear_key);await ticks(30)
	check(not world.depot.rear_fridges[4].opened and Session.stage==0,"E fecha a geladeira do fundo sem avançar as tarefas")
	rear_key=InputEventKey.new();rear_key.physical_keycode=KEY_E;rear_key.keycode=KEY_E;rear_key.pressed=false;Input.parse_input_event(rear_key)
	for fridge in world.depot.rear_fridges:
		if fridge.opened:find_interaction(fridge,"fridge").activate(player)
	await ticks(30)
	var detailed_cars:=0
	for car in world.street.find_children("Parked*","Node3D",true,false):
		if not car.has_meta("vehicle_kind"):continue
		var triangles:=0;var first_bounds:=true;var bounds:=AABB()
		for part in car.find_children("*","MeshInstance3D",true,false):
			var box: AABB=(car.global_transform.affine_inverse()*part.global_transform)*part.get_aabb()
			bounds=box if first_bounds else bounds.merge(box);first_bounds=false
			for index in part.mesh.get_surface_count():triangles+=part.mesh.surface_get_array_index_len(index)/3
		if triangles>25000 and bounds.size.x>3.5 and bounds.size.x<4.8 and bounds.size.y>1.2 and bounds.size.y<1.8:detailed_cars+=1
	check(detailed_cars==2,"sedã e hatch importados têm malhas detalhadas e escala de automóvel")
	var lower:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-20,4,6.5),Vector3(-20,-3,6.5),1))
	var upper:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(20,4,6.5),Vector3(20,-3,6.5),1))
	check(not lower.is_empty() and not upper.is_empty() and upper.position.y-lower.position.y>.8,"rua tem declive físico contínuo entre os lados do quarteirão")
	var post:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(.78,.5,1.3),Vector3(.78,.5,.2),1))
	check(not post.is_empty(),"balizadores da fachada têm colisão física")
	player.position=Vector3(-1.8,.02,1.8);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI;player.reset_physics_interpolation()
	Input.action_press("forward");await ticks(75);Input.action_release("forward");await ticks(10)
	check(player.position.z>3.1 and player.is_on_floor() and player.position.y<-.08,"jogador desce o meio-fio e entra na rua sem cair pelo chão")
	check(player.foot_audio.stream==player.asphalt_step,"passos na rua trocam para contato de asfalto")
	player.position=Vector3(-1.8,-.12,9.8);player.velocity=Vector3.ZERO;player.reset_physics_interpolation()
	Input.action_press("forward");await ticks(75);Input.action_release("forward");await ticks(10)
	check(player.position.z>11.0 and player.is_on_floor() and player.position.y>-.03,"jogador sobe à calçada oposta sem ficar preso no meio-fio")
	var apron:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10.1,2,10.4),Vector3(-10.1,-2,10.4),1))
	check(not apron.is_empty() and absf(apron.position.y-Street.surface_height(-10.1,10.4))<.015,"rampa de garagem tem piso físico coerente com a altura de navegação")
	player.position=Vector3(-10.1,Street.surface_height(-10.1,9.7)+.03,9.7);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI;player.reset_physics_interpolation()
	var ramp_contact:=false;var ramp_error:=0.0
	Input.action_press("forward")
	for i in 70:
		await ticks(1)
		if player.is_on_floor() and player.position.z>10.15 and player.position.z<10.60:
			ramp_contact=true;ramp_error=maxf(ramp_error,absf(player.position.y-Street.surface_height(player.position.x,player.position.z)))
	Input.action_release("forward");await ticks(8)
	check(player.is_on_floor() and player.position.z>11.0 and ramp_contact and ramp_error<.04,"jogador atravessa a nova rampa com contato no piso sem cair ou travar")
	var ramp_save:=world.navigation.nearest_walkable(Vector3(-10.1,-.6,10.4))
	check(absf(ramp_save.y-Street.surface_height(ramp_save.x,ramp_save.z)-.01)<.015,"checkpoint na rampa acompanha o piso inclinado")
	var alley:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-18,Street.grade(-18)+.8,.8),Vector3(-18,Street.grade(-18)+.8,-.8),1))
	check(not alley.is_empty(),"fechamento físico protege o vão entre as oficinas junto à borda da calçada")
	player.position=Vector3(3.8,.01,1.8);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.reset_physics_interpolation();await ticks(12)
	check(player.visual.find_child("Skeleton3D",true,false).get_bone_count()==72,"Dery mantém os 71 ossos recebidos e um controle adicional de peito superior")
	check(player.animator.get_animation_list().size()>=23,"23 clipes de Dery importados")
	for name in ["Dery","Felps","Enemy","Bryan","Zirico","Garota1","Garota2","Velha1","Customer3"]:
		var model: Node=load("res://assets/models/characters/"+name+".glb").instantiate()
		check(model.find_child("Skeleton3D",true,false)!=null,"rig importado: "+name)
		var meshes:=model.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty() and meshes[0].mesh.surface_get_material(0)!=null,"material presente: "+name)
		if name in ["Dery","Felps","Enemy"]:check(meshes[0].mesh.surface_get_material(0).albedo_texture!=null,"textura original preservada na derivação: "+name)
		model.free()
	var friends:=get_tree().get_nodes_in_group("familiar_npcs")
	check(friends.size()==2,"Bryan e Zirico estão presentes como conhecidos dos protagonistas")
	var child: FamiliarNPC=get_tree().get_first_node_in_group("familiar_npcs")
	check(child.identity=="Bryan" and float(child.visual.get_meta("height_m"))<1.3,"Bryan tem escala infantil própria")
	var stage_before:=Session.stage
	child.motion.ambient_active=false;child.motion.idle_time=0;child.motion.locomotion(9,0,false,false,false)
	check(child.interaction.activate(player) and Dialogue.sequence=="familiar_Bryan","Bryan tem conversa opcional com Dery e Felps")
	clear_dialogue()
	await ticks(2)
	check(not child.motion.ambient_active and child.motion.current_clip!="talk","conversa interrompe variação de postura e o conhecido retoma o repouso")
	check(Session.stage==stage_before,"conversa com Bryan preserva o progresso do expediente")
	var imported_normals:=false
	Preferences.pixel_scale=3;CharacterModels.apply_quality()
	for entry in CharacterModels.imported_materials.values():imported_normals=imported_normals or entry.material.normal_enabled
	check(not imported_normals,"modo Econômica desliga os mapas normais dos novos FBX")
	Preferences.pixel_scale=1;CharacterModels.apply_quality()
	for entry in CharacterModels.imported_materials.values():imported_normals=imported_normals or entry.material.normal_enabled
	check(imported_normals,"modo Nítida restaura os mapas normais dos novos FBX")
	var beer_finish:=ProductLibrary.material("beer_0")
	var beer_orm:=beer_finish.roughness_texture.get_image()
	check(beer_orm.get_pixel(128,130).g>.55 and beer_orm.get_pixel(128,50).g<.30,"rótulo fosco e vidro da garrafa têm respostas distintas à luz")
	var can_orm:=ProductLibrary.material("can_0").metallic_texture.get_image()
	check(can_orm.get_pixel(128,3).b>.85 and can_orm.get_pixel(128,130).b<.5,"alumínio exposto e impressão da lata têm metalicidade própria")
	check(beer_finish.albedo_texture.get_width()==512 and beer_finish.albedo_texture.get_image().has_mipmaps() and beer_finish.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,"embalagens usam arte revisada e mipmaps para distância")
	var varnish:=SurfaceMaterials.make("wood");var pallet_finish:=SurfaceMaterials.make("pallet_wood")
	check(varnish.clearcoat_enabled and not pallet_finish.clearcoat_enabled and pallet_finish.roughness_texture.get_image().get_pixel(200,200).g>varnish.roughness_texture.get_image().get_pixel(200,200).g+.25,"verniz da bancada difere da madeira crua dos paletes")
	Preferences.pixel_scale=3;Preferences.changed.emit()
	check(beer_finish.roughness_texture==null and beer_finish.metallic_texture==null and varnish.roughness_texture==null and not varnish.normal_enabled and not varnish.clearcoat_enabled,"Econômica desliga mapas de acabamento e camada de verniz")
	var cabinet_details_off:=not cabinet_probe.visible
	for light in cabinet_lights:cabinet_details_off=cabinet_details_off and not light.visible
	check(cabinet_details_off and shadow_light_count()==0 and float(app.retro.get_shader_parameter("bloom_strength"))==0,"Econômica desliga sombras, halo e iluminação/reflexo adicional das geladeiras")
	Preferences.pixel_scale=1;Preferences.changed.emit()
	check(beer_finish.roughness_texture!=null and varnish.normal_enabled and varnish.clearcoat_enabled,"Nítida restaura os acabamentos nos materiais já instanciados")
	var cabinet_details_on:=cabinet_probe.visible
	for light in cabinet_lights:cabinet_details_on=cabinet_details_on and light.visible
	check(cabinet_details_on and shadow_light_count()==5 and not bool(app.retro.get_shader_parameter("posterize")),"Nítida restaura a iluminação detalhada sem posterizar a imagem")
	var elder: Node3D=CharacterModels.create("Velha1");add_child(elder)
	var elder_motion:=LivingMotion.new();elder.add_child(elder_motion);elder_motion.setup(elder,elder)
	check(absf(elder_motion.feet.clearance-float(elder.get_meta("foot_clearance")))<.001,"contato dos pés usa a medida do modelo recebido")
	elder.queue_free()
	var skeleton: Skeleton3D=player.motion.skeleton
	var chest_index:=skeleton.find_bone("chest")
	var breath_before:=skeleton.get_bone_global_pose(chest_index).basis.get_scale()
	var waist_before:=skeleton.get_bone_pose_rotation(skeleton.find_bone("waist"))
	var upper_before:=skeleton.get_bone_pose_rotation(skeleton.find_bone("upper_chest"))
	await ticks(35)
	check(breath_before.distance_to(skeleton.get_bone_global_pose(chest_index).basis.get_scale())>.0001,"respiração altera a caixa torácica em repouso")
	check(waist_before.angle_to(skeleton.get_bone_pose_rotation(skeleton.find_bone("waist")))>.001 and upper_before.angle_to(skeleton.get_bone_pose_rotation(skeleton.find_bone("upper_chest")))>.001,"cintura e peito superior articulam separadamente em repouso")
	var arms_relaxed:=true
	for side in ["L","R"]:
		var arm: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("arm_"+side)).origin
		var elbow: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("forearm_"+side)).origin
		var wrist: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+side)).origin
		var hip: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("thigh_"+side)).origin
		arms_relaxed=arms_relaxed and wrist.y<hip.y+.15 and elbow.y<arm.y-.18 and absf(wrist.x-hip.x)<.23
	check(arms_relaxed,"cotovelos baixos e punhos abaixo do quadril no repouso")
	var left_ankle:=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("foot_L")).origin
	var right_ankle:=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("foot_R")).origin
	check(absf(left_ankle.x-right_ankle.x)<.33 and absf(left_ankle.y-right_ankle.y)<.02,"repouso tem base estreita e dois pés apoiados")
	check(world.depot.felps.model.find_child("Felps_Head",true,false)!=null,"Felps correto usa malha de cabeça separada")
	player.position=Vector3(3.8,.01,.9);player.camera_rig.yaw=0
	var start:=player.position
	Input.action_press("forward");await ticks(24);Input.action_release("forward");await ticks(10)
	var walked:=start.distance_to(player.position)
	check(walked>.5,"WASD move Dery com colisão real")
	player.position=start;player.velocity=Vector3.ZERO
	Input.action_press("forward");Input.action_press("sprint");await ticks(24);Input.action_release("forward");Input.action_release("sprint");await ticks(2)
	check(start.distance_to(player.position)>walked,"corrida mais rápida que caminhada")
	Input.action_press("crouch");await ticks(3)
	check(player.crouching and player.capsule.height<1.35,"agachamento altera colisão")
	Input.action_release("crouch");await ticks(3)
	# Synthetic absolute coordinates must not be warped by headless mouse capture.
	# Keep the event going through the real viewport and application's input path.
	var previous_mouse_mode:=Input.mouse_mode
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var previous_distance:=player.camera_rig.target_distance
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=Vector2(640,360);wheel.global_position=wheel.position;Input.parse_input_event(wheel);await ticks(3)
	check(player.camera_rig.target_distance<previous_distance,"roda do mouse chega à câmera pela viewport")
	var previous_yaw:=player.camera_rig.yaw
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(50,0);motion.position=Vector2(640,360);motion.global_position=motion.position;Input.parse_input_event(motion);await ticks(3)
	check(player.camera_rig.yaw!=previous_yaw,"movimento do mouse gira a câmera pela viewport")
	Input.mouse_mode=previous_mouse_mode
	player.position=Vector3(5.45,0,-9.6);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI/2;player.camera_rig.target_distance=2.5
	await ticks(30)
	check(player.camera_rig.arm.get_hit_length()<1.0,"SpringArm encurta ao encostar na parede")
	check(player.camera_rig.camera.global_position.x<5.9,"câmera permanece do lado interno da parede")
	player.position=Vector3(5.55,0,-9.6);player.camera_rig.yaw=0;await ticks(20)
	check(player.camera_rig.arm.position.x<.25,"ombro recolhe lateralmente perto da parede")
	var camera_probe:=PhysicsShapeQueryParameters3D.new();var camera_sphere:=SphereShape3D.new();camera_sphere.radius=.045;camera_probe.shape=camera_sphere;camera_probe.transform=Transform3D(Basis.IDENTITY,player.camera_rig.camera.global_position);camera_probe.collision_mask=1
	check(world.get_world_3d().direct_space_state.intersect_shape(camera_probe).is_empty(),"volume próximo da lente fica fora da parede")
	player.camera_rig.target_distance=0;await ticks(40)
	check(player.camera_rig.first_person and player.visual.find_child("Dery_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and player.visual.find_child("Dery_Body",true,false).visible,"aproximação entra em primeira pessoa com corpo visível e cabeça apenas na sombra")
	player.position=Vector3(3.4,0,-7.8);player.reset_physics_interpolation()
	player.camera_rig.target_distance=2.5;await ticks(40)
	check(not player.camera_rig.first_person and player.visual.find_child("Dery_Head",true,false).visible and player.visual.find_child("Dery_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"afastamento retorna à terceira pessoa")
	player.position=CheckoutFixture.CUSTOMER_POSITION;player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI/2;player.camera_rig.pitch=-.13;player.reset_physics_interpolation();await ticks(30)
	check(player.target!=null and player.target.kind=="talk","Felps é alcançável pela interação sobre o balcão")
	# Flush accumulated input before advancing physics; a fast headless run can fit
	# multiple physics ticks before the next rendered frame dispatches the event.
	var interact_key:=InputEventKey.new();interact_key.physical_keycode=KEY_E;interact_key.keycode=KEY_E;interact_key.pressed=true;Input.parse_input_event(interact_key);Input.flush_buffered_events();await ticks(6)
	check(Session.stage==1,"tecla E conversa com Felps e libera tarefas")
	check(Dialogue.active,"diálogo exibe falas reais")
	check(world.depot.felps.motion.current_clip=="talk","Felps gesticula enquanto fala")
	interact_key=InputEventKey.new();interact_key.physical_keycode=KEY_E;interact_key.keycode=KEY_E;interact_key.pressed=false;Input.parse_input_event(interact_key);Input.flush_buffered_events()
	clear_dialogue()
	check(not Session.deliver("loose"),"caixa errada não avança reposição")
	var door:=find_interaction(world.depot.stock_door,"door")
	var a:=Vector3(4.9,1,-10.3);var b:=Vector3(4.9,1,-11.8)
	var space:=world.get_world_3d().direct_space_state
	check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty(),"porta fechada bloqueia passagem")
	door.activate(player);await ticks(40)
	check(space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty(),"porta aberta libera passagem física")
	var fridge:=find_interaction(world.depot.fridge_target,"fridge")
	var initial_bottles: int=world.depot.fridge_target.products.groups["beer_0"].baked_count
	check(not find_interaction(world.depot.crates.stock_1,"crate").activate(player),"caixa distante exige aproximação antes de alcançar")
	var drop_item: Node3D=world.depot.crates.stock_1
	player.position=drop_item.global_position+Vector3(0,0,.7);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.reset_physics_interpolation()
	find_interaction(drop_item,"crate").activate(player)
	await key_press(KEY_Q);await key_press(KEY_TAB)
	check(player.drop_pending and world.player==player,"Q durante a pegada agenda a soltura e Tab aguarda a animação")
	await ticks(160)
	check(player.carried==null and not player.handling.busy and absf(drop_item.global_position.y)<.04 and absf(drop_item.global_rotation.x)<.01 and absf(drop_item.global_rotation.z)<.01,"soltura agendada apoia a caixa em pé no chão sem perder o objeto")
	player.position=drop_item.global_position+Vector3(0,0,.7);player.velocity=Vector3.ZERO;player.reset_physics_interpolation()
	check(find_interaction(drop_item,"crate").activate(player),"caixa largada pode ser pega novamente")
	await ticks(90)
	player.position=Vector3(0,0,-15.1);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.reset_physics_interpolation();await ticks(5)
	check(not player.handling.placement().valid,"parede impede apoiar a caixa do outro lado")
	await key_press(KEY_Q)
	check(player.carried==drop_item and not app.interface.notice_label.text.is_empty(),"Q sem espaço preserva a caixa e avisa o jogador")
	player.position=Vector3(0,0,-12.5);player.velocity=Vector3.ZERO;player.reset_physics_interpolation();await ticks(10)
	check(player.handling.can_place and player.handling.preview.visible,"marca de colocação aparece verde sobre piso livre")
	await key_press(KEY_TAB)
	check(world.player==felps and player.carried==drop_item and drop_item.get_parent()==player.socket and Session.carried_id.is_empty(),"trocar para Felps mantém a caixa fisicamente com Deryk")
	var held_position:=player.global_position
	check(Session.save_shift(felps.global_position)==OK,"salvamento aceita Felps ativo enquanto Deryk segura caixa")
	app.start_saved();world=app.world;felps=world.characters.Felps;player=world.characters.Dery;await ticks(12)
	check(world.player==felps and player.carried==world.depot.crates.stock_1 and player.position.distance_to(held_position)<.1 and felps.position.distance_to(CheckoutFixture.STAFF_POSITION)<.1 and get_tree().get_nodes_in_group("protagonists").size()==2,"continuar restaura Felps no balcão, Deryk e sua caixa sem duplicar personagens")
	await key_press(KEY_TAB);await key_press(KEY_Q);await ticks(100)
	var floor_position: Vector3=world.depot.crates.stock_1.global_position
	Session.save_shift(player.global_position);app.start_saved();world=app.world;player=world.player;felps=world.characters.Felps;await ticks(8)
	check(player.carried==null and world.depot.crates.stock_1.global_position.distance_to(floor_position)<.02,"caixa apoiada conserva sua posição ao salvar e continuar")
	skeleton=player.motion.skeleton;fridge=find_interaction(world.depot.fridge_target,"fridge")
	for id in ["stock_1","stock_2"]:
		var item: Node3D=world.depot.crates[id]
		player.position=item.position+Vector3(0,0,.7)
		check(find_interaction(item,"crate").activate(player),"pegar "+id)
		check(player.motion.action_active and item.get_parent()!=player.socket,"pegar caixa começa com alcance antes da fixação")
		await ticks(85)
		check(player.carried==item and item.get_parent()==player.socket,"caixa presa ao transporte visível")
		var palm: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand_L")).origin
		check(palm.distance_to(item.to_global(Vector3(.325,.275,-.09)))<.10,"mão permanece junto à pega lateral da caixa")
		player.position=world.depot.fridge_target.global_position+Vector3(1.35,0,0)
		if not fridge.open:fridge.activate(player)
		check(fridge.activate(player),"repor "+id)
		await ticks(75)
		check(player.carried==null,"mãos livres após reposição")
		check(world.depot.fridge_target.products.groups["beer_0"].baked_count==initial_bottles+2*Session.stocked.size(),"malha visível recebe novos produtos após reposição")
	check(Session.stage==3 and Session.stocked.size()==2,"duas reposições completam objetivo na ordem")
	var loose: Node3D=world.depot.crates.loose
	player.position=loose.global_position+Vector3(0,0,.7)
	find_interaction(loose,"crate").activate(player);await ticks(85)
	player.position=Vector3(-3.8,0,-12.8)
	var pallet: Interaction
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="pallet":pallet=node
	check(pallet.activate(player) and Session.organized,"organização move caixa para palete")
	await ticks(85)
	check(loose.global_position.distance_to(Vector3(-3.8,.23,-13.8))<.1,"caixa permanece materialmente no palete")
	clear_dialogue()
	check(not Session.can_warn(),"aviso exige clientes atendidos além das tarefas")
	player.position=Vector3(4.7,0,-8.5);player.velocity=Vector3.ZERO
	# Simulate the actual complete routes. No waypoint skipping or teleporting customers.
	Engine.time_scale=12
	var waiting_ticks:=0
	var checkout_gate_checked:=false
	var register_checked:=false
	var change_checked:=false
	var sale_resumed:=false
	var bulk_checked:=false
	var delivered_checked:=false
	for i in 3000:
		await get_tree().physics_frame
		if world.customer!=null:
			served_states[world.customer.state]=true
			if world.customer.state in [Customer.State.WAITING,Customer.State.PAYING] and world.customer.global_position.distance_to(CheckoutFixture.CUSTOMER_POSITION)>.4:checkout_positions_valid=false
			if world.customer.state==Customer.State.WAITING and not world.customer.purchase_complete:
				if not checkout_gate_checked:
					waiting_ticks+=1
					if waiting_ticks<60:continue
					check(Session.customers_served==0 and not world.try_checkout(world.characters.Dery),"cliente aguarda atendimento e Deryk não conclui a venda no lugar de Felps")
					checkout_gate_checked=true
				if world.player.identity!="Felps":world.switch_player()
				elif app.interface.checkout==null and world.player.target!=null and world.player.target.kind=="checkout":
					var service_key:=InputEventKey.new();service_key.physical_keycode=KEY_E;service_key.keycode=KEY_E;service_key.pressed=true;Input.parse_input_event(service_key);Input.flush_buffered_events()
					service_key=InputEventKey.new();service_key.physical_keycode=KEY_E;service_key.keycode=KEY_E;service_key.pressed=false;Input.parse_input_event(service_key);Input.flush_buffered_events()
				if app.interface.checkout!=null:
					var sale:=world.sale
					match sale.phase:
						ShopSale.Phase.REGISTER:
							if sale.needs_bulk() and not sale.bulk_supplied:
								check(not world.customer.product.visible and not world.checkout_step("confirm"),"pedido de caixa fechada aguarda mercadoria física e não inventa produto nas mãos do cliente")
								var fetched:=await fetch_order_box()
								check(fetched and world.sale.bulk_supplied and world.characters.Dery.carried==null,"Deryk percorre o estoque, pega a caixa e entrega no balcão antes de voltar a Felps")
								if not fetched:break
								bulk_checked=true;continue
							if not register_checked:
								check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.checkout.get_global_rect()) and world.characters.Felps.input_locked,"tela do caixa cabe na janela e impede caminhada enquanto recebe cliques")
								await press_register("Register_beer_0");await press_register("ConfirmItems")
								check(sale.phase==ShopSale.Phase.REGISTER and not world.checkout_step("receive") and Session.sales_cents==0,"produto ou quantidade errada impede cobrança e recebe resposta do cliente")
								await press_register("Remove_beer_0");register_checked=true
							for sku in sale.order:
								while int(sale.registered.get(sku,0))<int(sale.order[sku]):await press_register("Register_"+sku)
							await press_register("ConfirmItems")
						ShopSale.Phase.PAYMENT:
							await press_register("ReceiveCash")
							if not change_checked:check(sale.phase==ShopSale.Phase.CHANGE and world.depot.counter.drawer_is_open,"receber dinheiro abre a gaveta e libera a separação do troco")
						ShopSale.Phase.CHANGE:
							if not change_checked:
								await press_register("Coin_500");await press_register("ConfirmChange")
								check(sale.phase==ShopSale.Phase.CHANGE and not world.customer.purchase_complete and Session.sales_cents==0,"troco errado mantém venda pendente e permite corrigir sem cobrar outra vez")
								await press_register("UndoCoin");await press_register("Coin_500");change_checked=true
							if not sale_resumed:
								Session.save_shift(world.player.global_position)
								var current_id:=sale.id
								app.start_saved();world=app.world;player=world.characters.Dery;felps=world.characters.Felps;await ticks(8)
								check(world.sale.id==current_id and world.sale.phase==ShopSale.Phase.CHANGE and world.sale.selected_change()==500 and world.customer.state==Customer.State.WAITING and Session.customers_served==0,"continuar preserva cliente, registro, dinheiro recebido e troco parcial sem concluir ou duplicar venda")
								sale_resumed=true;continue
							var remaining:=sale.change_due()-sale.selected_change()
							for coin in ShopSale.COINS:
								while coin<=remaining:
									await press_register("Coin_"+str(coin));remaining-=coin
							await press_register("ConfirmChange")
						ShopSale.Phase.READY:
							var previous_count:=Session.customers_served;var previous_cash:=Session.sales_cents
							await press_register("DeliverPurchase")
							if not delivered_checked:
								check(world.customer.purchase_complete and world.customer.bag.visible and Session.customers_served==previous_count+1 and Session.sales_cents==previous_cash+sale.total() and not world.checkout_step("deliver"),"entrega cria recibo, sacola e receita uma única vez e libera a saída do cliente")
								delivered_checked=true
		if Dialogue.active and world.customer!=null and world.customer.state==Customer.State.WAITING:
			clear_dialogue()
		if Session.warning_delivered:break
	Engine.time_scale=1
	if not Session.warning_delivered:
		print("CHECKOUT_FLOW_DEBUG served=",Session.customers_served," stage=",Session.stage," active=",world.player.identity," dery=",world.characters.Dery.position," phase=",world.sale.phase if world.sale!=null else -1," customer=",world.customer.position if world.customer!=null else Vector3.ZERO," state=",world.customer.state if world.customer!=null else -1," routes=",world.customer.reroutes if world.customer!=null else -1," next=",world.customer.waypoints[0] if world.customer!=null and not world.customer.waypoints.is_empty() else Vector3.ZERO," dialogue=",Dialogue.active)
	check(Session.customers_served>=3,"clientes atravessam loja, compram e saem")
	check(register_checked and change_checked and sale_resumed and bulk_checked and delivered_checked,"turno percorre registro, troco, retomada e trabalho dos dois personagens")
	var ledger_total:=0
	for receipt in Session.receipts:ledger_total+=int(receipt.total)
	check(ledger_total==Session.sales_cents and Session.receipts.size()==Session.customers_served,"receita do turno corresponde aos recibos sem duplicação após continuar")
	var served_checkpoint=JSON.parse_string(FileAccess.get_file_as_string(Session.SAVE_PATH))
	check(served_checkpoint is Dictionary and int(served_checkpoint.get("customers",0))==Session.customers_served,"saída do cliente salva automaticamente o total de atendimentos concluídos")
	var ambient_finished:=true
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		if friend.motion.ambient_active:
			var clip: String=friend.motion.clips.get(friend.motion.current_clip,"")
			ambient_finished=ambient_finished and not clip.is_empty() and friend.motion.animator.get_animation(clip).loop_mode==Animation.LOOP_NONE
	check(ambient_finished,"conhecidos mantêm variações de repouso que terminam durante o expediente longo")
	check(served_states.size()>=7,"máquina de estados dos clientes executa o ciclo completo")
	check(checkout_positions_valid,"todos os clientes são atendidos junto ao novo balcão esquerdo")
	check(Session.warning_delivered and Session.stage==6,"aviso ocorre somente depois da rotina e da visita")
	clear_dialogue()
	if world.player.identity!="Dery":world.switch_player()
	player=world.player
	player.position=Vector3(4,0,-6);await ticks(3)
	check(Dialogue.active,"ruído posterior tem reação narrativa")
	clear_dialogue()
	check(find_interaction(world.depot.old_door,"note").activate(player) and Session.finale_seen,"inspeção do ruído conclui a demonstração")
	check(Session.save_shift(Vector3(0,0,-4))==OK,"salvamento grava checkpoint")
	Session.new_shift();check(Session.load_shift() and Session.stage==7 and Session.stocked.size()==2,"checkpoint restaura progressão e tarefas")
	clear_dialogue()
	await get_tree().process_frame
	app.start_saved();world=app.world;player=world.player;await ticks(5)
	check(player.position.distance_to(Vector3(0,0,-4))<.3,"continuar restaura posição no mundo")
	check(not is_instance_valid(world.depot.crates.stock_1),"continuar não duplica caixas já repostas")
	check(world.depot.fridge_target.products.groups["beer_0"].baked_count==initial_bottles+4,"continuar restaura produtos na malha da geladeira")
	var migrated:=world.navigation.nearest_walkable(Vector3(1,0,-4))
	check(migrated.distance_to(Vector3(1,0,-4))>.3 and migrated.distance_to(Vector3(1,0,-4))<2,"checkpoint antigo dentro da gôndola migra para corredor próximo")
	Session.save_shift(Vector3(20,0,1.8))
	await get_tree().process_frame
	app.start_saved();world=app.world;player=world.player;await ticks(15)
	check(player.is_on_floor() and player.position.y>.4,"checkpoint antigo na rua acompanha a nova cota do terreno")
	Session.save_shift(Vector3(-4.25,0,-2.8))
	await get_tree().process_frame
	app.start_saved();world=app.world;player=world.player;await ticks(15)
	var restored_probe:=PhysicsShapeQueryParameters3D.new();var restored_capsule:=CapsuleShape3D.new();restored_capsule.radius=.24;restored_capsule.height=1.68
	restored_probe.shape=restored_capsule;restored_probe.transform=Transform3D(Basis.IDENTITY,player.global_position+Vector3.UP*.87);restored_probe.collision_mask=1
	check(player.is_on_floor() and world.get_world_3d().direct_space_state.intersect_shape(restored_probe).is_empty(),"checkpoint antigo no novo balcão restaura personagem fora dos móveis")
	app.interface.set_paused(true);var frozen:=Session.world_seconds
	var frozen_haze: float=world.street.get_node("StreetHaze").time;var frozen_light: float=world.get_node("NightMood").time;await ticks(3)
	check(Session.world_seconds==frozen,"pausa congela o relógio narrativo")
	check(world.street.get_node("StreetHaze").time==frozen_haze and world.get_node("NightMood").time==frozen_light,"pausa congela a deriva da névoa e as variações de luz")
	app.interface.set_paused(false)
	clear_dialogue()
	var legacy:={"version":1,"stage":1,"stocked":[],"organized":false,"customers":0,"position":[0,0,-12.5],"carried":"stock_1"}
	var legacy_file:=FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE);legacy_file.store_string(JSON.stringify(legacy));legacy_file.close()
	app.start_saved();world=app.world;player=world.player;await ticks(8)
	check(player.identity=="Dery" and player.carried_id=="stock_1" and player.carried==world.depot.crates.stock_1 and world.characters.Felps.position.distance_to(CheckoutFixture.STAFF_POSITION)<.1,"checkpoint antigo da versão 1 migra para a dupla preservando a caixa carregada")
	Session.save_shift(player.global_position)
	var previous_format=JSON.parse_string(FileAccess.get_file_as_string(Session.SAVE_PATH));previous_format.version=2
	for field in ["sale","customer_state","next_sale_id","sales_cents","receipts","familiar_visits"]:previous_format.erase(field)
	legacy_file=FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE);legacy_file.store_string(JSON.stringify(previous_format));legacy_file.close()
	app.start_saved();world=app.world;player=world.player;await ticks(8)
	check(player.carried_id=="stock_1" and world.characters.size()==2 and Session.sales_cents==0 and Session.receipts.is_empty(),"checkpoint da versão 2 preserva a dupla e caixas ao migrar para pedidos e dinheiro")
	print("RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	app.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.2).timeout
	Geo.materials.clear()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
