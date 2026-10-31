extends Node
## Condensed real-game review. Narrative time and player locations are staged.
var app: Node
var phase:=0
var clock:=0.0
var total:=0.0
var moved:=false
var capture_wait:=-1.0
var shown: Dictionary={}
var caption: Label
var after_lines:=0
var prank_seen:=false
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.ps1_mode=false;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);app.world.spawn_wait=999;Session.greet();Session.world_seconds=60
 place(Vector3(2.8,.01,-12.2),atan2(2.8,3.62),-.16)
 var layer:=CanvasLayer.new();layer.layer=8;add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(905,25);caption.add_theme_font_override("font",TitlePresentation.VCR);caption.add_theme_font_size_override("font_size",23);caption.add_theme_color_override("font_color",Color("e9dec6"));caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2);caption.text="0.30.0 / ESTOQUE\nUm arrasto atrás da porta"
 caption.position=Vector2(540,25);caption.size=Vector2(240,110);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func place(at: Vector3,yaw: float,pitch: float=-.10) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=yaw;actor.camera_rig.pitch=pitch;actor.camera_rig.reset_follow()
func open_doors() -> void:
 for door in [app.world.depot.stock_door,app.world.depot.service_door]:
  for child in door.get_children():
   if child is Interaction and child.kind=="door" and not child.open and not child.busy:child.activate(app.world.player)
func space() -> void:
 var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
 event=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
func shot(id: String) -> void:
 if shown.has(id):return
 shown[id]=true;call_deferred("capture",id)
func _process(delta: float) -> void:
 clock+=delta;total+=delta
 if total>38:call_deferred("finish");set_process(false);return
 match phase:
  0:
   if clock>1.4 and not moved:moved=true;place(Vector3(.7,.01,-14.0),atan2(.25,1.8),-.20);caption.text="0.30.0 / ESTOQUE\nO som parou."
   if app.world.scary.state().door_phase=="handle":
    if capture_wait<0:capture_wait=.35
    capture_wait-=delta
    if capture_wait<=0:shot("handle")
   if app.world.scary.state().door_phase=="done":
    phase=1;clock=0;place(Vector3(-3.1,.01,-2.8),PI,-.10);Session.world_seconds=float(app.world.scary.state().last_event)+40;caption.text="0.30.0 / VITRINE\nBryan foi aprontar"
  1:
   if app.world.scary.done("bryan_prank"):
    if not prank_seen:prank_seen=true;clock=0
    if clock>.35:shot("bryan")
    if clock>1.25:
     phase=2;clock=0;app.world.friday.begin_outage();Dialogue.clear();Session.campaign.flags.generator_key=true;Session.campaign.flags.counter_secured=true;place(Vector3(4.35,.01,-19.4),-PI/2);app.world.friday.activate("generator",app.world.player);Dialogue.clear();caption.text="0.30.0 / GERADOR\nA energia voltou"
  2:
   if clock>1.25:
    open_doors();Session.world_seconds=float(app.world.scary.state().last_scare)+40;place(Vector3(3.2,.01,-7.5),atan2(-1.45,1.0),-.08);phase=3;clock=0;caption.text="0.30.0 / A VOLTA\nPassos no salão"
  3:
   if app.world.scary.done("return_intruder"):shot("crossing")
   if is_instance_valid(app.world.scary.intruder) and app.world.scary.intruder.position.z< -12.5:shot("stock_route")
   if app.world.scary.done("yard_slam"):shot("slam")
   if app.world.scary.done("return_aftermath"):
    phase=4;clock=0;caption.text="0.30.0 / FELPS\nNinguém veio pela frente"
  4:
   if clock>1.5 and after_lines==0:after_lines=1;space()
   if clock>2.8 and after_lines==1:after_lines=2;space()
   if clock>4.1 and after_lines==2:after_lines=3;space();shot("aftermath")
   if clock>6:set_process(false);call_deferred("finish")
func capture(id: String) -> void:
 await RenderingServer.frame_post_draw
 var output:=OS.get_environment("SCARES_REVIEW_PATH")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 print("SCARES CAPTURE ",id)
func finish() -> void:
 print("SCARES REVIEW ",JSON.stringify({"handle":app.world.scary.done("stock_handle"),"bryan":app.world.scary.done("bryan_prank"),"crossing":app.world.scary.done("return_intruder"),"slam":app.world.scary.done("yard_slam"),"aftermath":app.world.scary.done("return_aftermath")}))
 Dialogue.clear();app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
