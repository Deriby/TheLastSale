extends Node
## Separate real-engine views of Friday's guidance; no tasks are auto-completed.
var app: Node
var clock:=0.0
var stage:=-1
var caption: Label
var card: ColorRect
var taken:=false
var advanced:=false
var quiet_marker_seen:=false
var output:=""
var shots: Array[String]=[]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.fov=68;Preferences.ps1_mode=false;Preferences.immersive_hud=true;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);app.world.active=true;app.world.spawn_wait=999;Session.greet();Dialogue.clear();app.interface.hud_seconds=40;app.interface.character_remaining=0;app.interface.objective_remaining=0;app.world.presence.state().next_at=99999
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer);card=ColorRect.new();layer.add_child(card);card.size=Vector2(1280,720);card.color=Color("14201b")
 caption=Label.new();layer.add_child(caption);caption.position=Vector2(80,190);caption.size=Vector2(1120,350);caption.add_theme_font_size_override("font_size",29);caption.text="0.35.0 — ORIENTAÇÃO PELO CENÁRIO\n\nEtiquetas, lugares e uma lista no balcão.\nA orientação aparece quando você consulta.\nTrechos separados; posições preparadas para revisão."
 output=OS.get_environment("GUIDANCE_REVIEW_PATH")
func place(at: Vector3,target: Vector3) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=atan2(-(target.x-at.x),-(target.z-at.z));actor.camera_rig.pitch=atan2(target.y-at.y-1.6,Vector2(target.x-at.x,target.z-at.z).length());actor.camera_rig.reset_follow()
func next_stage() -> void:
 stage+=1;clock=0;taken=false;advanced=false;card.hide();caption.position=Vector2(300,8);caption.size=Vector2(950,48);caption.add_theme_font_size_override("font_size",18)
 match stage:
  0:
   place(Vector3(4.85,.01,-9.25),Vector3(4.5,1.7,-11));caption.text="1 / A porta ESTOQUE é a referência para chegar às caixas."
  1:
   place(Vector3(1,.01,-12.25),Vector3(1,.29,-13.5));caption.text="2 / R1 e R2: códigos impressos nas caixas, sem nomes flutuando."
  2:
   place(Vector3(-3.7,.01,-4.8),app.world.supplies.boards.G1.global_position);caption.text="3 / G1: placa física na primeira geladeira da parede esquerda."
  3:
   place(Vector3(-3.7,.01,-5.3),app.world.supplies.boards.P1.global_position);caption.text="4 / P1: identificação junto dos salgadinhos. R3 é reposição extra."
  4:
   place(Vector3(-3.05,.01,-2.12),app.world.supplies.shift_sheet.global_position);caption.text="5 / A lista fica presa ao balcão e pode ser consultada com E."
  5:
   app.world.supplies.read_shift_sheet(app.world.player);caption.text="6 / Só quando você consulta: uma orientação curta de Felps."
  6:
   Dialogue.clear();app.interface.open_journal();caption.text="7 / J continua mostrando o objetivo completo e as referências dos lugares."
  7:
   app.interface.close_journal();Preferences.immersive_hud=false;Preferences.apply();app.world.supplies.refresh();place(Vector3(4.85,.01,-9.25),Vector3(1,1,-13.5));caption.text="8 / Quem preferir pode manter as indicações completas nas configurações."
  8:set_process(false);call_deferred("finish")
func _process(delta: float) -> void:
 clock+=delta
 if stage<0:
  if clock>1.4:next_stage()
  return
 if stage<6:quiet_marker_seen=quiet_marker_seen or app.interface.supply_marker.visible
 if stage==5 and clock>.45 and not advanced:advanced=true;Dialogue.next_line()
 if not taken and clock>1.0:taken=true;call_deferred("shot",["estoque","caixas","g1","p1","lista","consulta","caderno","completo"][stage])
 if clock>(3.0 if stage==6 else 2.4):next_stage()
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 shots.append(id);print("GUIDANCE SHOT ",id)
func finish() -> void:
 print("GUIDANCE REVIEW ",JSON.stringify({"shots":shots,"quiet_marker_seen":quiet_marker_seen,"stage":Session.stage,"stocked":Session.stocked,"organized":Session.organized}))
 Dialogue.clear();app.world.sound.stop_all();app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if shots.size()==8 and not quiet_marker_seen else 1)
