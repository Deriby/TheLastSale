class_name SettingsPanel
extends PanelContainer
signal closed
var rows: VBoxContainer
func _ready() -> void:
	custom_minimum_size=Vector2(570,minf(660,maxf(300,get_viewport_rect().size.y-70)))
	var margin:=MarginContainer.new();add_child(margin)
	for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	var scroll:=ScrollContainer.new();scroll.name="SettingsScroll";margin.add_child(scroll)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",11);scroll.add_child(rows)
	var heading:=Label.new();heading.text="CONFIGURAÇÕES";heading.add_theme_font_size_override("font_size",24);rows.add_child(heading)
	add_slider("Volume geral","volume",0,1,.05)
	add_slider("Música / rádio","music_volume",0,1,.05)
	add_slider("Efeitos e ambiente","effects_volume",0,1,.05)
	add_slider("Sensibilidade do mouse","sensitivity",.001,.006,.0002)
	add_slider("Campo de visão","fov",55,90,1)
	add_slider("Câmera inicial (0 = primeira pessoa)","camera_distance",0,3.6,.2)
	var immersive:=CheckButton.new();immersive.name="ImmersiveHUD";immersive.text="HUD discreto / tarefas no caderno [J]";immersive.button_pressed=Preferences.immersive_hud;rows.add_child(immersive)
	immersive.toggled.connect(func(value):Preferences.immersive_hud=value;Preferences.save())
	add_slider("Granulação","grain",0,.10,.005)
	add_slider("Interferência VHS","vhs",0,1,.05)
	var label:=Label.new();label.text="Resolução interna / qualidade";rows.add_child(label)
	var select:=OptionButton.new();select.name="RenderQuality";rows.add_child(select)
	select.add_item("Nítida — resolução da janela",1);select.add_item("Retrô — metade da resolução",2);select.add_item("Econômica — um terço",3)
	select.add_item("PS1 — 320×240 (4:3)",4)
	select.add_item("PS1/2 — 640×480 (4:3)",5)
	select.select((4 if Preferences.ps1_high_resolution else 3) if Preferences.ps1_mode else Preferences.pixel_scale-1)
	select.item_selected.connect(func(i):
		var mode:=select.get_item_id(i)
		Preferences.ps1_mode=mode==4 or mode==5
		Preferences.ps1_high_resolution=mode==5
		Preferences.pixel_scale=2 if Preferences.ps1_mode else mode
		Preferences.save())
	add_psx_option("Precisão de vértices PS1","PSXVertices","psx_vertices")
	add_psx_option("Texturas afins PS1","PSXAffine","psx_affine")
	var psx_note:=Label.new();psx_note.text="Efeitos ativos nos modos PS1 e PS1/2.";rows.add_child(psx_note)
	var limit_label:=Label.new();limit_label.text="Limite de quadros";rows.add_child(limit_label)
	var limit:=OptionButton.new();rows.add_child(limit)
	limit.add_item("30 FPS",30);limit.add_item("60 FPS",60);limit.add_item("Sem limite",0)
	limit.select(0 if Preferences.frame_limit==30 else (1 if Preferences.frame_limit==60 else 2))
	limit.item_selected.connect(func(i):Preferences.frame_limit=limit.get_item_id(i);Preferences.save())
	var screen:=CheckButton.new();screen.text="Tela cheia";screen.button_pressed=Preferences.fullscreen;rows.add_child(screen)
	screen.toggled.connect(func(v):Preferences.fullscreen=v;Preferences.save())
	var back:=Button.new();back.text="VOLTAR";rows.add_child(back);back.pressed.connect(func():Preferences.save();closed.emit())
func add_slider(title: String,key: String,lo: float,hi: float,step: float) -> void:
	var row:=HBoxContainer.new();rows.add_child(row)
	var label:=Label.new();label.text=title;label.custom_minimum_size.x=280;row.add_child(label)
	var slider:=HSlider.new();slider.min_value=lo;slider.max_value=hi;slider.step=step;slider.value=Preferences.get(key);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
	slider.value_changed.connect(func(v):Preferences.set(key,v);Preferences.apply())

func add_psx_option(title: String,id: String,key: String) -> void:
	var label:=Label.new();label.text=title;rows.add_child(label)
	var select:=OptionButton.new();select.name=id;rows.add_child(select)
	select.add_item("Desligada",0);select.add_item("Suave",1);select.add_item("Marcada",2)
	select.select(Preferences.get(key))
	select.item_selected.connect(func(i):Preferences.set(key,select.get_item_id(i));Preferences.save())
