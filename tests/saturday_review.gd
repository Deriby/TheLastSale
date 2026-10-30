extends Node
## Staged views only; the integration scene tests actual routes and inputs separately.
var app: Node
var world: ShiftWorld
func _ready() -> void:call_deferred("review")
func capture(id: String) -> void:
	for i in 24:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("REVIEW_OUTPUT_DIR")
	if folder.is_empty():folder="user://saturday_review"
	DirAccess.make_dir_recursive_absolute(folder)
	var path:=folder.path_join(id+".png")
	get_viewport().get_texture().get_image().save_png(path);print("CAPTURE ",path)
func review() -> void:
	Session.new_shift();Session.advance_to_saturday();Session.stage=4
	Session.campaign.phase="saturday_investigation";Session.campaign.flags.visitor_left=true
	Session.stocked.assign(["stock_1","stock_2"]);Session.organized=true
	Session.campaign.clues.local_outage=true;Session.customers_served=2
	Session.receipts=[{"id":5,"total":1250,"customer":"ClienteTrabalho","night":1,"time":"21:47"},{"id":6,"total":850,"customer":"ClienteBone","night":1,"time":"22:08"}]
	Session.campaign.records=[{"id":"service_before_open","time":"21:32","text":"CAM 03 • Movimento no pátio antes da abertura. Nenhuma entrega autorizada. Arquivo de vídeo indisponível; evento textual preservado."}]
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=true;Preferences.pixel_scale=2
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await get_tree().process_frame
	app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=false
	world.select_player("Felps");world.try_surveillance()
	var panel: SurveillancePanel=app.interface.surveillance
	for i in 3:
		panel.select_channel(i);await capture("camera_"+str(i))
	panel.show_page(1);await capture("dvr_events")
	for id in SaturdayShift.REQUIRED:Session.campaign.clues[id]=true
	Session.campaign.phase="saturday_decisions";Session.changed.emit();panel.show_page(2)
	panel.find_child("CopyEvidence",true,false).pressed.emit();panel.find_child("ContactHelp",true,false).pressed.emit()
	await capture("journal")
	app.interface.close_surveillance()
	Session.campaign.phase="complete";Session.campaign.reports.saturday={"customers":2,"sales_cents":2100}
	Session.campaign.decisions.exit="prepared";app.interface.show_night_summary();await capture("summary")
	app.queue_free();await get_tree().process_frame;Geo.materials.clear();CharacterModels.costume_materials.clear()
	get_tree().quit()
