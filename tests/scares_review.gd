extends Node
## Staged progress and camera turn for review; normal game timing and occlusion.
var app: Node
var seconds:=0.0
var visible_seconds:=0.0
var min_z:=0.0
var max_z:=-1000.0
var shot_taken:=false
var label: Label
var card: ColorRect
var model_path:=""
var library_path:=""
var retired_hidden:=false
var watched:=false
var doors_opened:=false
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.fov=70;Preferences.ps1_mode=false;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);app.interface.hud.hide();app.world.spawn_wait=999;Session.greet();Dialogue.clear()
 app.world.friday.begin_outage();Dialogue.clear();Session.campaign.flags.generator_key=true;Session.campaign.flags.counter_secured=true
 app.world.player.position=Vector3(4.35,.01,-19.4);app.world.friday.activate("generator",app.world.player);Dialogue.clear();Session.world_seconds=420
 var actor: DepotPlayer=app.world.player;actor.position=Vector3(4.25,.01,-6.4);actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=-1.4;actor.camera_rig.pitch=-.10;actor.camera_rig.reset_follow()
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer)
 card=ColorRect.new();card.size=Vector2(1280,720);card.color=Color.BLACK;layer.add_child(card)
 label=Label.new();layer.add_child(label);label.position=Vector2(80,210);label.size=Vector2(1120,300);label.add_theme_font_size_override("font_size",32);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.text="0.30.2 — APARIÇÃO SUTIL\n\nUm instante junto ao batente do estoque.\nGravação da cena real, em velocidade normal."
func _process(delta: float) -> void:
 seconds+=delta;app.interface.hud.hide()
 if not doors_opened and not app.world.player.motion.action_active:
  doors_opened=true
  for door in [app.world.depot.stock_door,app.world.depot.service_door]:
   for child in door.get_children():
    if child is Interaction and child.kind=="door" and not child.open:child.activate(app.world.player)
 if seconds>3 and card.visible:
  card.hide();label.position=Vector2(26,22);label.size=Vector2(1000,35);label.add_theme_font_size_override("font_size",20);label.text="0.30.2  /  TEMPO NORMAL  /  sem travessia pelo salão"
 if seconds>4 and seconds<4.65:
  app.world.player.camera_rig.yaw=lerpf(-1.4,-.40,smoothstep(4,4.6,seconds))
 if is_instance_valid(app.world.scary.intruder):
  var actor: FrightIntruder=app.world.scary.intruder
  if not watched:
   watched=true;model_path=actor.visual.scene_file_path;library_path=actor.motion.animator.get_animation_library("natural").resource_path
   actor.departed.connect(func():retired_hidden=not app.world.scary.player_sees_body(actor.position) and not app.world.scary.other_witnesses(actor.position))
  min_z=minf(min_z,actor.position.z);max_z=maxf(max_z,actor.position.z)
  if app.world.scary.player_sees_body(actor.position):visible_seconds+=delta
  if actor.seen_time>.24 and not shot_taken:shot_taken=true;call_deferred("capture","vulto")
 if seconds>9.5:set_process(false);call_deferred("finish")
func capture(id: String) -> void:
 await RenderingServer.frame_post_draw
 var output:=OS.get_environment("SCARES_REVIEW_PATH")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
func finish() -> void:
 var result:={"model":model_path,"animation_library":library_path,"glimpsed":app.world.scary.done("return_intruder"),"gone":app.world.scary.done("intruder_gone"),"retired_out_of_view":retired_hidden,"visible_seconds":visible_seconds,"stock_min_z":min_z,"stock_max_z":max_z,"forced_dialogue":Dialogue.active,"door_slam":app.world.scary.done("yard_slam"),"fov":70,"duration":seconds}
 print("SUBTLE REVIEW ",JSON.stringify(result))
 print("REVIEW STATE ",Session.campaign.phase," ",app.world.scary.state()," player=",app.world.player.position," yaw=",app.world.player.camera_rig.yaw," safe=",app.world.scary.safe()," witness=",app.world.scary.other_witnesses(FrightIntruder.EDGE)," hidden=",app.world.scary.player_sees_body(FrightIntruder.HIDDEN)," edge=",app.world.scary.can_see(FrightIntruder.EDGE+Vector3(.2,1.5,0)))
 Dialogue.clear();app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if result.glimpsed and result.gone else 1)
