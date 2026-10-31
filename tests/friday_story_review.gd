extends Node
## Condensed real-game review; time and locations are staged between chapters.
var app: Node
var elapsed:=0.0
var step:=-1
var line:=0
var caption: Label
var captured: Dictionary={}
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.ps1_mode=false;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.finish_title_launch(false);app.world.spawn_wait=999
 if not OS.get_environment("FRIDAY_STORY_REVIEW_START").is_empty():elapsed=float(OS.get_environment("FRIDAY_STORY_REVIEW_START"))
 var layer:=CanvasLayer.new();layer.layer=8;add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(895,25);caption.add_theme_font_override("font",TitlePresentation.VCR);caption.add_theme_font_size_override("font_size",23);caption.add_theme_color_override("font_color",Color("e9dec6"));caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
func press_space() -> void:
 var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
 event=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
func place(at: Vector3,yaw: float) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=yaw;actor.camera_rig.pitch=-.08;actor.camera_rig.reset_follow()
func _process(delta: float) -> void:
 elapsed+=delta
 var next:=0 if elapsed<4.5 else 1 if elapsed<9.5 else 2 if elapsed<10.8 else 3 if elapsed<15.5 else 4 if elapsed<22 else 5
 if next!=step:
  step=next;line=0
  match step:
   0:caption.text="0.29.0 / CHEGADA\nDois irmãos. Mais um turno."
   1:
    Dialogue.clear();Session.greet();app.world.select_player("Felps");place(CheckoutFixture.STAFF_POSITION+Vector3(0,0,-1.0),atan2(-2.02,-1.3))
    app.world.sale=ShopSale.create(1);app.world.spawn_customer(false,{"identity":"ClienteBone","appearance":1,"position":[-3.1,0,-2.7],"state":int(Customer.State.WAITING)})
    app.world.begin_checkout(app.world.customer);caption.text="0.29.0 / CLIENTES\nUma pergunta fora de hora"
   2:
    Dialogue.clear();app.interface.close_checkout()
    if is_instance_valid(app.world.customer):app.world.customer.queue_free()
    app.world.customer=null;app.world.sale=null;app.world.select_player("Dery");app.world.everyday.spawn_observer();Session.world_seconds=226;Session.customers_served=1
    var target: Vector3=app.world.everyday.observer.position;place(Vector3(3,.01,.9),atan2(-(target.x-3),-(target.z-.9)))
    caption.text="0.29.0 / PERCEPÇÃO\nAlguém olhando a loja"
   3:
    place(CheckoutFixture.CUSTOMER_POSITION+Vector3(0,0,1.2),atan2(2.02,1.5));app.world.story.try_remark(app.world.player);caption.text="0.29.0 / OS IRMÃOS\nEles comentam o que você viu"
   4:
    Dialogue.clear();Session.campaign.phase="closing"
    for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.queue_free()
    for flag in ["till_closed","stock_checked","lights_off","reunite"]:Session.campaign.flags[flag]=true
    app.world.friday.apply_power()
    for actor in app.world.characters.values():
     actor.position=Vector3(3.8 if actor.identity=="Dery" else 4.4,.01,1.4);actor.visual.rotation.y=PI if actor.identity=="Dery" else -PI/2;actor.reset_physics_interpolation()
    for index in 9:
     var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true;app.world.player.camera_rig.handle_input(event)
    place(Vector3(3.8,.01,1.4),0);app.world.friday.activate("exit",app.world.player);caption.text="0.29.0 / FECHAMENTO\nO salão ficou vazio."
   5:
    if app.interface.night_panel!=null:app.interface.night_panel.find_child("NextNight",true,false).pressed.emit()
    else:app.start_saturday();app.interface.set_paused(false)
    app.world.spawn_wait=999;place(CheckoutFixture.CUSTOMER_POSITION+Vector3(0,0,1.2),atan2(2.02,1.5));app.world.saturday.introduce(app.world.player);caption.text="0.29.0 / SÁBADO\nA conversa continua"
 var desired:=0
 match step:
  0:desired=2 if elapsed>=3.0 else 1 if elapsed>=1.6 else 0
  1:desired=3 if elapsed>=8.3 else 2 if elapsed>=7.1 else 1 if elapsed>=5.6 else 0
  3:desired=2 if elapsed>=13.7 else 1 if elapsed>=12.2 else 0
  4:desired=3 if elapsed>=19.9 else 2 if elapsed>=18.4 else 1 if elapsed>=17.1 else 0
  5:desired=1 if elapsed>=24 else 0
 if desired>line:line=desired;press_space()
 for entry in [[2.0,"arrival"],[6.6,"customer"],[10.4,"observer"],[12.6,"reaction"],[18.8,"closing"],[21.8,"summary"],[24.8,"saturday"]]:
  if elapsed>=entry[0] and not captured.has(entry[1]):captured[entry[1]]=true;call_deferred("capture",entry[1])
 var stop_at:=26.5 if OS.get_environment("FRIDAY_STORY_REVIEW_END").is_empty() else float(OS.get_environment("FRIDAY_STORY_REVIEW_END"))
 if elapsed>=stop_at:set_process(false);call_deferred("finish")
func capture(id: String) -> void:
 await RenderingServer.frame_post_draw
 var output:=OS.get_environment("FRIDAY_STORY_REVIEW_PATH")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 print("FRIDAY STORY CAPTURE ",id)
func finish() -> void:
 print("FRIDAY STORY REVIEW ",JSON.stringify({"arrival":app.world.story.done("arrival"),"perceived_observer":app.world.story.noticed("observer_seen"),"reacted":app.world.story.done("remark_observer_seen"),"closing":app.world.story.done("closing_hook"),"saturday":int(Session.campaign.night)==1}))
 Dialogue.clear();app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
