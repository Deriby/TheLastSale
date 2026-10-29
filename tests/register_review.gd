extends Node
var app: Node
var report: Dictionary={}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func press(id: String) -> void:
	await frames(1)
	var button:=app.interface.checkout.find_child(id,true,false) as Button
	if button!=null:button.pressed.emit()
	await frames(2)
func shot(id: String) -> void:
	await frames(3)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/register_017_"+id+".png")
	var panel: CheckoutPanel=app.interface.checkout
	report[id]={"phase":int(app.world.sale.phase),"panel_rect":str(panel.get_global_rect()) if panel!=null else "closed","window_size":str(get_window().size),"internal_resolution":str(app.viewport.size),"order":app.world.sale.order,"total":app.world.sale.total(),"selected_change":app.world.sale.selected_change(),"message":app.world.sale.message,"sales_cents":Session.sales_cents}
	print("CAPTURE ",id," ",JSON.stringify(report[id]))
func stage_customer() -> void:
	app.world.spawn_customer(false)
	var customer: Customer=app.world.customer
	# Visual staging only; integration tests walk the complete customer and courier routes.
	customer.position=CheckoutFixture.CUSTOMER_POSITION;customer.waypoints.clear();customer.state=Customer.State.WAITING;customer.visual.rotation.y=-PI/2;customer.product.visible=not customer.empty_handed;customer.reset_physics_interpolation()
	app.world.try_checkout(app.world.player)
	while Dialogue.active:Dialogue.next_line()
func review() -> void:
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=true;Preferences.pixel_scale=2;Preferences.grain=0
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false);Session.greet();app.world.switch_player()
	var actor: DepotPlayer=app.world.player
	actor.camera_rig.yaw=-PI/2;actor.camera_rig.pitch=-.22;actor.camera_rig.target_distance=0;actor.camera_rig.distance=0;actor.camera_rig.reset_follow()
	stage_customer();await shot("register")
	await press("Register_water");await press("Register_water");await press("Register_snack_0");await press("ConfirmItems");await press("ReceiveCash")
	await press("Coin_500");await press("ConfirmChange");await shot("wrong_change")
	await press("Coin_200");await press("Coin_100");await press("Coin_50");await press("ConfirmChange");await shot("ready")
	await press("DeliverPurchase");await shot("delivered")
	app.world.customer.queue_free();app.world.customer=null;stage_customer();await shot("bulk_request")
	FileAccess.open("/tmp/register_017_layout.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	app.interface.close_checkout();Dialogue.clear();app.queue_free();await frames(8)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(3);get_tree().quit()
