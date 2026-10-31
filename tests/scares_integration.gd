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
 await ticks(35);Session.world_seconds=float(world.scary.state().last_scare)+40
 world.cashier_open=true;await stand(Vector3(4.35,.01,-9.1),PI)
 check(not is_instance_valid(world.scary.intruder),"susto de retorno aguarda um atendimento aberto")
 world.cashier_open=false
 check(world.scary.can_see(FridayScares.CROSS_POINT) and not world.scary.can_see(FridayScares.START+Vector3.UP*1.5),"rota cruza o campo visível, começando fora da visão")
 await ticks(4)
 check(is_instance_valid(world.scary.intruder) and world.scary.done("return_crossing"),"voltar pelo estoque inicia a travessia no salão")
 if not is_instance_valid(world.scary.intruder):
  print("SCARE DEBUG ",world.player.position," ",world.player.camera_rig.yaw," ",world.scary.state());await finish_test();return
 check(not world.scary.intruder.is_in_group("customers") and world.customer==null,"figura não ocupa nem conclui o caixa")
 var intruder_at:=world.scary.intruder.position;var saved_leg:=world.scary.intruder.leg;await reload()
 check(is_instance_valid(world.scary.intruder) and reloaded_actor_position.distance_to(intruder_at)<.03 and reloaded_actor_leg==saved_leg,"save conserva posição e percurso da figura")
 check(world.scary.dim_remaining>0 and world.scary.ceiling[0].light.light_energy<float(world.scary.ceiling[0].energy),"save conserva a oscilação passageira da iluminação")
 var frozen:=world.scary.intruder.position;var dim:=world.scary.dim_remaining
 await key(KEY_J);await ticks(8)
 check(get_tree().paused and world.scary.intruder.position.distance_to(frozen)<.01 and is_equal_approx(world.scary.dim_remaining,dim),"caderno pausa figura e iluminação durante o susto")
 await key(KEY_J)
 await stand(Vector3(3.2,.01,-7.5),atan2(-1.45,1.0))
 var continuous_intruder:=true;before=world.scary.intruder.position
 for frame in 1200:
  await ticks(1)
  continuous_intruder=continuous_intruder and world.scary.intruder.position.distance_to(before)<.25;before=world.scary.intruder.position
  if world.scary.done("return_aftermath"):break
 if not world.scary.done("return_aftermath"):print("SCARE ROUTE ",world.scary.intruder.snapshot()," path=",world.scary.intruder.waypoints," dialogue=",Dialogue.sequence," active=",Dialogue.active," stock=",door_interaction(world.depot.stock_door).open," yard=",door_interaction(world.depot.service_door).open)
 check(continuous_intruder and world.scary.done("return_intruder"),"figura atravessa o salão com colisão e animação de locomoção")
 check(world.scary.done("yard_slam") and world.scary.intruder.position.z< -16.7,"porta bate depois que a figura atravessa para o pátio")
 check(Dialogue.sequence=="friday_return_aftermath" and world.scary.done("return_aftermath"),"Felps reage somente depois de Deryk perceber a figura")
 clear_dialogue();await ticks(40)
 check(not door_interaction(world.depot.service_door).open and absf(world.depot.service_door.rotation.y)<.01,"batida fecha a porta existente, mantendo interação e colisão")
 var felps_before: Vector3=world.characters.Felps.position
 world.characters.Felps.position=Vector3(4.8,.01,-17.7);world.characters.Felps.reset_physics_interpolation()
 world.scary.state().events.erase("yard_slam");door_interaction(world.depot.service_door).activate(world.player);await ticks(35)
 world.scary.try_slam()
 check(door_interaction(world.depot.service_door).open and not world.scary.done("yard_slam"),"porta aguarda quando um protagonista está na área de giro do lado do pátio")
 world.characters.Felps.position=felps_before;world.characters.Felps.reset_physics_interpolation();await ticks(35)
 check(world.scary.ceiling.all(func(data):return is_equal_approx(data.light.light_energy,float(data.energy))) and world.sound.compressors.all(func(player):return player.playing),"luzes comerciais se recuperam e refrigeração não é interrompida")
 var volume:=Preferences.effects_volume;Preferences.effects_volume=0;Preferences.apply()
 check(world.scary.drag.volume_db<=-70 and world.scary.intruder.foot.volume_db<=-70,"sons novos respeitam volume de efeitos")
 Preferences.effects_volume=volume;Preferences.apply()
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"terceira pessoa pela rodinha permanece após o susto")
 await reload();await ticks(5)
 check(not Dialogue.active and world.scary.done("return_aftermath") and not world.scary.state().return_armed,"continuar não repete a travessia nem a conversa do susto")
 Session.campaign.phase="closing";Session.campaign.flags.till_closed=true;Session.campaign.flags.stock_checked=true;Session.campaign.flags.lights_off=true;Session.campaign.flags.reunite=true
 for actor in world.characters.values():actor.position=Vector3(3.8 if actor.identity=="Dery" else 4.4,.01,1.4);actor.reset_physics_interpolation()
 world.friday.activate("exit",world.player)
 check(Dialogue.sequence=="friday_closing_hook" and not JSON.stringify(Dialogue.queue).contains("cara da rua"),"fechamento reconhece a invasão e preserva o gancho para sábado")
 clear_dialogue();await ticks(110)
 check(Session.campaign.phase=="complete" and app.interface.night_panel!=null,"os sustos não bloqueiam o fechamento original")
 app.interface.night_panel.find_child("NextNight",true,false).pressed.emit();world=app.world;await ticks(4)
 check(not is_instance_valid(world.scary.intruder) and not world.scary.drag.playing,"sábado não recria sustos nem o invasor da sexta")
 check(JSON.stringify(world.story.saturday_memory()).contains("cara que eu vi"),"sábado conserva a lembrança da ameaça percebida")
 var legacy:=Session.snapshot_data();legacy.campaign.erase("friday_scares");Session.write_save(legacy)
 check(Session.load_shift() and Session.campaign.friday_scares.events is Dictionary,"save anterior recebe campos opcionais sem perder a campanha")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;await get_tree().create_timer(.15,true,false,true).timeout;app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(4)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("SCARES RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
 get_tree().quit(0 if failures.is_empty() else 1)
