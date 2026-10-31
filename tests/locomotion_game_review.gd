extends Node
## Real player input, collisions, camera, HUD and followers in the published depot.
var app: Node
var elapsed := 0.0
var swapped := false
func _ready() -> void:
	Preferences.ps1_mode=false;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	place_actor(app.world.player)
	Input.action_press("forward")
func place_actor(actor: DepotPlayer) -> void:
	actor.global_position=Vector3(3.0,.01,1.0);actor.velocity=Vector3.ZERO;actor.visual.rotation.y=PI;actor.reset_physics_interpolation()
	actor.camera_rig.yaw=0;actor.camera_rig.pitch=-.12;actor.camera_rig.target_distance=2.5;actor.camera_rig.reset_follow()
func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed>3.3 and not swapped:
		swapped=true;Input.action_release("forward")
		app.world.player.global_position=Vector3(3.5,.01,-8.2);app.world.player.reset_physics_interpolation()
		app.world.switch_player();place_actor(app.world.player);Input.action_press("forward")
	if elapsed>6.6:Input.action_release("forward")
	if elapsed>7.4:
		set_process(false);call_deferred("finish")
func finish() -> void:
	Input.action_release("forward");app.queue_free()
	for frame in 5:await get_tree().process_frame
	await get_tree().create_timer(.12,true).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
