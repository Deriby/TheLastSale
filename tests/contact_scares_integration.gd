extends "res://tests/everyday_integration.gd"
var metrics: Dictionary={}
func run() -> void:
 Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.spawn_wait=999
 Session.greet();Dialogue.clear();Session.world_seconds=100;world.presence.state().next_at=99999;world.scary.state().door_phase="done";world.scary.state().events.stock_handle=true
 world.horror.contact_hit()
 check(world.horror.impact_weight()==0 and not world.sound.contact.playing,"não há impacto sem um susto realmente enquadrado")
 world.scary.state().prank={"phase":"hidden","time":0.0,"revision":41};world.scary.bryan.position=FridayScares.BRYAN_HIDE;world.scary.bryan.reset_physics_interpolation();world.scary.bryan.scare_pose="crouch_idle"
 await stand(Vector3(3.2,.01,-3.1),0);await ticks(15)
 check(world.scary.state().prank.phase=="hidden","Bryan continua escondido quando Deryk está longe")
 world.select_player("Felps");await stand(Vector3(-2.7,.01,-13.2),0);await ticks(10)
 check(world.scary.state().prank.phase=="hidden","a brincadeira continua destinada a Deryk")
 world.active=false;world.characters.Felps.position=CheckoutFixture.STAFF_POSITION;world.characters.Felps.reset_physics_interpolation();await ticks(4);world.select_player("Dery");await stand(Vector3(-2.7,.01,-13.2),0)
 var at:=world.player.position
 check(not world.scary.can_see(world.scary.bryan.position+Vector3.UP*.65),"as caixas ocultam o corpo de Bryan antes do susto")
 world.active=true
 await ticks(4)
 check(not world.player.camera_rig.focusing() and not world.scary.done("bryan_prank"),"a câmera não anuncia o esconderijo antes de Bryan sair")
 var continuous:=true;var before:=world.scary.bryan.position;var saved_rush:=false;var restored_rush:=false;var max_step:=0.0;var physics_frame:=Engine.get_physics_frames()
 for frame in 350:
  await ticks(1)
  var elapsed_steps:=maxi(1,Engine.get_physics_frames()-physics_frame);physics_frame=Engine.get_physics_frames()
  var step:=world.scary.bryan.position.distance_to(before);max_step=maxf(max_step,step/elapsed_steps);continuous=continuous and step<4.5*elapsed_steps/60.0+.025;before=world.scary.bryan.position
  if not saved_rush and world.scary.state().prank.phase=="rushing":
   saved_rush=true;var saved:=world.scary.bryan.position;Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;world.presence.state().next_at=99999
   restored_rush=world.scary.state().prank.phase=="rushing" and world.scary.bryan.position.distance_to(saved)<.12;before=world.scary.bryan.position;physics_frame=Engine.get_physics_frames()
  if world.scary.done("bryan_prank"):break
 check(saved_rush and restored_rush,"save durante a aproximação conserva Bryan e sua rota física")
 check(continuous,"Bryan chega perto por movimento físico sem saltar de posição")
 check(world.scary.done("bryan_prank") and world.horror.focused_event=="bryan_jump","a saída das caixas termina no jumpscare de Bryan")
 var separation:=world.player.position.distance_to(world.scary.bryan.position)
 check(separation<1.80 and separation>.65 and world.scary.bryan.position.z< -11.6,"a revelação acontece perto de Deryk, exclusivamente nos fundos")
 check(world.player.position.distance_to(at)<.03,"o susto não teleporta Deryk até a criança")
 await ticks(8)
 check(world.horror.impact_weight()>.60 and world.sound.contact.playing,"aproximação, som de impacto e imagem começam juntos")
 check(world.sound.contact.stream.resource_path.ends_with("contact_sting.wav") and world.sound.voices.any(func(v):return v.stream!=null and v.stream.resource_path.ends_with("bryan_pop.ogg")),"o impacto original acompanha a voz já existente de Bryan")
 await ticks(10)
 var face:=world.scary.pop_pose.face_point
 check((-world.player.camera_rig.camera.global_basis.z).dot((face-world.player.camera_rig.camera.global_position).normalized())>.99,"a câmera acompanha o rosto real durante a pose")
 check(world.player.camera_rig.camera.fov<43 and world.player.camera_rig.target_distance==0,"zoom breve aproxima a leitura sem alterar a rodinha")
 check(float(app.retro.get_shader_parameter("scare_amount"))>.2 and is_instance_valid(world.scary.pop_pose),"distorção curta e rastreamento do rosto acompanham a animação natural")
 var near_distance:=world.scary.bryan.position.distance_to(world.player.position)
 check(near_distance<1.35,"Bryan completa o avanço curto até perto da lente pela física")
 var impact_age:=world.horror.impact_age;var kick_age:=world.player.camera_rig.kick_age
 app.interface.set_paused(true);await ticks(10)
 check(is_equal_approx(world.horror.impact_age,impact_age) and is_equal_approx(world.player.camera_rig.kick_age,kick_age),"pausa congela pose, efeito e tranco de câmera")
 app.interface.set_paused(false);Preferences.effects_volume=0;Preferences.apply()
 check(world.sound.contact.volume_db< -80,"o novo impacto obedece ao volume de efeitos")
 Preferences.effects_volume=.8;Preferences.apply();await ticks(110)
 check(world.horror.impact_weight()==0 and float(app.retro.get_shader_parameter("scare_amount"))==0 and world.player.camera_rig.camera.rotation.length()<.0001,"imagem e câmera voltam ao normal sem efeito preso")
 check(not world.player.camera_rig.focusing() and absf(world.player.camera_rig.camera.fov-Preferences.fov)<.3,"controle e campo de visão são devolvidos depois da peça")
 var notes: int=Session.campaign.experience.notes.size();Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(4)
 check(world.scary.done("bryan_prank") and not world.sound.contact.playing and world.horror.impact_weight()==0 and Session.campaign.experience.notes.size()==notes,"continuar depois da peça não repete som, efeito nem anotação")
 var legacy:=Session.snapshot_data();legacy.campaign.friday_scares.events.erase("bryan_prank");legacy.campaign.friday_scares.prank={"phase":"waiting","position":[-2.8,0,-.1],"revision":0};Session.write_save(legacy);app.start_saved();world=app.world;world.spawn_wait=999
 check(world.scary.state().prank.phase=="walking" and world.scary.bryan.scare_goal==FridayScares.BRYAN_HIDE,"checkpoint antigo migra para as caixas, sem recriar interação no vidro")
 metrics.bryan={"max_step_m":max_step,"reveal_distance_m":separation,"near_distance_m":near_distance,"rush_resume":restored_rush}
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;Dialogue.clear();world.sunday.begin_escape();Dialogue.clear();world.sunday.state().generator_mode="stock";Session.campaign.flags.generator_running=true;world.sunday.apply_scene()
 var killer:=world.sunday.killer;killer.grace=999;world.characters.Felps.position=CheckoutFixture.STAFF_POSITION
 await stand(Vector3(.7,.01,-13.5),0);killer.position=Vector3(.7,.01,-14.25);killer.reset_physics_interpolation();await ticks(3)
 check(not world.horror.begin_capture(killer,world.player),"câmera de captura não antecipa um golpe ainda evitável")
 var original_zoom:=world.player.camera_rig.target_distance;var victim_at:=world.player.position;var killer_at:=killer.position
 killer.grace=0;killer.mode="attack";killer.target_identity="Dery";killer.attack_time=.16
 for frame in 30:
  await ticks(1)
  if world.horror.capture_age>=0:break
 check(world.horror.capture_age>=0 and world.sunday.stopped and not world.active,"golpe confirmado inicia o contato antes da derrota")
 check(app.interface.campaign_panel==null and world.player.camera_rig.focusing(),"o jumpscare não fica escondido debaixo do menu de derrota")
 check(world.player.input_locked and not world.switch_player(),"captura segura o controle apenas durante o enquadramento")
 await ticks(16)
 check(world.horror.capture_hit and world.sound.contact.playing and world.horror.impact_weight()>.4,"captura recebe impacto no avanço dos braços")
 check(is_instance_valid(world.horror.capture_pose) and world.horror.capture_pose.amount>.8 and killer.visual.get_meta("character_identity","")=="Enemy","captura usa o modelo e o rig do assassino original")
 check(world.player.position.distance_to(victim_at)<.03 and killer.position.distance_to(killer_at)<.05,"contato não aproxima os corpos por teleporte")
 check(world.player.camera_rig.target_distance==original_zoom,"captura preserva a distância escolhida na rodinha")
 var capture_age:=world.horror.capture_age;app.interface.set_paused(true);await ticks(10)
 check(is_equal_approx(world.horror.capture_age,capture_age),"pausa também congela a sequência de captura")
 app.interface.save_current()
 var death_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Session.SAVE_PATH))
 check(float(death_save.campaign.sunday.killer.grace)>0,"salvar durante a captura preserva o checkpoint seguro em vez do golpe fatal")
 app.interface.set_paused(false);await ticks(80)
 check(app.interface.campaign_panel!=null and app.interface.campaign_panel.kind=="defeat" and Session.campaign.ending.is_empty(),"contato termina na derrota recuperável original")
 check(int(Session.snapshot_data().version)==5,"sequências novas conservam o formato de save")
 app.interface.campaign_panel.find_child("RetrySunday",true,false).pressed.emit();world=app.world;world.spawn_wait=999;await ticks(4)
 check(world.active and not world.sunday.stopped and world.sunday.killer.grace>0,"retomar conserva a proteção e o checkpoint viável da fuga")
 check(world.horror.capture_age<0 and world.horror.impact_weight()==0 and float(app.retro.get_shader_parameter("scare_fade"))==0 and not world.player.input_locked,"retomar limpa câmera, fade e controle da captura anterior")
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5 and not world.player.camera_rig.first_person,"terceira pessoa continua disponível depois de retomar")
 killer=world.sunday.killer;killer.grace=999;world.sunday.state().generator_mode="stock";Session.campaign.flags.generator_running=true;world.sunday.apply_scene()
 await stand(Vector3(.7,.01,-13.5),0);killer.position=Vector3(.7,.01,-14.25);killer.reset_physics_interpolation();await ticks(3)
 var third_zoom:=world.player.camera_rig.target_distance
 killer.grace=0;killer.mode="attack";killer.target_identity="Dery";killer.attack_time=.16
 for frame in 30:
  await ticks(1)
  if world.horror.capture_age>=0:break
 check(world.horror.capture_age>=0 and world.player.camera_rig.target_distance==third_zoom and not world.player.camera_rig.first_person,"captura em terceira pessoa mantém a distância escolhida")
 await ticks(18)
 check(world.player.motion.visual_meshes.all(func(mesh):return mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY),"avatar local não encobre o rosto durante o contato em terceira pessoa")
 var enemy_face:=world.horror.capture_pose.face_point
 check((-world.player.camera_rig.camera.global_basis.z).dot((enemy_face-world.player.camera_rig.camera.global_position).normalized())>.985,"terceira pessoa também enquadra o rosto exato do assassino")
 var wheel_event:=InputEventMouseButton.new();wheel_event.button_index=MOUSE_BUTTON_WHEEL_UP;wheel_event.pressed=true;world.player.camera_rig.handle_input(wheel_event);await ticks(5)
 check(world.player.camera_rig.target_distance<third_zoom and world.player.camera_rig.target_distance>1.5,"rodinha continua respondendo durante a sequência breve")
 await ticks(80)
 check(app.interface.campaign_panel!=null and app.interface.campaign_panel.kind=="defeat","captura em terceira pessoa também termina no fluxo de derrota")
 app.interface.campaign_panel.find_child("RetrySunday",true,false).pressed.emit();world=app.world;world.spawn_wait=999;await ticks(4)
 check(world.player.motion.visual_meshes.any(func(mesh):return mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON) and float(app.retro.get_shader_parameter("scare_amount"))==0,"retomar restaura a visibilidade normal do avatar e limpa o impacto")
 await finish_test()
func finish_test() -> void:
 Dialogue.clear();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(6)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("CONTACT METRICS ",JSON.stringify(metrics));print("CONTACT RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
