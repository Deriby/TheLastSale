extends Node
## Real W/Shift input, original collisions, camera, HUD and animation controller.
var app: Node
var elapsed:=0.0
var swapped:=false
var running_seconds: Dictionary={"Dery":0.0,"Felps":0.0}
func _ready() -> void:
	Preferences.ps1_mode=false;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false);place_actor(app.world.player)
func place_actor(actor: DepotPlayer) -> void:
	actor.global_position=Vector3(3.3,.01,.4);actor.velocity=Vector3.ZERO;actor.visual.rotation.y=PI;actor.reset_physics_interpolation()
	actor.camera_rig.yaw=0;actor.camera_rig.pitch=-.12;actor.camera_rig.target_distance=2.5;actor.camera_rig.reset_follow()
func _physics_process(delta: float) -> void:
	if app==null:return
	var actor: DepotPlayer=app.world.player
	if actor.motion.current_clip=="run" and actor.actual_speed>3.4:running_seconds[actor.identity]+=delta
func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed>=3.6 and not swapped:
		swapped=true;Input.action_release("forward");Input.action_release("sprint")
		app.world.player.global_position=Vector3(3.8,.01,-8.8);app.world.player.reset_physics_interpolation()
		app.world.switch_player();place_actor(app.world.player)
	var local:=fmod(elapsed,3.6)
	if elapsed<7.2 and local<2.6:
		Input.action_press("forward")
		if local>=.6:Input.action_press("sprint")
		else:Input.action_release("sprint")
	else:Input.action_release("forward");Input.action_release("sprint")
	if elapsed>=7.8:set_process(false);set_physics_process(false);call_deferred("finish")
func finish() -> void:
	Input.action_release("forward");Input.action_release("sprint");print("GAME SPRINT SECONDS ",JSON.stringify(running_seconds))
	var valid: bool=running_seconds.Dery>1.3 and running_seconds.Felps>1.3
	app.queue_free()
	for frame in 5:await get_tree().process_frame
	await get_tree().create_timer(.12,true).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	get_tree().quit(0 if valid else 1)
