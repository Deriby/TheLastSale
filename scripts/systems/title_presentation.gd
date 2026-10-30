class_name TitlePresentation
extends Control
## Launch-only tape sequence. Reuses the existing world/viewport, never advances it.
signal intro_finished
const SERIF = preload("res://assets/fonts/title/TitleSerif.ttf")
const MONO = preload("res://assets/fonts/title/TitleMono.ttf")
const DURATION := 9.4
const CAMERA_POSITION := Vector3(-8.2,1.85,9.7)
const CAMERA_TARGET := Vector3(.6,2.05,-.1)
var intro_active := false
var title_active := false
var elapsed := 0.0
var title_time := 0.0
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
var skip_hint: Label
var transition: ColorRect
var transition_tween: Tween
var drone: AudioStreamPlayer
var tape: AudioStreamPlayer
var select_audio: AudioStreamPlayer

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere=ColorRect.new();add_child(atmosphere);fill(atmosphere)
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/title_atmosphere.gdshader");atmosphere.material=material
	osd=Control.new();osd.z_index=101;add_child(osd);fill(osd)
	var play:=text(osd,"PLAY  ▶  SP",14);play.position=Vector2(48,31)
	counter=text(osd,"FITA 01   00:00:00",12);counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);counter.offset_left=-320;counter.offset_right=-48;counter.offset_top=33;counter.offset_bottom=56;counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var footer:=text(osd,"FRANCA, SÃO PAULO  /  DEPOIS DO FECHAMENTO",11);footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);footer.position=Vector2(48,-40)
	intro=Control.new();intro.z_index=100;add_child(intro);fill(intro);intro.mouse_filter=Control.MOUSE_FILTER_STOP
	black=ColorRect.new();intro.add_child(black);fill(black);black.color=Color.BLACK
	var noise:=ColorRect.new();intro.add_child(noise);fill(noise);noise.material=material
	heading=text(intro,"",44);heading.add_theme_font_override("font",SERIF);center(heading,Rect2(-520,-80,1040,100))
	caption=text(intro,"",14);center(caption,Rect2(-500,29,1000,50))
	skip_hint=text(intro,"ESPAÇO / ENTER / ESC  ·  PULAR INTRO",11);skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);skip_hint.offset_left=-520;skip_hint.offset_right=-48;skip_hint.offset_top=-43;skip_hint.offset_bottom=-22;skip_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	transition=ColorRect.new();transition.z_index=110;add_child(transition);fill(transition);transition.color=Color(0,0,0,0)
	drone=audio("res://assets/audio/title/title_drone.ogg")
	var loop: AudioStreamOggVorbis=drone.stream.duplicate();loop.loop=true;drone.stream=loop
	tape=audio("res://assets/audio/title/intro_tape.ogg")
	select_audio=audio("res://assets/audio/title/select.wav")
	Preferences.changed.connect(apply_audio)
	apply_audio();intro.hide();hide()

func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);control.mouse_filter=Control.MOUSE_FILTER_IGNORE

func text(parent: Control,value: String,font_size: int) -> Label:
	var label:=Label.new();parent.add_child(label);label.text=value;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",MONO);label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("bfb8a4"));return label

func center(label: Label,rect: Rect2) -> void:
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.offset_left=rect.position.x;label.offset_top=rect.position.y;label.offset_right=rect.end.x;label.offset_bottom=rect.end.y
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func audio(path: String) -> AudioStreamPlayer:
	var player:=AudioStreamPlayer.new();add_child(player);player.stream=load(path);return player

func apply_audio() -> void:
	if drone==null:return
	drone.volume_db=-80 if Preferences.music_volume<=0 else -10+linear_to_db(Preferences.music_volume)
	tape.volume_db=-15+linear_to_db(maxf(Preferences.effects_volume,.001))
	select_audio.volume_db=-25+linear_to_db(maxf(Preferences.effects_volume,.001))

func begin(world: ShiftWorld) -> void:
	restore_camera()
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
	intro_active=true;title_active=true;elapsed=0;title_time=0;warmup_frames=2
	show();atmosphere.show();osd.show();intro.show();black.color.a=1
	transition.color.a=0
	drone.stop();tape.stop();update_intro()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func update_intro() -> void:
	if elapsed<1.2:
		heading.text="";caption.text=""
	elif elapsed<4.0:
		heading.text="Two Brothers Lab";heading.add_theme_font_size_override("font_size",44);caption.text="A P R E S E N T A"
		heading.modulate.a=smoothstep(1.2,1.8,elapsed)*(1.0-smoothstep(3.15,3.95,elapsed));caption.modulate.a=heading.modulate.a
	else:
		heading.text="FRANCA, SÃO PAULO";heading.add_theme_font_size_override("font_size",30);caption.text="SEXTA-FEIRA  /  21:40"
		heading.modulate.a=smoothstep(4.0,4.7,elapsed)*(1.0-smoothstep(6.4,7.5,elapsed));caption.modulate.a=heading.modulate.a
	black.color.a=1.0-smoothstep(7.0,DURATION,elapsed)
	skip_hint.modulate.a=.3+smoothstep(.3,1.0,elapsed)*.35

func finish_intro() -> void:
	if not intro_active:return
	intro_active=false;elapsed=DURATION;intro.hide();tape.stop();intro_finished.emit()

func restore_camera() -> void:
	for actor in hidden_actors:
		if is_instance_valid(actor.node):actor.node.visible=actor.visible
	hidden_actors.clear()
	if is_instance_valid(camera):camera.queue_free()
	camera=null
	if is_instance_valid(previous_camera) and previous_camera.is_inside_tree():previous_camera.make_current()
	previous_camera=null

func dismiss(animate := false) -> void:
	var was_title:=title_active
	intro_active=false;title_active=false;intro.hide();osd.hide();atmosphere.hide();restore_camera()
	drone.stop();tape.stop()
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
	if is_inside_tree() and is_visible_in_tree():select_audio.play()

func _input(event: InputEvent) -> void:
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
		if is_instance_valid(camera):
			camera.position=CAMERA_POSITION+Vector3(sin(title_time*.08)*.18,sin(title_time*.13)*.015,cos(title_time*.08)*.07)
			camera.look_at(CAMERA_TARGET)
		counter.text="FITA 01   00:%02d:%02d"%[int(title_time/60.0),int(title_time)%60]
	if intro_active:
		elapsed+=step;update_intro()
		if elapsed>=DURATION:finish_intro()

func _exit_tree() -> void:
	if is_instance_valid(drone):drone.stop();tape.stop();select_audio.stop()
	restore_camera()
