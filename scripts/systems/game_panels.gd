class_name GamePanels
extends RefCounted
## Shared native UI finishes. Presentation never changes campaign or transaction state.
const INK:=Color("26312e")
const MUTED:=Color("87968d")
const GOLD:=Color("d9b66f")
const PAPER:=Color("e8dfc8")
const MONO=preload("res://assets/fonts/title/TitleMono.ttf")
static func box(color: Color,border: Color=Color("48554c"),padding: int=16,radius: int=4) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new();style.bg_color=color;style.border_color=border;style.set_border_width_all(1);style.set_corner_radius_all(radius);style.set_content_margin_all(padding);return style
static func theme(paper: bool=false) -> Theme:
 var t:=Theme.new();t.default_font=ThemeDB.fallback_font;t.default_font_size=16
 var ink:=INK if paper else Color("e9e8dc")
 t.set_color("font_color","Label",ink)
 for type in ["Button","OptionButton","CheckButton"]:
  t.set_color("font_color",type,ink);t.set_color("font_hover_color",type,INK if paper else Color("fff1c9"));t.set_color("font_pressed_color",type,ink);t.set_color("font_focus_color",type,ink);t.set_color("font_disabled_color",type,Color("7b8076"))
  t.set_stylebox("normal",type,box(Color("d8d0b9") if paper else Color("2a3732"),Color("b1a68b") if paper else Color("4b5d51"),10))
  t.set_stylebox("hover",type,box(Color("f2e9d0") if paper else Color("3b4b3e"),GOLD,10))
  t.set_stylebox("pressed",type,box(Color("c9c3ae") if paper else Color("17251d"),GOLD,10))
  t.set_stylebox("disabled",type,box(Color("ddd5c1") if paper else Color("202923"),Color("797c6a") if paper else Color("364039"),10))
  var focus:=box(Color(0,0,0,0),Color("83643b") if paper else GOLD,0);focus.set_border_width_all(2);t.set_stylebox("focus",type,focus)
 t.set_stylebox("panel","PanelContainer",box(PAPER if paper else Color("17231f"),Color("b2a68a") if paper else Color("687262"),20,5))
 t.set_stylebox("background","ProgressBar",box(Color("cbc2aa") if paper else Color("101a16"),Color(0,0,0,0),0,2))
 t.set_stylebox("fill","ProgressBar",box(Color("60775a"),Color(0,0,0,0),0,2))
 var track:=box(Color("475348"),Color("475348"),0,2);track.content_margin_top=2;track.content_margin_bottom=2
 t.set_stylebox("slider","HSlider",track)
 var fill:=track.duplicate();fill.bg_color=GOLD;fill.border_color=GOLD;t.set_stylebox("grabber_area","HSlider",fill);t.set_stylebox("grabber_area_highlight","HSlider",fill)
 t.set_stylebox("panel","PopupMenu",box(Color("e9e2cf"),Color("776b51"),8));t.set_color("font_color","PopupMenu",INK);t.set_stylebox("hover","PopupMenu",box(Color("788665"),Color("788665"),2));t.set_color("font_hover_color","PopupMenu",Color.WHITE)
 for type in ["VBoxContainer","HBoxContainer","GridContainer"]:t.set_constant("separation",type,10)
 return t
static func label(parent: Node,value: String,size: int=16,color: Color=Color(-1,-1,-1),font: Font=null) -> Label:
 var l:=Label.new();parent.add_child(l);l.text=value;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if color.r>=0:l.add_theme_color_override("font_color",color)
 if font!=null:l.add_theme_font_override("font",font)
 return l
static func button(parent: Node,id: String,value: String,callback: Callable,primary: bool=false) -> Button:
 var b:=Button.new();parent.add_child(b);b.name=id;b.text=value;b.custom_minimum_size.y=40;b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;b.pressed.connect(callback)
 if primary:
  b.add_theme_stylebox_override("normal",box(Color("b99a59"),Color("edcf8e"),10));b.add_theme_color_override("font_color",Color("17231d"));b.add_theme_color_override("font_hover_color",Color("fff4d5"))
 return b
static func card(parent: Node,color: Color=Color("202e27"),paper: bool=false) -> VBoxContainer:
 var panel:=PanelContainer.new();parent.add_child(panel);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",box(PAPER if paper else color,Color("b7aa8b") if paper else Color("48594b"),16))
 if paper:panel.theme=theme(true)
 var col:=VBoxContainer.new();panel.add_child(col);col.add_theme_constant_override("separation",10);return col
static func rule(parent: Node,color: Color=Color("465349")) -> void:
 var line:=ColorRect.new();parent.add_child(line);line.custom_minimum_size.y=1;line.color=color;line.mouse_filter=Control.MOUSE_FILTER_IGNORE
static func title(parent: Node,eyebrow: String,heading: String,paper: bool=false) -> void:
 label(parent,eyebrow,12,Color("74674d") if paper else GOLD,MONO)
 label(parent,heading,34,INK if paper else Color("f0ebd9"),TitlePresentation.DISPLAY)
static func enter(control: Control) -> void:
 control.modulate.a=0
 control.create_tween().tween_property(control,"modulate:a",1.0,.17)
static func fit(control: Control,preferred: Vector2,available: Vector2) -> void:
 if control==null or control.is_queued_for_deletion():return
 control.size=preferred.max(control.get_combined_minimum_size())
 var factor:=minf(1.0,minf((available.x-40)/control.size.x,(available.y-40)/control.size.y))
 control.scale=Vector2.ONE*maxf(.25,factor);control.position=(available-control.size*control.scale)*.5
