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
 check(world.player.camera_rig.focusing() and is_equal_approx(world.player.camera_rig.target_distance,distance),"maçaneta recebe foco breve sem mudar a distância da câmera")
 await reload();await ticks(140)
 check(world.scary.done("stock_handle") and world.scary.state().door_phase=="done" and not world.scary.drag.playing,"save no susto conclui a maçaneta sem repetir o arrasto")
 var note_count: int=Session.campaign.experience.notes.size();await ticks(20)
 check(Session.campaign.experience.notes.size()==note_count,"observação da porta não se duplica")
 Session.world_seconds=float(world.scary.state().last_event)+10
 await stand(Vector3(-3.1,.01,-2.8),PI)
 check(world.scary.state().prank.is_empty(),"há intervalo de calma antes da brincadeira de Bryan")
 Session.world_seconds=float(world.scary.state().last_event)+40;await ticks(3)
 check(world.scary.state().prank.get("phase")=="walking" and world.scary.bryan.scare_moving,"Bryan precisa caminhar até os fundos")
 var bryan_at:=world.scary.bryan.position;await reload()
 check(world.scary.bryan.position.distance_to(bryan_at)<.25 and world.scary.bryan.scare_moving,"save retoma Bryan na rota da brincadeira sem teleporte")
 var continuous:=true;var before:=world.scary.bryan.position
 for frame in 2100:
  await ticks(1)
  continuous=continuous and world.scary.bryan.position.distance_to(before)<.18;before=world.scary.bryan.position
  if world.scary.state().prank.phase=="hidden":break
 check(continuous and world.scary.state().prank.phase=="hidden","Bryan chega fisicamente ao esconderijo nos fundos")
 check(not world.scary.done("bryan_prank"),"Bryan escondido aguarda Deryk chegar perto")
 await stand(Vector3(-2.7,.01,-13.2),0)
 for frame in 300:
  await ticks(1)
  if world.scary.done("bryan_prank"):break
 check(world.scary.done("bryan_prank") and world.player.camera_rig.focusing(),"Bryan sai das caixas e o jumpscare enquadra a criança")
 await ticks(22)
 check(world.scary.bryan.position.z< -11.6 and world.scary.bryan.position.distance_to(world.player.position)<1.6 and not Dialogue.active,"peça termina perto de Deryk nos fundos sem diálogo obrigatório")
 check(JSON.stringify(world.story.familiar_lines("Bryan",world.player,0)).contains("coração"),"a conversa opcional traz o alívio depois da brincadeira")
 await reload();note_count=Session.campaign.experience.notes.size();await ticks(30)
 check(world.scary.done("bryan_prank") and Session.campaign.experience.notes.size()==note_count,"continuar não repete a batida nem sua anotação")
 clear_dialogue();check(world.friday.begin_outage(),"apagão mantém a entrada original da missão do gerador")
 clear_dialogue();Session.campaign.flags.generator_key=true;Session.campaign.flags.counter_secured=true
 await stand(Vector3(4.35,.01,-19.4));check(world.friday.activate("generator",world.characters.Dery),"gerador continua exigindo a ação original de Deryk")
 clear_dialogue();await ticks(85)
 check(not world.scary.state().return_armed and not is_instance_valid(world.scary.intruder),"gerador não anuncia nem agenda a antiga figura de corpo inteiro")
 check(world.sound.compressors.all(func(player):return player.playing),"refrigeração e energia voltam normalmente")
 var legacy_glimpse:=Session.snapshot_data();legacy_glimpse.campaign.friday_scares.intruder={"kind":"stock_glimpse","state":"emerging","position":[3.1,0,-12.4],"leg":0};legacy_glimpse.campaign.friday_scares.return_armed=true
 Session.write_save(legacy_glimpse);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(4)
 check(not is_instance_valid(world.scary.intruder) and world.scary.done("intruder_gone"),"save antigo não recria a figura exposta nem a antiga anotação automática")
 check(not world.scary.done("return_intruder") and not world.story.noticed("return_intruder"),"migração não inventa uma observação que o jogador não teve")
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"rodinha continua permitindo terceira pessoa")
 Session.campaign.phase="closing";Session.campaign.flags.till_closed=true;Session.campaign.flags.stock_checked=true;Session.campaign.flags.lights_off=true;Session.campaign.flags.reunite=true
 for actor in world.characters.values():actor.position=Vector3(3.8 if actor.identity=="Dery" else 4.4,.01,1.4);actor.reset_physics_interpolation()
 world.friday.activate("exit",world.player)
 check(Dialogue.sequence=="friday_closing_hook" and not JSON.stringify(Dialogue.queue).contains("cara da rua"),"fechamento reconhece a invasão e preserva o gancho para sábado")
 clear_dialogue();await ticks(110)
 check(Session.campaign.phase=="complete" and app.interface.night_panel!=null,"os sustos não bloqueiam o fechamento original")
 app.interface.night_panel.find_child("NextNight",true,false).pressed.emit();world=app.world;await ticks(4)
 check(not is_instance_valid(world.scary.intruder) and not world.scary.drag.playing,"sábado não recria sustos nem o invasor da sexta")
 check(not JSON.stringify(world.story.saturday_memory()).contains("cara que eu vi") and not JSON.stringify(world.story.saturday_memory()).contains("Achei que vi"),"sábado não explica aparições silenciosas que o jogador pode ter perdido")
 var legacy:=Session.snapshot_data();legacy.campaign.erase("friday_scares");Session.write_save(legacy)
 check(Session.load_shift() and Session.campaign.friday_scares.events is Dictionary,"save anterior recebe campos opcionais sem perder a campanha")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;await get_tree().create_timer(.15,true,false,true).timeout;app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(4)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("SCARES RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
 get_tree().quit(0 if failures.is_empty() else 1)
