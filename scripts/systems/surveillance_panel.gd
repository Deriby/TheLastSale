class_name SurveillancePanel
extends RetroDesktop
## One live viewport inside the local desktop; event archives remain text.
var feed: SubViewport
var camera: Camera3D
var status: Label
var archive: Label
var journal: Label
var feedback: Label
var osd: Label
var synchronization: Control
var pages: Array[Control]=[]
var tabs: Array[Button]=[]
var channel_buttons: Array[Button]=[]
var page:=0
var channel:=0
var frame_wait:=0.0
var signal_time:=0.0
var choice_buttons: Dictionary={}
func _ready() -> void:
 name="SurveillancePanel"
 var column:=build_desktop("Depósito • Central de segurança","Central de segurança",[{"title":"Câmeras","icon":"monitor","callback":func():show_page(0)},{"title":"Registros","icon":"folder","callback":func():show_page(1)},{"title":"Caderno","icon":"file","callback":func():show_page(2)}])
 var tab_row:=HBoxContainer.new();column.add_child(tab_row)
 for data in [["LivePage","Monitor ao vivo"],["EventsPage","Registros do DVR"],["JournalPage","Caderno e decisões"]]:
  var index:=tabs.size();var tab:=button(tab_row,data[0],data[1],show_page.bind(index));tab.custom_minimum_size=Vector2(155,32);tabs.append(tab)
 status=text(column,"",13)
 for index in 3:
  var body:=HBoxContainer.new();column.add_child(body);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;pages.append(body)
 var sidebar:=VBoxContainer.new();pages[0].add_child(sidebar);sidebar.custom_minimum_size.x=190
 text(sidebar,"Canais de vídeo",19);text(sidebar,"Depósito / rede local",13)
 for index in SaturdayShift.CAMERAS.size():
  var item:=button(sidebar,"Camera"+str(index),SaturdayShift.CAMERAS[index].name,select_channel.bind(index));item.custom_minimum_size.y=50;item.alignment=HORIZONTAL_ALIGNMENT_LEFT;channel_buttons.append(item)
 text(sidebar,"A imagem acompanha o que acontece na loja.",13)
 var monitor:=VBoxContainer.new();pages[0].add_child(monitor);monitor.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 feed=SubViewport.new();feed.name="SingleSecurityFeed";feed.size=Vector2i(384,216);feed.world_3d=world.get_world_3d();feed.render_target_update_mode=SubViewport.UPDATE_DISABLED;feed.handle_input_locally=false;feed.gui_disable_input=true;feed.msaa_3d=Viewport.MSAA_DISABLED;add_child(feed)
 camera=Camera3D.new();camera.cull_mask=0xfffff ^ 32;camera.fov=76;camera.far=65;camera.current=true;feed.add_child(camera)
 var bezel:=PanelContainer.new();monitor.add_child(bezel);bezel.size_flags_vertical=Control.SIZE_EXPAND_FILL;bezel.custom_minimum_size=Vector2(560,300);bezel.add_theme_stylebox_override("panel",style(Color("111c1b"),Color("707c84"),3))
 var screen:=Control.new();bezel.add_child(screen)
 var picture:=TextureRect.new();screen.add_child(picture);picture.name="CameraImage";picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;picture.texture=feed.get_texture();picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var finish:=ShaderMaterial.new();finish.shader=load("res://shaders/security_camera.gdshader");picture.material=finish
 osd=text(screen,"",15);osd.position=Vector2(12,10);osd.size=Vector2(600,25);osd.add_theme_color_override("font_color",Color("b9efc9"));osd.autowrap_mode=TextServer.AUTOWRAP_OFF;osd.add_theme_font_override("font",load("res://assets/fonts/title/TitleMono.ttf"))
 synchronization=ColorRect.new();screen.add_child(synchronization);synchronization.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);synchronization.color=Color(0.01,.04,.04,.75);synchronization.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var connecting:=text(synchronization,"SINCRONIZANDO CANAL…",18);connecting.set_anchors_and_offsets_preset(Control.PRESET_CENTER);connecting.position=Vector2(-150,-15);connecting.size=Vector2(300,35);connecting.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;connecting.add_theme_color_override("font_color",Color("c0e5cc"))
 text(monitor,"● AO VIVO     Arquivos anteriores: consulte Registros do DVR.",13).autowrap_mode=TextServer.AUTOWRAP_OFF
 var records_body:=panel(pages[1]);archive=text(scroll_body(records_body),"",15)
 var record_actions:=VBoxContainer.new();pages[1].add_child(record_actions);record_actions.custom_minimum_size.x=240;text(record_actions,"Investigar registros",18)
 button(record_actions,"ReviewEvents","Anotar evento dos fundos",func():act("review_events"))
 button(record_actions,"CompareReceipt","Relacionar visita e recibo",func():act("compare_receipt"))
 text(record_actions,"Os eventos anteriores são registros escritos. Não há vídeo recuperado deste trecho.",14)
 var notes:=panel(pages[2]);journal=text(scroll_body(notes),"",15)
 var decisions:=VBoxContainer.new();pages[2].add_child(decisions);decisions.custom_minimum_size.x=290
 text(decisions,"Preparação para domingo",18);text(decisions,"As escolhas ficam salvas e podem ser revistas antes de sair.",13)
 choice_buttons.copy=button(decisions,"CopyEvidence","Copiar registros e recibo",choose.bind("evidence","copy"))
 choice_buttons.recorder=button(decisions,"LeaveEvidence","Deixar só no gravador",choose.bind("evidence","recorder"))
 choice_buttons.contact=button(decisions,"ContactHelp","Avisar o responsável",choose.bind("help","contact"))
 choice_buttons.wait=button(decisions,"WaitHelp","Esperar até amanhã",choose.bind("help","wait"))
 text(decisions,"Prepare a saída usando E no comando das portas, à direita da entrada.",13)
 choice_buttons.unchanged=button(decisions,"SkipExit","Seguir sem preparar",choose.bind("exit","unchanged"))
 feedback=text(column,"Selecione um canal ou consulte os registros.",13);feedback.custom_minimum_size.y=34;feedback.max_lines_visible=2;feedback.add_theme_color_override("font_color",Color("315478"))
 app_visibility_changed.connect(func(_value):sync_feed());document_visibility_changed.connect(func(_value):sync_feed());Session.changed.connect(refresh);select_channel(0);show_page(0)
func sync_feed() -> void:
 var active:=page==0 and not minimized and not (document_panel!=null and document_panel.visible)
 if world.everyday!=null:world.everyday.watched_camera=camera if active else null
 feed.render_target_update_mode=SubViewport.UPDATE_ONCE if active else SubViewport.UPDATE_DISABLED
func show_page(value: int) -> void:
 page=value
 if world.everyday!=null:world.everyday.watched_camera=camera if page==0 and not minimized else null
 for i in pages.size():pages[i].visible=i==page
 sync_feed()
 for index in tabs.size():selected(tabs[index],index==page)
 animate_page(pages[page])
 refresh()
func select_channel(value: int) -> void:
 channel=clampi(value,0,SaturdayShift.CAMERAS.size()-1)
 var data:=SaturdayShift.CAMERAS[channel]
 camera.position=data.at;camera.look_at(data.target);frame_wait=0
 signal_time=.16;synchronization.show()
 for index in channel_buttons.size():selected(channel_buttons[index],index==channel)
 world.saturday.observe_channel(channel)
 refresh()
func refresh() -> void:
 if not is_instance_valid(world) or status==null:return
 status.text=("AO VIVO • "+SaturdayShift.CAMERAS[channel].name+" • SÁBADO "+Session.clock_text()) if page==0 else "ARQUIVO TEXTUAL • EVENTOS E ANOTAÇÕES" if page==1 else "CADERNO • PREPARAÇÃO PARA DOMINGO"
 archive.text="DVR • REGISTRO DE EVENTOS (TEXTO, SEM REPRODUÇÃO DE VÍDEO)\n\n"
 if Session.campaign.records.is_empty():archive.text+="Ainda não há um evento separado para investigar. Conclua os dois atendimentos."
 for record in Session.campaign.records:archive.text+="SÁBADO "+str(record.time)+" • "+str(record.text)+"\n\n"
 archive.text+="\nRECIBOS DO TURNO\n"
 for receipt in Session.receipts:
  archive.text+="#%03d • %s • %s • %s\n"%[int(receipt.id),str(receipt.get("time","sem horário")),str(NPCCast.profile(str(receipt.get("customer",""))).get("label","Cliente")),ShopSale.money(int(receipt.total))]
 archive.text+="\nA visita é posterior ao evento. O recibo documenta a presença do cliente; não prova que ele estava no pátio. Ele mencionou uma porta que não se vê da rua."
 journal.text=world.saturday.journal()
 var enabled: bool=world.saturday.complete_clues() and Session.campaign.phase=="saturday_decisions"
 for item in choice_buttons.values():item.disabled=not enabled
 var review:=find_child("ReviewEvents",true,false) as Button
 if review!=null:review.disabled=not Session.flag("visitor_left")
 var compare:=find_child("CompareReceipt",true,false) as Button
 if compare!=null:compare.disabled=not Session.campaign.clues.get("dvr_service",false)
func act(action: String) -> void:
 if world.saturday.console_action(action):feedback.text="Anotação salva no caderno. Deryk precisa conferir a porta e as caixas no estoque."
 else:feedback.text="Conclua os atendimentos e consulte o evento antes de comparar o recibo."
 refresh()
func choose(key: String,value: String) -> void:
 if world.saturday.decide(key,value):
  var responses: Dictionary={"copy":"Felps copiou os registros e guardou o recibo fora do gravador. A gravação mais antiga ainda precisa ser recuperada domingo.","recorder":"Os registros ficam só no gravador. Domingo, será preciso proteger o equipamento.","contact":"Felps avisou o responsável e combinou uma ligação para domingo. Isso prepara ajuda; não encerra o perigo.","wait":"A dupla vai esperar antes de comunicar a suspeita. Ainda poderá pedir ajuda domingo.","unchanged":"A dupla seguirá sem conferir a saída. Você ainda pode prepará-la antes de encerrar as decisões."}
  feedback.text=responses[value]
 refresh()
func _process(delta: float) -> void:
 desktop_tick(delta)
 signal_time=maxf(0,signal_time-delta);synchronization.visible=signal_time>0
 if page!=0 or minimized or document_panel!=null and document_panel.visible:return
 frame_wait-=delta
 if frame_wait<=0:
  frame_wait=.1;feed.render_target_update_mode=SubViewport.UPDATE_ONCE
  osd.text="CAM %02d  /  %s  /  %s"%[channel+1,SaturdayShift.CAMERAS[channel].name,Session.clock_text()]
  status.text="AO VIVO • "+SaturdayShift.CAMERAS[channel].name+" • SÁBADO "+Session.clock_text()
