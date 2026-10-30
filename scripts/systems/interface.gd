class_name ShiftInterface
extends CanvasLayer
signal new_game
signal continue_game
signal pause_changed(value: bool)
signal retry_game
signal next_night
var root: Control
var hud: Control
var menu: PanelContainer
var settings: SettingsPanel
var sunday_desk: SundayDesk
var campaign_panel: CampaignPanel
var surveillance: SurveillancePanel
var checkout: CheckoutPanel
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
var character_label: Label
var carry_status: Label
var supply_marker: PanelContainer
var supply_marker_text: Label
var notice_label: Label
var notice_remaining:=0.0
var switch_fade: ColorRect
var fade_tween: Tween
var night_label: Label
var night_panel: PanelContainer
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=5
	root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
	root.theme=make_theme()
	switch_fade=ColorRect.new();root.add_child(switch_fade);switch_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);switch_fade.color=Color(0,0,0,0);switch_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
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
	night_label=label(top,"FRANCA / SEXTA-FEIRA",14);night_label.modulate=Color("c6b18b")
	clock=label(top,"21:40",25)
	character_label=label(top,"DERYK • REPOSIÇÃO   [TAB] FELPS",15);character_label.modulate=Color("c6b18b")
	objective=label(top,"",18);objective.custom_minimum_size=Vector2(500,60);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var cross:=label(hud,"·",26);cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);cross.position-=Vector2(4,18)
	prompt=label(hud,"",19);prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);anchored_rect(prompt,Rect2(-360,-180,720,38));prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	carry_status=label(hud,"",16);carry_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);anchored_rect(carry_status,Rect2(-400,-218,800,32));carry_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice_label=label(hud,"",17);notice_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);anchored_rect(notice_label,Rect2(-480,32,450,100));notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var sub:=VBoxContainer.new();sub.name="Subtitles";hud.add_child(sub);sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);anchored_rect(sub,Rect2(-430,-133,860,125));sub.mouse_filter=Control.MOUSE_FILTER_IGNORE
	speaker=label(sub,"",15);speaker.modulate=Color("c6b18b");speaker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle=label(sub,"",21);subtitle.custom_minimum_size=Vector2(860,80);subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stamina=ProgressBar.new();hud.add_child(stamina);stamina.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);anchored_rect(stamina,Rect2(34,-45,130,5));stamina.show_percentage=false;stamina.max_value=1
	var hint:=label(hud,"WASD mover   SHIFT correr   CTRL agachar   E interagir   Q apoiar   TAB trocar\nMOUSE olhar   RODA primeira pessoa   F lanterna   C DVR   H chamar/aguardar   ESPAÇO fala   ESC pausa",13)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.name="ControlsHint";hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);anchored_rect(hint,Rect2(-710,-92,680,85));hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hint.modulate=Color("babbaa")
	supply_marker=PanelContainer.new();supply_marker.name="SupplyDestination";hud.add_child(supply_marker);supply_marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;supply_marker.custom_minimum_size=Vector2(300,70)
	supply_marker_text=label(supply_marker,"",16);supply_marker_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;supply_marker_text.custom_minimum_size.x=270
	supply_marker.hide()
	hud.hide()
func anchored_rect(control: Control,rect: Rect2) -> void:
	control.offset_left=rect.position.x;control.offset_top=rect.position.y
	control.offset_right=rect.end.x;control.offset_bottom=rect.end.y
func build_menu() -> void:
	menu=PanelContainer.new();root.add_child(menu);menu.position=Vector2(55,80);menu.size=Vector2(480,560)
	var v:=VBoxContainer.new();menu.add_child(v);v.add_theme_constant_override("separation",13)
	label(v,"UM TURNO EM FRANCA, SP",15).modulate=Color("b8a078")
	title=label(v,"A ÚLTIMA\nVENDA",52)
	label(v,"DEPOIS DO FECHAMENTO",17).modulate=Color("b8a078")
	message=label(v,"21h40. O bairro vai dormir.\nPra vocês, ainda é expediente.",18)
	buttons=VBoxContainer.new();v.add_child(buttons);buttons.add_theme_constant_override("separation",9)
	rebuild_buttons()
	label(v,"0.21.0 • Reposição e entregas guiadas\nFones de ouvido recomendados",13).modulate=Color("9ca58f")
func button(text: String,callback: Callable) -> Button:
	var b:=Button.new();buttons.add_child(b);b.text=text;b.pressed.connect(callback);return b
func rebuild_buttons() -> void:
	for node in buttons.get_children():node.queue_free()
	if has_started:button("RETOMAR",func():set_paused(false))
	else:button("INICIAR EXPEDIENTE",func():new_game.emit();has_started=true;set_paused(false))
	if FileAccess.file_exists(Session.SAVE_PATH):button("CONTINUAR TURNO SALVO",func():continue_game.emit();has_started=true;set_paused(false))
	if has_started:button("SALVAR TURNO",save_current)
	if has_started and Session.campaign.phase=="sunday_escape":button("RETOMAR CHECKPOINT DA FUGA",func():retry_game.emit();set_paused(false))
	button("CONFIGURAÇÕES",open_settings)
	button("SAIR",func():get_tree().quit())
func save_current() -> void:
	var player:=get_tree().get_first_node_in_group("player") as DepotPlayer
	if player!=null:
		for actor in get_tree().get_nodes_in_group("protagonists"):
			if actor.handling.busy or actor.motion.action_active:
				message.text="Espere terminar de movimentar a caixa antes de salvar.";return
		var err:=Session.save_shift(player.global_position)
		message.text="Turno salvo." if err==OK else "Não foi possível salvar o turno."
func set_paused(value: bool) -> void:
	if value:close_surveillance();close_sunday_desk()
	paused=value;get_tree().paused=value
	menu.visible=value;hud.visible=not value
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value:
		title.text="EXPEDIENTE\nEM PAUSA";rebuild_buttons()
	pause_changed.emit(value)
func open_settings() -> void:
	menu.hide();settings=SettingsPanel.new();root.add_child(settings);settings.position=Vector2(355,35)
	settings.closed.connect(func():settings.queue_free();settings=null;menu.show())
func open_checkout(world: ShiftWorld) -> void:
	if paused or checkout!=null or surveillance!=null or sunday_desk!=null or campaign_panel!=null:return
	checkout=CheckoutPanel.new();checkout.world=world;root.add_child(checkout);checkout.position=Vector2(160,30)
	checkout.closed.connect(close_checkout)
	world.set_register_open(true);hud.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func close_checkout() -> void:
	if checkout==null:return
	if is_instance_valid(checkout.world):checkout.world.set_register_open(false)
	checkout.queue_free();checkout=null
	if not paused:hud.show();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func open_surveillance(world: ShiftWorld) -> void:
	if paused or checkout!=null or surveillance!=null or not world.saturday.can_open(world.player):return
	world.set_surveillance_open(true)
	surveillance=SurveillancePanel.new();surveillance.world=world;root.add_child(surveillance);surveillance.position=Vector2(60,35)
	surveillance.closed.connect(close_surveillance)
	# The security viewport renders instead of the covered player viewport.
	get_parent().viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	hud.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func close_surveillance() -> void:
	if surveillance==null:return
	if is_instance_valid(surveillance.world):surveillance.world.set_surveillance_open(false)
	surveillance.feed.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.remove_child(surveillance);surveillance.queue_free();surveillance=null
	get_parent().viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	if not paused:hud.show();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func open_sunday_desk(world: ShiftWorld) -> void:
	if paused or sunday_desk!=null or campaign_panel!=null or not world.sunday.can_open(world.player):return
	world.sunday.desk_open=true;world.characters.Felps.input_locked=true
	sunday_desk=SundayDesk.new();sunday_desk.world=world;root.add_child(sunday_desk);sunday_desk.position=Vector2(100,35)
	sunday_desk.closed.connect(close_sunday_desk)
	get_parent().viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	hud.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func close_sunday_desk() -> void:
	if sunday_desk==null:return
	if is_instance_valid(sunday_desk.world):sunday_desk.world.sunday.desk_open=false;sunday_desk.world.characters.Felps.input_locked=false
	sunday_desk.video.stop();root.remove_child(sunday_desk);sunday_desk.queue_free();sunday_desk=null
	get_parent().viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	if not paused:hud.show();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func close_campaign(unpause:=true) -> void:
	if campaign_panel!=null:root.remove_child(campaign_panel);campaign_panel.queue_free();campaign_panel=null
	if unpause:set_paused(false)
func show_campaign(kind: String) -> void:
	close_campaign(false);close_sunday_desk();close_checkout();set_paused(true);menu.hide();hud.hide()
	campaign_panel=CampaignPanel.new();campaign_panel.world=get_parent().world;campaign_panel.kind=kind
	root.add_child(campaign_panel);campaign_panel.position=Vector2(260,100)
	campaign_panel.cancel.connect(func():close_campaign())
	campaign_panel.escape.connect(func(alone: bool):
		var world:=campaign_panel.world;close_campaign(false)
		if not world.sunday.finish(alone):set_paused(false))
	campaign_panel.retry.connect(func():close_campaign(false);retry_game.emit();set_paused(false))
	campaign_panel.restart.connect(func():close_campaign(false);new_game.emit();has_started=true;set_paused(false))
func update_objective() -> void:
	night_label.text="FRANCA / "+Session.night_title()
	var player:=get_tree().get_first_node_in_group("player") as DepotPlayer
	var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
	if player!=null and int(Session.campaign.night)<2 and not player.carried_id.is_empty():
		objective.text=StockTasks.crate_name(player.carried_id)+"\nDestino: "+StockTasks.destination(player.carried_id)+". [E] usar no destino; [Q] apoiar."
	elif player!=null and player.identity=="Dery" and world!=null and world.supplies!=null and world.supplies.active_order() and Session.campaign.phase in ["routine","saturday_routine"]:
		objective.text="Pedido #%03d: pegue a caixa LARANJA VENDA no estoque e entregue na marca do balcão. [E] deixar para Felps."%world.sale.id
	elif Session.campaign.phase!="routine":objective.text=Session.objective()
	else:objective.text="Atenda os clientes no balcão. [Tab] Deryk cuida da reposição." if player!=null and player.identity=="Felps" and Session.stage in [1,2,3,4] else Session.objective()
func on_spoken(who: String,text: String) -> void:
	speaker.text=who+"  •  [ESPAÇO] continuar" if not who.is_empty() else "";subtitle.text=text
	hud.get_node("ControlsHint").visible=not Dialogue.active
func set_character(actor: DepotPlayer,animate := true) -> void:
	character_label.text="DERYK • REPOSIÇÃO   [TAB] FELPS" if actor.identity=="Dery" else "FELPS • ATENDIMENTO   [TAB] DERYK"
	update_objective()
	prompt.text="";carry_status.text=""
	if animate and has_started and not paused:
		if fade_tween!=null:fade_tween.kill()
		switch_fade.color=Color(0,0,0,.85)
		fade_tween=create_tween();fade_tween.tween_property(switch_fade,"color:a",0.0,.18)
func show_notice(text: String) -> void:
	notice_label.text=text;notice_remaining=4.0
	if checkout!=null and is_instance_valid(checkout.world) and checkout.world.sale!=null:
		checkout.world.sale.message=text;checkout.queue_refresh()
func _process(_delta: float) -> void:
	var player:=get_tree().get_first_node_in_group("player") as DepotPlayer
	if player!=null:
		stamina.value=player.stamina;stamina.visible=player.stamina<.98
		carry_status.text=("Preparando a caixa…" if player.handling.busy or player.motion.action_active else StockTasks.crate_name(player.carried_id)+" • [Q] apoiar") if player.carried!=null else ""
	update_supply_marker()

	if not paused:
		notice_remaining=maxf(0,notice_remaining-_delta)
		if notice_remaining==0:notice_label.text=""
	clock.text=Session.clock_text()
func show_night_summary() -> void:
	if night_panel!=null:return
	close_checkout();set_paused(true);menu.hide();hud.hide()
	night_panel=PanelContainer.new();root.add_child(night_panel);night_panel.position=Vector2(310,155);night_panel.custom_minimum_size=Vector2(660,410)
	var scroll:=ScrollContainer.new();night_panel.add_child(scroll);scroll.custom_minimum_size=Vector2(628,388)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	var column:=VBoxContainer.new();scroll.add_child(column);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",18)
	var saturday:=int(Session.campaign.night)==1
	label(column,"SÁBADO CONCLUÍDO" if saturday else "SEXTA-FEIRA CONCLUÍDA",31)
	var report: Dictionary=Session.campaign.reports.get("saturday" if saturday else "friday",{})
	label(column,"Os dois saíram juntos.\n%d atendimentos • Vendas %s"%[int(report.get("customers",0)),ShopSale.money(int(report.get("sales_cents",0)))],21)
	var message_text:="A pane foi comunicada ao responsável pelo depósito.\nSábado: atenda os clientes, confira as câmeras\ne investigue os fundos com a dupla."
	if saturday:
		message_text="Registros: "+("cópia guardada" if Session.campaign.decisions.get("evidence","")=="copy" else "somente no gravador")
		message_text+="\nContato: "+("responsável avisado" if Session.campaign.decisions.get("help","")=="contact" else "ainda sem aviso")
		message_text+="\nSaída: "+("preparada" if Session.campaign.decisions.get("exit","")=="prepared" else "sem preparação")
		message_text+="\nDomingo: recupere a gravação antiga, enfrente\na perseguição e decida como sair do depósito."
	var note:=label(column,message_text,18);note.custom_minimum_size.x=610
	var proceed:=Button.new();column.add_child(proceed);proceed.text="COMEÇAR DOMINGO" if saturday else "COMEÇAR SÁBADO"
	proceed.name="NextNight"
	proceed.pressed.connect(func():night_panel.queue_free();night_panel=null;next_night.emit();set_paused(false))
	var leave:=Button.new();column.add_child(leave);leave.text="SAIR • CAMPANHA SALVA";leave.pressed.connect(func():get_tree().quit())
	proceed.grab_focus()
func _input(event: InputEvent) -> void:
	if campaign_panel!=null:
		if event.is_action_pressed("pause") and campaign_panel.kind=="escape":close_campaign()
		if event.is_action_pressed("pause") or event.is_action_pressed("switch_character"):get_viewport().set_input_as_handled()
		return
	if sunday_desk!=null:
		if event.is_action_pressed("pause") or event.is_action_pressed("surveillance"):
			close_sunday_desk();get_viewport().set_input_as_handled();return
		if event.is_action_pressed("switch_character"):
			var world:=sunday_desk.world;close_sunday_desk();world.switch_player();get_viewport().set_input_as_handled();return
	if surveillance!=null:
		if event.is_action_pressed("pause") or event.is_action_pressed("surveillance"):
			close_surveillance();get_viewport().set_input_as_handled();return
		if event.is_action_pressed("switch_character"):
			var world:=surveillance.world;close_surveillance();world.switch_player();get_viewport().set_input_as_handled();return
	if night_panel!=null:
		if event.is_action_pressed("pause") or event.is_action_pressed("switch_character"):get_viewport().set_input_as_handled()
		return
	if checkout!=null:
		if event.is_action_pressed("pause"):
			close_checkout();get_viewport().set_input_as_handled();return
		if event.is_action_pressed("switch_character"):
			var world:=checkout.world;close_checkout();world.switch_player();get_viewport().set_input_as_handled();return
	if event.is_action_pressed("pause") and has_started:
		if settings!=null:settings.closed.emit()
		else:set_paused(not paused)
		get_viewport().set_input_as_handled()

func update_supply_marker() -> void:
	supply_marker.hide()
	if paused or checkout!=null or surveillance!=null or sunday_desk!=null or campaign_panel!=null or Dialogue.active:return
	var world: ShiftWorld=get_parent().world
	if world==null or not world.active or world.supplies==null:return
	var goal:=world.supplies.goal()
	if goal.is_empty():return
	var camera:=world.player.camera_rig.camera
	var at: Vector3=goal.at
	var display: Rect2=get_parent().screen.get_global_rect()
	var projected: Vector2=camera.unproject_position(at)/Vector2(get_parent().viewport.size)
	var point:=display.position+projected*display.size
	var behind:=camera.is_position_behind(at)
	if behind:
		var local:=camera.to_local(at)
		point=root.size*.5+Vector2(local.x,-local.y).normalized()*root.size.length()
	var unclamped:=point-Vector2(150,55)
	var position_hint:=Vector2(clampf(unclamped.x,34,root.size.x-334),clampf(unclamped.y,220,root.size.y-360))
	var arrow:="↓"
	if behind or unclamped.distance_to(position_hint)>15:
		var direction:=point-root.size*.5
		arrow=("→" if direction.x>0 else "←") if absf(direction.x)>absf(direction.y) else ("↓" if direction.y>0 else "↑")
	supply_marker.position=position_hint;supply_marker.size=Vector2(300,80)
	supply_marker_text.text=arrow+" "+str(goal.text)+"\n"+str(goal.hint)+" • %.1f m"%Vector2(world.player.position.x-at.x,world.player.position.z-at.z).length()
	supply_marker.show()
