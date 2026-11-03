extends Node
## Fixed, matched first-person views for visual comparison. No campaign progress is completed.
var app: Node
var world: ShiftWorld
var output:=""
var movie:=false
var shots: Array=[]
var views: Array[Dictionary]=[
 {"id":"salao","at":Vector3(3.5,.01,-2.0),"to":Vector3(-1.2,1.6,-7.4),"caption":"SALÃO / luz de loja, sombras e materiais"},
 {"id":"caixa","at":Vector3(-3.0,.01,-3.1),"to":Vector3(-4.6,1.5,-.4),"caption":"CAIXA / um lugar familiar no fim do turno"},
 {"id":"estoque","at":Vector3(2.0,.01,-12.6),"to":Vector3(-1.5,1.45,-15.8),"caption":"FUNDOS / marcas de uso e luz de serviço"},
 {"id":"fachada","at":Vector3(-8.0,.01,6.5),"to":Vector3(0,2.45,-.3),"caption":"FACHADA / loja quente, bairro frio"},
 {"id":"rua","at":Vector3(4.7,.01,6.7),"to":Vector3(-16,1.5,11.7),"caption":"BAIRRO / postes, distância e silêncio"}]
func _ready() -> void:process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func frames(count: int=6) -> void:
 for i in count:await get_tree().process_frame
func run() -> void:
 output=OS.get_environment("VISUAL_DIRECTION_PATH")
 if output.is_empty():output="/tmp/visual-direction"
 DirAccess.make_dir_recursive_absolute(output);movie="movie" in OS.get_cmdline_user_args()
 Preferences.ps1_mode=false;Preferences.pixel_scale=1;Preferences.frame_limit=30;Preferences.fov=68;Preferences.grain=.012;Preferences.vhs=.045;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);app.interface.hud.hide();world=app.world;world.spawn_wait=999;Session.greet();Dialogue.clear();world.presence.state().next_at=99999
 var layer:=CanvasLayer.new();layer.layer=20;add_child(layer)
 var caption:=Label.new();layer.add_child(caption);caption.position=Vector2(24,20);caption.add_theme_font_size_override("font_size",19);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_y",2)
 for data in views:
  var at: Vector3=data.at
  at.y=Street.surface_height(at.x,at.z)+.01 if at.z>=0 else .01
  world.player.position=at;world.player.velocity=Vector3.ZERO;world.player.reset_physics_interpolation()
  var rig:=world.player.camera_rig;var eye:=at+Vector3.UP*1.62;var toward: Vector3=data.to-eye
  rig.target_distance=0;rig.distance=0;rig.yaw=atan2(-toward.x,-toward.z);rig.pitch=asin(toward.normalized().y);rig.reset_follow()
  caption.text=("0.40.0 / DIREÇÃO VISUAL\n"+str(data.caption)) if movie else ""
  await frames(4 if movie else 14);await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(output+"/"+str(data.id)+".png");shots.append(data.id)
  if movie:
   var start:=rig.yaw
   var tween:=create_tween();tween.tween_property(rig,"yaw",start+.14,2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);await tween.finished
 print("VISUAL DIRECTION REVIEW ",JSON.stringify({"shots":shots,"pixel_scale":Preferences.pixel_scale,"fov":Preferences.fov,"grain":Preferences.grain,"vhs":Preferences.vhs,"native_first_person":true,"matched_views":true,"speed":1}))
 Dialogue.clear();world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await frames(6);await get_tree().create_timer(.25,true,false,true).timeout
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
