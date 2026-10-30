class_name SundayDesk
extends PanelContainer
signal closed
var world: ShiftWorld
var video: VideoStreamPlayer
var message: Label
var information: Label
var analyze: Button
var elapsed:=0.0
var watched:=false
func text(parent: Node,value: String,size:=18) -> Label:
	var item:=Label.new();parent.add_child(item);item.text=value;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.add_theme_font_size_override("font_size",size);return item
func button(parent: Node,id: String,title: String,callback: Callable) -> Button:
	var item:=Button.new();parent.add_child(item);item.name=id;item.text=title;item.pressed.connect(callback);return item
func _ready() -> void:
	name="SundayDesk";process_mode=Node.PROCESS_MODE_PAUSABLE;custom_minimum_size=Vector2(1080,650);size=custom_minimum_size
	var scroll:=ScrollContainer.new();add_child(scroll);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	var column:=VBoxContainer.new();scroll.add_child(column);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",9)
	var head:=HBoxContainer.new();column.add_child(head);text(head,"DVR • ARQUIVO ANTERIOR À SEXTA",24)
	button(head,"CloseSundayDesk","VOLTAR [ESC / C]",func():closed.emit())
	information=text(column,"",17)
	var work:=HBoxContainer.new();column.add_child(work);work.add_theme_constant_override("separation",16)
	var aspect:=AspectRatioContainer.new();work.add_child(aspect);aspect.custom_minimum_size=Vector2(640,360);aspect.ratio=16.0/9.0
	video=VideoStreamPlayer.new();aspect.add_child(video);video.expand=true;video.volume_db=-30;video.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if FileAccess.file_exists("res://assets/video/dvr_wednesday.ogv"):video.stream=load("res://assets/video/dvr_wednesday.ogv")
	video.finished.connect(func():watched=true;refresh())
	var actions:=VBoxContainer.new();work.add_child(actions);actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_theme_constant_override("separation",8)
	button(actions,"RecoverRecording","RECUPERAR / REPRODUZIR",recover)
	analyze=button(actions,"AnalyzeRecording","CONCLUIR ANÁLISE",analyze_recording)
	button(actions,"TakeProof","LEVAR CÓPIA NO USB",act.bind("copy"))
	button(actions,"ReleaseStock","DESTRAVAR ESTOQUE",act.bind("release"))
	button(actions,"ContactSunday","COMBINAR AJUDA",act.bind("contact"))
	button(actions,"SendProof","ENVIAR CÓPIA AO CONTATO",act.bind("send"))
	button(actions,"LeaveProof","DEIXAR SOMENTE NO DVR",act.bind("leave"))
	message=text(column,"",17);message.modulate=Color("c6b18b")
	Session.changed.connect(refresh);refresh()
func refresh() -> void:
	if information==null:return
	information.text="Módulo entregue. O fragmento é de quarta-feira: o cliente de boné acompanha um homem até o acesso de manutenção. O homem foi dado como desaparecido. O cadastro liga o cliente ao antigo serviço de manutenção." if Session.flag("clip_reviewed") else "Fragmento de quarta-feira encontrado. Reproduza e analise o arquivo." if Session.flag("module_delivered") else "Índice ausente. Deryk precisa recolher o módulo na manutenção antiga e entregá-lo no balcão."
	information.text+="\nArquivo: "+("analisado" if Session.flag("clip_reviewed") else "pendente")+" • Prova: "+str({"recorder":"só no gravador","carried":"USB com Felps","offsite":"cópia fora do depósito"}.get(world.sunday.state().proof,"pendente"))
	analyze.disabled=not watched or Session.flag("clip_reviewed")
	find_child("RecoverRecording",true,false).disabled=not Session.flag("module_delivered") or video.stream==null or Session.flag("proof_destroyed")
	find_child("ReleaseStock",true,false).disabled=world.sunday.phase()!="sunday_escape" or world.sunday.state().generator_mode!="stock" or Session.flag("stock_released")
	for id in ["TakeProof","SendProof","LeaveProof"]:find_child(id,true,false).disabled=not Session.flag("clip_reviewed") or Session.flag("proof_destroyed")
func recover() -> void:
	if not Session.flag("module_delivered") or video.stream==null or Session.flag("proof_destroyed"):return
	elapsed=0;watched=false;video.play();message.text="QUARTA-FEIRA • CAM 03 • Reprodução do arquivo recuperado. O vídeo pode ser revisto.";refresh()
func analyze_recording() -> void:
	if not watched or not world.sunday.review_recording():return
	closed.emit()
	Dialogue.play("sunday_reveal",[["Felps","É o cliente do boné. Ele acompanhou o homem até aquela passagem. Foi a última imagem antes do desaparecimento."],["Dery","O cadastro confirma: ele fazia manutenção aqui. Ainda tinha acesso pelo pátio."],["Felps","Então sexta ele testou a luz. E sábado veio saber onde ficava o gravador."],["Dery","Vamos copiar isso e avisar o responsável. Eu confiro o quadro para liberar a saída; fica no terminal acompanhando."]])
func act(action: String) -> void:
	if world.sunday.desk_action(action):
		if action=="release":closed.emit();return
		message.text={"copy":"USB com o fragmento e o cadastro guardado com Felps. Se ele sair, a cópia sai junto.","send":"Fragmento enviado ao contato combinado dentro da história. A prova está preservada fora do depósito.","contact":"Responsável avisado. Zirico espera na calçada à direita, perto do primeiro ponto de encontro.","leave":"A prova fica só no gravador. Se o invasor alcançá-lo, poderá destruí-la."}[action]
	else:message.text="Analise a gravação primeiro. Para enviar, combine ajuda antes. Uma cópia já enviada não pode ser desfeita."
	refresh()
func _process(delta: float) -> void:
	if video.is_playing():
		elapsed+=delta
		if elapsed>=2 and not watched:watched=true;refresh()
