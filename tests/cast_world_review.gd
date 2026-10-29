extends Node
## Actual depot scene, imported car and replacement customers, with optional Eco quality.
var app: Node
var camera: Camera3D
var prefix:="cast_world"
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov:=60.0) -> void:
	camera.position=at;camera.look_at(target);camera.fov=fov
	await frames(10);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png");print("CAPTURE ",id)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	if prefix.contains("eco"):Preferences.pixel_scale=3
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.root.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;app.world.add_child(camera);camera.current=true
	app.world.player.position=Vector3(-2.0,0,-1.85);app.world.player.visual.rotation.y=PI/2;app.world.player.reset_physics_interpolation()
	await shot("depot",Vector3(-.45,1.58,-.05),Vector3(-4.65,1.16,-2.85),74)
	app.world.player.hide()
	await shot("felps",Vector3(-3.0,1.55,-3.1),Vector3(-5.12,1.12,-3.1),61)
	await shot("bryan",Vector3(-.5,1.25,-1.7),Vector3(-2.8,.65,-.1),60)
	await shot("zirico",Vector3(3,1.5,3.7),Vector3(5.1,1.0,1.65),58)
	await shot("car",Vector3(6.1,1.4,6.8),Vector3(3,.8,9.55),60)
	for i in 3:
		var client:=Customer.new();client.navigation=app.world.navigation;client.appearance=i;app.world.add_child(client)
		client.position=CheckoutFixture.CUSTOMER_POSITION;client.visual.rotation.y=-PI/2;client.product.show();client.motion.play("hold_bottle",0)
		await shot("customer_"+str(i+1),Vector3(-5.0,1.58,-1.5),Vector3(-3.10,1.02,-2.8),65)
		client.queue_free();await frames(3)
	var enabled:=0
	for entry in CharacterModels.imported_materials.values():
		if entry.material.normal_enabled:enabled+=1
	print("IMPORTED_QUALITY pixel_scale=",Preferences.pixel_scale," normal_materials=",enabled)
	app.queue_free();await frames(20)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(4);get_tree().quit()
