class_name SundayDesk
extends RetroDesktop
var video: VideoStreamPlayer
var message: Label
var information: Label
var analyze: Button
var playback: ProgressBar
var playback_time: Label
var pause_button: Button
var outcome: ProgressBar
var outcome_time:=0.0
var elapsed:=0.0
var watched:=false
var paused_before_minimize:=false
func _ready() -> void:
 name="SundayDesk"
 var column:=build_desktop("Depósito • Arquivos e recuperação","Arquivo recuperado",[{"title":"Arquivo DVR","icon":"monitor","callback":func():dismiss_document();restore_app()},{"title":"Documentos","icon":"folder","callback":func():show_document("CADASTRO.TXT – Bloco de notas",information.text)}])
 var location:=PanelContainer.new();column.add_child(location);location.add_theme_stylebox_override("panel",style(Color.WHITE,Color("a0adbb"),0));text(location,"Endereço    DVR (D:)  ›  Manutenção  ›  Quarta-feira",13)
 var work:=HBoxContainer.new();column.add_child(work);work.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var explorer:=VBoxContainer.new();work.add_child(explorer);explorer.custom_minimum_size.x=165
 text(explorer,"Arquivos do DVR",19);text(explorer,"ESTAÇÃO 01
└ DVR (D:)
   └ Manutenção",14)
 var file:=button(explorer,"ArchiveFile","CAM03_QUA.OGV",recover);file.tooltip_text="Reproduzir o fragmento recuperado";file.custom_minimum_size.y=40
 button(explorer,"OpenDocument","CADASTRO.TXT",func():show_document("CADASTRO.TXT – Bloco de notas",information.text))
 text(explorer,"Arquivo de quarta-feira.\nAs imagens não são ao vivo.",13)
 var viewer:=VBoxContainer.new();work.add_child(viewer);viewer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var frame:=PanelContainer.new();viewer.add_child(frame);frame.add_theme_stylebox_override("panel",style(Color("101823"),Color("8f9eab"),2));frame.custom_minimum_size=Vector2(480,270);frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
 video=VideoStreamPlayer.new();frame.add_child(video);video.expand=true;video.volume_db=-30;video.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if FileAccess.file_exists("res://assets/video/dvr_wednesday.ogv"):video.stream=load("res://assets/video/dvr_wednesday.ogv")
 video.finished.connect(func():watched=true;playback.value=8;playback_time.text="00:08 / 00:08";refresh())
 playback=ProgressBar.new();viewer.add_child(playback);playback.custom_minimum_size.y=7;playback.show_percentage=false;playback.max_value=8
 var transport:=HBoxContainer.new();viewer.add_child(transport)
 button(transport,"RecoverRecording","▶ Reproduzir",recover)
 pause_button=button(transport,"PauseRecording","Ⅱ Pausar",func():video.paused=not video.paused;pause_button.text="▶ Continuar" if video.paused else "Ⅱ Pausar")
 playback_time=text(transport,"00:00 / 00:08",13);playback_time.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var info_box:=panel(viewer,Color("fffff7"));information=text(scroll_body(info_box),"",13);information.custom_minimum_size.y=60
 var actions:=VBoxContainer.new();work.add_child(actions);actions.custom_minimum_size.x=220
 text(actions,"Operações",19)
 analyze=button(actions,"AnalyzeRecording","Concluir análise",analyze_recording)
 button(actions,"TakeProof","Levar cópia no USB",act.bind("copy"))
 button(actions,"SendProof","Enviar cópia ao contato",act.bind("send"))
 button(actions,"LeaveProof","Deixar somente no DVR",act.bind("leave"))
 text(actions,"Comunicação e acesso",15)
 button(actions,"ContactSunday","Combinar ajuda",act.bind("contact"))
 button(actions,"ReleaseStock","Destravar estoque",act.bind("release"))
 outcome=ProgressBar.new();actions.add_child(outcome);outcome.custom_minimum_size.y=8;outcome.show_percentage=false;outcome.max_value=1;outcome.hide()
 text(actions,"ESC / C fecha o terminal.
TAB volta para Deryk.",13)
 message=text(column,"Selecione o arquivo para reproduzir ou recuperar o fragmento.",13);message.custom_minimum_size.y=34;message.max_lines_visible=2;message.add_theme_color_override("font_color",Color("315478"))
 app_visibility_changed.connect(on_app_visible);Session.changed.connect(refresh);refresh()
func refresh() -> void:
 if information==null:return
 find_child("OpenDocument",true,false).disabled=not Session.flag("module_delivered")
 find_child("ArchiveFile",true,false).disabled=not Session.flag("module_delivered") or video.stream==null or Session.flag("proof_destroyed")
 status_text.text="Circuito: "+str({"off":"desligado","stock":"estoque","salon":"salão"}[world.sunday.state().generator_mode])+"  •  ESC / C sair  •  TAB trocar"
 information.text="Módulo entregue. O fragmento é de quarta-feira: o cliente de boné acompanha um homem até o acesso de manutenção. O homem foi dado como desaparecido. O cadastro liga o cliente ao antigo serviço de manutenção." if Session.flag("clip_reviewed") else "Fragmento de quarta-feira encontrado. Reproduza e analise o arquivo." if Session.flag("module_delivered") else "Índice ausente. Deryk precisa recolher o módulo na manutenção antiga e entregá-lo no balcão."
 information.text+="\nArquivo: "+("analisado" if Session.flag("clip_reviewed") else "pendente")+" • Prova: "+str({"recorder":"só no gravador","carried":"USB com Felps","offsite":"cópia fora do depósito"}.get(world.sunday.state().proof,"pendente"))
 analyze.disabled=not watched or Session.flag("clip_reviewed")
 find_child("RecoverRecording",true,false).disabled=not Session.flag("module_delivered") or video.stream==null or Session.flag("proof_destroyed")
 find_child("ReleaseStock",true,false).disabled=world.sunday.phase()!="sunday_escape" or world.sunday.state().generator_mode!="stock" or Session.flag("stock_released")
 for id in ["TakeProof","SendProof","LeaveProof"]:find_child(id,true,false).disabled=not Session.flag("clip_reviewed") or Session.flag("proof_destroyed")
func recover() -> void:
 if not Session.flag("module_delivered") or video.stream==null or Session.flag("proof_destroyed"):return
 elapsed=0;watched=false;video.paused=false;playback.value=0;playback_time.text="00:00 / 00:08";pause_button.text="Ⅱ Pausar";video.play();message.text="QUARTA-FEIRA • CAM 03 • Reprodução do arquivo recuperado. O vídeo pode ser revisto.";refresh()
func analyze_recording() -> void:
 if not watched or not world.sunday.review_recording():return
 closed.emit()
 Dialogue.play("sunday_reveal",[["Felps","É o cliente do boné. Ele acompanhou o homem até aquela passagem. Foi a última imagem antes do desaparecimento."],["Dery","O cadastro confirma: ele fazia manutenção aqui. Ainda tinha acesso pelo pátio."],["Felps","Então sexta ele testou a luz. E sábado veio saber onde ficava o gravador."],["Dery","Vamos copiar isso e avisar o responsável. Eu confiro o quadro para liberar a saída; fica no terminal acompanhando."]])
func act(action: String) -> void:
 if world.sunday.desk_action(action):
  outcome_time=.4;outcome.value=0;outcome.show()
  if action=="release":closed.emit();return
  message.text={"copy":"USB com o fragmento e o cadastro guardado com Felps. Se ele sair, a cópia sai junto.","send":"Fragmento enviado ao contato combinado dentro da história. A prova está preservada fora do depósito.","contact":"Responsável avisado. Zirico espera na calçada à direita, perto do primeiro ponto de encontro.","leave":"A prova fica só no gravador. Se o invasor alcançá-lo, poderá destruí-la."}[action]
 else:message.text="Analise a gravação primeiro. Para enviar, combine ajuda antes. Uma cópia já enviada não pode ser desfeita."
 refresh()
func _process(delta: float) -> void:
 desktop_tick(delta)
 pause_button.disabled=not video.is_playing() and not video.paused
 if outcome_time>0:outcome_time=maxf(0,outcome_time-delta);outcome.value=1-outcome_time/.4
 if video.is_playing() and not video.paused:
  playback.value=video.stream_position
  playback_time.text="00:%02d / 00:08"%int(video.stream_position)
  elapsed+=delta
  if elapsed>=2 and not watched:watched=true;refresh()

func on_app_visible(value: bool) -> void:
 if not value:paused_before_minimize=video.paused;video.paused=true
 else:video.paused=paused_before_minimize
