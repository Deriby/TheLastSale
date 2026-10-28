class_name ShiftInterface
extends CanvasLayer
signal new_game
signal continue_game
signal pause_changed(value: bool)
var root: Control
var hud: Control
var menu: PanelContainer
var settings: SettingsPanel
var objective: Label
var prompt: Label
var subtitle: Label
var speaker: Label
var clock: Label
var stamina: ProgressBar
var title: Label
var buttons: VBoxContainer
var message: Label
var paused:=true
var has_started:=false
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=5
	root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
	root.theme=make_theme()
	build_hud();build_menu()
	Session.changed.connect(update_objective)
	Dialogue.spoken.connect(on_spoken)
	update_objective()
func make_theme() -> Theme:
	var t:=Theme.new();t.default_font_size=18
	var style:=StyleBoxFlat.new();style.bg_color=Color(.045,.055,.052,.96);style.border_color=Color("675c45");style.set_border_width_all(1);style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=11;style.content_margin_bottom=11
	t.set_stylebox("panel","PanelContainer",style)
	var normal:=style.duplicate();normal.bg_color=Color(.12,.14,.13,.92);normal.border_color=Color("4c5148")
	var hover:=normal.duplicate();hover.bg_color=Color("393e30");hover.border_color=Color("ad9d79")
	t.set_stylebox("normal","Button",normal);t.set_stylebox("hover","Button",hover);t.set_stylebox("focus","Button",hover);t.set_stylebox("pressed","Button",hover)
	t.set_color("font_color","Label",Color("e4decb"));t.set_color("font_color","Button",Color("e4decb"))
	return t
func label(parent: Node,text: String,font_size: int) -> Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_shadow_color",Color.BLACK);l.add_theme_constant_override("shadow_offset_x",1);l.add_theme_constant_override("shadow_offset_y",2);parent.add_child(l);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l
func build_hud() -> void:
	hud=Control.new();root.add_child(hud);hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var top:=VBoxContainer.new();hud.add_child(top);top.position=Vector2(34,30);top.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label(top,"FRANCA / SEXTA-FEIRA",14).modulate=Color("c6b18b")
	clock=label(top,"21:40",25)
	objective=label(top,"",18);objective.custom_minimum_size=Vector2(500,60);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var cross:=label(hud,"·",26);cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);cross.position-=Vector2(4,18)
	prompt=label(hud,"",19);prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);prompt.position=Vector2(-360,-180);prompt.size=Vector2(720,38);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var sub:=VBoxContainer.new();hud.add_child(sub);sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);sub.position=Vector2(-430,-133);sub.size=Vector2(860,125);sub.mouse_filter=Control.MOUSE_FILTER_IGNORE
	speaker=label(sub,"",15);speaker.modulate=Color("c6b18b");speaker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle=label(sub,"",21);subtitle.custom_minimum_size=Vector2(860,80);subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stamina=ProgressBar.new();hud.add_child(stamina);stamina.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);stamina.position=Vector2(34,-45);stamina.size=Vector2(130,5);stamina.show_percentage=false;stamina.max_value=1
	var hint:=label(hud,"WASD mover   SHIFT correr   CTRL agachar   E interagir   Q soltar\nMOUSE olhar   RODA aproximar / primeira pessoa   ESPAÇO avançar fala   ESC pausa",13)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);hint.position=Vector2(-620,-52);hint.size=Vector2(590,45);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hint.modulate=Color("babbaa")
	hud.hide()
func build_menu() -> void:
	menu=PanelContainer.new();root.add_child(menu);menu.position=Vector2(55,80);menu.size=Vector2(480,560)
	var v:=VBoxContainer.new();menu.add_child(v);v.add_theme_constant_override("separation",13)
	label(v,"UM TURNO EM FRANCA, SP",15).modulate=Color("b8a078")
	title=label(v,"A ÚLTIMA\nVENDA",52)
	label(v,"DEPOIS DO FECHAMENTO",17).modulate=Color("b8a078")
	message=label(v,"21h40. O bairro vai dormir.\nPra vocês, ainda é expediente.",18)
	buttons=VBoxContainer.new();v.add_child(buttons);buttons.add_theme_constant_override("separation",9)
	rebuild_buttons()
	label(v,"Demonstração 0.3.1 • Capítulo 1\nFones de ouvido recomendados",13).modulate=Color("9ca58f")
func button(text: String,callback: Callable) -> Button:
	var b:=Button.new();buttons.add_child(b);b.text=text;b.pressed.connect(callback);return b
func rebuild_buttons() -> void:
	for node in buttons.get_children():node.queue_free()
	if has_started:button("RETOMAR",func():set_paused(false))
	else:button("INICIAR EXPEDIENTE",func():new_game.emit();has_started=true;set_paused(false))
	if FileAccess.file_exists(Session.SAVE_PATH):button("CONTINUAR TURNO SALVO",func():continue_game.emit();has_started=true;set_paused(false))
	if has_started:button("SALVAR TURNO",save_current)
	button("CONFIGURAÇÕES",open_settings)
	button("SAIR",func():get_tree().quit())
func save_current() -> void:
	var player:=get_tree().get_first_node_in_group("player") as DepotPlayer
	if player!=null:
		var err:=Session.save_shift(player.global_position)
		message.text="Turno salvo." if err==OK else "Não foi possível salvar o turno."
func set_paused(value: bool) -> void:
	paused=value;get_tree().paused=value
	menu.visible=value;hud.visible=not value
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value:
		title.text="EXPEDIENTE\nEM PAUSA";rebuild_buttons()
	pause_changed.emit(value)
func open_settings() -> void:
	menu.hide();settings=SettingsPanel.new();root.add_child(settings);settings.position=Vector2(355,35)
	settings.closed.connect(func():settings.queue_free();settings=null;menu.show())
func update_objective() -> void:objective.text=Session.objective()
func on_spoken(who: String,text: String) -> void:
	speaker.text=who;subtitle.text=text
func _process(_delta: float) -> void:
	var player:=get_tree().get_first_node_in_group("player") as DepotPlayer
	if player!=null:stamina.value=player.stamina;stamina.visible=player.stamina<.98
	var minutes:=21*60+40+int(Session.world_seconds/8)
	if Session.stage>=5:minutes=maxi(minutes,22*60+35)
	clock.text="%02d:%02d"%[minutes/60%24,minutes%60]
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and has_started:
		if settings!=null:settings.closed.emit()
		else:set_paused(not paused)
		get_viewport().set_input_as_handled()
