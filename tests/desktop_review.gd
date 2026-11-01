extends Node
## Actual terminal interaction, staged campaign prerequisites for visual review.
var app: Node
var clock:=0.0
var stage:=-1
var caption: Label
var card: ColorRect
var taken:=false
var output:=""
var screenshots: Array[String]=[]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.ps1_mode=false;Preferences.apply();Session.new_shift();Session.advance_to_saturday()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);app.world.active=true;app.world.spawn_wait=999;app.world.saturday.introduce(app.world.player);Dialogue.clear();Session.customers_served=2;app.world.saturday.begin_investigation();Dialogue.clear();app.world.select_player("Felps");app.world.player.position=CheckoutFixture.STAFF_POSITION
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer);card=ColorRect.new();layer.add_child(card);card.size=Vector2(1280,720);card.color=Color("102039")
 caption=Label.new();layer.add_child(caption);caption.position=Vector2(80,190);caption.size=Vector2(1120,350);caption.add_theme_font_size_override("font_size",29);caption.text="0.34.0 — O COMPUTADOR DO DEPÓSITO\n\nÁrea de trabalho, janelas e controles no estilo XP.\nCaptura real: câmeras, registros, arquivo e reprodução.\nProgresso da campanha preparado para mostrar as telas."
 output=OS.get_environment("DESKTOP_REVIEW_PATH")
func next_stage() -> void:
 stage+=1;clock=0;taken=false;card.hide();caption.position=Vector2(18,2);caption.size=Vector2(1240,26);caption.add_theme_font_size_override("font_size",16)
 match stage:
  0:app.interface.open_surveillance(app.world);caption.text="1 / Central de segurança: janela animada, canais e imagem ao vivo."
  1:app.interface.surveillance.select_channel(2);caption.text="2 / Troca de câmera com sincronização breve e identificação sobre a imagem."
  2:app.interface.surveillance.show_page(1);caption.text="3 / Registros do DVR em uma janela própria: anotações e recibos."
  3:
   for id in SaturdayShift.REQUIRED:Session.campaign.clues[id]=true
   Session.campaign.phase="saturday_decisions";app.interface.surveillance.show_page(2);app.interface.surveillance.choose("help","contact");caption.text="4 / Caderno e decisões: botões, seleção e informações legíveis."
  4:app.interface.surveillance.minimize_app();app.interface.surveillance.start_menu.show();caption.text="5 / Minimizar revela a área de trabalho e o menu Iniciar. O canal para de renderizar."
  5:
   app.interface.close_surveillance();Session.advance_to_sunday();app.build_world();app.world.active=true;app.world.spawn_wait=999;app.world.sunday.introduce(app.world.player);Dialogue.clear();Session.campaign.flags.module_found=true;Session.campaign.flags.module_delivered=true;app.world.select_player("Felps");app.world.player.position=CheckoutFixture.STAFF_POSITION;app.interface.open_sunday_desk(app.world);app.interface.sunday_desk.recover();caption.text="6 / Arquivo de quarta-feira: player com reprodução, pausa e progresso real."
  6:
   app.interface.sunday_desk.analyze_recording();Dialogue.clear();app.interface.open_sunday_desk(app.world);app.interface.sunday_desk.show_document("CADASTRO.TXT – Bloco de notas",app.interface.sunday_desk.information.text);caption.text="7 / Documento em uma segunda janela, sobre o arquivo recuperado."
  7:app.interface.sunday_desk.dismiss_document();app.interface.sunday_desk.act("copy");caption.text="8 / Operações confirmadas na interface: cópia salva com Felps."
  8:set_process(false);call_deferred("finish")
func _process(delta: float) -> void:
 clock+=delta;app.interface.hud.hide()
 if stage<0:
  if clock>1.4:next_stage()
  return
 if not taken and clock>.9:taken=true;call_deferred("shot",["cameras","patio","registros","caderno","desktop","player","documento","copia"][stage])
 if clock>(3.0 if stage==5 else 2.2):next_stage()
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
 screenshots.append(id);print("DESKTOP SHOT ",id)
func finish() -> void:
 print("DESKTOP REVIEW ",JSON.stringify({"screenshots":screenshots,"proof":app.world.sunday.state().proof,"copy_carrier":app.world.sunday.state().get("proof_carrier",""),"desk_open":app.world.sunday.desk_open}))
 app.interface.close_sunday_desk();app.world.sound.stop_all();app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if screenshots.size()==8 else 1)
