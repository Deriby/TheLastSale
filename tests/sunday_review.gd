extends Node
## Staged visual review. Actual quest routes and real pursuit are tested separately.
var app: Node
var world: ShiftWorld
var camera: Camera3D
func _ready() -> void:call_deferred("review")
func capture(id: String) -> void:
	for i in 18:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("REVIEW_OUTPUT_DIR");DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder.path_join(id+".png"));print("SUNDAY_CAPTURE ",id)
func view(at: Vector3,target: Vector3) -> void:camera.position=at;camera.look_at(target);camera.make_current()
func review() -> void:
	Session.new_shift();Session.advance_to_sunday();Session.campaign.phase="sunday_investigation"
	Session.campaign.flags.module_found=true;Session.campaign.flags.module_delivered=true;Session.campaign.flags.help_notified=true
	Session.campaign.decisions={"help":"contact","exit":"prepared"};Session.stocked.assign(["stock_1","stock_2"]);Session.organized=true
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=true;Preferences.pixel_scale=2
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await get_tree().process_frame
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=false
	world.select_player("Felps");world.try_surveillance();app.interface.sunday_desk.recover();await capture("dvr_playback")
	app.interface.close_sunday_desk();world.sunday.change_door("old",true)
	world.player.camera_rig.process_mode=Node.PROCESS_MODE_DISABLED;world.player.process_mode=Node.PROCESS_MODE_DISABLED
	camera=Camera3D.new();camera.fov=72;world.add_child(camera);app.interface.hud.hide()
	view(Vector3(.25,1.5,-17.3),Vector3(-.1,1.25,-20));await capture("maintenance_room")
	Session.campaign.phase="sunday_escape";Session.stage=6;Session.campaign.flags.stock_released=true;world.sunday.state().doors.stock=true
	world.sunday.state().killer={"position":[4.8,0,-12.4],"mode":"chase","facing":0,"grace":0};world.sunday.spawn_killer();world.sunday.apply_scene()
	world.characters.Dery.position=Vector3(4.5,0,-9.8);world.characters.Dery.torch.show()
	view(Vector3(4.75,1.6,-8.5),Vector3(4.7,1.3,-12.4));await capture("pursuer")
	world.sunday.caught_identity="Dery";app.interface.show_campaign("defeat");await capture("retry")
	for id in ["resolved","unresolved","alone"]:
		Session.campaign.phase="campaign_complete";Session.campaign.ending={"id":id,"survivors":["Felps"] if id=="alone" else ["Dery","Felps"],"proof":id=="resolved","help":true,"exit_prepared":true}
		app.interface.show_campaign("ending");await capture("ending_"+id)
	app.queue_free();await get_tree().process_frame;await get_tree().create_timer(.2).timeout
	Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear();get_tree().quit()
