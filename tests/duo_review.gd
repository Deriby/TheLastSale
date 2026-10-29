extends Node
var app: Node
var report: Dictionary={}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func shot(id: String) -> void:
	await frames(5)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/duo_016_"+id+".png")
	var world: ShiftWorld=app.world
	report[id]={"active_character":world.player.identity,"protagonists":get_tree().get_nodes_in_group("protagonists").size(),"active_controllers":get_tree().get_nodes_in_group("player").size(),"dery_holding":world.characters.Dery.carried_id,"prompt":app.interface.prompt.text,"preview_visible":world.characters.Dery.handling.preview!=null and world.characters.Dery.handling.preview.visible}
	report[id].actor_position=str(world.player.global_position)
	report[id].can_checkout=world.can_checkout(world.player)
	report[id].hud_rects={"subtitles":str(app.interface.hud.get_node("Subtitles").get_global_rect()),"hint":str(app.interface.hud.get_node("ControlsHint").get_global_rect())}
	print("CAPTURE ",id," ",JSON.stringify(report[id]))
func review() -> void:
	Preferences.ps1_mode=false;Preferences.pixel_scale=1;Preferences.grain=0
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false);Session.greet()
	var actor: DepotPlayer=app.world.player
	actor.position=Vector3(0,0,-12.2);actor.camera_rig.yaw=0;actor.camera_rig.pitch=-.22;actor.reset_physics_interpolation();actor.camera_rig.reset_follow()
	actor.pick_up(app.world.depot.crates.stock_1,"stock_1",true)
	await frames(12);await shot("deryk_carry")
	app.world.switch_player()
	var felps: DepotPlayer=app.world.player
	felps.camera_rig.yaw=-PI/2;felps.camera_rig.pitch=-.22;felps.camera_rig.target_distance=0;felps.camera_rig.distance=0;felps.camera_rig.reset_follow()
	app.world.spawn_customer(false)
	var customer: Customer=app.world.customer
	# Staged camera proof; the integration suite separately tests the complete walking route.
	customer.position=CheckoutFixture.CUSTOMER_POSITION;customer.waypoints.clear();customer.state=Customer.State.WAITING;customer.visual.rotation.y=-PI/2;customer.product.visible=true;customer.reset_physics_interpolation()
	await frames(12);await shot("felps_checkout")
	var key:=InputEventKey.new();key.physical_keycode=KEY_E;key.keycode=KEY_E;key.pressed=true;Input.parse_input_event(key);Input.flush_buffered_events()
	await frames(3)
	key=InputEventKey.new();key.physical_keycode=KEY_E;key.keycode=KEY_E;key.pressed=false;Input.parse_input_event(key);Input.flush_buffered_events()
	await shot("felps_service")
	FileAccess.open("/tmp/duo_016_layout.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	Dialogue.clear();app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
