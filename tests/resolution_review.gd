extends Node
var app: Node
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String) -> void:
	await frames(4);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/ps1_015_"+id+".png")
	print("CAPTURE ",id," render=",app.viewport.size," window=",get_window().size," game_rect=",app.screen.get_global_rect())
func review() -> void:
	Preferences.ps1_mode=true;Preferences.pixel_scale=2;Preferences.grain=0
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	app.world.player.position=Vector3(2.7,.01,-.1);app.world.player.camera_rig.yaw=.32;app.world.player.reset_physics_interpolation()
	await shot("gameplay")
	app.interface.set_paused(true);app.interface.open_settings();await shot("settings")
	var report:={"internal_resolution":app.viewport.size,"window_size":get_window().size,"ui_size":app.interface.root.size,"image_rect":str(app.screen.get_global_rect()),"shader_game_bounds":str(app.retro.get_shader_parameter("game_bounds"))}
	FileAccess.open("/tmp/ps1_015_layout.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	app.interface.settings.closed.emit();app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
