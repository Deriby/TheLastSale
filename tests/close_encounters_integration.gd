extends "res://tests/everyday_integration.gd"
var results: Array=[]
func boot(saturday: bool=false) -> void:
 Dialogue.clear();Session.new_shift()
 if saturday:Session.advance_to_saturday()
 app.build_world();world=app.world;world.active=false;world.spawn_wait=999;world.set_physics_process(false);world.horror.set_physics_process(false);world.encounters.set_physics_process(false);world.presence.state().next_at=99999
 Dialogue.clear();Session.world_seconds=400;world.scary.state().door_phase="done";world.scary.state().prank={"phase":"done"};world.scary.state().events.stock_handle=true;world.scary.state().events.bryan_prank=true
 Session.campaign.phase="closing" if saturday else "restored";Session.campaign.flags.generator_running=true
 world.friday.apply_power();world.horror.state().quiet_until=0
func open(door: Node3D) -> void:
 for child in door.get_children():
  if child is Interaction and child.kind=="door":child.open=true;child.busy=false
 door.rotation.y=1.45 if door==world.depot.service_door else -1.45
func scan() -> void:world.encounters._physics_process(.1)
func run() -> void:
 Preferences.camera_distance=0;Preferences.frame_limit=60;Preferences.pixel_scale=2;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false)
 for id in ["generator_return","stock_corner"]:
  var saturday: bool=id=="stock_corner";boot(saturday)
  var door: Node3D=world.depot.stock_door if saturday else world.depot.service_door
  var at:=Vector3(4.85,.01,-11.8 if saturday else -17.3)
  await stand(Vector3(2.8,.01,-3.0));world.active=true;scan()
  check(not world.encounters.blocking(),id+": susto não dispara longe da passagem")
  world.active=false;await stand(at,PI);world.active=true
  if saturday:Session.campaign.flags.door_attempt=false
  else:Session.campaign.flags.generator_running=false
  open(door);scan()
  check(not world.encounters.blocking(),id+": avanço exige o acontecimento anterior da campanha")
  Session.campaign.flags.door_attempt=true;Session.campaign.flags.generator_running=true
  for child in door.get_children():
   if child is Interaction and child.kind=="door":child.open=false
  scan();check(not world.encounters.blocking(),id+": porta fechada impede a emboscada")
  open(door);world.cashier_open=true;scan();world.cashier_open=false
  check(not world.encounters.blocking(),id+": painel aberto impede o evento")
  world.horror.calm(20);scan();check(not world.encounters.blocking(),id+": intervalo entre sustos é respeitado")
  world.horror.state().quiet_until=0
  var player_at:=world.player.position;var zoom:=world.player.camera_rig.target_distance
  var notes: int=Session.campaign.experience.notes.size();var clues: Dictionary=Session.campaign.clues.duplicate(true)
  world.encounters.set_physics_process(true)
  var seen:=false;var core_visible:=false;var max_seen:=0.0;var saved:=false;var resume_ok:=false;var framed:=false
  for frame in 240:
   Session.world_seconds+=1.0/60;await ticks(1)
   var actor:=world.encounters.watcher
   if is_instance_valid(actor) and actor.started:
    if actor.contact_fired:
     seen=true;max_seen+=1.0/60
     if actor.phase=="holding" and actor.age>.15:
      var face: Vector3=actor.lean.points.face
      framed=framed or (-world.player.camera_rig.camera.global_basis.z).dot((face-world.player.camera_rig.camera.global_position).normalized())>.99
     for bone in ["pelvis","waist","chest","thigh_L","thigh_R"]:
      core_visible=core_visible or world.encounters.clear_ray(world.player.camera_rig.camera.global_position,actor.bone_world(bone))
     if not saved:
      saved=true;Session.save_shift(world.player.position)
      var data: Dictionary=Session.snapshot_data().campaign.experience.close_encounters
      resume_ok=bool(data.used.get(id,false)) and bool(data.active.watcher.get("contact_fired",false))
   if seen and not world.encounters.blocking():break
  check(seen and bool(world.encounters.state().used.get(id,false)),id+": aproximação dispara o encontro novo com o assassino")
  check(max_seen>.25 and not core_visible,id+": rosto fica legível e o corpo permanece atrás da parede")
  check(framed,id+": a mira acompanha o rosto já deformado pela animação")
  check(world.player.position.distance_to(player_at)<.03 and world.player.camera_rig.target_distance==zoom,id+": evento não teleporta o jogador nem muda a rodinha")
  check(saved and resume_ok,id+": save registra o susto consumido e não rearma o impacto")
  check(Session.campaign.experience.notes.size()==notes and Session.campaign.clues==clues and not Dialogue.active,id+": não cria fala, pista ou tarefa explicando a aparição")
  check(not world.encounters.blocking() and world.encounters.state().active.is_empty(),id+": assassino recua para a cobertura antes de ser retirado")
  world.encounters.set_physics_process(false);world.horror.state().quiet_until=0;scan();await ticks(8)
  check(not world.encounters.blocking(),id+": voltar à passagem não repete a emboscada")
  check(world.sound.compressors.all(func(player):return player.playing),id+": susto mantém a refrigeração e a energia reais")
  results.append({"event":id,"occurred":seen,"body_visible":core_visible,"face_framed":framed,"visible_seconds":max_seen,"checkpoint_consumed":resume_ok,"last_rejection":world.encounters.last_rejection})
  Session.save_shift(world.player.position);app.start_saved();world=app.world;world.active=true;world.spawn_wait=999;world.set_physics_process(false);world.presence.state().next_at=99999;await ticks(10)
  check(bool(world.encounters.state().used.get(id,false)) and not world.encounters.blocking() and not world.sound.contact.playing,id+": continuar não repete o rosto nem o som")
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;await ticks(3)
 check(not world.encounters.blocking() and world.encounters.state().active.is_empty(),"domingo não duplica o assassino com os novos encontros opcionais")
 await finish_test()
func finish_test() -> void:
 Dialogue.clear();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(6)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("AMBUSH METRICS ",JSON.stringify(results));print("AMBUSH RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
