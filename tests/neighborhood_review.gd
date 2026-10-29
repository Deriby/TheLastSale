extends Node
## Street identity and safe walking space, viewed with fixed cameras.
var app: Node
var camera: Camera3D
var prefix:="neighborhood09"
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String,at: Vector3,target: Vector3,fov: float) -> void:
	if prefix.contains("quick") and id not in ["brick_garage","garage_day","inside_out"]:return
	if prefix.contains("economic") and id not in ["inside_out","downhill_lots","brick_garage"]:return
	camera.position=at;camera.look_at(target);camera.fov=fov
	await frames(8);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+prefix+"_"+id+".png");print("CAPTURE ",id)
func street_shot(id: String,at: Vector3,target: Vector3,fov:=72.0) -> void:
	at.y+=Street.grade(at.x);target.y+=Street.grade(target.x);await shot(id,at,target,fov)
func review() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	if prefix.contains("economic"):Preferences.pixel_scale=3
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide();app.world.depot.felps.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;camera.far=110;app.world.add_child(camera);camera.current=true
	var shadowed:=0;var normal_maps:=0
	for light in app.world.find_children("*","Light3D",true,false):
		if light.shadow_enabled:shadowed+=1
	for mat in Geo.materials.values():
		if mat is StandardMaterial3D and mat.normal_enabled:normal_maps+=1
	print("QUALITY scale=",Preferences.pixel_scale," shadowed_lights=",shadowed," normal_maps=",normal_maps)
	await shot("inside_out",Vector3(-4.95,1.72,-2.25),Vector3(3.4,1.95,10.5),78)
	await shot("downhill",Vector3(-1,1.9,6.6),Vector3(-50,-.2,6.6),65)
	await shot("uphill",Vector3(0,1.9,6.6),Vector3(50,2.3,6.6),65)
	await shot("opposite",Vector3(1,1.8,2.2),Vector3(1,1.6,13),72)
	await street_shot("downhill_lots",Vector3(-17,1.7,6),Vector3(-15,1.6,13),85)
	await street_shot("brick_garage",Vector3(-9.7,1.7,8.2),Vector3(-10.1,1.25,12.4),75)
	await street_shot("courtyard",Vector3(22,1.7,5.3),Vector3(23.2,1.5,-.8),72)
	await street_shot("corner_shop",Vector3(-22,1.7,7),Vector3(-21.1,1.7,12.4),65)
	await street_shot("gas_shop",Vector3(9.8,1.6,5),Vector3(10.2,1.25,0),68)
	await street_shot("tile_house",Vector3(22,1.7,6.9),Vector3(23.5,1.4,12.3),68)
	await street_shot("skyline",Vector3(14,2.2,6),Vector3(12,5,-.5),80)
	await street_shot("bicycle",Vector3(-8.8,1.25,10.1),Vector3(-8.4,.7,11.9),72)
	await street_shot("workshop",Vector3(-22,1.7,5.5),Vector3(-21.75,2.0,0),69)
	var env: Environment=app.world.get_node("Atmosphere").environment
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("b8c8d1");env.ambient_light_color=Color("d5dde1");env.ambient_light_energy=.68;env.fog_light_color=Color("b8c8d1")
	var sun: DirectionalLight3D=app.world.get_child(1);sun.light_color=Color("fff1d3");sun.light_energy=1;sun.rotation_degrees=Vector3(-52,-35,0)
	for light in app.world.street.find_children("*","Light3D",true,false):light.light_energy=0
	for light in app.world.depot.get_node("Architecture/Facade").find_children("*","SpotLight3D",true,false):light.light_energy=0
	await street_shot("lots_day",Vector3(-17,1.7,6),Vector3(-15,1.6,13),85)
	await street_shot("garage_day",Vector3(-9.7,1.7,8.2),Vector3(-10.1,1.25,12.4),75)
	await street_shot("courtyard_day",Vector3(22,1.7,5.3),Vector3(23.2,1.5,-.8),72)
	await street_shot("tile_house_day",Vector3(22,1.7,6.9),Vector3(23.5,1.4,12.3),68)
	await shot("opposite_day",Vector3(1,1.8,2.2),Vector3(1,1.6,13),72)
	await street_shot("bicycle_day",Vector3(-8.8,1.25,10.1),Vector3(-8.4,.7,11.9),72)
	await street_shot("workshop_day",Vector3(-22,1.7,5.5),Vector3(-21.75,2.0,0),69)
	app.queue_free();await frames(20);await get_tree().create_timer(.2).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();await frames(4);get_tree().quit()
