extends Node
var app: Node
var camera: Camera3D
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func capture(id: String,at: Vector3,focus: Vector3) -> void:
	camera.position=at;camera.look_at(focus,Vector3.UP)
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/depot_"+id+".png")
func review() -> void:
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	app.interface.hud.hide();app.world.active=false
	app.world.player.process_mode=Node.PROCESS_MODE_DISABLED;app.world.player.visual.hide()
	camera=Camera3D.new();app.world.add_child(camera);camera.current=true;camera.fov=62
	await capture("entrance",Vector3(-3.85,1.68,-1.0),Vector3(.0,1.4,-7.0))
	await capture("gondola",Vector3(4.15,1.68,-4.9),Vector3(-2.0,1.25,-6.2))
	await capture("refrigeration",Vector3(-3.7,1.55,-3.35),Vector3(-5.4,1.15,-5.5))
	await capture("checkout",Vector3(2.1,1.65,-.5),Vector3(4.35,1.28,-2.8))
	await capture("roof",Vector3(-3.85,1.65,-2.0),Vector3(1.8,4.45,-8.8))
	app.queue_free();await frames(20)
	Geo.materials.clear();ProductLibrary.meshes.clear();ProductLibrary.materials.clear()
	get_tree().quit()
