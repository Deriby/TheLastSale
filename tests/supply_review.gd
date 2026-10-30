extends Node
## Staged captures of identification and native HUD. Functional actions tested separately.
var app: Node
var world: ShiftWorld
func snap(id: String) -> void:
	for i in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("REVIEW_OUTPUT_DIR");DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder.path_join(id+".png"));print("SUPPLY_CAPTURE ",id)
func stand(at: Vector3,yaw: float,pitch: float) -> void:
	world.player.position=at;world.player.velocity=Vector3.ZERO;world.player.camera_rig.yaw=yaw;world.player.camera_rig.pitch=pitch;world.player.camera_rig.reset_follow()
func _ready() -> void:call_deferred("run")
func run() -> void:
	Session.new_shift();Session.stage=1;Preferences.ps1_mode=true;Preferences.ps1_high_resolution=true;Preferences.pixel_scale=2
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await get_tree().process_frame
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=false
	stand(Vector3(.7,0,-11.9),0,-.25);world.supplies.refresh();await snap("stock_labels")
	world.characters.Dery.pick_up(world.depot.crates.stock_1,"stock_1",true);world.active=true;Session.changed.emit()
	stand(Vector3(-3.95,0,-4.8),PI/2,-.1);world.depot.fridge_target.toggle();await snap("fridge_destination")
	world.active=false;world.characters.Dery.handling.place(Vector3(-4.5,0,-3.8));await get_tree().create_timer(1.3).timeout
	stand(Vector3(-3.1,0,-4.7),-PI/2,-.15);world.characters.Dery.pick_up(world.depot.crates.stock_shelf,"stock_shelf",true);world.active=true;Session.changed.emit();await snap("shelf_destination")
	world.active=false;world.characters.Dery.handling.place(Vector3(-3.9,0,-5.8));await get_tree().create_timer(1.3).timeout
	world.sale=ShopSale.create(2);world.ensure_order_crate();world.spawn_customer(false,{"position":[-3.1,0,-2.7],"state":int(Customer.State.WAITING),"service_started":true,"identity":"ClienteTrabalho","appearance":4})
	world.characters.Dery.pick_up(world.depot.crates[world.sale.supply_id()],world.sale.supply_id(),true)
	stand(Vector3(-2.5,0,-2.15),PI/2,-.16);world.supplies.refresh();world.active=true;Session.changed.emit();await snap("order_delivery")
	app.queue_free();await get_tree().process_frame;await get_tree().create_timer(.2).timeout
	Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear();get_tree().quit()
