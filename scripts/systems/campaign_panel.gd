class_name CampaignPanel
extends PanelContainer
signal cancel
signal escape(alone: bool)
signal retry
signal restart
var world: ShiftWorld
var kind:="escape"
var aftermath: VBoxContainer
var epilogue: VBoxContainer
var air: AudioStreamPlayer
var reveal_age:=0.0
var reading_scroll: ScrollContainer
func text(parent: Node,value: String,size:=20) -> Label:
	return GamePanels.label(parent,value,size,Color("ece7d5"),TitlePresentation.DISPLAY if size>=30 else null)
func button(parent: Node,id: String,title: String,callback: Callable) -> Button:
	return GamePanels.button(parent,id,title,callback,id in ["EscapeTogether","RetrySunday","RestartCampaign"])
func _ready() -> void:
	name="CampaignPanel";custom_minimum_size=Vector2(800,560);size=custom_minimum_size;theme=GamePanels.theme()
	if kind!="ending":GamePanels.enter(self)
	var scroll:=ScrollContainer.new();reading_scroll=scroll;add_child(scroll);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	var body:=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",15)
	match kind:
		"escape":
			GamePanels.label(body,"DOMINGO / CONFIRMAÇÃO DE SAÍDA",13,GamePanels.GOLD,GamePanels.MONO);GamePanels.rule(body)
			text(body,"A SAÍDA ESTÁ AQUI",30)
			var together:=world.sunday.together_at_exit()
			text(body,"Os dois chegaram. Você pode encerrar a fuga junto do companheiro." if together else "Seu companheiro ainda está no depósito ou no caminho. Sair agora encerra a campanha sem resgatá-lo.")
			var departing: Array[String]=[];departing.assign(["Dery","Felps"] if together else [world.player.identity])
			var proof_text:="Prova preservada: sim" if world.sunday.proof_preserved(departing) else "Prova preservada: não. Sem uma cópia, o caso ficará aberto."
			if not together and world.sunday.state().proof=="carried" and str(world.sunday.state().get("proof_carrier",""))!=world.player.identity:proof_text="Prova com o companheiro: reúna a dupla para levá-la."
			text(body,proof_text,18)
			var both:=button(body,"EscapeTogether","FUGIR COM OS DOIS",func():escape.emit(false));both.disabled=not together
			if not together:button(body,"LeaveAlone","CONFIRMAR: SAIR SEM O COMPANHEIRO",func():escape.emit(true))
			button(body,"CancelEscape","VOLTAR E REUNIR A DUPLA",func():cancel.emit()).grab_focus()
		"defeat":
			GamePanels.label(body,"DOMINGO / ÚLTIMO CHECKPOINT",13,Color("db9a7f"),GamePanels.MONO);GamePanels.rule(body,Color("985e4b"))
			text(body,"A FUGA FOI INTERROMPIDA",30)
			text(body,("Deryk" if world.sunday.caught_identity=="Dery" else "Felps")+" foi alcançado. Isso não é um final da história. Retome o checkpoint no início da fuga e tente outra rota.")
			button(body,"RetrySunday","RETOMAR CHECKPOINT DA FUGA",func():retry.emit()).grab_focus()
			button(body,"QuitDefeat","SAIR • CHECKPOINT SALVO",func():get_tree().quit())
		"ending":
			var container:=body
			aftermath=VBoxContainer.new();container.add_child(aftermath);aftermath.add_theme_constant_override("separation",24)
			aftermath.alignment=BoxContainer.ALIGNMENT_END;aftermath.custom_minimum_size.y=480
			var read_button:=button(aftermath,"ReadEpilogue","LER O RELATO [ENTER]",finish_aftermath)
			read_button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;read_button.grab_focus()
			epilogue=VBoxContainer.new();container.add_child(epilogue);epilogue.add_theme_constant_override("separation",15);body=epilogue
			GamePanels.label(body,"ARQUIVO DO CASO / DEPOIS DO FECHAMENTO",13,GamePanels.GOLD,GamePanels.MONO);GamePanels.rule(body)
			var ending: Dictionary=Session.campaign.ending
			match str(ending.get("id","unresolved")):
				"resolved":
					text(body,"OS DOIS VOLTARAM",31)
					text(body,"Deryk e Felps saíram juntos com a prova preservada. O fragmento, o cadastro e os relatos permitiram identificar o ex-funcionário da manutenção. O acesso antigo foi fechado, e ele foi detido durante a investigação do desaparecimento.")
				"unresolved":
					text(body,"A PORTA FICOU PARA TRÁS",31)
					text(body,"Deryk e Felps conseguiram sair juntos. Sem a gravação preservada, o relato não bastou para esclarecer o desaparecimento. A rotina mudou, o acesso foi fechado, mas o paradeiro do homem continuou sem confirmação.")
				"alone":
					text(body,"SÓ UM VOLTOU",31)
					var survivor: String="Deryk" if "Dery" in ending.get("survivors",[]) else "Felps"
					text(body,survivor+" alcançou a saída e decidiu partir sem reunir o companheiro. O relato foi registrado. Depois daquela madrugada, o destino de quem ficou no depósito permaneceu desconhecido.")
			text(body,"O contato combinado já esperava na rua." if ending.get("help",false) else "A ajuda só foi procurada depois de sair do quarteirão.",18)
			text(body,"A preparação de sábado encurtou a abertura da saída." if ending.get("exit_prepared",false) else "A saída precisou ser aberta manualmente durante a fuga.",18)
			text(body,"FIM • SEXTA / SÁBADO / DOMINGO",18)
			button(body,"RestartCampaign","REINICIAR CAMPANHA",func():restart.emit()).grab_focus()
			button(body,"QuitEnding","SAIR • FINAL SALVO",func():get_tree().quit())
			begin_aftermath()

func begin_aftermath() -> void:
	var saved: Dictionary=world.sunday.climax.state()
	if bool(saved.aftermath_seen):aftermath.hide();reveal_age=1.2;return
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	epilogue.hide();aftermath.get_node("ReadEpilogue").grab_focus()
	air=AudioStreamPlayer.new();add_child(air)
	var stream: AudioStreamWAV=load("res://assets/audio/neighborhood_air.wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=stream.data.size()/2;air.stream=stream
	air.volume_db=-23+linear_to_db(maxf(.001,Preferences.effects_volume));air.play()
	Preferences.changed.connect(refresh_aftermath)
func refresh_aftermath() -> void:
	if is_instance_valid(air):air.volume_db=-23+linear_to_db(maxf(.001,Preferences.effects_volume))
func _input(event: InputEvent) -> void:
	if kind!="ending" or epilogue==null or epilogue.visible:return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_ENTER,KEY_KP_ENTER] or event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER]):
		finish_aftermath();get_viewport().set_input_as_handled()
func finish_aftermath() -> void:
	if epilogue==null or epilogue.visible:return
	var saved: Dictionary=world.sunday.climax.state();saved.aftermath_left=0;saved.aftermath_seen=true
	remove_theme_stylebox_override("panel")
	aftermath.hide();epilogue.show();modulate.a=0;epilogue.get_node("RestartCampaign").grab_focus();reveal_age=0
	Session.save_shift(world.player.position)
	call_deferred("start_reading")
func start_reading() -> void:
	await get_tree().process_frame
	if is_instance_valid(reading_scroll):reading_scroll.scroll_vertical=0
func _process(delta: float) -> void:
	if kind!="ending" or epilogue==null or not is_instance_valid(world) or int(Session.campaign.night)!=2 or Session.campaign.phase!="campaign_complete":return
	if not epilogue.visible:
		var saved: Dictionary=world.sunday.climax.state();saved.aftermath_left=maxf(0,float(saved.aftermath_left)-delta)
		if float(saved.aftermath_left)<=0:finish_aftermath()
	else:
		reveal_age=minf(1.2,reveal_age+delta);modulate.a=smoothstep(0,1.2,reveal_age)
		if is_instance_valid(air):
			air.volume_db=-23+linear_to_db(maxf(.001,Preferences.effects_volume))+linear_to_db(maxf(.001,1-reveal_age/1.2))
			if reveal_age>=1.2:air.stop();air.stream=null
func _exit_tree() -> void:
	if is_instance_valid(air):air.stop();air.stream=null
