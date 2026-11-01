extends "res://tests/everyday_integration.gd"
var event: SaturdayUnease
func reload() -> void:
 Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;event=world.saturday.unease;event.set_physics_process(false);world.presence.state().next_at=99999;await ticks(4)
func eligible() -> void:
 event.state().quiet_until=0;event.state().head_quiet=0;event.cue=""
func run() -> void:
 Preferences.camera_distance=0;Preferences.frame_limit=60;Preferences.apply();Session.new_shift();Session.advance_to_saturday()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;world.spawn_wait=999;event=world.saturday.unease;event.set_physics_process(false);world.presence.state().next_at=99999;Dialogue.clear();Session.campaign.phase="saturday_investigation";Session.world_seconds=300
 for person in get_tree().get_nodes_in_group("familiar_npcs"):person.queue_free()
 world.characters.Felps.position=Vector3(3.5,.01,-1.3);world.characters.Felps.reset_physics_interpolation()
 var notes: int=Session.campaign.experience.notes.size();var clues: Dictionary=Session.campaign.clues.duplicate(true);var records: Array=Session.campaign.records.duplicate(true)
 var camera_before: float=world.player.camera_rig.yaw
 check(event!=null and event.car.name=="ParkedSedan","sábado usa o carro já presente no cenário")
 check(event.find_children("*","CollisionObject3D",true,false).is_empty(),"marcas no chão não acrescentam obstáculos")
 check(not event.extra_marks.visible and not bool(event.state().shifted),"vestígios adicionais começam recolhidos")
 await stand(Vector3(.2,.01,-13.5),atan2(1.35,1.3));event.state().entered=200;event.state().steps=true;event.state().cloth=true
 event._physics_process(.1)
 check(not bool(event.state().shifted),"caixa não se altera antes de o jogador examiná-la")
 Session.campaign.clues.moved_boxes=true;event.state().inspected=200
 check(not event.can_shift(),"presença próxima impede deslocamento escondido")
 await stand(Vector3(4.8,.01,-9.0),0);world.characters.Felps.position=Vector3(-1.2,.01,-14.0);await ticks(3)
 check(not event.can_shift(),"companheiro perto da caixa também impede a mudança")
 world.characters.Felps.position=Vector3(3.5,.01,-1.3);await ticks(3)
 check(event.can_shift(),"caixa fica livre para mudar quando ninguém está perto nem olhando")
 await stand(Vector3(4.8,.01,-14.0),atan2(5.95,.8))
 check(not event.can_shift(),"olhar para a caixa à distância impede a mudança")
 await stand(Vector3(4.8,.01,-9.0),0)
 var outlines: Array[Node3D]=[];var outlines_at: Array[Vector3]=[]
 for child in world.saturday.board.get_children():
  if child.has_meta("stationary_dust"):outlines.append(child);outlines_at.append(child.global_position)
 event._physics_process(.1);await ticks(3)
 check(bool(event.state().shifted) and world.saturday.board.position.is_equal_approx(Vector3(-1.15,0,-14.8)+SaturdayUnease.SHIFT),"retorno aos fundos pode encontrar a caixa ligeiramente deslocada")
 var stationary:=outlines.size()==3
 for i in outlines.size():stationary=stationary and outlines[i].global_position.distance_to(outlines_at[i])<.001 and outlines[i].get_parent()==world.depot
 check(stationary,"marca original no pó permanece na posição antiga")
 check(event.extra_marks.visible,"rastros adicionais aparecem no chão depois da mudança")
 check(not world.depot.blockers.has(SaturdayUnease.OLD_BOARD) and world.depot.blockers.has(Rect2(SaturdayUnease.OLD_BOARD.position+Vector2(.28,-.04),SaturdayUnease.OLD_BOARD.size)),"navegação acompanha a caixa sem manter obstáculo invisível antigo")
 check(not world.presence.safe(),"intervalo depois do vestígio bloqueia uma cabeça simultânea")
 await reload()
 check(bool(event.state().shifted) and event.extra_marks.visible and world.saturday.board.position.is_equal_approx(Vector3(-.87,0,-14.84)),"save restaura caixa, rastros e posição física")
 var shifted_at: Vector3=world.saturday.board.position;eligible();event._physics_process(.1)
 check(world.saturday.board.position==shifted_at,"caixa muda uma única vez, inclusive depois de continuar")
 event.state().steps=false;event.state().cloth=false;event.state().last_sound=-1000;event.state().entered=200;eligible();await stand(Vector3(3.4,.01,-13.5),0)
 var index: int=world.sound.voice_index;event._physics_process(.1)
 check(bool(event.state().steps) and event.cue=="steps" and world.sound.voice_index==index+1,"primeiro passo vem do pátio durante a investigação")
 var voice: AudioStreamPlayer3D=world.sound.voices[index%world.sound.voices.size()]
 check(voice.position==SaturdayUnease.FOOT_A and voice.stream.resource_path.ends_with("step_tile.wav") and voice.volume_db<=-18,"passo usa origem 3D atrás da porta e volume discreto")
 event._physics_process(.49)
 check(event.second_step and world.sound.voice_index==index+2 and world.sound.voices[(index+1)%world.sound.voices.size()].position==SaturdayUnease.FOOT_B,"segundo passo avança pelo pátio sem criar personagem andando")
 event._physics_process(.1)
 check(world.sound.voice_index==index+2 and not bool(event.state().cloth),"passos não repetem e tecido aguarda outro intervalo")
 eligible();event.state().last_sound=Session.world_seconds-35;event._physics_process(.1)
 check(bool(event.state().cloth) and event.cue=="cloth" and world.sound.voice_index==index+3,"tecido ocorre depois, separado dos passos")
 voice=world.sound.voices[(index+2)%world.sound.voices.size()]
 check(voice.position==SaturdayUnease.CLOTH and voice.stream.resource_path.ends_with("cloth_brush.ogg"),"Foley original é posicionado atrás da porta antiga")
 var fx: float=Preferences.effects_volume;Preferences.effects_volume=0;Preferences.apply()
 check(voice.volume_db<=-75,"sons discretos respeitam a configuração de efeitos")
 Preferences.effects_volume=fx;Preferences.apply();await reload();eligible();await stand(Vector3(3.4,.01,-13.5),0);index=world.sound.voice_index;event._physics_process(.1)
 check(world.sound.voice_index==index and bool(event.state().steps) and bool(event.state().cloth),"continuar não repete os sons já consumidos")
 var face_point:=event.window_point();var at:=event.car.to_global(Vector3(.35,0,2.4));at.y=Street.surface_height(at.x,at.z)+.01
 await stand(at,atan2(-(face_point.x-at.x),-(face_point.z-at.z)));event.state().entered=100;event.state().last_sound=200;eligible();event._physics_process(.8)
 check(event.near_window() and event.window_visible() and not bool(event.state().face_used),"olhar diretamente para o vidro impede surgimento do rosto")
 world.cashier_open=true;world.player.camera_rig.yaw+=PI;world.player.camera_rig.reset_follow();await ticks(2);event._physics_process(1)
 check(not bool(event.state().face_used),"interface aberta impede susto no carro")
 world.cashier_open=false;eligible();world.characters.Felps.position=at+Vector3(1,0,0);await ticks(2);event._physics_process(1)
 check(not bool(event.state().face_used),"companheiro próximo impede encontro particular no vidro")
 world.characters.Felps.position=Vector3(3.5,.01,-1.3);world.characters.Felps.reset_physics_interpolation();await ticks(2);eligible();camera_before=world.player.camera_rig.yaw;var player_before:=world.player.position;event._physics_process(.7)
 check(bool(event.state().face_used) and is_instance_valid(event.figure),"oportunidade tardia nasce dentro do carro enquanto a janela está fora da vista")
 check(is_equal_approx(world.player.camera_rig.yaw,camera_before) and world.player.position.distance_to(player_before)<.02,"evento não gira a câmera nem desloca o jogador")
 check(event.figure.find_children("*","CollisionObject3D",true,false).is_empty() and event.figure.visual.get_meta("character_identity","")=="Enemy","encontro usa assassino original sem novo corpo colidindo com o carro")
 await ticks(10);world.player.camera_rig.yaw=atan2(-(face_point.x-at.x),-(face_point.z-at.z));world.player.camera_rig.reset_follow()
 for frame in 50:
  await ticks(1)
  if not is_instance_valid(event.figure) or event.figure.phase=="holding":break
 check(is_instance_valid(event.figure) and event.figure.phase=="holding","virar a própria câmera revela a cabeça brevemente através do vidro")
 if is_instance_valid(event.figure):
  var amount: float=event.figure.amount;await reload()
  check(is_instance_valid(event.figure) and event.figure.amount>.95 and bool(event.state().face_used),"save no instante do rosto retoma a pose sem rearmar oportunidade")
  if is_instance_valid(event.figure):
   var age: float=event.figure.age;app.interface.set_paused(true);await ticks(8)
   check(is_equal_approx(event.figure.age,age),"pausa congela o instante do encontro")
   app.interface.set_paused(false);await ticks(75)
 check(not is_instance_valid(event.figure) and event.state().face.is_empty(),"assassino abaixa atrás da carroceria e libera o checkpoint")
 await reload();eligible();event._physics_process(1)
 check(not is_instance_valid(event.figure) and bool(event.state().face_used),"rosto não reaparece depois de continuar nem a cada virada")
 event.state().face_used=false;event.state().turn_wait=0;eligible();world.player.camera_rig.yaw+=PI;world.player.camera_rig.reset_follow();await ticks(3);event._physics_process(.7)
 check(is_instance_valid(event.figure),"prepara outra linha de teste com a janela fora da vista")
 await ticks(230)
 check(not is_instance_valid(event.figure) and bool(event.state().face_used),"sem virar a câmera, o momento acaba e é consumido mesmo assim")
 check(not Dialogue.active and Session.campaign.experience.notes.size()==notes and Session.campaign.records==records,"novos vestígios e aparições não geram aviso, fala ou registro automático")
 clues.moved_boxes=true
 check(Session.campaign.clues==clues and int(Session.snapshot_data().version)==5,"nenhuma pista obrigatória extra e save mantém compatibilidade")
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"rodinha mantém terceira pessoa disponível depois do encontro")
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;await ticks(3)
 check(world.saturday.unease==null,"domingo preserva perseguição sem o sistema opcional de sábado")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(5)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("UNEASE RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
