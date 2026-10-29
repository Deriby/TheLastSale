extends Node
var screen: SubViewportContainer
var viewport: SubViewport
var world: ShiftWorld
var interface: ShiftInterface
var retro: ShaderMaterial
var initial_world_pristine:=false
func _ready() -> void:
	Controls.install()
	screen=SubViewportContainer.new();add_child(screen);screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);screen.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.stretch=true;screen.stretch_shrink=Preferences.pixel_scale;screen.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport=SubViewport.new();viewport.size=Vector2i(640,360);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.handle_input_locally=false;screen.add_child(viewport)
	var layer:=CanvasLayer.new();layer.layer=2;add_child(layer)
	var effect:=ColorRect.new();layer.add_child(effect);effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);effect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	retro=ShaderMaterial.new();retro.shader=load("res://shaders/retro.gdshader");effect.material=retro
	interface=ShiftInterface.new();add_child(interface)
	interface.new_game.connect(start_new)
	interface.continue_game.connect(start_saved)
	Preferences.changed.connect(apply_settings);apply_settings()
	initial_world_pristine=Session.stage==0 and Session.stocked.is_empty() and not Session.organized and Session.carried_id.is_empty()
	build_world()
	get_tree().paused=true
func apply_settings() -> void:
	SurfaceMaterials.apply_quality()
	CharacterModels.apply_quality()
	if screen!=null:screen.stretch_shrink=Preferences.pixel_scale
	if viewport!=null:viewport.msaa_3d=Viewport.MSAA_2X if Preferences.pixel_scale==1 else Viewport.MSAA_DISABLED
	if retro!=null:
		retro.set_shader_parameter("grain",Preferences.grain);retro.set_shader_parameter("vhs",Preferences.vhs)
		retro.set_shader_parameter("bloom_strength",.48 if Preferences.pixel_scale<3 else 0.0)
func build_world() -> void:
	if world!=null:
		viewport.remove_child(world);world.free()
	world=ShiftWorld.new();viewport.add_child(world)
	world.player.focused.connect(func(text):interface.prompt.text=text)
	world.restore_transient()
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

func _unhandled_input(event: InputEvent) -> void:
	if interface.paused or world==null:return
	world.player.camera_rig.handle_input(event)
	world.player.handle_input(event)
