class_name CampaignPanel
extends PanelContainer
signal cancel
signal escape(alone: bool)
signal retry
signal restart
var world: ShiftWorld
var kind:="escape"
func text(parent: Node,value: String,size:=20) -> Label:
	var item:=Label.new();parent.add_child(item);item.text=value;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.add_theme_font_size_override("font_size",size);return item
func button(parent: Node,id: String,title: String,callback: Callable) -> Button:
	var item:=Button.new();parent.add_child(item);item.name=id;item.text=title;item.pressed.connect(callback);return item
func _ready() -> void:
	name="CampaignPanel";custom_minimum_size=Vector2(760,520);size=custom_minimum_size
	var scroll:=ScrollContainer.new();add_child(scroll);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	var body:=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",15)
	match kind:
		"escape":
			text(body,"A SAÍDA ESTÁ AQUI",30)
			var together:=world.sunday.together_at_exit()
			text(body,"Os dois chegaram. Você pode encerrar a fuga junto do companheiro." if together else "Seu companheiro ainda está no depósito ou no caminho. Sair agora encerra a campanha sem resgatá-lo.")
			text(body,"Prova preservada: "+("sim" if world.sunday.proof_preserved(["Dery","Felps"]) else "não. Os dois podem sobreviver, mas o caso ficará aberto."),18)
			var both:=button(body,"EscapeTogether","FUGIR COM OS DOIS",func():escape.emit(false));both.disabled=not together
			if not together:button(body,"LeaveAlone","CONFIRMAR: SAIR SEM O COMPANHEIRO",func():escape.emit(true))
			button(body,"CancelEscape","VOLTAR E REUNIR A DUPLA",func():cancel.emit()).grab_focus()
		"defeat":
			text(body,"A FUGA FOI INTERROMPIDA",30)
			text(body,("Deryk" if world.sunday.caught_identity=="Dery" else "Felps")+" foi alcançado. Isso não é um final da história. Retome o checkpoint no início da fuga e tente outra rota.")
			button(body,"RetrySunday","RETOMAR CHECKPOINT DA FUGA",func():retry.emit()).grab_focus()
			button(body,"QuitDefeat","SAIR • CHECKPOINT SALVO",func():get_tree().quit())
		"ending":
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
