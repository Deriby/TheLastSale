extends Node
## Actual engine capture; staged late-Saturday positions, no replacement artwork.
var app: Node
var clock:=0.0
var stage:=-1
var card: ColorRect
var caption: Label
var taken:=false
var face_captured:=false
var output:=""
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.fov=68;Preferences.frame_limit=30;Preferences.ps1_mode=false;Preferences.apply();Session.new_shift();Session.advance_to_saturday()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);app.world.active=true;app.world.spawn_wait=999;Dialogue.clear();Session.world_seconds=420;Session.campaign.phase="saturday_investigation";app.world.presence.state().next_at=99999;app.world.saturday.unease.set_physics_process(false)
 for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.queue_free()
 for child in app.world.depot.stock_door.get_children():
  if child is Interaction and child.kind=="door":child.activate(app.world.player)
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer);card=ColorRect.new();layer.add_child(card);card.size=Vector2(1280,720);card.color=Color.BLACK
 caption=Label.new();layer.add_child(caption);caption.position=Vector2(80,190);caption.size=Vector2(1120,350);caption.add_theme_font_size_override("font_size",30);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.text="0.32.0 — NA VOLTA, ALGUMA COISA MUDOU\n\nVestígios e sons nos fundos. Uma presença no vidro.\nCenas separadas; intervalos cortados nesta prévia."
 output=OS.get_environment("SATURDAY_UNEASE_REVIEW_PATH")
func place(at: Vector3,target: Vector3,pitch: float) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=atan2(-(target.x-at.x),-(target.z-at.z));actor.camera_rig.pitch=pitch;actor.camera_rig.reset_follow()
func next_stage() -> void:
 stage+=1;clock=0;taken=false
 var world: ShiftWorld=app.world
 card.hide();caption.position=Vector2(25,20);caption.size=Vector2(1190,40);caption.add_theme_font_size_override("font_size",19)
 match stage:
  0:
   place(Vector3(3.1,.01,-13.7),Vector3(4.7,0,-15.5),-.72);caption.text="1 / Fundos: marcas discretas perto da porta trancada."
  1:
   place(Vector3(1.0,.01,-12.9),world.saturday.board.position,-.50);caption.text="2 / Caixa e marca no pó: antes de sair dos fundos."
  2:
   world.saturday.unease.state().shifted=true;world.saturday.unease.apply_board_shift();caption.text="3 / Voltando depois: a caixa mudou; a marca no pó ficou."
  3:
   place(Vector3(3.5,.01,-13.9),Vector3(4.8,0,-16.5),-.12);caption.text="4 / Dois passos no pátio, do outro lado da porta. Use fones."
   world.sound.play_spatial("res://assets/audio/step_tile.wav",SaturdayUnease.FOOT_A,-18,true)
  4:
   place(Vector3(1.0,.01,-13.4),Vector3(.65,0,-16.18),-.1);caption.text="5 / Um tecido roça atrás da porta velha. Ninguém atravessa a loja."
   world.sound.play_spatial("res://assets/audio/saturday/cloth_brush.ogg",SaturdayUnease.CLOTH,-17,true)
  5:
   var event: SaturdayUnease=world.saturday.unease
   var at:=event.car.to_global(Vector3(.35,0,2.4));at.y=Street.surface_height(at.x,at.z)+.01
   place(at,event.window_point(),-.15);caption.text="6 / Carro já estacionado: o rosto aparece só por um instante ao virar."
   world.player.camera_rig.yaw+=1.1;world.player.camera_rig.reset_follow();event.spawn_face()
  6:set_process(false);call_deferred("finish")
func _process(delta: float) -> void:
 clock+=delta;app.interface.hud.hide()
 if stage<0:
  if clock>2:next_stage()
  return
 if stage==3 and clock>.48 and not taken:taken=true;app.world.sound.play_spatial("res://assets/audio/step_tile.wav",SaturdayUnease.FOOT_B,-18,true)
 if stage==5:
  if clock>.7 and clock<1.2:
   var actor: DepotPlayer=app.world.player;var point: Vector3=app.world.saturday.unease.window_point()
   var target:=atan2(-(point.x-actor.position.x),-(point.z-actor.position.z))
   actor.camera_rig.yaw=lerp_angle(target+1.1,target,smoothstep(.7,1.2,clock))
  var figure: CarWindowPresence=app.world.saturday.unease.figure
  if is_instance_valid(figure) and figure.phase=="holding" and not taken:taken=true;face_captured=true;call_deferred("shot","window")
 elif stage!=3 and clock>.8 and not taken:taken=true;call_deferred("shot","scene_"+str(stage))
 if clock> (4.2 if stage==5 else 2.6):next_stage()
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 print("UNEASE SHOT ",id)
func finish() -> void:
 print("UNEASE REVIEW notes=",Session.campaign.experience.notes.size()," dialogue=",Dialogue.active," face_captured=",face_captured)
 app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
