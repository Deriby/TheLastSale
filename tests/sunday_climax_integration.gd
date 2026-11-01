extends "res://tests/everyday_integration.gd"
var climax: SundayClimax
func boot() -> void:
 Preferences.camera_distance=0;Preferences.frame_limit=60;Preferences.immersive_hud=true;Preferences.apply();Session.new_shift();Session.advance_to_sunday()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;world.spawn_wait=999;world.sunday.introduce(world.characters.Dery);clear_dialogue();climax=world.sunday.climax;climax.set_physics_process(false)
 world.sunday.change_door("stock",true);world.sunday.change_door("old",true);world.characters.Felps.position=CheckoutFixture.STAFF_POSITION;world.characters.Felps.reset_physics_interpolation();Session.world_seconds=100;climax.state().started=0
 await ticks(5)
func wait_head() -> void:
 for frame in 60:
  await ticks(1)
  if not is_instance_valid(climax.watcher) or climax.watcher.phase=="holding":return
func run() -> void:
 await boot()
 check(climax!=null and world.presence.sites.is_empty(),"domingo usa uma única oportunidade final independente das cabeças das outras noites")
 var notes: int=Session.campaign.experience.notes.size();var clues: Dictionary=Session.campaign.clues.duplicate(true);var records: Array=Session.campaign.records.duplicate(true)
 await stand(Vector3(.5,.01,-12.2),atan2(4.0,3.4))
 climax._physics_process(.1)
 check(not is_instance_valid(climax.watcher),"a cabeça espera a recuperação do módulo")
 Session.campaign.flags.module_found=true;climax.state().started=Session.world_seconds;climax._physics_process(.1)
 check(not is_instance_valid(climax.watcher),"rotina de investigação precede a oportunidade, sem exigir espera para concluir")
 climax.state().started=0;world.sunday.desk_open=true;climax._physics_process(.1)
 check(not is_instance_valid(climax.watcher),"terminal aberto bloqueia a aparição final")
 world.sunday.desk_open=false;var yaw: float=world.player.camera_rig.yaw;climax._physics_process(.1)
 var prepared: Array[bool]=[false];var head_seen:=false;var body_seen:=false;var seconds:=0.0
 if is_instance_valid(climax.watcher):climax.watcher.prepared.connect(func():prepared[0]=true)
 for frame in 100:
  await ticks(1)
  if not is_instance_valid(climax.watcher):break
  if climax.watcher.started:
   body_seen=body_seen or climax.any_visible(climax.watcher.body_points())
   if climax.any_visible(climax.watcher.head_points()):head_seen=true;seconds+=1.0/60.0
 check(prepared[0] and head_seen,"última cabeça pode ser percebida entre as caixas no domingo")
 check(not body_seen and seconds<1.3,"corpo permanece encoberto e a janela de percepção é curta")
 check(bool(climax.state().peek_used) and not is_instance_valid(climax.watcher),"recolhimento consome a oportunidade uma única vez")
 check(is_equal_approx(world.player.camera_rig.yaw,yaw) and not Dialogue.active,"aparição não vira a câmera nem inicia uma fala")
 check(Session.campaign.experience.notes.size()==notes and Session.campaign.clues==clues and Session.campaign.records==records,"ver a cabeça não acrescenta nota, pista ou confirmação")
 Session.save_shift(world.player.position);app.start_saved();world=app.world;climax=world.sunday.climax;climax.set_physics_process(false);await ticks(3);climax._physics_process(.1)
 check(bool(climax.state().peek_used) and not is_instance_valid(climax.watcher),"continuar não repete a cabeça concluída")
 climax.state().peek_used=false;climax.retry_at=0;world.player.camera_rig.yaw+=PI;world.player.camera_rig.reset_follow();await ticks(3);climax._physics_process(.1);await ticks(100)
 check(bool(climax.state().peek_used) and not is_instance_valid(climax.watcher),"olhar para o outro lado permite perder o momento inteiro")
 climax.state().peek_used=false;climax.retry_at=0;await stand(Vector3(.5,.01,-12.2),atan2(4.0,3.4));climax.create({},.6);await wait_head()
 check(is_instance_valid(climax.watcher) and climax.watcher.phase=="holding","prepara o instante da cabeça para salvar e retomar")
 if is_instance_valid(climax.watcher):
  var at: Vector3=climax.watcher.bone_world("head");Session.save_shift(world.player.position);app.start_saved();world=app.world;climax=world.sunday.climax;climax.set_physics_process(false);await ticks(3)
  check(is_instance_valid(climax.watcher) and climax.watcher.bone_world("head").distance_to(at)<.05,"save retoma pose e duração da última aparição")
  if is_instance_valid(climax.watcher):
   var age: float=climax.watcher.age;app.interface.set_paused(true);await ticks(8)
   check(is_equal_approx(climax.watcher.age,age),"caderno ou pausa congela a aparição final")
   app.interface.set_paused(false)
 world.sunday.begin_escape();clear_dialogue();await ticks(2);world.sunday.killer.set_physics_process(false);climax._physics_process(.1)
 check(is_instance_valid(world.sunday.killer) and world.sunday.killer.visual==world.enemy_visual,"fuga reutiliza o perseguidor físico e o modelo original")
 check(not is_instance_valid(climax.watcher) or not world.sunday.killer.visual.visible,"perseguidor só fica visível depois de a última cabeça se recolher")
 await ticks(60);climax._physics_process(.1)
 check(not is_instance_valid(climax.watcher) and world.sunday.killer.visual.visible,"troca para a ameaça ocorre sem deixar outro homem no salão")
 var enemy: KillerAgent=world.sunday.killer;enemy.grace=0
 world.sunday.change_door("stock",false);world.characters.Dery.position=Vector3(3.3,.01,-3.2);world.characters.Felps.position=CheckoutFixture.STAFF_POSITION
 enemy.position=Vector3(4.85,.01,-14.5);enemy.start_search("search",Vector3(4.85,.01,-12.3));enemy.search_tick(2)
 check(enemy.search_time==0 and enemy.search_travel==2,"tempo de deslocamento até a lembrança não consome a busca local")
 enemy.position=enemy.goal;enemy.search_tick(1.21)
 check(enemy.search_step==1 and enemy.goal.distance_to(enemy.search_anchor)<=2.2 and enemy.goal!=enemy.search_anchor,"ao chegar, busca verifica um ponto próximo e alcançável")
 var remembered:=enemy.search_anchor;var destination:=enemy.goal;world.characters.Dery.position=Vector3(-3,.01,-4);enemy.search_tick(.1)
 check(enemy.search_anchor==remembered and enemy.goal==destination,"mover o jogador escondido não altera a lembrança do assassino")
 enemy.search_pause=.4;enemy.step_distance=.25;Session.save_shift(world.player.position);app.start_saved();world=app.world;climax=world.sunday.climax;climax.set_physics_process(false);enemy=world.sunday.killer;enemy.set_physics_process(false);await ticks(2)
 check(enemy.search_anchor.distance_to(remembered)<.01 and enemy.goal.distance_to(destination)<.01 and enemy.search_step==1 and is_equal_approx(enemy.search_pause,.4) and is_equal_approx(enemy.step_distance,.25),"save conserva ponto de busca, pausa, índice e intervalo dos passos")
 enemy.start_search("search",Vector3(0,0,-19));enemy.search_tick(12.1)
 check(enemy.mode=="patrol","destino bloqueado tem limite de busca e não prende a perseguição para sempre")
 enemy.position=Vector3(4.85,.01,-14.5);enemy.start_search("investigate",Vector3(4.85,.01,-12.1));enemy.sense_wait=999;enemy.grace=0;var voice_index: int=world.sound.voice_index;enemy.set_physics_process(true);await ticks(55);enemy.set_physics_process(false)
 check(world.sound.voice_index>voice_index,"passos do perseguidor são emitidos enquanto o corpo realmente caminha")
 var voice: AudioStreamPlayer3D=world.sound.voices[(world.sound.voice_index-1)%world.sound.voices.size()]
 check(voice.stream.resource_path.ends_with("step_tile.wav") and voice.global_position.distance_to(enemy.global_position)<1.2,"passo 3D acompanha a posição física do assassino")
 check(voice.attenuation_filter_cutoff_hz==1800,"parede e porta abafam passos ouvidos do outro lado")
 enemy.position=enemy.goal;enemy.search_pause=.05;enemy.step_distance=0;enemy.sense_wait=999;voice_index=world.sound.voice_index;enemy.set_physics_process(true);await ticks(20);enemy.set_physics_process(false)
 check(world.sound.voice_index==voice_index,"assassino parado observando não produz passos de caminhada")
 enemy.position=Vector3(4.85,.01,-13.8);enemy.visual.rotation.y=0;world.characters.Dery.position=Vector3(4.85,.01,-12.1);world.characters.Dery.torch.show();world.characters.Dery.crouching=false;world.characters.Dery.concealed=false
 var notices: Array[String]=[];world.notice.connect(func(value):notices.append(value));enemy.mode="patrol";enemy.sense()
 check(enemy.mode=="chase" and notices.is_empty(),"HUD discreto deixa o jogador perceber a detecção pelos movimentos")
 Preferences.immersive_hud=false;enemy.mode="patrol";enemy.sense()
 check(notices.size()==1 and notices[0].contains("ele me viu"),"HUD completo conserva a instrução acessível de detecção")
 Preferences.immersive_hud=true;Preferences.apply();world.select_player("Dery");await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"rodinha continua oferecendo terceira pessoa durante a perseguição")
 Session.campaign.flags.front_open=true;Session.campaign.flags.help_notified=true;world.sunday.state().proof="offsite";world.sunday.apply_scene()
 for actor in world.characters.values():actor.position=Vector3(10 if actor.identity=="Dery" else 10.5,Street.surface_height(10,1.8),1.8);actor.reset_physics_interpolation()
 check(world.sunday.finish(false),"desfecho ainda exige chegar fisicamente com a dupla")
 var panel: CampaignPanel=app.interface.campaign_panel
 check(panel!=null and panel.kind=="ending" and not panel.epilogue.visible and panel.aftermath.visible,"antes do texto final há uma pausa curta no local da saída")
 check(not world.active and get_tree().paused and panel.air.playing,"ameaça e mecanismos param enquanto o ar da rua permanece audível")
 var remaining: float=climax.state().aftermath_left;await ticks(50)
 check(float(climax.state().aftermath_left)<remaining and not panel.epilogue.visible,"instante de respiro avança mesmo com a simulação encerrada")
 var effects: float=Preferences.effects_volume;Preferences.effects_volume=0;Preferences.apply()
 check(panel.air.volume_db<=-80,"som do respiro também respeita o volume dos efeitos")
 Preferences.effects_volume=effects;Preferences.apply();Session.save_shift(world.player.position);var saved_left: float=climax.state().aftermath_left;app.start_saved();world=app.world;climax=world.sunday.climax;await ticks(4);panel=app.interface.campaign_panel
 check(panel!=null and not panel.epilogue.visible and float(climax.state().aftermath_left)<=saved_left,"continuar conserva o respiro em andamento e o final escolhido")
 await key(KEY_ENTER);await ticks(80)
 check(panel.epilogue.visible and panel.modulate.a>.99 and bool(climax.state().aftermath_seen),"leitura pode ser antecipada e o epílogo entra suavemente")
 check(panel.air.stream==null and Session.campaign.ending.id=="resolved" and Session.campaign.ending.proof,"respiro termina sem mudar sobreviventes nem prova")
 app.start_saved();world=app.world;await ticks(4);panel=app.interface.campaign_panel
 check(panel.epilogue.visible and not panel.aftermath.visible,"respiro concluído não precisa ser revisto ao continuar")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(5)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("CLIMAX RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
