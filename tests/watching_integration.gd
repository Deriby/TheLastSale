extends "res://tests/everyday_integration.gd"
var views: Array[Vector3]=[Vector3(4.25,.01,-6.4),Vector3(3.1,.01,-3.5),Vector3(-3,.01,-2.5),Vector3(4.25,.01,-4),Vector3(-.15,.01,-11),Vector3(-4.2,.01,-4),Vector3(.15,.01,-3.4),Vector3(4.25,.01,-8),Vector3(-.15,.01,-10.5),Vector3(-4,.01,-7.8),Vector3(.3,.01,-8.3),Vector3(1.5,.01,-12.0),Vector3(.5,.01,-12.1)]
func run() -> void:
 Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.spawn_wait=999;Session.greet();clear_dialogue();Session.world_seconds=100;world.presence.state().next_at=99999
 for person in get_tree().get_nodes_in_group("familiar_npcs"):person.queue_free()
 world.characters.Felps.position=Vector3(-18,.01,1.8);world.characters.Felps.visual.rotation.y=0;world.characters.Felps.reset_physics_interpolation()
 for door in [world.depot.stock_door,world.depot.service_door]:
  for child in door.get_children():
   if child is Interaction and child.kind=="door":child.activate(world.player)
 await ticks(35);world.scary.state().door_phase="done"
 var feet_planted:=true
 var notes_before: int=Session.campaign.experience.notes.size();var observations_before: Dictionary=Session.campaign.friday_story.observations.duplicate(true)
 for index in world.presence.sites.size():
  var site: Dictionary=world.presence.sites[index]
  var at: Vector3=views[index];var target: Vector3=site.pos+Vector3.UP*1.7
  await stand(at,atan2(-(target.x-at.x),-(target.z-at.z)));world.presence.state().next_at=99999
  world.presence.create(site,.26)
  var actor: HeadWatcher=world.presence.watcher
  var prepared: Array[bool]=[false];var rejected: Array[bool]=[false];var retired: Array[bool]=[false]
  actor.prepared.connect(func():prepared[0]=true)
  actor.rejected.connect(func():rejected[0]=true)
  actor.withdrawn.connect(func():retired[0]=not world.presence.any_visible(actor.body_points()+actor.head_points()))
  var foot_start:=Vector3.INF;var foot_other:=Vector3.INF
  var body_exposed:=false;var head_visible:=false;var exposure:=0.0
  for frame in 160:
   await ticks(1)
   if not is_instance_valid(actor):break
   if actor.started:
    if foot_start==Vector3.INF:foot_start=actor.bone_world("foot_L");foot_other=actor.bone_world("foot_R")
    feet_planted=feet_planted and actor.bone_world("foot_L").distance_to(foot_start)<.025 and actor.bone_world("foot_R").distance_to(foot_other)<.025
    body_exposed=body_exposed or world.presence.any_visible(actor.body_points())
    if world.presence.any_visible(actor.head_points()):head_visible=true;exposure+=1.0/60.0
  print("WATCH SITE ",site.id," prepared=",prepared[0]," rejected=",rejected[0]," visible=",head_visible," body=",body_exposed," seconds=",exposure," retired=",retired[0])
  check(prepared[0] and head_visible,"cabeça pode ser percebida em "+str(site.id))
  check(not body_exposed,"tronco e pernas ficam encobertos em "+str(site.id))
  check(retired[0] and exposure<1.4,"retirada encoberta e tempo curto em "+str(site.id))
  if is_instance_valid(actor):actor.queue_free();await ticks(2)
 check(feet_planted,"abaixar e erguer a cabeça mantém os pés plantados atrás da cobertura")
 check(Session.campaign.experience.notes.size()==notes_before and Session.campaign.friday_story.observations==observations_before,"aparições não escrevem pistas nem confirmam uma observação")
 check(not Dialogue.active and not world.scary.done("return_intruder"),"várias cabeças não geram conversa ou confirmação narrativa")
 world.presence.state().next_at=99999
 await stand(Vector3(4.25,.01,-8.5),atan2(3.75,-1.55))
 var notes_at_miss: int=Session.campaign.experience.notes.size();var count_at_miss: int=world.presence.state().count
 world.presence.create(world.presence.sites[3],.18)
 var missed: HeadWatcher=world.presence.watcher
 for frame in 30:
  await ticks(1)
  if not is_instance_valid(missed) or missed.started:break
 world.player.camera_rig.yaw=PI;world.player.camera_rig.reset_follow();await ticks(90)
 check(not is_instance_valid(missed) and int(world.presence.state().count)==count_at_miss+1,"uma aparição pode terminar inteira fora da vista sem esperar o jogador olhar")
 check(Session.campaign.experience.notes.size()==notes_at_miss and not Dialogue.active,"perder a aparição não gera pista, fala ou aviso substituto")
 world.presence.state().next_at=99999;await stand(Vector3(4.25,.01,-6.4),atan2(.65,5.6))
 var count_before_guard: int=world.presence.state().count
 world.characters.Felps.position=Vector3(4.8,.01,-7.4);world.characters.Felps.visual.rotation.y=PI;world.characters.Felps.motion.attention.following=false;world.characters.Felps.motion.attention.yaw=0;world.characters.Felps.reset_physics_interpolation()
 world.presence.create(world.presence.sites[0],.2);await ticks(18)
 check(not is_instance_valid(world.presence.watcher) and int(world.presence.state().count)==count_before_guard,"olhar direto de outro personagem impede a cabeça de aparecer")
 world.characters.Felps.position=Vector3(-18,.01,1.8);world.characters.Felps.visual.rotation.y=0;world.characters.Felps.reset_physics_interpolation();world.presence.state().next_at=99999
 world.cashier_open=true;world.presence.create(world.presence.sites[0],.2);await ticks(18)
 check(not is_instance_valid(world.presence.watcher),"caixa aberto impede uma nova aparição")
 world.cashier_open=false;world.presence.state().next_at=99999
 await stand(Vector3(4.25,.01,-8.5),atan2(3.75,-1.55))
 world.presence.create(world.presence.sites[3],.45)
 for frame in 60:
  await ticks(1)
  if not is_instance_valid(world.presence.watcher) or world.presence.watcher.phase=="holding":break
 check(is_instance_valid(world.presence.watcher) and world.presence.watcher.phase=="holding","prepara oportunidade em andamento para testar retomada")
 if is_instance_valid(world.presence.watcher):
  var saved_count: int=world.presence.state().count
  var at_save: Vector3=world.presence.watcher.bone_world("head")
  Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(3)
  check(is_instance_valid(world.presence.watcher) and world.presence.watcher.phase=="holding" and int(world.presence.state().count)==saved_count and world.presence.watcher.bone_world("head").distance_to(at_save)<.04,"save retoma cabeça, duração e oportunidade sem contar de novo")
  if is_instance_valid(world.presence.watcher):
   var age: float=world.presence.watcher.age;var amount: float=world.presence.watcher.amount
   await key(KEY_J);await ticks(8)
   check(get_tree().paused and is_equal_approx(world.presence.watcher.age,age) and is_equal_approx(world.presence.watcher.amount,amount),"caderno pausa corpo e tempo da aparição")
   await key(KEY_J);await ticks(70)
  check(not is_instance_valid(world.presence.watcher) and world.presence.state().active.is_empty(),"retirada concluída limpa o ator do próximo checkpoint")
  Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(5)
  check(not is_instance_valid(world.presence.watcher) and int(world.presence.state().count)==saved_count,"continuar após a retirada não repete a mesma oportunidade")
 world.presence.state().count=8;world.presence.state().next_at=0;await ticks(60)
 check(not is_instance_valid(world.presence.watcher),"limite por noite evita cabeças em toda virada de câmera")
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"terceira pessoa continua disponível pela rodinha")
 var legacy:=Session.snapshot_data();legacy.campaign.experience.erase("watching_presence");Session.write_save(legacy);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(3)
 check(world.presence.state().used.is_empty() and int(Session.campaign.night)==0,"save anterior recebe oportunidades opcionais sem perder a campanha")
 Session.advance_to_saturday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;await ticks(3)
 check(int(world.presence.state().count)==0 and world.presence.state().used.is_empty(),"sábado tem novas oportunidades sem repetir os contadores da sexta")
 Session.campaign.phase="saturday_routine";clear_dialogue();world.scary.state().prank={"phase":"waiting"};world.scary.state().events.bryan_prank=true;world.presence.state().next_at=99999
 await stand(Vector3(4.25,.01,-8.5),atan2(3.75,-1.55));world.presence.create(world.presence.sites[3],.2);await ticks(14)
 check(int(world.presence.state().count)==1,"estado antigo de Bryan na sexta não bloqueia uma cabeça no sábado")
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;await ticks(3)
 check(world.presence.sites.is_empty() and not is_instance_valid(world.presence.watcher),"domingo conserva somente a ameaça da perseguição existente")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(5)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("WATCHING RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
