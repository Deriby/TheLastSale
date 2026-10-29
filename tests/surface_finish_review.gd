extends Node
## Fixed lighting and cameras compare material response without changing the scene.
var app: Node
var camera: Camera3D
var prefix:="surfaces13"
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov: float) -> void:
	if prefix.contains("quick") and id not in ["counter","stock","street"]:return
	camera.position=at;camera.look_at(target);camera.fov=fov
	await frames(3);await RenderingServer.frame_post_draw
	app.viewport.get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png")
	print("CAPTURE ",id)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	Preferences.pixel_scale=1;Preferences.grain=0
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide();app.world.depot.felps.hide()
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.hide()
	if prefix.contains("economic"):Preferences.pixel_scale=3;Preferences.changed.emit()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;app.world.add_child(camera);camera.current=true
	await shot("counter",Vector3(-2.95,1.57,-1.30),Vector3(-4.30,1.10,-2.90),57)
	await shot("floor",Vector3(2.8,1.35,-1.9),Vector3(.2,.05,-4.0),66)
	await shot("stock",Vector3(3.45,1.56,-8.70),Vector3(1.40,1.05,-7.0),56)
	await shot("fridge",Vector3(-3.55,1.65,-8.4),Vector3(-4.9,1.15,-6.15),62)
	await shot("crates",Vector3(3.05,1.25,.18),Vector3(4.6,.48,-1.25),60)
	await shot("street",Vector3(-8.1,1.55,6.4),Vector3(1.0,.8,9.9),70)
	app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
