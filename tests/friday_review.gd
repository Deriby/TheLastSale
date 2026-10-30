extends Node
## Staged views for visual comparison; physical routes are covered by integration.
var app: Node
var world: ShiftWorld
var camera: Camera3D
func _ready() -> void:call_deferred("review")
func settle() -> void:
	for i in 12:await get_tree().process_frame
func view(at: Vector3,target: Vector3) -> void:
	camera.position=at;camera.look_at(target);camera.make_current()
func capture(id: String) -> void:
	await settle();await RenderingServer.frame_post_draw
	var path:="/tmp/friday_018_"+id+".png"
	get_viewport().get_texture().get_image().save_png(path);print("CAPTURE ",path)
func review() -> void:
	Session.new_shift();Session.stage=4;Session.warning_delivered=true
	Session.stocked.assign(["stock_1","stock_2"]);Session.organized=true;Session.customers_served=4
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=true;Preferences.pixel_scale=2
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await get_tree().process_frame
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=false
	Session.stage=6;Session.changed.emit()
	world.player.camera_rig.process_mode=Node.PROCESS_MODE_DISABLED
	world.player.process_mode=Node.PROCESS_MODE_DISABLED;app.interface.prompt.text=""
	camera=Camera3D.new();camera.fov=64;world.add_child(camera)
	view(Vector3(4.2,1.9,-.3),Vector3(-1.3,1.4,-7));await capture("store_powered")
	world.friday.begin_outage()
	while Dialogue.active:Dialogue.next_line()
	await capture("outage")
	Session.campaign.flags.generator_key=true;Session.campaign.flags.counter_secured=true
	view(Vector3(3.85,1.8,-17.0),Vector3(5.4,.6,-19.45));await capture("generator_off")
	Session.campaign.phase="restored";Session.campaign.flags.generator_running=true;world.friday.apply_power();Session.changed.emit()
	await capture("generator_running")
	view(Vector3(4.2,1.9,-.3),Vector3(-1.3,1.4,-7));await capture("power_restored")
	Session.campaign.phase="complete";Session.campaign.flags.lights_off=true
	Session.campaign.completed_nights=[0];Session.campaign.reports.friday={"customers":4,"sales_cents":13850}
	world.friday.apply_power();app.interface.show_night_summary();await capture("friday_summary")
	app.interface.night_panel.find_child("NextNight",true,false).pressed.emit();world=app.world
	await settle();await capture("saturday_preview")
	app.queue_free();await get_tree().process_frame
	Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear()
	get_tree().quit()
