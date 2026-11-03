class_name CloseEncounters
extends WatchingPresence
## Two private, proximity-driven ambushes at real doorways. Never a public crossing.
var active_id:=""
var retry_at:=0.0
var variant_cursor: Dictionary={}
static func ambushes() -> Dictionary:
	return {
		"generator_return":{"id":"generator_return","pos":Vector3(3.2,0,-15.5),"style":"lean","lean":Vector3.RIGHT,"facing":PI,"shift":.10,"lean_waist":.68,"lean_neck":-.16,"minimum_distance":.85,"contact":true},
		"stock_corner":{"id":"stock_corner","pos":Vector3(3.65,0,-9.3),"style":"lean","lean":Vector3.RIGHT,"facing":PI,"shift":.10,"lean_waist":.68,"lean_neck":-.16,"minimum_distance":.85,"contact":true}}
static func positions(id: String) -> Array[Vector3]:
	if id=="generator_return":return [Vector3(3.1,0,-15.35),Vector3(3.0,0,-15.25),Vector3(3.05,0,-15.4),Vector3(3.2,0,-15.5),Vector3(3.3,0,-15.65)]
	return [Vector3(3.65,0,-9.3),Vector3(3.65,0,-9.15),Vector3(3.65,0,-9.0),Vector3(3.8,0,-9.3),Vector3(3.5,0,-9.15)]
func state() -> Dictionary:
	if not Session.campaign.experience.get("close_encounters") is Dictionary:
		Session.campaign.experience.close_encounters={"used":{},"active":{}}
	return Session.campaign.experience.close_encounters
func _ready() -> void:
	Session.saving.connect(capture)
	if int(Session.campaign.night)>=2:state().active={};return
	var data: Dictionary=state().active
	if not data.is_empty() and ambushes().has(data.get("event","")):
		active_id=str(data.event)
		var site: Dictionary=ambushes()[active_id].duplicate();site.variant=clampi(int(data.get("variant",0)),0,positions(active_id).size()-1);site.pos=positions(active_id)[site.variant]
		create(site,.62,data.get("watcher",{}),true)
func safe() -> bool:
	return world.active and not world.is_queued_for_deletion() and int(Session.campaign.night)<2 and world.scary.safe() and not is_instance_valid(world.presence.watcher) and not is_instance_valid(world.everyday.observer)
func blocking() -> bool:return is_instance_valid(watcher) and not watcher.is_queued_for_deletion()
func peak_allowed(actor: HeadWatcher) -> bool:
	last_rejection=""
	if not safe():last_rejection="busy";return false
	if witnesses(actor):last_rejection="witness";return false
	var floor_hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*.25,actor.position-Vector3.UP*.3,1))
	if floor_hit.is_empty() or floor_hit.normal.dot(Vector3.UP)<.8:last_rejection="floor";return false
	var shape:=CapsuleShape3D.new();shape.height=1.6;shape.radius=.18
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,actor.position+Vector3.UP*.84);query.collision_mask=1
	if not world.get_world_3d().direct_space_state.intersect_shape(query).is_empty():last_rejection="occupied";return false
	var core: Array[Vector3]=[]
	for bone in ["pelvis","waist","chest","thigh_L","thigh_R","shin_L","shin_R"]:core.append(actor.bone_world(bone))
	if any_clear(core):last_rejection="body";return false
	for point in actor.face_points():
		if not clear_face_view(point):last_rejection="face_covered";return false
	return true
func create(site: Dictionary,hold: float=.62,resume: Dictionary={},_directed: bool=true) -> void:
	active_id=str(site.id);watcher=HeadWatcher.new();watcher.world=world;watcher.director=self;watcher.site=site;watcher.position=site.pos;watcher.hold=hold;watcher.directed=true;watcher.resume=resume;world.add_child(watcher)
	watcher.prepared.connect(func():capture())
	watcher.contact_seen.connect(func():
		state().used[active_id]=true;capture();Session.save_shift(world.player.position))
	watcher.rejected.connect(func():retry_at=Session.world_seconds+.25;state().active={})
	watcher.withdrawn.connect(func():
		state().active={};world.horror.calm(38);Session.save_shift(world.player.position))
func capture() -> void:
	state().active={"event":active_id,"variant":watcher.site.get("variant",0),"watcher":watcher.snapshot()} if blocking() and watcher.started else {}
func _physics_process(_delta: float) -> void:
	if not safe() or blocking() or Session.world_seconds<retry_at or world.horror.ambient_blocked() or world.player.identity!="Dery" or world.player.carried!=null:return
	var id:=""
	if int(Session.campaign.night)==0 and Session.campaign.phase in ["restored","closing"] and Session.flag("generator_running"):
		var at:=world.player.position
		if at.x>3.7 and at.x<5.6 and at.z< -16.4 and at.z> -18.0:id="generator_return"
	elif int(Session.campaign.night)==1 and Session.flag("door_attempt") and Session.campaign.phase in ["saturday_investigation","saturday_decisions","closing"]:
		var at:=world.player.position
		if at.x>3.7 and at.x<5.6 and at.z< -11.45 and at.z> -13.4:id="stock_corner"
	if id.is_empty() or bool(state().used.get(id,false)):return
	var door:=world.depot.service_door if id=="generator_return" else world.depot.stock_door
	var opened:=false
	for child in door.get_children():
		if child is Interaction and child.kind=="door":opened=child.open and not child.busy
	if not opened:return
	var point: Vector3=ambushes()[id].pos+Vector3.UP*.25
	if not world.horror.ready_for(point,3.6):return
	var site: Dictionary=ambushes()[id].duplicate();site.variant=int(variant_cursor.get(id,0))%positions(id).size();site.pos=positions(id)[site.variant];variant_cursor[id]=int(site.variant)+1
	create(site)
