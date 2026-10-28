extends Node
var app: Node
var camera: Camera3D
var prefix:="street"
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3) -> void:
	camera.position=at;camera.look_at(target)
	await frames(8);await RenderingServer.frame_post_draw
	app.viewport.get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png")
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide();app.world.depot.felps.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;app.world.add_child(camera);camera.current=true;camera.fov=72
	camera.fov=56
	await shot("night_front",Vector3(.4,2.15,9.8),Vector3(.4,3.15,0))
	camera.fov=72
	await shot("night_opposite",Vector3(1,1.8,2.2),Vector3(1,1.6,13))
	var env: WorldEnvironment=app.world.get_child(0)
	env.environment.background_color=Color("b8c8d1");env.environment.ambient_light_color=Color("d5dde1");env.environment.ambient_light_energy=.68
	var sun: DirectionalLight3D=app.world.get_child(1);sun.light_color=Color("fff1d3");sun.light_energy=1.0;sun.rotation_degrees=Vector3(-52,-35,0)
	for light in app.world.street.find_children("*","OmniLight3D",true,false):light.light_energy=0
	for light in app.world.depot.get_node("Architecture/Facade").find_children("*","SpotLight3D",true,false):light.light_energy=0
	camera.fov=56
	await shot("day_front",Vector3(.4,2.15,9.8),Vector3(.4,3.15,0))
	camera.fov=72
	await shot("day_opposite",Vector3(1,1.9,2.0),Vector3(1,1.6,13))
	await shot("day_downhill",Vector3(-1,1.9,6.6),Vector3(-31,.3,6.6))
	await shot("day_uphill",Vector3(0,1.9,6.6),Vector3(30,2.0,6.6))
	if prefix.begins_with("debug"):
		await shot("gate_original",Vector3(-9.55,1.3,8.5),Vector3(-9.55,1.3,12.4))
		for mat in Geo.materials.values():
			if mat.albedo_texture!=null and mat.albedo_texture.resource_path.ends_with("street/gate.png"):mat.uv1_triplanar=false
		await shot("gate_uv",Vector3(-9.55,1.3,8.5),Vector3(-9.55,1.3,12.4))
		for mat in Geo.materials.values():
			if mat.albedo_texture!=null and mat.albedo_texture.resource_path.ends_with("street/gate.png"):mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		await shot("gate_unshaded",Vector3(-9.55,1.3,8.5),Vector3(-9.55,1.3,12.4))
	app.queue_free();await frames(20);await get_tree().create_timer(.2).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();await frames(4);get_tree().quit()
