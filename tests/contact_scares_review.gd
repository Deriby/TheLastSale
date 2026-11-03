extends Node
## Real encounter code and physical pursuer; campaign prerequisites staged between clips.
var app: Node
var world: ShiftWorld
var caption: Label
var output:=""
var clips: Array=[]
func _ready() -> void:process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func wait(seconds: float) -> void:await get_tree().create_timer(seconds,true,false,true).timeout
func frames(count: int=4) -> void:
 for frame in count:await get_tree().process_frame
func place(at: Vector3,yaw: float,distance: float=0) -> void:
 world.player.position=at;world.player.velocity=Vector3.ZERO;world.player.reset_physics_interpolation()
 var rig:=world.player.camera_rig;rig.yaw=yaw;rig.pitch=-.12;rig.target_distance=distance;rig.distance=distance;rig.arm.spring_length=distance;rig.camera.position.z=distance;rig.reset_follow()
func boot(night: int=0) -> void:
 Dialogue.clear();app.interface.close_campaign(false);app.interface.set_paused(false);app.interface.hud.hide();Session.new_shift()
 if night==1:Session.advance_to_saturday()
 elif night==2:Session.advance_to_sunday()
 app.build_world();world=app.world;world.active=false;world.spawn_wait=999;Session.greet();Dialogue.clear();Session.world_seconds=400
 world.presence.state().next_at=99999;world.scary.state().door_phase="done";world.scary.state().prank={"phase":"done"};world.scary.state().events.stock_handle=true;world.scary.state().events.bryan_prank=true;world.horror.state().quiet_until=0
func open_door(door: Node3D) -> void:
 for child in door.get_children():
  if child is Interaction and child.kind=="door":child.open=true;child.busy=false
 door.rotation.y=1.45 if door==world.depot.service_door else -1.45
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
func ambush(id: String) -> void:
 var saturday:=id=="stock_corner";boot(1 if saturday else 0)
 Session.campaign.phase="closing" if saturday else "restored";Session.campaign.flags.generator_running=true;Session.campaign.flags.door_attempt=saturday;world.friday.apply_power()
 open_door(world.depot.stock_door if saturday else world.depot.service_door)
 place(Vector3(4.85,.01,-11.8 if saturday else -17.3),PI);await frames(5)
 caption.text="2 / NOVO ENCONTRO NA SAÍDA DO ESTOQUE\nNo fechamento do sábado, depois da tentativa de entrada." if saturday else "1 / NOVA EMBOSCADA NA VOLTA DO GERADOR\nO rosto surge por trás do batente quando você volta para a loja."
 world.active=true
 for frame in 120:
  await frames(1)
  if bool(world.encounters.state().used.get(id,false)):break
 var occurred: bool=world.encounters.state().used.get(id,false)
 await wait(.24);await shot(id)
 clips.append({"event":id,"new_event":true,"occurred":occurred,"focus":world.player.camera_rig.focusing(),"impact":world.horror.impact_weight(),"third_person":false,"camera_distance":world.player.camera_rig.target_distance})
 await wait(1.55)
func bryan() -> void:
 boot();world.scary.state().events.erase("bryan_prank");world.scary.state().prank={"phase":"hidden","time":0.0,"revision":41};world.scary.bryan.position=FridayScares.BRYAN_HIDE;world.scary.bryan.reset_physics_interpolation();world.scary.bryan.scare_pose="crouch_idle";place(Vector3(-2.7,.01,-13.2),0);await frames(5)
 caption.text="3 / BRYAN ESCONDIDO NAS CAIXAS\nEle sai do esconderijo e avança de verdade. Sem interação no vidro."
 world.active=true
 for frame in 140:
  await frames(1)
  if world.scary.done("bryan_prank"):break
 await wait(.42);await shot("bryan_boxes")
 var face_pixel: Vector2=world.player.camera_rig.camera.unproject_position(world.horror.tracked_face())/app.viewport.get_visible_rect().size
 clips.append({"event":"bryan_boxes","new_event":false,"occurred":world.scary.done("bryan_prank"),"focus":world.player.camera_rig.focusing(),"impact":world.horror.impact_weight(),"third_person":false,"camera_distance":world.player.camera_rig.target_distance,"distance_m":world.player.position.distance_to(world.scary.bryan.position),"face_screen":[face_pixel.x,face_pixel.y]})
 await wait(1.70)
func capture(third: bool=false) -> void:
 boot(2);world.sunday.begin_escape();Dialogue.clear();world.sunday.state().generator_mode="stock";Session.campaign.flags.generator_running=true;world.sunday.apply_scene()
 var killer:=world.sunday.killer;killer.grace=999;var x:=.7 if third else 4.8;place(Vector3(x,.01,-13.5 if third else -13.0),0,1.92 if third else 0)
 killer.position=Vector3(x,.01,-15.8 if third else -15.3);killer.visual.rotation.y=0;killer.mode="chase";killer.target_identity="Dery";killer.goal=world.player.position;killer.last_seen=world.player.position;killer.reset_physics_interpolation();await frames(5)
 caption.text="5 / RODINHA PRESERVADA\nA mesma captura em terceira pessoa, com a distância escolhida." if third else "4 / O ASSASSINO ALCANÇA O JOGADOR\nPerseguidor físico, avanço dos braços, impacto e derrota recuperável."
 killer.grace=0;world.active=true
 for frame in 150:
  await frames(1)
  if world.horror.capture_age>.20 or app.interface.campaign_panel!=null:break
 await shot("capture_third" if third else "capture_first")
 clips.append({"event":"capture_third" if third else "capture_first","new_event":false,"occurred":world.horror.capture_age>=0,"focus":world.player.camera_rig.focusing(),"impact":world.horror.impact_weight(),"third_person":not world.player.camera_rig.first_person,"camera_distance":world.player.camera_rig.target_distance})
 await wait(1.35)
func run() -> void:
 output=OS.get_environment("CONTACT_REVIEW_PATH")
 if output.is_empty():output="/tmp/contact-review"
 DirAccess.make_dir_recursive_absolute(output)
 Preferences.camera_distance=0;Preferences.ps1_mode=false;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.fov=68;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);app.interface.hud.hide()
 var layer:=CanvasLayer.new();layer.layer=20;add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(24,20);caption.add_theme_font_size_override("font_size",20);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_y",2)
 if "bryan" in OS.get_cmdline_user_args():await bryan()
 else:await ambush("generator_return");await ambush("stock_corner");await bryan();await capture();await capture(true)
 print("CONTACT REVIEW ",JSON.stringify({"clips":clips,"actual_game_rendering":true,"speed":1,"campaign_conditions_staged":true,"pixel_scale":Preferences.pixel_scale,"fov":Preferences.fov}))
 Dialogue.clear();get_tree().paused=false;world.sound.stop_all();await wait(.25);app.queue_free();await frames(6);await wait(.25)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 get_tree().quit(0 if clips.all(func(item):return item.occurred and item.focus and item.impact>.10) else 1)
