extends Node
var screen: SubViewportContainer
var viewport: SubViewport
var world: ShiftWorld
var interface: ShiftInterface
var retro: ShaderMaterial
var initial_world_pristine:=false
func _ready() -> void:
	Controls.install()
	var background:=ColorRect.new();background.name="LetterboxBackground";add_child(background);background.color=Color.BLACK;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen=SubViewportContainer.new();add_child(screen);screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);screen.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.stretch=true;screen.stretch_shrink=Preferences.pixel_scale;screen.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport=SubViewport.new();viewport.size=Vector2i(640,360);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.handle_input_locally=false;screen.add_child(viewport)
	var layer:=CanvasLayer.new();layer.layer=2;add_child(layer)
	var effect:=ColorRect.new();layer.add_child(effect);effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);effect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	retro=ShaderMaterial.new();retro.shader=load("res://shaders/retro.gdshader");effect.material=retro
	interface=ShiftInterface.new();add_child(interface)
	interface.new_game.connect(start_new)
	interface.continue_game.connect(start_saved)
	interface.next_night.connect(start_next_night)
	Preferences.changed.connect(apply_settings);get_viewport().size_changed.connect(update_render_size);apply_settings()
	initial_world_pristine=Session.stage==0 and Session.stocked.is_empty() and not Session.organized and Session.carried_id.is_empty() and Session.campaign.phase=="routine"
	build_world()
	get_tree().paused=true
func apply_settings() -> void:
	SurfaceMaterials.apply_quality()
	ProductLibrary.apply_quality()
	CharacterModels.apply_quality()
	update_render_size()
	if viewport!=null:viewport.msaa_3d=Viewport.MSAA_2X if Preferences.pixel_scale==1 else Viewport.MSAA_DISABLED
	if retro!=null:
		retro.set_shader_parameter("grain",Preferences.grain);retro.set_shader_parameter("vhs",Preferences.vhs)
		retro.set_shader_parameter("bloom_strength",.30 if Preferences.pixel_scale<3 else 0.0)
		retro.set_shader_parameter("posterize",Preferences.pixel_scale>1)
func update_render_size() -> void:
	if screen==null or viewport==null:return
	var available:=get_viewport().get_visible_rect().size
	if available.x<=0 or available.y<=0:return
	var bounds:=Vector4(0,0,1,1)
	screen.scale=Vector2.ONE
	if Preferences.ps1_mode:
		var render_size:=Vector2(640,480) if Preferences.ps1_high_resolution else Vector2(320,240)
		var zoom:=maxi(1,floori(minf(available.x/render_size.x,available.y/render_size.y)))
		screen.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		screen.stretch_shrink=zoom;screen.size=render_size*zoom
		# Enlarge 640x480 to the same 4:3 area even when the window fits a fractional scale.
		if Preferences.ps1_high_resolution:screen.scale=Vector2.ONE*minf(available.x/screen.size.x,available.y/screen.size.y)
		var display_size:=screen.size*screen.scale
		screen.position=((available-display_size)*.5).floor()
		bounds=Vector4(screen.position.x/available.x,screen.position.y/available.y,(screen.position.x+display_size.x)/available.x,(screen.position.y+display_size.y)/available.y)
	else:
		screen.stretch_shrink=Preferences.pixel_scale
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if retro!=null:retro.set_shader_parameter("game_bounds",bounds)
func build_world() -> void:
	interface.close_surveillance();interface.close_checkout()
	if world!=null:
		viewport.remove_child(world);world.free()
	world=ShiftWorld.new();viewport.add_child(world)
	for actor in world.characters.values():actor.focused.connect(on_focused.bind(actor))
	world.player_changed.connect(func(actor: DepotPlayer):interface.set_character(actor))
	world.notice.connect(interface.show_notice)
	world.checkout_requested.connect(func():interface.open_checkout(world))
	world.surveillance_requested.connect(func():interface.open_surveillance(world))
	world.checkout_closed.connect(interface.close_checkout)
	world.checkout_changed.connect(interface.update_objective)
	world.slice_finished.connect(interface.show_night_summary)
	interface.set_character(world.player,false)
	world.restore_transient()
func on_focused(text: String,actor: DepotPlayer) -> void:
	if actor.controlled:interface.prompt.text=text
func start_new() -> void:
	Dialogue.clear();Session.new_shift()
	if initial_world_pristine and is_instance_valid(world) and not world.active:
		world.player.position=world.navigation.nearest_walkable(Session.saved_position);world.player.velocity=Vector3.ZERO;world.player.reset_physics_interpolation()
		world.player.camera_rig.target_distance=Preferences.camera_distance;world.player.camera_rig.distance=Preferences.camera_distance;world.player.camera_rig.reset_follow()
		world.player.camera_rig.arm.spring_length=Preferences.camera_distance;world.player.camera_rig.camera.position.z=Preferences.camera_distance
	else:build_world()
	initial_world_pristine=false;world.active=true
func start_saved() -> void:
	initial_world_pristine=false
	Dialogue.clear()
	if not Session.load_shift():Session.new_shift()
	build_world();world.active=true
func start_saturday() -> void:
	Dialogue.clear();Session.advance_to_saturday();build_world();world.active=true
	Session.save_shift(world.player.global_position)

func start_next_night() -> void:
	if int(Session.campaign.night)==0:start_saturday();return
	Dialogue.clear();Session.advance_to_sunday();build_world();world.active=true
	Session.save_shift(world.player.global_position)
func _unhandled_input(event: InputEvent) -> void:
	if interface.paused or interface.checkout!=null or interface.surveillance!=null or world==null:return
	if event.is_action_pressed("surveillance"):
		if not world.try_surveillance():interface.show_notice("Felps acessa as câmeras no caixa, depois da conversa de abertura. Termine o atendimento aberto antes de usar C.")
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("switch_character"):
		world.switch_player();get_viewport().set_input_as_handled();return
	world.player.camera_rig.handle_input(event)
	world.player.handle_input(event)
