extends Node
## Staged visual inspection only. The separate campaign_route test starts fresh.
var app: Node
var clock:=0.0
var stage:=-1
var taken:=false
var caption: Label
var output:=""
var review_camera: Camera3D
var focus_actor: Node3D
var shots: Array[String]=[]
var run_seconds: Dictionary={"Dery":0.0,"Felps":0.0}
const NAMES: Array[String]=["menu","deryk_correndo","felps_correndo","cliente","zirico","bryan","configuracoes","pane","cameras","gravacao","prova_na_saida"]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.fov=68;Preferences.ps1_mode=false;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(300,8);caption.size=Vector2(950,65);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.add_theme_font_size_override("font_size",18)
 output=OS.get_environment("RELEASE_REVIEW_PATH");next_stage()
func place_runner() -> void:
 var actor: DepotPlayer=app.world.player;actor.position=Vector3(3.3,.01,.4);actor.velocity=Vector3.ZERO;actor.visual.rotation.y=PI;actor.reset_physics_interpolation();actor.camera_rig.yaw=0;actor.camera_rig.pitch=-.16;actor.camera_rig.target_distance=2.5;actor.camera_rig.distance=2.5;actor.camera_rig.reset_follow()
func lens(at: Vector3,target: Vector3) -> void:
 if not is_instance_valid(review_camera):review_camera=Camera3D.new();review_camera.fov=64;app.world.add_child(review_camera)
 review_camera.position=at;review_camera.look_at(target);review_camera.make_current()
func next_stage() -> void:
 Input.action_release("forward");Input.action_release("sprint");stage+=1;clock=0;taken=false;focus_actor=null
 var world: ShiftWorld=app.world
 match stage:
  0:
   app.interface.begin_title(world);app.interface.presentation.finish_intro();caption.text="0.36.0 / REVISÃO VISUAL • cenas separadas e posições preparadas para inspeção."
  1:
   app.interface.finish_title_launch(false);Dialogue.clear();world.spawn_wait=999;world.presence.state().next_at=99999;place_runner();caption.text="Deryk / entrada real de caminhada e corrida, com colisão e câmera originais."
  2:
   world.switch_player();place_runner();caption.text="Felps / a mesma rota com sua animação de corrida."
  3:
   world.active=false;world.spawn_customer(false);focus_actor=world.customer;app.interface.hud.hide();caption.text="Cliente / caminhada do personagem original pela rota de chegada."
  4,5:
   for actor in get_tree().get_nodes_in_group("familiar_npcs"):
    if actor.identity==("Zirico" if stage==4 else "Bryan"):focus_actor=actor;actor.depart(world.navigation.path(actor.position,Vector3(18,0,1.8)));break
   caption.text="Zirico / cadência e postura de bêbado." if stage==4 else "Bryan / passos e postura de criança inquieta."
  6:
   app.interface.set_paused(true);app.interface.open_settings();caption.text="Configurações / sair com Esc agora também salva volume, FOV e sensibilidade."
  7:
   app.interface.settings.closed.emit();app.interface.set_paused(false);world.active=true;world.friday.begin_outage();Dialogue.clear();world.active=false
   lens(Vector3(4.4,1.7,-1.4),Vector3(-1.0,1.4,-6.2));caption.text="Sexta / pane mantém só a iluminação de emergência; os equipamentos ficam sem energia."
  8:
   Session.advance_to_saturday();app.build_world();world=app.world;world.active=true;world.saturday.introduce(world.player);Dialogue.clear();world.select_player("Felps");world.try_surveillance();caption.text="Sábado / câmera ao vivo compartilha o cenário; o computador mantém as regras da investigação."
  9:
   app.interface.close_surveillance();Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.sunday.introduce(world.player);Dialogue.clear();Session.campaign.flags.module_found=true;Session.campaign.flags.module_delivered=true;world.select_player("Felps");world.try_surveillance();app.interface.sunday_desk.recover();caption.text="Domingo / reprodução do arquivo real, com interface e tipografia nítidas."
  10:
   app.interface.close_sunday_desk();world.sunday.state().proof="carried";world.sunday.state().proof_carrier="Dery";app.interface.show_campaign("escape");caption.text="Saída / a confirmação avisa quando a cópia ficou com o companheiro."
  11:set_process(false);call_deferred("finish")
func _physics_process(delta: float) -> void:
 if not is_instance_valid(app) or stage not in [1,2]:return
 var actor: DepotPlayer=app.world.player
 if actor.motion.current_clip=="run" and actor.actual_speed>3.3:run_seconds[actor.identity]+=delta
func _process(delta: float) -> void:
 clock+=delta
 if stage in [1,2]:
  Input.action_press("forward")
  if clock>.4:Input.action_press("sprint")
 if is_instance_valid(focus_actor):lens(focus_actor.position+Vector3(.7,1.15,2.8),focus_actor.position+Vector3.UP*(.65 if stage==5 else 1.05))
 if not taken and clock>1.1:taken=true;call_deferred("shot",NAMES[stage])
 if clock>(2.6 if stage in [1,2] else 2.0):next_stage()
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 shots.append(id);print("RELEASE SHOT ",id)
func finish() -> void:
 Input.action_release("forward");Input.action_release("sprint");Dialogue.clear();print("RELEASE VISUAL ",JSON.stringify({"shots":shots,"run_seconds":run_seconds,"staged_views":true,"speed":1}))
 app.world.sound.stop_all();app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if shots.size()==11 and run_seconds.Dery>1.4 and run_seconds.Felps>1.4 else 1)
