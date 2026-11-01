extends "res://tests/everyday_integration.gd"
var reloaded_actor_position:=Vector3.ZERO
var reloaded_actor_leg:=-1
func door_interaction(node: Node) -> Interaction:
 for child in node.get_children():
  if child is Interaction and child.kind=="door":return child
 return null
func reload() -> void:
 Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999
 if is_instance_valid(world.scary.intruder):reloaded_actor_position=world.scary.intruder.position;reloaded_actor_leg=world.scary.intruder.leg
 await ticks(4)
func run() -> void:
 Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.spawn_wait=999
 Session.greet();clear_dialogue();Session.world_seconds=60
 await stand(Vector3(2.8,.01,-12.2))
 check(world.scary.state().door_phase=="dragging" and world.scary.drag.playing,"entrar no estoque inicia um arrasto atrás da porta antiga")
 check(world.scary.drag.global_position.z< -15.5 and world.scary.drag.max_distance==12,"arrasto vem da posição física da porta")
 var yaw:=world.player.camera_rig.yaw;var distance:=world.player.camera_rig.target_distance
 await reload()
 check(world.scary.state().door_phase=="dragging" and world.scary.drag.playing,"continuar retoma arrasto em andamento")
 await stand(Vector3(.7,.01,-14.0))
 for frame in 150:
  await ticks(1)
  if world.scary.state().door_phase=="quiet":break
 check(world.scary.state().door_phase=="quiet" and not world.scary.drag.playing,"aproximar-se faz o arrasto parar antes do susto")
 var door_at:=world.depot.old_door.transform
 await ticks(42)
 check(world.scary.done("stock_handle") and world.scary.state().door_phase=="handle","depois do silêncio a maçaneta reage")
 check(absf(world.scary.handle.rotation.z)>.005 and world.depot.old_door.transform==door_at,"animação mexe a maçaneta e mantém a porta e sua colisão no lugar")
 check(is_equal_approx(world.player.camera_rig.yaw,yaw) and is_equal_approx(world.player.camera_rig.target_distance,distance),"susto não gira nem afasta a câmera do jogador")
 await reload();await ticks(140)
 check(world.scary.done("stock_handle") and world.scary.state().door_phase=="done" and not world.scary.drag.playing,"save no susto conclui a maçaneta sem repetir o arrasto")
 var note_count: int=Session.campaign.experience.notes.size();await ticks(20)
 check(Session.campaign.experience.notes.size()==note_count,"observação da porta não se duplica")
 Session.world_seconds=float(world.scary.state().last_event)+10
 await stand(Vector3(-3.1,.01,-2.8),PI)
 check(world.scary.state().prank.is_empty(),"há intervalo de calma antes da brincadeira de Bryan")
 Session.world_seconds=float(world.scary.state().last_event)+40;await ticks(3)
 check(world.scary.state().prank.get("phase")=="walking" and world.scary.bryan.scare_moving,"Bryan precisa caminhar até a vitrine")
 var bryan_at:=world.scary.bryan.position;await reload()
 check(world.scary.bryan.position.distance_to(bryan_at)<.25 and world.scary.bryan.scare_moving,"save retoma Bryan na rota da brincadeira sem teleporte")
 var prank_phase: String=world.scary.state().prank.phase
 world.scary.state().prank.phase="waiting"
 check(not world.scary.blocks_ambient(),"Bryan esperando fora da visão não bloqueia outros acontecimentos")
 world.scary.state().prank.phase=prank_phase
 var continuous:=true;var before:=world.scary.bryan.position
 for frame in 650:
  await ticks(1)
  continuous=continuous and world.scary.bryan.position.distance_to(before)<.18;before=world.scary.bryan.position
  if world.scary.done("bryan_prank"):break
 check(continuous and world.scary.done("bryan_prank"),"Bryan chega fisicamente e dá a batida na vitrine")
 check(world.scary.bryan.position.distance_to(FridayScares.WINDOW)<.55 and not Dialogue.active,"falso susto revela Bryan sem travar o controle")
 check(JSON.stringify(world.story.familiar_lines("Bryan",world.player,0)).contains("coração"),"a conversa opcional traz o alívio depois da brincadeira")
 await reload();note_count=Session.campaign.experience.notes.size();await ticks(30)
 check(world.scary.done("bryan_prank") and Session.campaign.experience.notes.size()==note_count,"continuar não repete a batida nem sua anotação")
 clear_dialogue();check(world.friday.begin_outage(),"apagão mantém a entrada original da missão do gerador")
 clear_dialogue();Session.campaign.flags.generator_key=true;Session.campaign.flags.counter_secured=true
 await stand(Vector3(4.35,.01,-19.4));check(world.friday.activate("generator",world.characters.Dery),"gerador continua exigindo a ação original de Deryk")
 clear_dialogue();await ticks(85)
 check(world.scary.state().return_armed and not is_instance_valid(world.scary.intruder),"ligar o gerador prepara o susto para a volta, sem criar alguém no pátio")
 check(world.sound.compressors.all(func(player):return player.playing),"refrigeração e energia voltam antes do susto")
 for door in [world.depot.service_door,world.depot.stock_door]:
  var interaction:=door_interaction(door)
  if not interaction.open:interaction.activate(world.player)
 await ticks(35);Session.world_seconds=420
 world.cashier_open=true;await stand(Vector3(4.25,.01,-6.4),-.40)
 check(not is_instance_valid(world.scary.intruder),"aparição discreta aguarda um atendimento aberto")
 world.cashier_open=false
 await stand(Vector3(4.25,.01,-6.4),.04)
 check(not is_instance_valid(world.scary.intruder),"olhar diretamente para o vão não força uma apresentação do assassino")
 door_interaction(world.depot.stock_door).activate(world.player);await ticks(35)
 await stand(Vector3(4.25,.01,-6.4),-.40)
 check(not is_instance_valid(world.scary.intruder),"porta fechada impede aparição através da folha de metal")
 world.cashier_open=true;door_interaction(world.depot.stock_door).activate(world.player);await ticks(35)
 var felps_at: Vector3=world.characters.Felps.position;var felps_facing: float=world.characters.Felps.visual.rotation.y
 world.characters.Felps.position=Vector3(4.8,.01,-7.4);world.characters.Felps.visual.rotation.y=PI;world.characters.Felps.reset_physics_interpolation();world.cashier_open=false;await ticks(8)
 check(world.scary.other_witnesses(FrightIntruder.EDGE) and not is_instance_valid(world.scary.intruder),"Felps com vista para o estoque impede a aparição")
 world.cashier_open=true;world.characters.Felps.position=felps_at;world.characters.Felps.visual.rotation.y=felps_facing;world.characters.Felps.reset_physics_interpolation()
 world.spawn_customer(false);world.customer.waypoints.clear();world.customer.position=Vector3(4.8,.01,-7.4);world.customer.visual.rotation.y=PI;world.customer.set_physics_process(false);world.customer.reset_physics_interpolation();world.cashier_open=false;await ticks(8)
 check(not is_instance_valid(world.scary.intruder),"cliente com linha de visão impede aparição diante dele")
 world.cashier_open=true;discard_customer();await ticks(2)
 var bryan_before: Vector3=world.scary.bryan.position;var bryan_facing: float=world.scary.bryan.visual.rotation.y
 world.scary.bryan.position=Vector3(4.8,.01,-7.4);world.scary.bryan.visual.rotation.y=PI;world.scary.bryan.set_physics_process(false);world.scary.bryan.reset_physics_interpolation();world.cashier_open=false;await ticks(8)
 check(not is_instance_valid(world.scary.intruder),"Bryan vendo o fundo também impede a figura")
 world.cashier_open=true;world.scary.bryan.position=bryan_before;world.scary.bryan.visual.rotation.y=bryan_facing;world.scary.bryan.set_physics_process(true);world.scary.bryan.reset_physics_interpolation()
 await stand(Vector3(4.25,.01,-6.4),PI);world.cashier_open=false;await ticks(8)
 check(not is_instance_valid(world.scary.intruder),"estar de costas não registra uma presença que o jogador não viu")
 var lights_before: Array=[]
 for light in world.friday.lights:lights_before.append(light.light_energy)
 var door_before:=world.depot.service_door.transform
 await stand(Vector3(4.25,.01,-6.4),-.40)
 check(is_instance_valid(world.scary.intruder) and world.scary.done("quiet_return"),"olhada periférica prepara apenas uma figura atrás do batente")
 if not is_instance_valid(world.scary.intruder):
  var camera:=world.player.camera_rig.camera;var point:=FrightIntruder.EDGE+Vector3(.2,1.5,0)
  print("GLIMPSE DEBUG ",world.scary.state()," hidden=",world.scary.player_sees_body(FrightIntruder.HIDDEN)," witness=",world.scary.other_witnesses(FrightIntruder.EDGE)," edge=",world.scary.can_see(point)," screen=",camera.unproject_position(point)/camera.get_viewport().get_visible_rect().size);await finish_test();return
 check(not world.scary.intruder.is_in_group("customers") and world.customer==null,"figura continua separada de vendas e atendimento")
 check(world.scary.intruder.visual.scene_file_path==world.enemy_visual.scene_file_path and world.scary.intruder.visual.scene_file_path.ends_with("Enemy.glb"),"aparição conserva o modelo original do assassino")
 check(not world.scary.done("return_intruder"),"preparar uma figura ainda escondida não inventa uma observação")
 var intruder_at:=world.scary.intruder.position;var saved_leg:=world.scary.intruder.leg;await reload()
 check(is_instance_valid(world.scary.intruder) and reloaded_actor_position.distance_to(intruder_at)<.03 and reloaded_actor_leg==saved_leg,"save retoma posição e fase discreta sem teleporte")
 var frozen:=world.scary.intruder.position;var held:=world.scary.intruder.held
 await key(KEY_J);await ticks(8)
 check(get_tree().paused and world.scary.intruder.position.distance_to(frozen)<.01 and is_equal_approx(world.scary.intruder.held,held),"caderno congela deslocamento e duração da aparição")
 await key(KEY_J)
 var current_yaw:=world.player.camera_rig.yaw;var current_pitch:=world.player.camera_rig.pitch;var current_distance:=world.player.camera_rig.target_distance
 var continuous_intruder:=true;var stays_in_stock:=true;var visible_seconds:=0.0;var retired_hidden: Array[bool]=[false]
 world.scary.intruder.departed.connect(func():retired_hidden[0]=not world.scary.player_sees_body(world.scary.intruder.position) and not world.scary.other_witnesses(world.scary.intruder.position))
 before=world.scary.intruder.position
 for frame in 400:
  await ticks(1)
  if not is_instance_valid(world.scary.intruder):break
  continuous_intruder=continuous_intruder and world.scary.intruder.position.distance_to(before)<.08;before=world.scary.intruder.position
  stays_in_stock=stays_in_stock and world.scary.intruder.position.z< -11.4
  if world.scary.player_sees_body(world.scary.intruder.position):visible_seconds+=1.0/60.0
 check(continuous_intruder and stays_in_stock,"figura se move fisicamente atrás do batente e nunca atravessa o salão")
 check(world.scary.done("intruder_gone") and retired_hidden[0],"retirada acontece somente encoberta pela parede ou fora de vista")
 check(visible_seconds>0 and visible_seconds<1.2,"vulto é visível por menos de 1,2 segundo sem virar uma apresentação")
 check(world.scary.done("return_intruder") and not Dialogue.active,"percepção real registra só uma impressão sem conversa automática")
 check(not world.scary.done("yard_slam") and world.depot.service_door.transform==door_before,"aparição não bate nem abre portas para chamar atenção")
 var unchanged_lights:=true
 for index in world.friday.lights.size():unchanged_lights=unchanged_lights and is_equal_approx(world.friday.lights[index].light_energy,lights_before[index])
 check(unchanged_lights and world.sound.compressors.all(func(player):return player.playing),"aparição não pisca a iluminação nem altera o circuito de refrigeração")
 check(is_equal_approx(world.player.camera_rig.yaw,current_yaw) and is_equal_approx(world.player.camera_rig.pitch,current_pitch) and is_equal_approx(world.player.camera_rig.target_distance,current_distance),"aparição não gira câmera nem altera a distância escolhida")
 check(JSON.stringify(Session.campaign.experience.notes).contains("impressão") and not JSON.stringify(Session.campaign.experience.notes).contains("atravessar o salão"),"anotação mantém dúvida sobre o que apareceu")
 await stand(CheckoutFixture.CUSTOMER_POSITION,PI/2)
 var first_line: Array[String]=[]
 Dialogue.spoken.connect(func(_who: String,text: String):first_line.append(text),CONNECT_ONE_SHOT)
 check(world.story.try_remark(world.player) and Dialogue.sequence=="friday_remark_return_intruder" and not first_line.is_empty() and first_line[0].contains("Achei que") and JSON.stringify(Dialogue.queue).contains("Não sei."),"só conversar por iniciativa própria após o gerador permite comentar uma impressão incerta")
 clear_dialogue()
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"terceira pessoa pela rodinha permanece após a aparição")
 await reload();await ticks(5)
 check(not Dialogue.active and not is_instance_valid(world.scary.intruder) and not world.scary.state().return_armed,"continuar não repete figura ou conversa de explicação")
 var witnessed:=Session.snapshot_data()
 world.scary.state().events={};world.scary.state().intruder={};world.scary.state().return_armed=true;world.scary.state().last_scare=-1000
 await wheel(MOUSE_BUTTON_WHEEL_UP,12);await stand(Vector3(4.25,.01,-6.4),-.40)
 check(is_instance_valid(world.scary.intruder),"segunda situação isolada prepara teste de olhar desviado")
 if is_instance_valid(world.scary.intruder):
  world.player.camera_rig.yaw=PI;world.player.camera_rig.reset_follow();await ticks(200)
  check(world.scary.done("intruder_gone") and not world.scary.done("return_intruder"),"quem desvia antes do vulto não recebe confirmação de algo que não viu")
 Session.write_save(witnessed);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(4)
 var legacy_glimpse:=Session.snapshot_data();legacy_glimpse.campaign.friday_scares.intruder={"state":"crossing","position":[-2,0,-8.5],"leg":0};legacy_glimpse.campaign.friday_scares.return_armed=true;legacy_glimpse.campaign.friday_scares.dim_time=2.0
 Session.write_save(legacy_glimpse);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(4)
 check(not is_instance_valid(world.scary.intruder) and world.scary.done("intruder_gone") and not world.scary.state().return_armed,"checkpoint antigo da travessia não recria um assassino exposto no salão")
 check(world.scary.done("return_intruder") and world.story.noticed("return_intruder"),"migrar encenação antiga preserva observações e progresso já salvos")
 Session.campaign.phase="closing";Session.campaign.flags.till_closed=true;Session.campaign.flags.stock_checked=true;Session.campaign.flags.lights_off=true;Session.campaign.flags.reunite=true
 for actor in world.characters.values():actor.position=Vector3(3.8 if actor.identity=="Dery" else 4.4,.01,1.4);actor.reset_physics_interpolation()
 world.friday.activate("exit",world.player)
 check(Dialogue.sequence=="friday_closing_hook" and not JSON.stringify(Dialogue.queue).contains("cara da rua"),"fechamento reconhece a invasão e preserva o gancho para sábado")
 clear_dialogue();await ticks(110)
 check(Session.campaign.phase=="complete" and app.interface.night_panel!=null,"os sustos não bloqueiam o fechamento original")
 app.interface.night_panel.find_child("NextNight",true,false).pressed.emit();world=app.world;await ticks(4)
 check(not is_instance_valid(world.scary.intruder) and not world.scary.drag.playing,"sábado não recria sustos nem o invasor da sexta")
 check(JSON.stringify(world.story.saturday_memory()).contains("Achei que vi"),"sábado conserva dúvida em vez de confirmar um invasor no salão")
 var legacy:=Session.snapshot_data();legacy.campaign.erase("friday_scares");Session.write_save(legacy)
 check(Session.load_shift() and Session.campaign.friday_scares.events is Dictionary,"save anterior recebe campos opcionais sem perder a campanha")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;await get_tree().create_timer(.15,true,false,true).timeout;app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(4)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("SCARES RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
 get_tree().quit(0 if failures.is_empty() else 1)
