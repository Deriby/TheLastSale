extends Node
## Review the customer/employee sightlines and horizon in the actual game scene.
var app: Node
var camera: Camera3D
var prefix:="scene05"
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov:=70.0,staff:=true) -> void:
	app.world.depot.felps.visible=staff
	camera.fov=fov;camera.position=at;camera.look_at(target)
	await frames(12);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png")
	print("CAPTURE ",id)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;camera.far=110;app.world.add_child(camera);camera.current=true
	await shot("customer",Vector3(-2.85,1.67,-1.8),Vector3(-4.5,1.25,-2.85),67)
	await shot("employee",Vector3(-5.13,1.68,-2.50),Vector3(-1.0,1.3,-5.4),76,false)
	await shot("worktop",Vector3(-5.14,1.68,-3.18),Vector3(-4.22,1.16,-2.80),64,false)
	await shot("drawer",Vector3(-5.20,1.25,-2.8),Vector3(-4.25,.72,-2.8),65,false)
	await shot("inside_out",Vector3(-4.95,1.72,-2.25),Vector3(3.4,1.95,10.5),78,false)
	await shot("entrance",Vector3(.10,1.70,-.55),Vector3(-.4,1.35,-6.8),74)
	await shot("aisle",Vector3(4.1,1.68,-3.0),Vector3(-1.6,1.25,-7.0),72)
	await shot("front",Vector3(.4,2.15,8.1),Vector3(.4,3.1,0),61)
	await shot("downhill",Vector3(-1,1.9,6.6),Vector3(-50,-.2,6.6),65)
	await shot("uphill",Vector3(0,1.9,6.6),Vector3(50,2.3,6.6),65)
	await shot("edge_fog",Vector3(-27,1.9+Street.grade(-27),6.6),Vector3(-130,Street.grade(-130)+1.7,6.6),68)
	var env: Environment=app.world.get_node("Atmosphere").environment
	env.fog_enabled=false
	await shot("edge_clear",Vector3(-27,1.9+Street.grade(-27),6.6),Vector3(-130,Street.grade(-130)+1.7,6.6),68)
	env.fog_enabled=true
	# Reference lighting only; gameplay remains at night.
	env.background_color=Color("b8c8d1");env.ambient_light_color=Color("d5dde1");env.ambient_light_energy=.68;env.fog_light_color=Color("b8c8d1")
	var sun: DirectionalLight3D=app.world.get_child(1);sun.light_color=Color("fff1d3");sun.light_energy=1.0;sun.rotation_degrees=Vector3(-52,-35,0)
	for light in app.world.street.find_children("*","OmniLight3D",true,false):light.light_energy=0
	for light in app.world.depot.get_node("Architecture/Facade").find_children("*","SpotLight3D",true,false):light.light_energy=0
	await shot("inside_out_day",Vector3(-4.95,1.72,-2.25),Vector3(3.4,1.95,10.5),78,false)
	app.queue_free();await frames(20);await get_tree().create_timer(.2).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();await frames(4);get_tree().quit()
