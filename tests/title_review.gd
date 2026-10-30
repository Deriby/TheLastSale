extends Node
var app: Node
var output: String
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func frames(count := 5) -> void:
	for i in count:await get_tree().process_frame
func capture(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")
	print("TITLE CAPTURE ",name)
func run() -> void:
	output=OS.get_environment("TITLE_REVIEW_PATH")
	if output.is_empty():output="/tmp"
	DirAccess.make_dir_recursive_absolute(output)
	# The software-rendered preview records the existing Retrô quality preset.
	Preferences.ps1_mode=false;Preferences.pixel_scale=2 if "movie" in OS.get_cmdline_user_args() else 1;Preferences.frame_limit=30;Preferences.apply()
	Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app)
	app.interface.begin_title(app.world)
	if "movie" in OS.get_cmdline_user_args():
		await get_tree().create_timer(12.5,true).timeout
	else:
		app.interface.presentation.elapsed=2.0;await capture("intro_author")
		app.interface.presentation.elapsed=5.0;await capture("intro_franca")
		app.interface.presentation.finish_intro();await capture("menu")
		app.interface.open_settings();await capture("settings")
		app.interface.settings.closed.emit()
		app.interface.start_from_title();await get_tree().create_timer(.65,true).timeout
		app.interface.set_paused(true);await capture("pause")
	app.queue_free();await frames(5)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	get_tree().quit()
