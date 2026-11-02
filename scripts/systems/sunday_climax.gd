class_name SundayClimax
extends WatchingPresence
## One optional last glimpse before the existing physical pursuer takes over.
var retry_at:=0.0
func state() -> Dictionary:
	if not world.sunday.state().get("climax") is Dictionary:
		world.sunday.state().climax={"started":-1.0,"peek_used":false,"peek":{},"aftermath_left":5.5,"aftermath_seen":false}
	return world.sunday.state().climax
func _ready() -> void:
	Session.saving.connect(capture)
	var data: Dictionary=state().peek
	if not data.is_empty():create({},float(data.get("hold",.24)),data)
func safe() -> bool:
	return world.active and not world.is_queued_for_deletion() and int(Session.campaign.night)==2 and Session.campaign.phase in ["sunday_investigation","sunday_prepare"] and not is_instance_valid(world.sunday.killer) and world.scary!=null and world.scary.safe()
func create(_site: Dictionary={},hold: float=.24,resume: Dictionary={},_directed: bool=false) -> void:
	var site: Dictionary=WatchingPresence.locations()[11].duplicate()
	site.minimum_distance=3.2
	site.peak_crouch=.22
	watcher=HeadWatcher.new();watcher.world=world;watcher.director=self;watcher.site=site;watcher.position=site.pos;watcher.hold=maxf(hold,1.45);watcher.directed=true;watcher.resume=resume;world.add_child(watcher)
	watcher.prepared.connect(func():state().peek_used=true;capture();Session.save_shift(world.player.position))
	watcher.rejected.connect(func():retry_at=Session.world_seconds+6)
	watcher.withdrawn.connect(func():state().peek={};Session.save_shift(world.player.position))
func capture() -> void:
	if int(Session.campaign.night)!=2:return
	state().peek=watcher.snapshot() if is_instance_valid(watcher) and watcher.started and not watcher.is_queued_for_deletion() else {}
func before_escape() -> void:
	state().peek_used=true
	if world.horror.focused_event.begins_with("watching_"):world.player.camera_rig.cancel_focus()
	if is_instance_valid(watcher):watcher.retreating=true
func handing_over() -> bool:return is_instance_valid(watcher) and not watcher.is_queued_for_deletion()
func _physics_process(_delta: float) -> void:
	if not world.active or world.is_queued_for_deletion():return
	if is_instance_valid(world.sunday.killer):world.sunday.killer.visual.visible=not handing_over()
	if Session.campaign.phase not in ["sunday_investigation","sunday_prepare"]:return
	if float(state().started)<0:state().started=Session.world_seconds
	if not world.horror.ready_for(WatchingPresence.locations()[11].pos+Vector3.UP*1.7,7.2) or not safe() or bool(state().peek_used) or is_instance_valid(watcher) or not Session.flag("module_found"):return
	if Session.world_seconds-float(state().started)<75 or Session.world_seconds<retry_at:return
	var distance: float=world.player.position.distance_to(WatchingPresence.locations()[11].pos)
	if distance<3.8 or distance>7.2:return
	create()
