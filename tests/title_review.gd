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
		await get_tree().create_timer(11.4,true).timeout
		app.interface.buttons.get_child(2).grab_focus()
		await get_tree().create_timer(1.5,true).timeout
		app.interface.focus_menu()
		await get_tree().create_timer(13.0,true).timeout
		app.interface.start_from_title()
		await get_tree().create_timer(1.4,true).timeout
	else:
		app.interface.presentation.set_process(false)
		app.interface.presentation.elapsed=2.0;app.interface.presentation.update_intro();await capture("intro_author")
		app.interface.presentation.elapsed=5.0;app.interface.presentation.update_intro();await capture("intro_franca")
		app.interface.presentation.finish_intro();app.interface.menu_motion.update(3);await capture("menu")
		app.interface.presentation.ambience.elapsed=3.25;app.interface.presentation.ambience.update(0);await capture("sign_flicker")
		app.interface.presentation.ambience.elapsed=10.2;app.interface.presentation.ambience.update(0);await capture("stock_light")
		var original_size:=get_window().size
		get_window().size=Vector2i(800,600);await capture("menu_800x600")
		get_window().size=original_size;await frames()
		app.interface.open_settings();await capture("settings")
		app.interface.settings.closed.emit()
		app.interface.start_from_title();await get_tree().create_timer(1.0,true).timeout
		app.interface.set_paused(true);app.interface.menu_motion.update(2);await capture("pause")
	app.queue_free();await frames(5)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	get_tree().quit()
