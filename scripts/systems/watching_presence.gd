class_name WatchingPresence
extends Node
## Optional, silent opportunities. Observation is never announced or written as a clue.
var world: ShiftWorld
var watcher: HeadWatcher
var sites: Array[Dictionary]=[]
var scan_wait:=0.0
var last_rejection:=""
func state() -> Dictionary:
	if not Session.campaign.experience.get("watching_presence") is Dictionary:
		Session.campaign.experience.watching_presence={"seed":randi_range(1,2000000000),"next_at":Session.world_seconds+75.0,"count":0,"used":{},"last":"","cursor":0,"active":{}}
	return Session.campaign.experience.watching_presence
func draw() -> float:
	state().seed=(int(state().seed)*48271)%2147483647
	return float(int(state().seed)%10000)/10000.0
static func locations() -> Array[Dictionary]:
	return [
		{"id":"stock_jamb","pos":Vector3(3.6,0,-12),"style":"lean","lean":Vector3.RIGHT,"facing":0.0},
		{"id":"east_frontage","pos":Vector3(6.35,.01575,.4),"style":"lean","lean":Vector3.BACK,"facing":-PI/2},
		{"id":"west_frontage","pos":Vector3(-5.65,0,.5),"style":"lean","lean":Vector3.BACK,"facing":PI/2},
		{"id":"rear_right_outer","pos":Vector3(.5,0,-6.95),"style":"rise","facing":PI/2},
		{"id":"rear_right_inner","pos":Vector3(2.2,0,-6.95),"style":"rise","facing":-PI/2},
		{"id":"rear_left_outer","pos":Vector3(-1.05,0,-6.95),"style":"rise","facing":-PI/2},
		{"id":"rear_left_inner","pos":Vector3(-2.75,0,-6.95),"style":"rise","facing":PI/2},
		{"id":"front_right_outer","pos":Vector3(.5,0,-4.7),"style":"rise","facing":PI/2},
		{"id":"front_right_inner","pos":Vector3(2.2,0,-4.7),"style":"rise","facing":-PI/2},
		{"id":"front_left_outer","pos":Vector3(-1.05,0,-4.7),"style":"rise","facing":-PI/2},
		{"id":"front_left_inner","pos":Vector3(-2.75,0,-4.7),"style":"rise","facing":PI/2},
		{"id":"stock_crates_middle","pos":Vector3(-3.5,0,-15.6),"style":"rise","facing":1.0,"base_crouch":1.12,"peak_crouch":.34},
		{"id":"stock_crates_west","pos":Vector3(-4.2,0,-15.6),"style":"rise","facing":.9,"base_crouch":1.12,"peak_crouch":.34}]
func _ready() -> void:
	if int(Session.campaign.night)>=2:return
	sites=locations()
	var data: Dictionary=state().get("active",{})
	if not data.is_empty():
		for site in sites:
			if site.id==data.get("site",""):create(site,float(data.get("hold",.26)),data);break
func safe() -> bool:
	if not world.active or world.is_queued_for_deletion() or int(Session.campaign.night)>=2 or not world.scary.safe():return false
	if Session.campaign.phase not in ["routine","restored","closing","saturday_routine","saturday_investigation","saturday_decisions"]:return false
	if is_instance_valid(world.everyday.observer):return false
	if int(Session.campaign.night)==0:
		if world.scary.blocks_ambient() or world.scary.state().prank.get("phase","") in ["walking","waiting","returning"]:return false
	return true
func clear_ray(origin: Vector3,point: Vector3) -> bool:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,point,1)).is_empty()
func any_clear(points: Array[Vector3]) -> bool:
	for point in points:
		if clear_ray(world.player.camera_rig.camera.global_position,point):return true
	return false
func any_visible(points: Array[Vector3]) -> bool:
	var camera:=world.player.camera_rig.camera
	for point in points:
		if camera.is_position_in_frustum(point) and clear_ray(camera.global_position,point):return true
	return false
func witnesses(actor: HeadWatcher) -> bool:
	var head:=actor.head_points()
	for group in ["protagonists","customers","familiar_npcs"]:
		for person in get_tree().get_nodes_in_group(group):
			if person==world.player or not world.is_ancestor_of(person) or person.is_queued_for_deletion():continue
			if person.global_position.distance_to(actor.position)<3.5:return true
			var toward: Vector3=((actor.position-person.global_position)*Vector3(1,0,1)).normalized()
			var gaze: Vector3=person.visual.global_basis*(Basis(Vector3.UP,person.motion.attention.yaw)*Vector3.BACK)
			# A fleeting head is easy to miss peripherally; a sustained look needs more privacy.
			if gaze.normalized().dot(toward)<(.90 if actor.hold<.7 else .60):continue
			var height: float=person.visual.get_meta("height_m",1.78)
			for point in head:
				if clear_ray(person.global_position+Vector3.UP*height*.87,point):return true
	return false
func peak_allowed(actor: HeadWatcher) -> bool:
	last_rejection=""
	if not safe():last_rejection="busy";return false
	if witnesses(actor):last_rejection="witness";return false
	if actor.site.id=="stock_jamb" and world.player.camera_rig.camera.global_position.x>4.3:last_rejection="cover_angle";return false
	var floor_hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*.25,actor.position-Vector3.UP*.3,1))
	if floor_hit.is_empty() or floor_hit.normal.dot(Vector3.UP)<.8:last_rejection="floor";return false
	var shape:=CapsuleShape3D.new();shape.height=1.6;shape.radius=.18
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,actor.position+Vector3.UP*.84);query.collision_mask=1
	if not world.get_world_3d().direct_space_state.intersect_shape(query).is_empty():last_rejection="occupied";return false
	if any_clear(actor.body_points()):last_rejection="body";return false
	if not any_clear(actor.head_points()):last_rejection="head";return false
	return true
func tick(delta: float) -> void:
	if int(Session.campaign.night)>=2 or not safe() or is_instance_valid(watcher):return
	scan_wait-=delta
	if scan_wait>0:return
	scan_wait=.3
	if int(state().count)>=8 or Session.world_seconds<float(state().next_at):return
	if int(Session.campaign.night)==0 and Session.stage==0:return
	if Session.world_seconds-float(world.scary.state().last_scare)<25:return
	var index:=int(state().cursor)%sites.size();state().cursor=(index+1)%sites.size()
	var site: Dictionary=sites[index]
	var distance: float=world.player.position.distance_to(site.pos)
	if int(state().used.get(site.id,0))>=2 or state().last==site.id or distance<4.5 or distance>17:return
	if clear_ray(world.player.camera_rig.camera.global_position,site.pos+Vector3.UP*1.25):return
	var hold:=.14+draw()*.20
	if distance>8 and draw()<.25:hold=.7+draw()*.45
	create(site,hold)
func create(site: Dictionary,hold: float,resume: Dictionary={}) -> void:
	watcher=HeadWatcher.new();watcher.world=world;watcher.site=site;watcher.position=site.pos;watcher.hold=hold;watcher.resume=resume;world.add_child(watcher)
	watcher.prepared.connect(func():
		state().count=int(state().count)+1;state().used[site.id]=int(state().used.get(site.id,0))+1;state().last=site.id;capture();Session.save_shift(world.player.position))
	watcher.rejected.connect(func():state().next_at=Session.world_seconds+2.0)
	watcher.withdrawn.connect(func():state().active={};state().next_at=Session.world_seconds+28+draw()*27;Session.save_shift(world.player.position))
func capture() -> void:
	if int(Session.campaign.night)>=2:return
	state().active=watcher.snapshot() if is_instance_valid(watcher) and watcher.started and not watcher.is_queued_for_deletion() else {}
