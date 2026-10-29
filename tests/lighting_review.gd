extends Node
## Fixed camera comparison of the complete lighting and camera grade.
var app: Node
var camera: Camera3D
var prefix:="lighting014"
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov: float) -> void:
	if prefix.contains("quick") and id not in ["front","entrance","fridges","street"]:return
	camera.position=at;camera.look_at(target);camera.fov=fov
	await frames(4);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png")
	if id in ["entrance","fridges"]:app.viewport.get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+"_raw.png")
	print("CAPTURE ",id)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	Preferences.pixel_scale=1;Preferences.grain=0
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide()
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):friend.hide()
	if prefix.contains("economic"):Preferences.pixel_scale=3;Preferences.changed.emit()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;app.world.add_child(camera);camera.current=true
	await frames(6)
	await shot("front",Vector3(.4,1.78,8.0),Vector3(-.3,2.15,-2.8),68)
	await shot("entrance",Vector3(3.6,1.68,-.4),Vector3(-1.2,1.35,-7.4),70)
	await shot("cashier",Vector3(-2.95,1.57,-1.3),Vector3(-4.30,1.10,-2.9),57)
	await shot("fridges",Vector3(-3.55,1.65,-8.4),Vector3(-4.9,1.15,-6.15),62)
	await shot("inside_out",Vector3(-4.95,1.72,-2.25),Vector3(3.4,1.95,10.5),78)
	await shot("street",Vector3(-8.1,1.55,6.4),Vector3(1.0,.8,9.9),70)
	await shot("stock",Vector3(4.7,1.7,-11.9),Vector3(-.7,1.25,-14.8),72)
	await shot("horizon",Vector3(-27,1.9+Street.grade(-27),6.6),Vector3(-105,1.7+Street.grade(-105),6.6),68)
	var lights:=[]
	for light in app.world.find_children("*","Light3D",true,false):
		lights.append({"path":str(app.world.get_path_to(light)),"energy":light.light_energy,"shadows":light.shadow_enabled,"visible":light.is_visible_in_tree(),"mask":light.light_cull_mask})
	FileAccess.open("/tmp/"+prefix+"_lights.json",FileAccess.WRITE).store_string(JSON.stringify(lights,"\t"))
	app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
