extends Node
## Condensed feature review: actual world, controls, shared audio and notebook.
var app: Node
var elapsed:=0.0
var step:=-1
var caption: Label
var saved: Dictionary={}
var output:=""
var line_index:=0
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.ps1_mode=false;Preferences.frame_limit=30;Preferences.grain=.012;Preferences.vhs=.045;Preferences.immersive_hud=true;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
 app.world.spawn_wait=999;Session.greet();place(Vector3(3.3,.01,.2),0)
 var layer:=CanvasLayer.new();layer.layer=8;add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(900,25);caption.add_theme_font_override("font",TitlePresentation.VCR);caption.add_theme_font_size_override("font_size",23);caption.add_theme_color_override("font_color",Color("e9dec6"));caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
 output=OS.get_environment("EVERYDAY_REVIEW_PATH")
func press(code: Key) -> void:
 var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
 event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
func scroll(button: MouseButton,count: int) -> void:
 for index in count:
  var event:=InputEventMouseButton.new();event.button_index=button;event.pressed=true;app.world.player.camera_rig.handle_input(event)
func place(at: Vector3,yaw: float) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=yaw;actor.camera_rig.pitch=-.12;actor.camera_rig.reset_follow()
 actor.camera_rig.distance=actor.camera_rig.target_distance;actor.camera_rig.arm.spring_length=actor.camera_rig.distance;actor.camera_rig.camera.position.z=actor.camera_rig.distance
func _process(delta: float) -> void:
 elapsed+=delta
 var next:=0 if elapsed<3.3 else 1 if elapsed<5.2 else 2 if elapsed<7.2 else 3 if elapsed<12.6 else 4 if elapsed<16.8 else 5
 if next!=step:
  step=next
  match step:
   0:Input.action_press("forward");caption.text="0.28.0 / EXPEDIENTE\nPrimeira pessoa"
   1:Input.action_release("forward");scroll(MOUSE_BUTTON_WHEEL_DOWN,10);caption.text="0.28.0 / CÂMERA\nRodinha: terceira pessoa"
   2:press(KEY_J);caption.text="0.28.0 / CADERNO\nTarefas e observações"
   3:
    if app.interface.notebook!=null:press(KEY_J)
    scroll(MOUSE_BUTTON_WHEEL_UP,16);place(Vector3(4.75,.01,-13.0),PI/3);Session.world_seconds=151;caption.text="0.28.0 / ESTOQUE\nO sino tocou na entrada"
   4:
    Dialogue.clear();Session.world_seconds=226;Session.customers_served=1;place(Vector3(3.0,.01,.9),0);caption.text="0.28.0 / FACHADA\nAlguém do outro lado"
   5:
    app.start_saturday();app.world.spawn_wait=999;app.world.saturday.introduce(app.world.player);Dialogue.clear();app.world.switch_player();app.world.everyday.spawn_observer();app.world.everyday.record("observer_arrived");app.interface.open_surveillance(app.world);caption.text="0.28.0 / SÁBADO\nCâmera ao vivo"
 if step==3:
  var line:=1 if elapsed>=9.0 and elapsed<10.8 else 2 if elapsed>=10.8 else 0
  if line>line_index:line_index=line;press(KEY_SPACE)
 if step==4 and elapsed>=13.2 and is_instance_valid(app.world.everyday.observer):
  var actor: DepotPlayer=app.world.player;var at: Vector3=app.world.everyday.observer.position
  actor.camera_rig.yaw=atan2(-(at.x-actor.position.x),-(at.z-actor.position.z));actor.camera_rig.pitch=-.01
 for entry in [[2.6,"shop"],[4.8,"third_person"],[6.2,"notebook"],[10.2,"stock"],[15.2,"street"],[19.2,"cctv"]]:
  if elapsed>=entry[0] and not saved.has(entry[1]):saved[entry[1]]=true;call_deferred("capture",entry[1])
 if elapsed>=20.4:set_process(false);call_deferred("finish")
func capture(id: String) -> void:
 if output.is_empty():return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png");print("EVERYDAY CAPTURE ",id)
func finish() -> void:
 Input.action_release("forward");print("EVERYDAY REVIEW ",JSON.stringify({"chime":Session.campaign.experience.notes.any(func(note):return str(note.get("id","")).ends_with("empty_chime")),"audio_listener":app.viewport.audio_listener_enable_3d,"camera_wheel":true,"notebook":saved.has("notebook"),"cctv":app.interface.surveillance!=null}))
 app.interface.close_surveillance();app.interface.close_journal(false);app.queue_free()
 for frame in 5:await get_tree().process_frame
 await get_tree().create_timer(.12,true).timeout
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
