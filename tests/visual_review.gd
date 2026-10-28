extends Node
var app: Node
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().physics_frame
func shot(id: String) -> void:
	await frames(20)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/"+id+".png")
	await get_tree().physics_frame
func review() -> void:
	await get_tree().physics_frame
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	await shot("menu")
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	var p: DepotPlayer=app.world.player
	await shot("entrance")
	p.position=Vector3(3.8,0,-6.5);p.camera_rig.yaw=PI/2;p.camera_rig.pitch=-.05
	await shot("sales")
	p.position=Vector3(0,0,-2);p.camera_rig.yaw=PI;p.camera_rig.pitch=-.10
	await shot("front")
	p.position=Vector3(0,0,-13.5);p.camera_rig.yaw=0
	await shot("stock")
	p.position=Vector3(3.25,0,-1.65);p.camera_rig.yaw=-.55;p.camera_rig.pitch=-.05;p.camera_rig.target_distance=0
	await frames(60)
	await shot("felps_v03")
	p.position=Vector3(5.5,0,-8.5);p.camera_rig.target_distance=2.2;p.camera_rig.yaw=0;p.camera_rig.pitch=-.08
	await frames(60)
	await shot("corridor_v03")
	p.position=Vector3(3.8,0,-7);p.visual.rotation.y=0;p.camera_rig.yaw=0
	await shot("dery_v03")
	p.camera_rig.target_distance=0;p.camera_rig.pitch=-.95
	await frames(60)
	await shot("body_v03")
	p.camera_rig.target_distance=2.2;p.camera_rig.pitch=-.08
	var crate: Node3D=app.world.depot.crates.stock_1
	p.position=crate.global_position+Vector3(0,0,.7)
	p.pick_up(crate,"stock_1")
	await frames(100)
	p.position=Vector3(3.8,0,-7);p.visual.rotation.y=0
	await shot("carry_v03")
	p.camera_rig.target_distance=0;p.camera_rig.pitch=-.55
	await frames(60)
	await shot("first_person_v03")
	p.camera_rig.target_distance=2.2
	p.position=Vector3(3.8,0,-1);p.camera_rig.yaw=PI;p.camera_rig.pitch=-.05
	for i in 3:
		var c:=Customer.new();c.navigation=app.world.navigation;c.appearance=i;app.world.add_child(c);c.position=Vector3(1.7+i*1.4,0,1.0);c.waypoints.clear();c.wait=999;c.visual.rotation.y=PI
	await shot("customers")
	app.queue_free()
	await frames(20)
	Geo.materials.clear()
	get_tree().quit()
