class_name FieldNotebook
extends PanelContainer
signal closed
var world: ShiftWorld
var current_task:=""
func text(parent: Node,value: String,size:=18) -> Label:
	var label:=Label.new();parent.add_child(label);label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",size);return label
func _ready() -> void:
	name="FieldNotebook";custom_minimum_size=Vector2(760,560);size=custom_minimum_size
	var paper_theme:=Theme.new();paper_theme.default_font=TitlePresentation.TYPEWRITER;paper_theme.default_font_size=17;theme=paper_theme
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",14);add_child(body)
	var header:=HBoxContainer.new();body.add_child(header);text(header,"CADERNO DO EXPEDIENTE",25)
	var close:=Button.new();header.add_child(close);close.name="CloseNotebook";close.text="VOLTAR [J / ESC]";close.pressed.connect(func():closed.emit())
	var scroll:=ScrollContainer.new();body.add_child(scroll);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	var column:=VBoxContainer.new();scroll.add_child(column);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",16)
	text(column,Session.night_title()+" / "+Session.clock_text(),16).modulate=Color("c4b18b")
	text(column,"AGORA",21);var task:=text(column,current_task);task.name="CurrentTask"
	if int(Session.campaign.night)==0:
		text(column,"REPOSIÇÃO / FECHAMENTO",21)
		for job in [["stock_1","R1 — geladeira G1"],["stock_2","R2 — geladeira G1"],["stock_shelf","R3 — salgadinhos da prateleira P1 (extra)"]]:
			text(column,("[x] " if job[0] in Session.stocked else "[ ] ")+job[1],17)
		text(column,("[x] " if Session.organized else "[ ] ")+"CASCOS VAZIOS — palete DEVOLUÇÕES no estoque",17)
		text(column,"Caixas laranja VENDA pertencem aos pedidos do caixa. Entregue a da numeração atual na marca do balcão. Na geladeira: E abre, E novamente repõe.",16)
	if int(Session.campaign.night)==1:text(column,world.saturday.journal(),16)
	if int(Session.campaign.night)==2:text(column,Session.campaign_objective(),17)
	text(column,"OBSERVAÇÕES",21)
	var notes: Array=Session.campaign.experience.notes
	if notes.is_empty():text(column,"Por enquanto, só mais um expediente.",17)
	for entry in notes:
		if not entry is Dictionary:continue
		text(column,["SEX","SÁB","DOM"][clampi(int(entry.get("night",0)),0,2)]+" "+str(entry.get("time",""))+" — "+str(entry.get("text","")),17)
	text(column,"CONTROLES",21)
	text(column,"WASD mover · MOUSE olhar · RODA aproximar/afastar entre primeira e terceira pessoa\nE interagir · Q apoiar caixa · TAB trocar Deryk/Felps · SHIFT correr · CTRL agachar\nF lanterna · C câmeras/terminal no caixa · H acompanhar/aguardar · ESPAÇO continuar fala\nJ caderno · ESC pausa. As escolhas da investigação continuam no caderno do caixa [C].",16)
	close.grab_focus()
