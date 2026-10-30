extends Node
var app: Node
var output: String
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func frames(count := 5) -> void:
	for i in count: await get_tree().process_frame
func shot(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")
	print("CAPTURE ",name)
func run() -> void:
	output=OS.get_environment("PSX_REVIEW_PATH")
	if output.is_empty():output="/tmp"
	Preferences.frame_limit=0;Preferences.grain=0;Preferences.vhs=0;Preferences.ps1_mode=true;Preferences.pixel_scale=2
	Preferences.psx_vertices=0;Preferences.psx_affine=0
	Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app)
	app.interface.menu.hide();app.interface.hud.show()
	app.world.player.hide()
	var camera:=Camera3D.new();app.world.add_child(camera);camera.current=true
	camera.position=Vector3(3.6,1.68,-.4);camera.look_at(Vector3(-1.2,1.35,-7.4));camera.fov=70
	await frames(8)
	for high in [false,true]:
		Preferences.ps1_high_resolution=high
		for intensity in [0,1,2]:
			Preferences.psx_vertices=intensity;Preferences.psx_affine=intensity;Preferences.apply()
			await shot(("ps12_" if high else "ps1_")+["off","soft","strong"][intensity])
	Preferences.psx_vertices=1;Preferences.psx_affine=1;Preferences.apply()
	app.interface.hud.hide();app.interface.open_settings();await frames()
	var scroll: ScrollContainer=app.interface.settings.find_child("SettingsScroll",true,false)
	scroll.scroll_vertical=420
	await shot("settings")
	app.queue_free();await frames()
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	get_tree().quit()
