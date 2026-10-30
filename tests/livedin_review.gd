extends Node
var app: Node
var world: ShiftWorld
var camera: Camera3D
func _ready() -> void:call_deferred("run")
func snap(id: String,at: Vector3,target: Vector3) -> void:
	camera.position=at;camera.look_at(target);camera.make_current()
	for i in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("REVIEW_OUTPUT_DIR");DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder.path_join(id+".png"));print("DETAIL_CAPTURE ",id)
func run() -> void:
	Session.new_shift();Preferences.ps1_mode=true;Preferences.ps1_high_resolution=true;Preferences.pixel_scale=2
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await get_tree().process_frame
	app.interface.has_started=true;app.interface.set_paused(false);app.interface.hud.hide();world=app.world;world.active=false
	world.player.camera_rig.process_mode=Node.PROCESS_MODE_DISABLED;world.player.process_mode=Node.PROCESS_MODE_DISABLED
	camera=Camera3D.new();camera.fov=68;world.add_child(camera)
	await snap("stock_tools",Vector3(.8,1.62,-13.65),Vector3(2.2,1.75,-15.85))
	if not OS.get_cmdline_user_args().has("stock-only"):await snap("working_counter",Vector3(-3.10,1.73,-.76),Vector3(-4.4,1.1,-3.15))
	if not OS.get_cmdline_user_args().has("stock-only"):await snap("street_bin",Vector3(-6.0,1.4,3.1),Vector3(-7.8,.7,.48))
	if not OS.get_cmdline_user_args().has("stock-only"):await snap("storefront",Vector3(1.5,1.7,6.5),Vector3(0,2.0,-.2))
	app.queue_free();await get_tree().process_frame;await get_tree().create_timer(.2).timeout
	Geo.materials.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
