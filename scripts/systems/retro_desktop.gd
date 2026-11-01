class_name RetroDesktop
extends PanelContainer
## Original desktop chrome, shared by the in-world CCTV and archive terminals.
signal closed
signal app_visibility_changed(value: bool)
signal document_visibility_changed(value: bool)
var world: ShiftWorld
var desktop: Control
var app_window: PanelContainer
var app_body: VBoxContainer
var taskbar: PanelContainer
var start_menu: PanelContainer
var task_button: Button
var desktop_clock: Label
var title_text: Label
var status_text: Label
var minimized:=false
var maximized:=false
var dragging:=false
var drag_offset:=Vector2.ZERO
var open_tween: Tween
var page_tween: Tween
var clock_wait:=0.0
var shortcuts: Array[Dictionary]=[]
var document_panel: PanelContainer
var document_title: Label
var document_text: Label
class DesktopIcon extends Control:
 var kind:="monitor"
 var extent:=32.0
 func _draw() -> void:
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE*extent/32.0)
  if kind=="folder":
   draw_rect(Rect2(2,5,14,7),Color("d7a136"));draw_rect(Rect2(2,10,29,20),Color("9c6925"));draw_rect(Rect2(3,9,28,18),Color("f4cf65"));draw_line(Vector2(4,10),Vector2(29,10),Color("fff4b1"),2)
  elif kind=="file":
   draw_rect(Rect2(6,2,22,29),Color("77808b"));draw_rect(Rect2(5,1,21,28),Color("fffdf5"));draw_rect(Rect2(8,4,14,6),Color("528aca"))
   for y in [14,18,22]:draw_line(Vector2(9,y),Vector2(22,y),Color("8797aa"),1)
  else:
   draw_rect(Rect2(2,3,29,21),Color("bec5c8"));draw_rect(Rect2(4,5,25,16),Color("233444"));draw_rect(Rect2(5,6,23,14),Color("4087bd"));draw_rect(Rect2(14,24,5,4),Color("aeb6bb"));draw_rect(Rect2(9,28,16,3),Color("dee4e4"));draw_line(Vector2(7,8),Vector2(20,8),Color("99d8ed"),1)
static func style(bg: Color,border: Color=Color("8d9bb0"),radius:=3) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=bg;box.border_color=border;box.set_border_width_all(1);box.set_corner_radius_all(radius);box.content_margin_left=10;box.content_margin_right=10;box.content_margin_top=6;box.content_margin_bottom=6;return box
static func desk_theme() -> Theme:
 var result:=Theme.new();result.default_font=ThemeDB.fallback_font;result.default_font_size=15
 result.set_color("font_color","Label",Color("233041"));result.set_color("font_color","Button",Color("253247"));result.set_color("font_hover_color","Button",Color("142842"));result.set_color("font_pressed_color","Button",Color("142842"));result.set_color("font_disabled_color","Button",Color("929695"))
 var normal:=style(Color("f6f4ed"),Color("8d9bb0"));normal.border_width_bottom=2
 var hover:=style(Color("fffdf6"),Color("e3ac36"));hover.set_border_width_all(2)
 var pressed:=style(Color("d7e6f6"),Color("3169a6"));pressed.border_width_top=2
 var disabled:=style(Color("e8e7e1"),Color("c6c7c0"))
 result.set_stylebox("normal","Button",normal);result.set_stylebox("hover","Button",hover);result.set_stylebox("pressed","Button",pressed);result.set_stylebox("disabled","Button",disabled)
 var focus:=style(Color(0,0,0,0),Color("558cc2"));focus.set_border_width_all(2);result.set_stylebox("focus","Button",focus)
 result.set_stylebox("panel","PanelContainer",style(Color("ffffff"),Color("b4bdc9"),0))
 result.set_stylebox("background","ProgressBar",style(Color("d8dfd9"),Color("8c9b92"),1));result.set_stylebox("fill","ProgressBar",style(Color("55a548"),Color("3e8a38"),1))
 result.set_stylebox("panel","PopupMenu",style(Color("fffdf6"),Color("8099b6"),1));result.set_stylebox("hover","PopupMenu",style(Color("316ac5"),Color("316ac5"),0));result.set_color("font_color","PopupMenu",Color("233041"));result.set_color("font_hover_color","PopupMenu",Color.WHITE)
 result.set_constant("separation","VBoxContainer",8);result.set_constant("separation","HBoxContainer",10)
 return result
func text(parent: Node,value: String,font_size:=15) -> Label:
 var item:=Label.new();parent.add_child(item);item.text=value;item.add_theme_font_size_override("font_size",font_size);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.custom_minimum_size.x=90;item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.mouse_filter=Control.MOUSE_FILTER_IGNORE;return item
func button(parent: Node,id: String,title: String,callback: Callable) -> Button:
 var item:=Button.new();parent.add_child(item);item.name=id;item.text=title;item.pressed.connect(callback);item.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;return item
func icon(parent: Node,kind: String,extent:=32.0) -> Control:
 var item:=DesktopIcon.new();item.kind=kind;item.extent=extent;item.custom_minimum_size=Vector2.ONE*extent;item.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(item);return item
func panel(parent: Node,color:=Color.WHITE) -> VBoxContainer:
 var border:=PanelContainer.new();border.add_theme_stylebox_override("panel",style(color,Color("b5c1cf"),2));parent.add_child(border);border.size_flags_horizontal=Control.SIZE_EXPAND_FILL;border.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var body:=VBoxContainer.new();border.add_child(body);return body
func scroll_body(parent: Node) -> VBoxContainer:
 var scroll:=ScrollContainer.new();parent.add_child(scroll);scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
 var body:=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return body
func build_desktop(title: String,application: String,routes: Array[Dictionary]) -> VBoxContainer:
 process_mode=Node.PROCESS_MODE_PAUSABLE;theme=desk_theme();add_theme_stylebox_override("panel",StyleBoxEmpty.new());set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 desktop=Control.new();add_child(desktop);desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var gradient:=Gradient.new();gradient.colors=PackedColorArray([Color("244f79"),Color("4e8b9a"),Color("20493c")]);gradient.offsets=PackedFloat32Array([0,.65,1])
 var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill_from=Vector2(.2,0);texture.fill_to=Vector2(.8,1)
 var paper:=TextureRect.new();desktop.add_child(paper);paper.texture=texture;paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var watermark:=text(desktop,"DEPÓSITO\nESTAÇÃO 01 / REDE LOCAL",17);watermark.position=Vector2(28,500);watermark.size=Vector2(240,80);watermark.add_theme_color_override("font_color",Color(1,1,1,.3))
 shortcuts=routes
 for index in shortcuts.size():
  var route: Dictionary=shortcuts[index]
  var launcher:=button(desktop,"DesktopShortcut"+str(index),"",func():restore_app();route.callback.call());launcher.position=Vector2(18,30+index*96);launcher.size=Vector2(110,84)
  launcher.add_theme_stylebox_override("normal",style(Color(0,0,0,0),Color(0,0,0,0)));launcher.add_theme_stylebox_override("hover",style(Color(1,1,1,.15),Color(1,1,1,.4)))
  var stack:=VBoxContainer.new();launcher.add_child(stack);stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.alignment=BoxContainer.ALIGNMENT_CENTER
  var symbol:=icon(stack,str(route.get("icon","monitor")));symbol.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  var caption:=text(stack,str(route.title),13);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_color_override("font_color",Color.WHITE);caption.add_theme_color_override("font_shadow_color",Color("173449"));caption.add_theme_constant_override("shadow_offset_y",1)
 app_window=PanelContainer.new();app_window.name="ApplicationWindow";desktop.add_child(app_window)
 var frame:=style(Color("ece9d8"),Color("1c57c4"),7);frame.set_border_width_all(3);frame.content_margin_left=3;frame.content_margin_right=3;frame.content_margin_top=0;frame.content_margin_bottom=3;frame.shadow_color=Color(0,0,0,.4);frame.shadow_size=9;frame.shadow_offset=Vector2(4,5);app_window.add_theme_stylebox_override("panel",frame)
 var column:=VBoxContainer.new();app_window.add_child(column);column.add_theme_constant_override("separation",0)
 var bar:=PanelContainer.new();bar.name="ApplicationTitleBar";column.add_child(bar);bar.custom_minimum_size.y=34;bar.add_theme_stylebox_override("panel",style(Color("2469dc"),Color("559bff"),5));bar.gui_input.connect(drag_window)
 var heading:=HBoxContainer.new();bar.add_child(heading);heading.add_theme_constant_override("separation",6);heading.mouse_filter=Control.MOUSE_FILTER_PASS
 icon(heading,"monitor",20);title_text=text(heading,title,17);title_text.add_theme_color_override("font_color",Color.WHITE);title_text.autowrap_mode=TextServer.AUTOWRAP_OFF
 button(heading,"MinimizeWindow","_",minimize_app).custom_minimum_size=Vector2(28,24)
 button(heading,"MaximizeWindow","□",toggle_maximize).custom_minimum_size=Vector2(28,24)
 var close:=button(heading,"CloseComputer","×",func():closed.emit());close.custom_minimum_size=Vector2(28,24);close.add_theme_stylebox_override("normal",style(Color("d76348"),Color("ffffff")));close.add_theme_color_override("font_color",Color.WHITE)
 var menu:=HBoxContainer.new();column.add_child(menu);menu.add_theme_constant_override("separation",18)
 for menu_index in 4:
  var entry:=MenuButton.new();menu.add_child(entry);entry.text=["Arquivo","Exibir","Atalhos","Ajuda"][menu_index];entry.flat=true
  var popup:=entry.get_popup()
  match menu_index:
   0:
    popup.add_item("Abrir aplicação",0);popup.add_item("Minimizar",1);popup.add_separator();popup.add_item("Sair do computador",2)
    popup.id_pressed.connect(func(id):
     if id==0:restore_app()
     elif id==1:minimize_app()
     else:closed.emit())
   1:
    popup.add_item("Maximizar / restaurar",0);popup.add_item("Mostrar área de trabalho",1)
    popup.id_pressed.connect(func(id):
     if id==0:toggle_maximize()
     else:minimize_app())
   2:
    for index in shortcuts.size():popup.add_item(str(shortcuts[index].title),index)
    popup.id_pressed.connect(func(id):restore_app();shortcuts[id].callback.call())
   3:
    popup.add_item("Ajuda da estação",0)
    popup.id_pressed.connect(func(_id):show_document("Ajuda da estação","Use os ícones da área de trabalho ou a barra de tarefas para restaurar a aplicação. Arraste a barra azul para mover a janela.\n\nESC / C sai do computador. TAB troca de personagem. As ações disponíveis dependem dos registros e da energia do depósito."))
 var contents:=ScrollContainer.new();column.add_child(contents);contents.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;contents.size_flags_vertical=Control.SIZE_EXPAND_FILL;contents.follow_focus=true
 var margin:=MarginContainer.new();contents.add_child(margin);margin.size_flags_vertical=Control.SIZE_EXPAND_FILL;margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
 app_body=VBoxContainer.new();margin.add_child(app_body);app_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var status_bar:=PanelContainer.new();column.add_child(status_bar);status_bar.custom_minimum_size.y=25;status_bar.add_theme_stylebox_override("panel",style(Color("e0e0d7"),Color("bbbeb8"),0));status_text=text(status_bar,"Pronto • estação local • ESC / C para sair · TAB troca de personagem",12);status_text.autowrap_mode=TextServer.AUTOWRAP_OFF
 taskbar=PanelContainer.new();taskbar.name="DesktopTaskbar";desktop.add_child(taskbar);taskbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);taskbar.offset_top=-48;taskbar.add_theme_stylebox_override("panel",style(Color("245edb"),Color("68a1f2"),0))
 var tasks:=HBoxContainer.new();taskbar.add_child(tasks)
 var start:=button(tasks,"StartMenuButton","iniciar",func():start_menu.visible=not start_menu.visible);start.custom_minimum_size=Vector2(92,30);start.add_theme_stylebox_override("normal",style(Color("3c913c"),Color("76b476"),8));start.add_theme_color_override("font_color",Color.WHITE);start.add_theme_font_size_override("font_size",18);start.add_theme_stylebox_override("hover",style(Color("4aa34a"),Color("a2dca2"),8));start.add_theme_color_override("font_hover_color",Color.WHITE)
 task_button=button(tasks,"RunningApplication",application,restore_app);task_button.custom_minimum_size.x=240
 var spacer:=Control.new();tasks.add_child(spacer);spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var user:=text(tasks,"FELPS / OPERADOR",12);user.autowrap_mode=TextServer.AUTOWRAP_OFF;user.size_flags_horizontal=Control.SIZE_SHRINK_END;user.add_theme_color_override("font_color",Color("d3e9ff"))
 desktop_clock=text(tasks,Session.clock_text(),16);desktop_clock.autowrap_mode=TextServer.AUTOWRAP_OFF;desktop_clock.custom_minimum_size.x=65;desktop_clock.size_flags_horizontal=Control.SIZE_SHRINK_END;desktop_clock.add_theme_color_override("font_color",Color.WHITE)
 start_menu=PanelContainer.new();start_menu.name="LocalStartMenu";desktop.add_child(start_menu);start_menu.custom_minimum_size=Vector2(300,200);start_menu.add_theme_stylebox_override("panel",style(Color("f5f4e9"),Color("2469dc"),6));start_menu.hide()
 var entries:=VBoxContainer.new();start_menu.add_child(entries);text(entries,"Felps • Estação do depósito",18)
 for route in shortcuts:button(entries,"StartShortcut"+str(entries.get_child_count()),str(route.title),func():start_menu.hide();restore_app();route.callback.call())
 button(entries,"LeaveComputer","Sair do computador",func():closed.emit())
 resized.connect(layout_desktop);call_deferred("layout_desktop");call_deferred("animate_open")
 return app_body
func layout_desktop() -> void:
 if app_window==null:return
 app_window.position=Vector2(12,12) if maximized else Vector2(142,30)
 app_window.size=desired_window_size()
 start_menu.position=Vector2(8,size.y-260)
func animate_open() -> void:
 if open_tween!=null:open_tween.kill()
 app_window.pivot_offset=app_window.size*.5;app_window.scale=Vector2(.975,.975);app_window.modulate.a=0
 open_tween=create_tween().set_parallel(true);open_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);open_tween.tween_property(app_window,"scale",Vector2.ONE,.2);open_tween.tween_property(app_window,"modulate:a",1.0,.18)
func minimize_app() -> void:
 minimized=true;start_menu.hide();dismiss_document();app_window.hide();app_visibility_changed.emit(false)
func restore_app() -> void:
 if not minimized:return
 minimized=false;app_window.show();animate_open();app_visibility_changed.emit(true)
func toggle_maximize() -> void:maximized=not maximized;layout_desktop()
func drag_window(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  dragging=event.pressed;drag_offset=event.global_position-app_window.global_position
 if event is InputEventMouseMotion and dragging and not maximized:
  app_window.position=(event.global_position-global_position-drag_offset).clamp(Vector2.ZERO,Vector2(maxf(0,size.x-app_window.size.x),maxf(0,size.y-app_window.size.y-50)))
func animate_page(control: Control) -> void:
 if page_tween!=null:page_tween.kill()
 for route in app_body.get_children():route.modulate.a=1
 control.modulate.a=.35;page_tween=create_tween();page_tween.tween_property(control,"modulate:a",1.0,.15)
func selected(item: Button,value: bool) -> void:
 item.add_theme_stylebox_override("normal",style(Color("d8e8fb") if value else Color("f6f4ed"),Color("397dc1") if value else Color("a6b1bd")))
func desktop_tick(delta: float) -> void:
 var bar_height:=maxf(48,taskbar.get_combined_minimum_size().y)
 taskbar.offset_top=-bar_height;taskbar.offset_bottom=0
 var desired:=desired_window_size()
 var minimum:=app_window.get_combined_minimum_size()
 if minimum.x<=desired.x and minimum.y<=desired.y and not app_window.size.is_equal_approx(desired):app_window.size=desired
 app_window.pivot_offset=app_window.size*.5
 clock_wait-=delta
 if clock_wait<=0:clock_wait=1;desktop_clock.text=Session.clock_text()

func show_document(title: String,content: String) -> void:
 if document_panel==null:
  document_panel=PanelContainer.new();document_panel.name="DesktopDocument";desktop.add_child(document_panel);document_panel.z_index=5;document_panel.custom_minimum_size=Vector2(620,250);document_panel.add_theme_stylebox_override("panel",style(Color("f6f4eb"),Color("2469dc"),5))
  var column:=VBoxContainer.new();document_panel.add_child(column)
  var heading:=PanelContainer.new();column.add_child(heading);heading.add_theme_stylebox_override("panel",style(Color("2469dc"),Color("5b9df4"),3));var row:=HBoxContainer.new();heading.add_child(row)
  document_title=text(row,"",17);document_title.add_theme_color_override("font_color",Color.WHITE);button(row,"CloseDocument","×",func():dismiss_document())
  document_text=text(column,"",15);document_text.custom_minimum_size=Vector2(580,130)
  button(column,"AcceptDocument","OK",func():dismiss_document()).size_flags_horizontal=Control.SIZE_SHRINK_END
 document_title.text=title;document_text.text=content;document_panel.position=(size-Vector2(620,250))*.5;document_panel.show();document_visibility_changed.emit(true)
func dismiss_document() -> bool:
 if document_panel==null or not document_panel.visible:return false
 document_panel.hide();document_visibility_changed.emit(false);return true

func desired_window_size() -> Vector2:
 var bar_height:=maxf(48,taskbar.get_combined_minimum_size().y)
 return Vector2(size.x-24,size.y-bar_height-24) if maximized else Vector2(size.x-170,size.y-bar_height-42)
