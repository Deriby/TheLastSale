class_name TitleMenuMotion
extends RefCounted
## Presentation only: native buttons keep their input, focus and callbacks.
var menu: Control
var column: VBoxContainer
var buttons: VBoxContainer
var lockup: Control
var base_position := Vector2.ZERO
var elapsed := 0.0
var entering := false
var quick := false
var entries: Array[Dictionary] = []

func _init(panel: Control,content: VBoxContainer,actions: VBoxContainer,heading: Control) -> void:
	menu=panel;column=content;buttons=actions;lockup=heading

func layout(at: Vector2) -> void:
	base_position=at
	apply_entrance()

func reveal(short := false) -> void:
	cancel();quick=short;elapsed=0;entering=true
	for row in column.get_children():
		if row==buttons:
			for action in buttons.get_children():entries.append({"node":action,"color":action.modulate})
		else:entries.append({"node":row,"color":row.modulate})
	apply_entrance()

func cancel() -> void:
	for entry in entries:
		if is_instance_valid(entry.node):entry.node.modulate=entry.color
	entries.clear();entering=false;elapsed=0
	menu.position=base_position;lockup.scale=Vector2.ONE

func apply_entrance() -> void:
	if not entering:menu.position=base_position;return
	var span:=.18 if quick else .64
	var spacing:=.012 if quick else .065
	var progress:=clampf(elapsed/(span+maxi(0,entries.size()-1)*spacing),0,1)
	var ease:=1.0-pow(1.0-progress,3)
	menu.position=base_position+Vector2(-24,5)*(1.0-ease)
	lockup.scale=Vector2.ONE*lerpf(.982,1.0,ease)
	for index in entries.size():
		var entry:=entries[index]
		if not is_instance_valid(entry.node):continue
		var color: Color=entry.color
		color.a*=smoothstep(index*spacing,index*spacing+span,elapsed)
		entry.node.modulate=color
	if progress>=1:cancel()

func update(delta: float) -> void:
	if not menu.is_visible_in_tree():return
	if entering:elapsed+=delta;apply_entrance()
	# Mouse hover takes priority over the last keyboard focus. Disabled Continue
	# remains dim and never acquires the animated selection treatment.
	var selected: Button
	for item in buttons.get_children():
		if item is Button and not item.disabled and item.is_hovered():selected=item;break
	if selected==null:
		for item in buttons.get_children():
			if item is Button and not item.disabled and item.has_focus():selected=item;break
	var blend:=1.0-exp(-maxf(delta,0.0)*14.0)
	for item in buttons.get_children():
		if not item.has_meta("title_style"):continue
		var previous:=float(item.get_meta("title_selection",0.0))
		var target:=1.0 if item==selected else 0.0
		if previous==target:continue
		var amount:=lerpf(previous,target,blend)
		if absf(amount-target)<.0005:amount=target
		item.set_meta("title_selection",amount)
		var style: StyleBoxFlat=item.get_meta("title_style")
		style.bg_color=Color(.42,.075,.045,.14*amount)
		style.border_color=Color(.8,.24,.15,amount*.9)
		style.content_margin_left=18+8*amount
		var color:=Color("b8af97").lerp(Color("fff0cd"),amount)
		for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:item.add_theme_color_override(state,color)
