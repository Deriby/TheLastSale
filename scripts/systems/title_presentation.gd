class_name TitlePresentation
extends Control
## Launch-only tape sequence. Reuses the existing world/viewport, never advances it.
signal intro_finished
const DISPLAY = preload("res://assets/fonts/title/retro/BebasNeue-Regular.ttf")
const TYPEWRITER = preload("res://assets/fonts/title/retro/SpecialElite-Regular.ttf")
const VCR = preload("res://assets/fonts/title/retro/VT323-Regular.ttf")
const DURATION := 9.4
const CAMERA_POSITION := Vector3(-8.2,1.85,9.7)
const CAMERA_TARGET := Vector3(.6,2.05,-.1)
var intro_active := false
var title_active := false
var elapsed := 0.0
var title_time := 0.0
var menu_time := 0.0
var warmup_frames := 0
var camera: Camera3D
var previous_camera: Camera3D
var hidden_actors: Array[Dictionary] = []
var atmosphere: ColorRect
var osd: Control
var counter: Label
var intro: Control
var black: ColorRect
var heading: Label
var caption: Label
var intro_rule: ColorRect
var skip_hint: Label
var transition: ColorRect
var transition_tween: Tween
var drone: AudioStreamPlayer
var tape: AudioStreamPlayer
var select_audio: AudioStreamPlayer
var stop_audio: AudioStreamPlayer
var ambience: TitleAmbience
var departing := false
var departure_tween: Tween
var menu_gain := 1.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere=ColorRect.new();add_child(atmosphere);fill(atmosphere)
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/title_atmosphere.gdshader");atmosphere.material=material
	osd=Control.new();osd.z_index=101;add_child(osd);fill(osd)
	var play:=text(osd,"PLAY  >  SP",22);play.position=Vector2(48,20)
	counter=text(osd,"FITA 01   00:00:00",20);counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);counter.offset_left=-320;counter.offset_right=-48;counter.offset_top=22;counter.offset_bottom=49;counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var footer:=text(osd,"FRANCA, SÃO PAULO  /  DEPOIS DO FECHAMENTO",17);footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);footer.position=Vector2(48,-40)
	intro=Control.new();intro.z_index=100;add_child(intro);fill(intro);intro.mouse_filter=Control.MOUSE_FILTER_STOP
	black=ColorRect.new();intro.add_child(black);fill(black);black.color=Color.BLACK
	var noise:=ColorRect.new();intro.add_child(noise);fill(noise);noise.material=material
	heading=text(intro,"",64);heading.add_theme_font_override("font",DISPLAY);center(heading,Rect2(-520,-88,1040,100))
	heading.add_theme_color_override("font_color",Color("eee3c8"))
	intro_rule=ColorRect.new();intro.add_child(intro_rule);intro_rule.color=Color("c34d36");intro_rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	intro_rule.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caption=text(intro,"",20);center(caption,Rect2(-500,36,1000,50))
	skip_hint=text(intro,"ESPAÇO / ENTER / ESC  ·  PULAR INTRO",17);skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);skip_hint.offset_left=-520;skip_hint.offset_right=-48;skip_hint.offset_top=-43;skip_hint.offset_bottom=-18;skip_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	transition=ColorRect.new();transition.z_index=110;add_child(transition);fill(transition);transition.color=Color(0,0,0,0)
	drone=audio("res://assets/audio/title/title_drone.ogg")
	var loop: AudioStreamOggVorbis=drone.stream.duplicate();loop.loop=true;drone.stream=loop
	tape=audio("res://assets/audio/title/intro_tape.ogg")
	select_audio=audio("res://assets/audio/title/select.wav")
	stop_audio=audio("res://assets/audio/title/ambient/tape_stop.ogg")
	ambience=TitleAmbience.new();add_child(ambience)
	Preferences.changed.connect(apply_audio)
	apply_audio();intro.hide();hide()

func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);control.mouse_filter=Control.MOUSE_FILTER_IGNORE

func text(parent: Control,value: String,font_size: int) -> Label:
	var label:=Label.new();parent.add_child(label);label.text=value;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",VCR);label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("bfb8a4"));return label

func center(label: Label,rect: Rect2) -> void:
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.offset_left=rect.position.x;label.offset_top=rect.position.y;label.offset_right=rect.end.x;label.offset_bottom=rect.end.y
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func audio(path: String) -> AudioStreamPlayer:
	var player:=AudioStreamPlayer.new();add_child(player);player.stream=load(path);return player

func apply_audio() -> void:
	if drone==null:return
	drone.volume_db=-80 if Preferences.music_volume<=0 or menu_gain<=0 else -10+linear_to_db(Preferences.music_volume*menu_gain)
	tape.volume_db=-15+linear_to_db(maxf(Preferences.effects_volume,.001))
	select_audio.volume_db=-25+linear_to_db(maxf(Preferences.effects_volume,.001))
	stop_audio.volume_db=-80 if Preferences.effects_volume<=0 else -16+linear_to_db(Preferences.effects_volume)
	ambience.apply_audio(Preferences.effects_volume,menu_gain)

func set_menu_gain(value: float) -> void:
	menu_gain=value;apply_audio()

func begin(world: ShiftWorld) -> void:
	if departure_tween!=null:departure_tween.kill();departure_tween=null
	if transition_tween!=null:transition_tween.kill();transition_tween=null
	departing=false;set_menu_gain(1)
	restore_camera()
	ambience.bind(world)
	previous_camera=world.player.camera_rig.camera
	# An empty storefront gives the title its atmosphere; restore every visibility
	# flag before gameplay, including the initially hidden enemy/character parts.
	var actors: Array=world.characters.values()
	for actor in get_tree().get_nodes_in_group("familiar_npcs"):
		if world.is_ancestor_of(actor):actors.append(actor)
	for actor in actors:
		hidden_actors.append({"node":actor,"visible":actor.visible});actor.hide()
	camera=Camera3D.new();camera.name="TitleCamera";camera.fov=59
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	world.add_child(camera);camera.position=CAMERA_POSITION;camera.look_at(CAMERA_TARGET);camera.make_current()
	intro_active=true;title_active=true;elapsed=0;title_time=0;menu_time=0;warmup_frames=2
	show();atmosphere.show();osd.show();intro.show();black.color.a=1
	transition.color.a=0
	drone.stop();tape.stop();update_intro()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func update_intro() -> void:
	var reveal:=0.0
	if elapsed<1.2:
		heading.text="";caption.text="";heading.modulate.a=0;caption.modulate.a=0
	elif elapsed<4.0:
		heading.text="Two Brothers Lab";heading.add_theme_font_size_override("font_size",64);caption.text="A P R E S E N T A"
		caption.add_theme_font_override("font",VCR);caption.add_theme_font_size_override("font_size",20)
		reveal=smoothstep(1.2,2.2,elapsed)
		heading.modulate.a=smoothstep(1.2,1.8,elapsed)*(1.0-smoothstep(3.15,3.95,elapsed));caption.modulate.a=heading.modulate.a
	else:
		heading.text="FRANCA, SÃO PAULO";heading.add_theme_font_size_override("font_size",48);caption.text="SEXTA-FEIRA  /  21:40"
		caption.add_theme_font_override("font",TYPEWRITER);caption.add_theme_font_size_override("font_size",16)
		reveal=smoothstep(4.0,5.2,elapsed)
		heading.modulate.a=smoothstep(4.0,4.7,elapsed)*(1.0-smoothstep(6.4,7.5,elapsed));caption.modulate.a=heading.modulate.a
	heading.offset_top=-88+10*(1.0-reveal);heading.offset_bottom=12+10*(1.0-reveal)
	var width:=lerpf(24,96,reveal)
	intro_rule.offset_left=-width*.5;intro_rule.offset_right=width*.5;intro_rule.offset_top=26;intro_rule.offset_bottom=28;intro_rule.modulate.a=heading.modulate.a
	black.color.a=1.0-smoothstep(7.0,DURATION,elapsed)
	skip_hint.modulate.a=.3+smoothstep(.3,1.0,elapsed)*.35

func finish_intro() -> void:
	if not intro_active:return
	intro_active=false;elapsed=DURATION;menu_time=0;intro.hide();tape.stop();ambience.start();intro_finished.emit()

func depart(callback: Callable) -> void:
	if departing:return
	departing=true;intro_active=false;intro.hide();stop_audio.play()
	departure_tween=create_tween().set_parallel(true)
	departure_tween.tween_property(transition,"color:a",1.0,.34).set_trans(Tween.TRANS_SINE)
	departure_tween.tween_method(set_menu_gain,menu_gain,0.0,.34)
	if is_instance_valid(camera):departure_tween.tween_property(camera,"fov",camera.fov-1.2,.34)
	departure_tween.chain().tween_callback(callback)

func restore_camera() -> void:
	if ambience!=null:ambience.restore()
	for actor in hidden_actors:
		if is_instance_valid(actor.node):actor.node.visible=actor.visible
	hidden_actors.clear()
	if is_instance_valid(camera):camera.queue_free()
	camera=null
	if is_instance_valid(previous_camera) and previous_camera.is_inside_tree():previous_camera.make_current()
	previous_camera=null

func dismiss(animate := false) -> void:
	if departure_tween!=null:departure_tween.kill();departure_tween=null
	departing=false
	var was_title:=title_active
	intro_active=false;title_active=false;intro.hide();osd.hide();atmosphere.hide();restore_camera()
	drone.stop();tape.stop();stop_audio.stop();set_menu_gain(1)
	if transition_tween!=null:transition_tween.kill()
	if animate and was_title:
		show();transition.color.a=1
		transition_tween=create_tween();transition_tween.tween_property(transition,"color:a",0.0,.5)
		transition_tween.tween_callback(hide)
	else:transition.color.a=0;hide()

func pause_backdrop() -> void:
	if title_active:dismiss()
	if transition_tween!=null:transition_tween.kill()
	intro_active=false;intro.hide();transition.color.a=0
	show();atmosphere.show();osd.hide()

func select_sound() -> void:
	if not departing and is_inside_tree() and is_visible_in_tree():select_audio.play()

func _input(event: InputEvent) -> void:
	if departing:get_viewport().set_input_as_handled();return
	if not intro_active:return
	var skip: bool=event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE,KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]
	skip=skip or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
	if skip:
		if elapsed>.25:finish_intro()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		if drone!=null:drone.stream_paused=true;tape.stream_paused=true
		return
	drone.stream_paused=false;tape.stream_paused=false
	# Ignore startup/loading deltas, then use real frame time so low FPS does not
	# stretch a nine-second opening into minutes. Audio starts after the warmup.
	var step:=delta
	if title_active and warmup_frames>0:
		warmup_frames-=1;step=0
		if warmup_frames==0:
			drone.play()
			if intro_active:tape.play()
	if title_active:
		title_time+=step
		if not intro_active and not departing:menu_time+=step;ambience.update(step)
		if is_instance_valid(camera) and not departing:
			var push:=smoothstep(0,14,menu_time)
			var direction: Vector3=(CAMERA_TARGET-CAMERA_POSITION).normalized()
			camera.position=CAMERA_POSITION+direction*push*.65+Vector3(sin(title_time*.1)*.16,sin(title_time*.16)*.018,cos(title_time*.1)*.06)
			camera.fov=lerpf(59,56.5,smoothstep(0,10,menu_time))
			camera.look_at(CAMERA_TARGET)
		counter.text="FITA 01   00:%02d:%02d"%[int(title_time/60.0),int(title_time)%60]
	if intro_active:
		elapsed+=step;update_intro()
		if elapsed>=DURATION:finish_intro()

func _exit_tree() -> void:
	if is_instance_valid(drone):drone.stop();tape.stop();select_audio.stop();stop_audio.stop()
	restore_camera()
