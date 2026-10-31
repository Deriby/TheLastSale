class_name SurveillancePanel
extends PanelContainer
## One low-resolution live view of the same World3D; archives are labeled text.
signal closed
var world: ShiftWorld
var feed: SubViewport
var camera: Camera3D
var status: Label
var archive: Label
var journal: Label
var feedback: Label
var pages: Array[Control]=[]
var page:=0
var channel:=0
var frame_wait:=0.0
var choice_buttons: Dictionary={}
func text(parent: Node,value: String,font_size:=18) -> Label:
	var item:=Label.new();parent.add_child(item);item.text=value
	item.add_theme_font_size_override("font_size",font_size);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return item
func button(parent: Node,id: String,title: String,callback: Callable) -> Button:
	var item:=Button.new();parent.add_child(item);item.name=id;item.text=title
	item.add_theme_font_size_override("font_size",16);item.pressed.connect(callback);return item
func _ready() -> void:
	name="SurveillancePanel";process_mode=Node.PROCESS_MODE_PAUSABLE
	custom_minimum_size=Vector2(1160,650);size=custom_minimum_size
	var scroll:=ScrollContainer.new();add_child(scroll);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	var column:=VBoxContainer.new();scroll.add_child(column);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10)
	var top:=HBoxContainer.new();column.add_child(top)
	text(top,"DEPÓSITO • SEGURANÇA / FELPS",23)
	button(top,"CloseCameras","VOLTAR [ESC / C]",func():closed.emit())
	var tabs:=HBoxContainer.new();column.add_child(tabs)
	button(tabs,"LivePage","AO VIVO",func():show_page(0))
	button(tabs,"EventsPage","EVENTOS DO DVR",func():show_page(1))
	button(tabs,"JournalPage","CADERNO / DECISÕES",func():show_page(2))
	status=text(column,"",17)
	for i in 3:
		var panel:=VBoxContainer.new();panel.add_theme_constant_override("separation",10);column.add_child(panel);pages.append(panel)
	var channels:=HBoxContainer.new();pages[0].add_child(channels)
	for i in SaturdayShift.CAMERAS.size():
		button(channels,"Camera"+str(i),SaturdayShift.CAMERAS[i].name,select_channel.bind(i))
	feed=SubViewport.new();feed.name="SingleSecurityFeed";feed.size=Vector2i(384,216)
	feed.world_3d=world.get_world_3d();feed.render_target_update_mode=SubViewport.UPDATE_DISABLED
	feed.handle_input_locally=false;feed.gui_disable_input=true;feed.msaa_3d=Viewport.MSAA_DISABLED
	add_child(feed)
	camera=Camera3D.new();camera.cull_mask=0xfffff ^ 32;camera.fov=76;camera.far=65;camera.current=true;feed.add_child(camera)
	var picture:=TextureRect.new();pages[0].add_child(picture);picture.custom_minimum_size=Vector2(768,360)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;picture.texture=feed.get_texture()
	var finish:=ShaderMaterial.new();finish.shader=load("res://shaders/security_camera.gdshader");picture.material=finish
	text(pages[0],"Imagem atual do depósito. Troque o canal para conferir a área.\nO gravador preservou registros escritos do evento anterior; consulte EVENTOS DO DVR.",16)
	archive=text(pages[1],"",18)
	button(pages[1],"ReviewEvents","ANOTAR EVENTO DOS FUNDOS",func():act("review_events"))
	button(pages[1],"CompareReceipt","SEPARAR RECIBO / RELACIONAR VISITA",func():act("compare_receipt"))
	var notebook:=HBoxContainer.new();pages[2].add_child(notebook);notebook.add_theme_constant_override("separation",20)
	var notes:=VBoxContainer.new();notebook.add_child(notes);notes.custom_minimum_size.x=600
	journal=text(notes,"",16)
	var decisions:=VBoxContainer.new();notebook.add_child(decisions);decisions.size_flags_horizontal=Control.SIZE_EXPAND_FILL;decisions.add_theme_constant_override("separation",10)
	text(decisions,"Escolhas salvas para domingo. Você pode revisá-las antes de sair do monitor.\nConversas opcionais ajudam, mas não são obrigatórias para investigar.",16)
	for key in ["evidence","help","exit"]:
		var row:=VBoxContainer.new();decisions.add_child(row);row.add_theme_constant_override("separation",6)
		match key:
			"evidence":
				choice_buttons.copy=button(row,"CopyEvidence","COPIAR REGISTROS E RECIBO",choose.bind("evidence","copy"))
				choice_buttons.recorder=button(row,"LeaveEvidence","DEIXAR SÓ NO GRAVADOR",choose.bind("evidence","recorder"))
			"help":
				choice_buttons.contact=button(row,"ContactHelp","AVISAR O RESPONSÁVEL",choose.bind("help","contact"))
				choice_buttons.wait=button(row,"WaitHelp","ESPERAR ATÉ AMANHÃ",choose.bind("help","wait"))
			"exit":
				text(row,"Para preparar a saída: feche o monitor e use E\nno comando das portas, à direita da entrada.",16)
				choice_buttons.unchanged=button(row,"SkipExit","SEGUIR SEM PREPARAR",choose.bind("exit","unchanged"))
	feedback=text(column,"",17);feedback.modulate=Color("c6b18b")
	Session.changed.connect(refresh);select_channel(0);show_page(0)
func show_page(value: int) -> void:
	page=value
	if world.everyday!=null:world.everyday.watched_camera=camera if page==0 else null
	for i in pages.size():pages[i].visible=i==page
	feed.render_target_update_mode=SubViewport.UPDATE_ONCE if page==0 else SubViewport.UPDATE_DISABLED
	refresh()
func select_channel(value: int) -> void:
	channel=clampi(value,0,SaturdayShift.CAMERAS.size()-1)
	var data:=SaturdayShift.CAMERAS[channel]
	camera.position=data.at;camera.look_at(data.target);frame_wait=0
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
	if page!=0:return
	frame_wait-=delta
	if frame_wait<=0:
		frame_wait=.1;feed.render_target_update_mode=SubViewport.UPDATE_ONCE
		status.text="AO VIVO • "+SaturdayShift.CAMERAS[channel].name+" • SÁBADO "+Session.clock_text()
