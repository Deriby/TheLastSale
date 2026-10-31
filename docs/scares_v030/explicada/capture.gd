extends Node
## Presentation only: recorded against the unchanged, extracted 0.30.0 project.
var app: Node
var phase:="intro"
var scene:=-1
var clock:=0.0
var total:=0.0
var first_event:=-1.0
var open_pending:=false
var advanced:=0
var black: ColorRect
var band: ColorRect
var title: Label
var detail: Label
var subtitle_panel: ColorRect
var subtitle: Label
var marker: Line2D
var marker_label: Label
var captures: Dictionary={}
var timeline: Array=[]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.fov=80;Preferences.ps1_mode=false;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);app.world.spawn_wait=999;Session.greet();Session.world_seconds=60
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer)
 band=ColorRect.new();layer.add_child(band);band.color=Color(0,0,0,.94);band.size=Vector2(1280,120)
 black=ColorRect.new();layer.add_child(black);black.color=Color.BLACK;black.size=Vector2(1280,720)
 title=Label.new();layer.add_child(title);title.add_theme_font_size_override("font_size",34);title.add_theme_color_override("font_color",Color("f6e4bb"));title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail=Label.new();layer.add_child(detail);detail.add_theme_font_size_override("font_size",25);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 subtitle_panel=ColorRect.new();layer.add_child(subtitle_panel);subtitle_panel.position=Vector2(0,580);subtitle_panel.size=Vector2(1280,140);subtitle_panel.color=Color(0,0,0,.93);subtitle_panel.hide()
 subtitle=Label.new();layer.add_child(subtitle);subtitle.position=Vector2(55,594);subtitle.size=Vector2(1170,120);subtitle.add_theme_font_size_override("font_size",26);subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 marker=Line2D.new();layer.add_child(marker);marker.width=3;marker.default_color=Color("ffcc66");marker.closed=true;marker.hide()
 marker_label=Label.new();layer.add_child(marker_label);marker_label.text="MAÇANETA";marker_label.add_theme_font_size_override("font_size",22);marker_label.add_theme_color_override("font_color",Color("ffcc66"));marker_label.add_theme_color_override("font_shadow_color",Color.BLACK);marker_label.add_theme_constant_override("shadow_offset_x",2);marker_label.add_theme_constant_override("shadow_offset_y",2);marker_label.hide()
 Dialogue.spoken.connect(on_spoken)
 pause_for_card("PRÉVIA EXPLICADA — VERSÃO 0.30", "Três cenas separadas do jogo.\nAssista com som.\nOs títulos e a marcação existem só neste vídeo.")
func stamp(event: String) -> void:
 var record:={"event":event,"scene":scene,"time":total};timeline.append(record);print("CLARITY TIMELINE ",JSON.stringify(record))
func pause_for_card(heading: String,body: String) -> void:
 app.interface.set_paused(true);app.interface.menu.hide();app.interface.hud.hide();black.show();marker.hide();marker_label.hide();subtitle_panel.hide();subtitle.hide()
 title.position=Vector2(90,175);title.size=Vector2(1100,100);title.text=heading
 detail.position=Vector2(90,290);detail.size=Vector2(1100,280);detail.text=body
func place(at: Vector3,yaw: float,pitch: float) -> void:
 var actor: DepotPlayer=app.world.player;actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=yaw;actor.camera_rig.pitch=pitch;actor.camera_rig.reset_follow()
func next_scene() -> void:
 scene+=1;clock=0;first_event=-1;phase="card";stamp("card")
 match scene:
  0:
   place(Vector3(.7,.01,-14.0),atan2(.26,1.75),-.20)
   pause_for_card("1. ESTOQUE — OLHE A MAÇANETA", "Um arrasto vem de trás da porta.\nEle para e, depois de um silêncio, a maçaneta mexe.\nO círculo indica onde olhar.")
  1:
   place(Vector3(-3.1,.01,-2.8),PI,-.12);Session.world_seconds=float(app.world.scary.state().last_event)+40
   pause_for_card("2. VITRINE — UM FALSO SUSTO", "Bryan caminha até a vitrine e dá uma batida.\nÉ uma brincadeira dele, para quebrar a tensão.")
  2:
   app.world.friday.begin_outage();Dialogue.clear();Session.campaign.flags.generator_key=true;Session.campaign.flags.counter_secured=true
   place(Vector3(4.35,.01,-19.4),-PI/2,-.1);app.world.friday.activate("generator",app.world.player);Dialogue.clear()
   Session.world_seconds=float(app.world.scary.state().last_scare)+40;place(Vector3(4.0,.01,-5.7),atan2(-.2,2.8),-.10);open_pending=true
   pause_for_card("3. VOLTA DO GERADOR — A FIGURA", "A câmera agora está mais afastada do corredor.\nUm homem cruza o salão e vai para o estoque.\nDepois, a porta do pátio bate nos fundos.")
  _:
   set_process(false);call_deferred("finish")
func play_scene() -> void:
 phase="play";clock=0;stamp("play");black.hide();app.interface.set_paused(false);app.interface.hud.hide();title.position=Vector2(34,12);title.size=Vector2(1212,48);detail.position=Vector2(34,63);detail.size=Vector2(1212,53)
 match scene:
  0:title.text="1. ESTOQUE";detail.text="Escute o arrasto e observe a maçaneta destacada."
  1:title.text="2. VITRINE";detail.text="Bryan está chegando à vitrine. Espere a batida."
  2:title.text="3. VOLTA DO GERADOR";detail.text="Olhe o corredor à frente: a figura vem da esquerda."
func open_doors() -> void:
 for door in [app.world.depot.stock_door,app.world.depot.service_door]:
  for child in door.get_children():
   if child is Interaction and child.kind=="door" and not child.open and not child.busy:child.activate(app.world.player)
func on_spoken(who: String,text: String) -> void:
 if phase not in ["play","aftermath"] or scene!=2:return
 subtitle_panel.visible=not text.is_empty();subtitle.visible=not text.is_empty();subtitle.text=("Deryk" if who=="Dery" else who)+": "+text
func space() -> void:
 var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
 event=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
func shot(id: String) -> void:
 if captures.has(id):return
 captures[id]=true;call_deferred("capture",id)
func _process(delta: float) -> void:
 clock+=delta;total+=delta
 if total>65:set_process(false);call_deferred("finish");return
 if phase=="intro":
  if clock>3:next_scene()
  return
 if phase=="card":
  if clock>3:play_scene()
  return
 if phase!="play":return
 app.interface.hud.hide()
 match scene:
  0:
   var at: Vector2=app.world.player.camera_rig.camera.unproject_position(app.world.scary.handle.global_position)
   var bounds: Rect2=app.screen.get_global_rect();at=bounds.position+at/Vector2(app.viewport.size)*bounds.size
   marker.points=PackedVector2Array()
   for index in 40:marker.add_point(at+Vector2(cos(index*TAU/40),sin(index*TAU/40))*40)
   marker.show();marker_label.show();marker_label.position=at+Vector2(48,-14)
   var door_phase: String=app.world.scary.state().door_phase
   if door_phase=="quiet":detail.text="O arrasto parou. Agora espere pela maçaneta."
   if door_phase=="handle":detail.text="A maçaneta está girando sozinha.";shot("porta_explicada")
   if door_phase=="done":
    if first_event<0:first_event=clock
    if clock-first_event>1:stamp("end");next_scene()
  1:
   if app.world.scary.done("bryan_prank"):
    if first_event<0:first_event=clock;stamp("tap")
    detail.text="Era o Bryan pregando uma peça. Esse é o falso alívio."
    if clock-first_event>.5:shot("bryan_explicado")
    if clock-first_event>2:stamp("end");next_scene()
  2:
   if open_pending and not app.world.player.motion.action_active:open_doors();open_pending=false
   if app.world.scary.done("return_intruder") and not captures.has("figura_aberta"):
    if first_event<0:first_event=clock;stamp("crossing")
    if clock-first_event>.20:shot("figura_aberta")
   if app.world.scary.done("yard_slam"):detail.text="A batida veio da porta do pátio, nos fundos."
   if app.world.scary.done("return_aftermath"):
    if phase=="play":phase="aftermath";clock=0;stamp("aftermath")
 if phase=="aftermath":return
func _physics_process(_delta: float) -> void:
 if phase!="aftermath":return
 app.interface.hud.hide()
 if clock>1.8 and advanced==0:advanced=1;space()
 if clock>3.4 and advanced==1:advanced=2;space()
 if clock>5.0 and advanced==2:advanced=3;space()
 if clock>7.8:stamp("end");set_process(false);set_physics_process(false);call_deferred("finish")
func capture(id: String) -> void:
 await RenderingServer.frame_post_draw
 var output:=OS.get_environment("CLARITY_REVIEW_PATH")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
func finish() -> void:
 var verified:={"handle":app.world.scary.done("stock_handle"),"bryan":app.world.scary.done("bryan_prank"),"crossing":app.world.scary.done("return_intruder"),"slam":app.world.scary.done("yard_slam"),"aftermath":app.world.scary.done("return_aftermath")}
 print("CLARITY REVIEW ",JSON.stringify({"verified":verified,"timeline":timeline,"duration":total,"fov":80,"hud_hidden_for_explanation":true}))
 Dialogue.clear();get_tree().paused=false;app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
