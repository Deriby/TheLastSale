extends Node
## Staged campaign conditions between clips; real event logic, normal playback speed.
var app: Node
var world: ShiftWorld
var caption: Label
var output:=""
var results: Array=[]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func wait(seconds: float) -> void:await get_tree().create_timer(seconds,true,false,true).timeout
func frames(count: int=4) -> void:
 for i in count:await get_tree().process_frame
func place(at: Vector3,yaw: float) -> void:
 world.player.position=at;world.player.velocity=Vector3.ZERO;world.player.reset_physics_interpolation();world.player.camera_rig.yaw=yaw;world.player.camera_rig.pitch=-.10;world.player.camera_rig.reset_follow()
func boot(saturday: bool=false) -> void:
 Dialogue.clear();Session.new_shift()
 if saturday:Session.advance_to_saturday()
 app.build_world();world=app.world;world.spawn_wait=999;world.active=false;Session.greet();Dialogue.clear();Session.world_seconds=300
 Session.campaign.phase="saturday_investigation" if saturday else "routine"
 world.presence.state().next_at=99999;world.scary.state().door_phase="done";world.horror.state().quiet_until=0
 if saturday:world.saturday.unease.set_physics_process(false)
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 if not output.is_empty():get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
func run() -> void:
 output=OS.get_environment("HORROR_REVIEW_PATH")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
 Preferences.camera_distance=0;Preferences.ps1_mode=false;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.fov=68;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);app.interface.hud.hide()
 var layer:=CanvasLayer.new();layer.layer=20;add_child(layer)
 caption=Label.new();layer.add_child(caption);caption.position=Vector2(24,20);caption.size=Vector2(1200,68);caption.add_theme_font_size_override("font_size",22);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
 caption.text="0.38.0 / SUSTOS COM DIREÇÃO\nCinco cenas do jogo real, em tempo normal. Condições preparadas entre cenas."
 await wait(2)
 boot();world.scary.state().door_phase="";Session.world_seconds=60;world.everyday.state().events.empty_chime=true;place(Vector3(.7,.01,-14.0),PI/2);await frames();world.active=true
 caption.text="1 / ESTOQUE\nO arrasto para. A câmera mostra a maçaneta mexendo."
 await wait(2.3);await shot("macaneta");results.append({"event":"handle","occurred":world.scary.done("stock_handle"),"focus":world.player.camera_rig.focusing()});await wait(3)
 boot();world.scary.state().events.stock_handle=true;world.scary.state().prank={"phase":"hidden","time":0.0,"revision":38};world.scary.bryan.position=FridayScares.BRYAN_HIDE;world.scary.bryan.reset_physics_interpolation();world.scary.bryan.scare_pose="crouch_idle";place(Vector3(-2.7,.01,-13.2),0);await frames(8);world.active=true
 caption.text="2 / A PEÇA DO BRYAN\nEle se esconde nas caixas e assusta Deryk quando sai."
 for i in 180:
  await frames(1)
  if world.scary.done("bryan_prank"):break
 await wait(.3);await shot("bryan");results.append({"event":"bryan","occurred":world.scary.done("bryan_prank"),"focus":world.player.camera_rig.focusing()});await wait(4)
 boot();world.characters.Felps.position=Vector3(-18,.01,1.8);world.characters.Felps.reset_physics_interpolation()
 for person in get_tree().get_nodes_in_group("familiar_npcs"):person.queue_free()
 for child in world.depot.stock_door.get_children():
  if child is Interaction and child.kind=="door" and not child.open:child.activate(world.player)
 place(Vector3(.5,.01,-12.2),PI);await frames(20);world.active=true
 caption.text="3 / O ASSASSINO ORIGINAL\nEsta aparição ganha foco. Só a cabeça fica exposta."
 world.presence.create(world.presence.sites[11],1.45,{},true);await wait(1);await shot("cabeca");results.append({"event":"head","occurred":bool(world.presence.state().get("directed_seen",false)),"focus":world.player.camera_rig.focusing()});await wait(3.5)
 boot(true);var unease:=world.saturday.unease;unease.state().entered=100;unease.state().steps=true;unease.state().cloth=true;unease.state().shifted=true;unease.state().last_sound=100;unease.state().quiet_until=0;unease.state().head_quiet=0;unease.apply_board_shift()
 var at:=unease.car.to_global(Vector3(.35,0,2.4));at.y=Street.surface_height(at.x,at.z)+.01
 var point:=unease.window_point();place(at,atan2(-(point.x-at.x),-(point.z-at.z))+PI);await frames(6);world.active=true;unease.set_physics_process(true)
 caption.text="4 / ROSTO NO VIDRO\nSó acontece perto do carro. A câmera mostra onde ele apareceu."
 await wait(1.5);await shot("vidro");results.append({"event":"car","occurred":bool(unease.state().face_used),"focus":world.player.camera_rig.focusing()});await wait(3.5)
 boot(true);world.horror.state().terminal_seen=true;place(Vector3(4.2,.01,-7.7),PI/2);await frames(6);world.active=true
 caption.text="5 / DEPOIS DO COMPUTADOR\nAo voltar aos fundos, a porta está entreaberta. O foco mostra a mudança."
 await wait(.7);await shot("porta");results.append({"event":"ajar","occurred":bool(world.horror.state().get("stock_ajar",false)),"focus":world.player.camera_rig.focusing()});await wait(4)
 print("HORROR REVIEW ",JSON.stringify(results));Dialogue.clear();world.sound.stop_all();await wait(.25);app.queue_free();await frames(6);await wait(.25)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 get_tree().quit(0 if results.all(func(item):return item.occurred and item.focus) else 1)
