extends Node
## Render the static batches at a different cadence from physics, including pause/reload.
var app: Node
var camera: Camera3D
var prefix:=""
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func view() -> void:
	camera=Camera3D.new();app.world.add_child(camera)
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position=Vector3(4.0,1.8,-.4);camera.look_at(Vector3(-1.5,1.0,-7.1));camera.fov=72;camera.current=true
	app.world.player.hide()
	app.world.depot.felps.hide()
func capture(id: String) -> Image:
	await frames(25)
	await RenderingServer.frame_post_draw
	var shot: Image=app.viewport.get_texture().get_image()
	shot.save_png("/tmp/retail_"+prefix+id+".png")
	print("CAPTURE ",id," alpha=",Engine.get_physics_interpolation_fraction())
	return shot
func reference_geometry() -> void:
	var count:=0
	for batch in app.world.find_children("*","Node3D",true,false):
		if not batch is PropBatch:continue
		for data in batch.groups.values():
			for at in data.transforms:
				var node:=MeshInstance3D.new();node.mesh=data.source_mesh;node.material_override=data.node.material_override;node.cast_shadow=data.node.cast_shadow
				node.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
				node.layers=data.node.layers
				batch.add_child(node);node.transform=at;count+=1
			data.node.hide()
	print("REFERENCE independent meshes: ",count)
func compare(actual: Image,reference: Image) -> bool:
	actual.convert(Image.FORMAT_RGB8);reference.convert(Image.FORMAT_RGB8)
	var a:=actual.get_data();var b:=reference.get_data();var different:=0;var total:=a.size()/3
	for i in total:
		var at:=i*3
		if maxi(absi(a[at]-b[at]),maxi(absi(a[at+1]-b[at+1]),absi(a[at+2]-b[at+2])))>20:different+=1
	var ratio:=float(different)/total
	print("RENDER_RESULT ",JSON.stringify({"different_pixels":different,"pixels":total,"ratio":ratio,"limit":.01}))
	return ratio<.01
func review() -> void:
	await get_tree().physics_frame
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]+"_"
	if prefix.contains("legacy"):Preferences.pixel_scale=2
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	view();await capture("menu")
	await get_tree().physics_frame
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false);view()
	await capture("running")
	app.interface.set_paused(true)
	var actual: Image=await capture("paused")
	reference_geometry()
	var reference: Image=await capture("reference")
	var passed:=compare(actual,reference)
	await get_tree().physics_frame
	app.start_new();app.interface.set_paused(false);view();await capture("reload")
	app.queue_free();await frames(20)
	await get_tree().create_timer(.2).timeout
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear()
	await frames(4);get_tree().quit(0 if passed else 1)
