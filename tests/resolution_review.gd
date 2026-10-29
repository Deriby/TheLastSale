extends Node
var app: Node
var report: Dictionary={}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String) -> void:
	await frames(4);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/ps12_0151_"+id+".png")
	print("CAPTURE ",id," render=",app.viewport.size," window=",get_window().size," game_rect=",app.screen.get_global_rect())
	var rect: Rect2=app.screen.get_global_rect()
	report[id]={"internal_resolution":[app.viewport.size.x,app.viewport.size.y],"window_size":[get_window().size.x,get_window().size.y],"ui_size":[app.interface.root.size.x,app.interface.root.size.y],"image_position":[rect.position.x,rect.position.y],"image_size":[rect.size.x,rect.size.y]}
func review() -> void:
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=false;Preferences.pixel_scale=2;Preferences.grain=0
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	app.world.player.position=Vector3(2.7,.01,-.1);app.world.player.camera_rig.yaw=.32;app.world.player.reset_physics_interpolation()
	await shot("ps1_320")
	app.interface.set_paused(true);app.interface.open_settings()
	var resolution_select: OptionButton=app.interface.settings.find_child("RenderQuality",true,false)
	resolution_select.select(4);resolution_select.item_selected.emit(4);await shot("settings")
	app.interface.settings.closed.emit();app.interface.set_paused(false);await shot("ps12_640")
	FileAccess.open("/tmp/ps12_0151_layout.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
