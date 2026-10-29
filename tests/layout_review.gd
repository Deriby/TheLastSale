extends Node
## Fixed views of the four reported scene issues; the slice stays paused for review.
var app: Node
var camera: Camera3D
var prefix:="layout012"
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov:=72.0) -> void:
	if prefix.contains("quick") and id not in ["wire_shadows","display","doors_open"]:return
	camera.position=at;camera.look_at(target);camera.fov=fov
	await frames(3);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png");print("CAPTURE ",id)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	Preferences.pixel_scale=1;Preferences.grain=0
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide()
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;app.world.add_child(camera);camera.current=true
	await shot("wire_shadows",Vector3(-11,1.85,7.6),Vector3(-6,.1,4.5),75)
	await shot("roof_inside",Vector3(-3.9,1.75,-1.6),Vector3(-3.1,4.6,-10.0),78)
	await shot("display",Vector3(3.05,1.25,.18),Vector3(4.6,.48,-1.25),60)
	await shot("rear_aisle",Vector3(-3.85,1.65,-8.50),Vector3(1.1,1.05,-10.2),78)
	if prefix.begins_with("after"):
		for fridge in app.world.depot.rear_fridges:fridge.hinge.rotation.y=-1.35
		await shot("doors_open",Vector3(-3.7,1.65,-8.5),Vector3(1.1,1.0,-10.1),78)
		await shot("roof_outside",Vector3(-9,8,2),Vector3(-2.7,4.7,-9),70)
	app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
