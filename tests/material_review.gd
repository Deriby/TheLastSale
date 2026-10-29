extends Node
## Identical cameras/light expose surface scale and response, before and after.
var app: Node
var camera: Camera3D
var prefix:="materials08"
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov: float) -> void:
	if prefix.contains("quick") and id not in ["wood","asphalt"]:return
	camera.position=at;camera.look_at(target);camera.fov=fov
	await frames(8);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png")
	print("CAPTURE ",id)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	var economic:=prefix.contains("economic")
	if economic:Preferences.pixel_scale=1
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide();app.world.depot.felps.hide()
	# Exercise the real settings signal after surfaces already exist.
	if economic:Preferences.pixel_scale=3;Preferences.changed.emit()
	var surfaces:=0;var detail:=0
	for mat in Geo.materials.values():
		if mat is StandardMaterial3D and mat.has_meta("surface_profile"):
			surfaces+=1
			if mat.normal_enabled:detail+=1
	var shadowed:=0
	for light in app.world.find_children("*","Light3D",true,false):
		if light.shadow_enabled:shadowed+=1
	print("MATERIALS quality=",Preferences.pixel_scale," surfaces=",surfaces," normal_maps_enabled=",detail," shadowed_lights=",shadowed)
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;camera.far=110;app.world.add_child(camera);camera.current=true
	await shot("wood",Vector3(-3.12,1.48,-3.6),Vector3(-4.35,1.07,-2.95),58)
	await shot("tile",Vector3(2.1,1.30,-.8),Vector3(.9,0,-2.3),62)
	await shot("wall",Vector3(3.65,1.8,-2.0),Vector3(5.89,1.4,-3.85),62)
	await shot("asphalt",Vector3(0,1.35,5.0),Vector3(1.9,-.14,6.5),65)
	await shot("paving",Vector3(-.8,1.4,3.05),Vector3(-3,0,1.6),62)
	await shot("inside_out",Vector3(-4.95,1.72,-2.25),Vector3(3.4,1.95,10.5),78)
	await shot("front",Vector3(.4,2.15,8.1),Vector3(.4,3.1,0),61)
	await shot("car",Vector3(6.5,1.55,6.6),Vector3(3,1.0,9.55),55)
	var env: Environment=app.world.get_node("Atmosphere").environment
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("b8c8d1");env.ambient_light_color=Color("d5dde1");env.ambient_light_energy=.68;env.fog_light_color=Color("b8c8d1")
	var sun: DirectionalLight3D=app.world.get_child(1);sun.light_color=Color("fff1d3");sun.light_energy=1;sun.rotation_degrees=Vector3(-52,-35,0)
	for light in app.world.street.find_children("*","Light3D",true,false):light.light_energy=0
	for light in app.world.depot.get_node("Architecture/Facade").find_children("*","SpotLight3D",true,false):light.light_energy=0
	await shot("paving_day",Vector3(-.8,1.4,3.05),Vector3(-3,0,1.6),62)
	await shot("asphalt_day",Vector3(0,1.35,5.0),Vector3(1.9,-.14,6.5),65)
	await shot("car_day",Vector3(6.5,1.55,6.6),Vector3(3,1.0,9.55),55)
	app.queue_free();await frames(20);await get_tree().create_timer(.2).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();await frames(4);get_tree().quit()
