extends Node
## Separate real-engine examples at normal speed; elapsed investigation is staged.
var app: Node
var clock:=0.0
var stage:=-1
var card: ColorRect
var caption: Label
var taken:=false
var head_started:=false
var output:=""
var seen_head:=false
var body_exposed:=false
var reveal_captured:=false
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.fov=68;Preferences.frame_limit=30;Preferences.ps1_mode=false;Preferences.immersive_hud=true;Preferences.apply();Session.new_shift();Session.advance_to_sunday()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);app.world.active=true;app.world.spawn_wait=999;app.world.sunday.introduce(app.world.characters.Dery);Dialogue.clear();Session.world_seconds=180;Session.campaign.flags.module_found=true;app.world.sunday.change_door("stock",true);app.world.sunday.change_door("old",true);app.world.sunday.climax.set_physics_process(false)
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer);card=ColorRect.new();layer.add_child(card);card.size=Vector2(1280,720);card.color=Color.BLACK
 caption=Label.new();layer.add_child(caption);caption.position=Vector2(80,190);caption.size=Vector2(1120,350);caption.add_theme_font_size_override("font_size",29);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.text="0.33.0 — DOMINGO\n\nUma última cabeça. Depois, a ameaça se aproxima.\nQuatro cenas separadas, em tempo normal. Use fones.\nA investigação e os intervalos foram cortados nesta prévia."
 output=OS.get_environment("SUNDAY_CLIMAX_REVIEW_PATH")
func place(at: Vector3,target: Vector3,pitch: float) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=atan2(-(target.x-at.x),-(target.z-at.z));actor.camera_rig.pitch=pitch;actor.camera_rig.reset_follow()
func next_stage() -> void:
 Input.action_release("backward");Input.action_release("crouch");stage+=1;clock=0;taken=false
 var world: ShiftWorld=app.world
 card.hide();caption.position=Vector2(25,20);caption.size=Vector2(1200,55);caption.add_theme_font_size_override("font_size",19)
 match stage:
  0:
   place(Vector3(.5,.01,-12.2),Vector3(-3.5,1.7,-15.6),-.12);caption.text="1 / Durante a investigação: só a cabeça, por um instante, entre as caixas."
  1:
   if OS.get_environment("SUNDAY_CLIMAX_PROBE_ONLY")=="1":set_process(false);call_deferred("finish");return
   Session.campaign.phase="sunday_prepare";world.sunday.begin_escape();Dialogue.clear();world.sunday.state().generator_mode="stock";world.sunday.change_door("stock",true);world.sunday.apply_scene();world.sunday.killer.position=Vector3(4.85,.01,-12.5);world.sunday.killer.grace=0
   place(Vector3(4.85,.01,-8.0),Vector3(4.85,1.4,-12.5),-.05);world.player.torch.show();Input.action_press("backward");caption.text="2 / Perseguição real: ele viu Deryk. Os passos vêm do corpo dele, sem aviso no HUD."
  2:
   var enemy: KillerAgent=world.sunday.killer
   place(Vector3(4.85,.01,-13.3),Vector3(4.85,1.3,-11),-.05);world.player.torch.hide();Input.action_press("crouch");world.sunday.change_door("stock",false);enemy.position=Vector3(4.85,.01,-8.9);enemy.visual.rotation.y=PI;enemy.reset_physics_interpolation();enemy.start_search("search",Vector3(4.85,.01,-10.1));enemy.grace=0
   caption.text="3 / Linha de visão quebrada: passos abafados e busca do outro lado da porta."
  3:
   Session.campaign.flags.front_open=true;Session.campaign.flags.help_notified=true;world.sunday.state().proof="offsite";world.sunday.apply_scene()
   for actor in world.characters.values():actor.position=Vector3(10 if actor.identity=="Dery" else 10.5,Street.surface_height(10,1.8),1.8);actor.reset_physics_interpolation()
   place(world.player.position,Vector3(9,1,3),-.05);world.sunday.finish(false);caption.text="4 / Depois da saída: alguns segundos de ar da rua antes do relato final."
  4:set_process(false);call_deferred("finish")
func _process(delta: float) -> void:
 clock+=delta;app.interface.hud.hide()
 if stage<0:
  if clock>2:next_stage()
  return
 if stage==0 and clock>.3 and not head_started:
  head_started=true;app.world.sunday.climax.create()
  app.world.sunday.climax.watcher.prepared.connect(func():print("CLIMAX HEAD prepared eye=",app.world.player.camera_rig.camera.global_position))
  app.world.sunday.climax.watcher.rejected.connect(func():print("CLIMAX HEAD rejected=",app.world.sunday.climax.last_rejection," eye=",app.world.player.camera_rig.camera.global_position))
 if stage==0 and is_instance_valid(app.world.sunday.climax.watcher):
  var actor: HeadWatcher=app.world.sunday.climax.watcher
  if actor.started:
   body_exposed=body_exposed or app.world.sunday.climax.any_visible(actor.body_points())
   seen_head=seen_head or app.world.sunday.climax.any_visible(actor.head_points())
   if actor.phase=="holding" and not taken:taken=true;call_deferred("shot","ultima_cabeca")
 elif stage in [1,2] and clock>.9 and not taken:taken=true;call_deferred("shot","perseguicao" if stage==1 else "busca")
 elif stage==3:
  if clock>1 and not taken:taken=true;call_deferred("shot","respiro")
  var panel: CampaignPanel=app.interface.campaign_panel
  if panel!=null and panel.epilogue.visible and panel.modulate.a>.99 and not reveal_captured:reveal_captured=true;call_deferred("shot","epilogo")
 var duration:=2.5 if stage in [0,1] else 5.0 if stage==2 else 7.5
 if clock>duration:next_stage()
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 print("CLIMAX SHOT ",id)
func finish() -> void:
 print("CLIMAX REVIEW ",JSON.stringify({"head_seen":seen_head,"body_exposed":body_exposed,"epilogue_revealed":reveal_captured,"ending":Session.campaign.ending.get("id",""),"notes":Session.campaign.experience.notes.size()}))
 app.world.sound.stop_all();app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if seen_head and not body_exposed and (reveal_captured or OS.get_environment("SUNDAY_CLIMAX_PROBE_ONLY")=="1") else 1)
