extends "res://tests/everyday_integration.gd"
func free_focus() -> void:
 world.player.camera_rig.cancel_focus();world.horror.state().quiet_until=0
func run() -> void:
 Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.spawn_wait=999
 Session.greet();Dialogue.clear();world.presence.state().next_at=99999;world.scary.state().door_phase="done";Session.world_seconds=100
 await stand(Vector3(.6,.01,-13.8),PI/2)
 var point:=world.scary.handle.global_position+Vector3(0,.04,.08)
 check(not world.horror.focus("far",Vector3(0,1,8),1,3),"foco não dispara longe do ponto do evento")
 world.cashier_open=true;check(not world.horror.focus("ui",point),"interface aberta impede um novo foco");world.cashier_open=false
 world.player.input_locked=true;check(not world.horror.focus("lock",point),"ação com controle bloqueado impede foco");world.player.input_locked=false
 Dialogue.play("focus_test",[["Dery","Um instante."]]);check(not world.horror.focus("dialogue",point),"conversa impede foco");Dialogue.clear()
 check(world.horror.focus("door",point,1.4,3),"perto da porta inicia o enquadramento real")
 var rig:=world.player.camera_rig;var at:=world.player.position;var zoom:=rig.target_distance
 check(not world.switch_player() and not world.try_surveillance(),"troca de personagem e computador aguardam o susto")
 Input.action_press("forward");await ticks(24);Input.action_release("forward")
 check(world.player.position.distance_to(at)<.025,"durante o foco movimento não atravessa o evento")
 var ray:=-rig.camera.global_basis.z
 check(ray.dot((point-rig.camera.global_position).normalized())>.995,"ponto exato fica no centro da câmera")
 var yaw:=rig.yaw;var event:=InputEventMouseMotion.new();event.relative=Vector2(450,90);rig.handle_input(event)
 check(is_equal_approx(yaw,rig.yaw),"mouse não disputa o enquadramento fixo")
 app.interface.set_paused(true);var remaining:=rig.focus_remaining;await ticks(10)
 check(is_equal_approx(remaining,rig.focus_remaining),"pausa congela duração do foco")
 app.interface.set_paused(false);await ticks(90)
 check(not rig.focusing() and not world.player.input_locked,"fim do foco devolve controle sem trava persistente")
 rig.handle_input(event);check(not is_equal_approx(yaw,rig.yaw),"mouse funciona novamente depois do susto")
 check(rig.target_distance==zoom and absf(rig.camera.fov-Preferences.fov)<.2,"foco preserva distância e devolve campo de visão escolhido")
 check(not world.horror.focus("overlap",point),"intervalo de respiro impede outro susto colado")
 free_focus();await wheel(MOUSE_BUTTON_WHEEL_DOWN,8);await stand(Vector3(.6,.01,-13.8),PI/2)
 check(world.horror.focus("third",point,1.2,3),"foco também funciona em terceira pessoa")
 await ticks(30)
 check((-rig.camera.global_basis.z).dot((point-rig.camera.global_position).normalized())>.995,"terceira pessoa enquadra o mesmo alvo sem mirar ao lado")
 check(rig.target_distance>1.5 and not rig.first_person,"foco não força primeira pessoa")
 Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;world.presence.state().next_at=99999;await ticks(5)
 check(not world.player.camera_rig.focusing() and not world.player.input_locked,"continuar durante foco não restaura controle preso")
 free_focus();await wheel(MOUSE_BUTTON_WHEEL_UP,15)
 # Test the full real walk from the shop to hiding, with the stock door closed.
 world.scary.state().events.stock_handle=true;world.scary.state().last_event=Session.world_seconds-40
 await stand(Vector3(3.2,.01,-3.1),0);world.scary.tick_prank(.1)
 check(world.scary.state().prank.get("phase")=="walking","Bryan sai do salão para preparar a peça")
 var bryan:=world.scary.bryan;var before:=bryan.position;var continuous:=true
 for frame in 2100:
  await ticks(1)
  continuous=continuous and bryan.position.distance_to(before)<.16;before=bryan.position
  if world.scary.state().prank.get("phase")=="hidden":break
 check(continuous and world.scary.state().prank.get("phase")=="hidden","Bryan percorre a loja e se esconde nos fundos sem teleporte")
 print("BRYAN HIDE ",bryan.position," phase=",world.scary.state().prank)
 check(bryan.position.distance_to(FridayScares.BRYAN_HIDE)<.26 and bryan.scare_pose=="crouch_idle","esconderijo fica atrás das caixas com pose abaixada")
 await ticks(30);check(not world.scary.done("bryan_prank"),"brincadeira não dispara enquanto Deryk está longe")
 world.select_player("Felps");await stand(Vector3(-3.0,.01,-13.1),0);world.scary.tick_prank(.2)
 check(not world.scary.done("bryan_prank") and world.scary.state().prank.phase=="hidden","Bryan espera Deryk, não assusta Felps")
 world.characters.Felps.position=CheckoutFixture.STAFF_POSITION;world.select_player("Dery");free_focus();await stand(Vector3(-2.7,.01,-13.2),0)
 var hidden:=not world.scary.can_see(bryan.position+Vector3.UP*.65)
 check(hidden,"caixas realmente ocultam Bryan antes do movimento")
 for frame in 240:
  await ticks(1)
  if world.scary.done("bryan_prank"):break
 check(world.scary.done("bryan_prank") and world.horror.focused_event=="bryan_jump","ver Bryan saindo dispara jumpscare com foco nele")
 await ticks(22);var head: Vector3=world.scary.pop_pose.face_point
 check(world.scary.can_see(head) and (-world.player.camera_rig.camera.global_basis.z).dot((head-world.player.camera_rig.camera.global_position).normalized())>.99,"rosto de Bryan está visível e central no susto")
 check(world.sound.voices.any(func(v):return v.stream!=null and v.stream.resource_path.ends_with("bryan_pop.ogg")),"impacto do susto vem da posição de Bryan")
 check(JSON.stringify(world.story.familiar_lines("Bryan",world.player,0)).contains("escondido nas caixas"),"reação explica a peça nos fundos")
 var notes: int=Session.campaign.experience.notes.size();Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;world.presence.state().next_at=99999;await ticks(100)
 check(world.scary.done("bryan_prank") and Session.campaign.experience.notes.size()==notes and not world.player.camera_rig.focusing(),"save depois da peça não repete impacto, nota ou câmera")
 # An early quiet interval forbids a second major beat; proximity arms the return.
 world.horror.state().last_major=Session.world_seconds;free_focus();await stand(Vector3(.5,.01,-13.8),PI/2);world.horror._physics_process(.1)
 check(not bool(world.horror.state().events.get("return_bang",false)),"pancada de retorno espera o intervalo de calma")
 world.horror.state().last_major=Session.world_seconds-46;await stand(Vector3(3,.01,-4),0);world.horror._physics_process(.1)
 check(not bool(world.horror.state().events.get("return_bang",false)),"pancada não acontece com jogador no salão")
 await stand(Vector3(.5,.01,-13.8),PI/2);world.horror._physics_process(.1)
 check(bool(world.horror.state().events.get("return_bang",false)) and world.horror.busy(),"voltar perto da porta permite pancada e foco")
 var count: int=world.sound.voice_index;await ticks(110);free_focus();world.horror._physics_process(.1)
 check(world.sound.voice_index==count,"pancada não repete em cada aproximação")
 world.horror.calm(20);world.sound.ambient_wait=.001;count=world.sound.ambient_index;world.sound._process(.5)
 check(world.sound.ambient_index==count and world.sound.compressors.all(func(v):return v.playing),"respiro suspende efeitos aleatórios e preserva equipamentos e circuitos")
 # A selected head receives a readable focus; its body stays covered.
 free_focus();world.horror.state().quiet_until=0;world.scary.state().door_phase="done";world.scary.state().prank.phase="done"
 for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.queue_free()
 world.characters.Felps.position=Vector3(-18,.01,1.8);world.characters.Felps.reset_physics_interpolation()
 for child in world.depot.stock_door.get_children():
  if child is Interaction and child.kind=="door" and not child.open:child.activate(world.player)
 await ticks(35)
 await stand(Vector3(4.25,.01,-4.0),PI)
 world.presence.create(world.presence.sites[3],1.45,{},true);await ticks(14)
 check(not is_instance_valid(world.presence.watcher) and world.presence.last_rejection=="face_covered","garrafas sem colisão física também impedem foco em rosto encoberto")
 await stand(Vector3(.5,.01,-12.2),PI)
 world.presence.create(world.presence.sites[11],1.45,{},true)
 var watcher:=world.presence.watcher;var seen:=0.0;var body:=false
 for frame in 180:
  await ticks(1)
  if not is_instance_valid(watcher):break
  body=body or world.presence.any_visible(watcher.body_points())
  if watcher.started and world.presence.any_visible(watcher.head_points()):seen+=1.0/60
 check(seen>1.0 and not body,"aparição dirigida mostra só a cabeça por tempo legível")
 await ticks(20)
 check(bool(world.presence.state().get("directed_seen",false)) and not world.player.camera_rig.focusing(),"aparição selecionada conclui foco e não se repete como novidade")
 Session.advance_to_saturday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;world.presence.state().next_at=99999;world.saturday.unease.set_physics_process(false);Dialogue.clear();Session.campaign.phase="saturday_investigation"
 await stand(Vector3(4.2,.01,-7.7),PI/2)
 check(not bool(world.horror.state().get("stock_ajar",false)),"porta permanece normal antes de usar o computador")
 world.surveillance_open=true;world.horror._physics_process(.1);world.surveillance_open=false
 world.horror._physics_process(.1)
 check(not bool(world.horror.state().get("stock_ajar",false)),"fechar computador preserva um intervalo antes da mudança")
 Session.world_seconds+=8;world.horror._physics_process(.1);await ticks(3)
 check(bool(world.horror.state().get("stock_ajar",false)) and absf(world.depot.stock_door.rotation.y+.62)<.01,"após o computador a porta fica fisicamente entreaberta quando ninguém olha")
 check(world.horror.focused_event=="stock_ajar" and world.player.camera_rig.focusing(),"aproximar-se da porta alterada dirige a câmera ao local")
 Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;world.presence.state().next_at=99999;await ticks(4)
 check(absf(world.depot.stock_door.rotation.y+.62)<.01 and not world.player.camera_rig.focusing(),"save conserva a porta alterada sem repetir o foco")
 for child in world.depot.stock_door.get_children():
  if child is Interaction and child.kind=="door":child.activate(world.player)
 await ticks(5);Session.save_shift(world.player.position);app.start_saved();world=app.world;await ticks(35)
 var fully_open:=world.depot.stock_door.rotation.y< -1.4
 for child in world.depot.stock_door.get_children():
  if child is Interaction and child.kind=="door":child.activate(world.player)
 await ticks(35);Session.save_shift(world.player.position);app.start_saved();world=app.world;await ticks(4)
 check(fully_open and absf(world.depot.stock_door.rotation.y)<.01,"E abre totalmente a porta entreaberta e o fechamento posterior persiste")
 world.sound.play_spatial("res://assets/audio/scares/handle_rattle.ogg",Vector3(.5,1,-15.7),-8)
 world.sound.occlusion_wait=0;world.sound._process(.2)
 var voice:=world.sound.voices[(world.sound.voice_index-1)%world.sound.voices.size()]
 check(voice.attenuation_filter_cutoff_hz<=1800 and bool(voice.get_meta("occluded",false)),"parede real abafa som da porta sem depender de câmera roteirizada")
 Preferences.effects_volume=0;Preferences.apply()
 check(voice.volume_db<=-80,"efeitos novos e abafados respeitam volume desligado")
 await finish_test()
func finish_test() -> void:
 Dialogue.clear();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(6);await get_tree().create_timer(.25,true,false,true).timeout
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("HORROR RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
