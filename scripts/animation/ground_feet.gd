class_name GroundFeet
extends SkeletonModifier3D
## Small terrain correction after animation. Authored support/swing phases remain intact.
var actor: Node3D
var clearance:=.1335
var motion: LivingMotion
var anchors: Dictionary={}
var was_support: Dictionary={"L":false,"R":false}
var bones: Dictionary={}
var anchor_limit:=.06
func reset_contacts() -> void:
	anchors.clear();was_support={"L":false,"R":false}
func _ready() -> void:
	var sk:=get_skeleton()
	for side in ["L","R"]:
		bones[side]=[sk.find_bone("thigh_"+side),sk.find_bone("shin_"+side),sk.find_bone("foot_"+side)]
var corrections: Dictionary = {"L":0.0,"R":0.0}
var supports: Dictionary = {"L":false,"R":false}
func _physics_process(delta: float) -> void:
	var skeleton:=get_skeleton()
	if skeleton==null or actor==null or not actor.is_inside_tree():return
	for side in ["L","R"]:
		var index:=skeleton.find_bone("foot_"+side)
		if index<0:continue
		var at:=skeleton.global_transform*skeleton.get_bone_global_pose(index).origin
		var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.28,at-Vector3.UP*.48,1)
		var hit:=actor.get_world_3d().direct_space_state.intersect_ray(query)
		var desired:=0.0
		supports[side]=false
		if not hit.is_empty() and hit.normal.dot(Vector3.UP)>.65:
			var gap: float=at.y-hit.position.y-clearance
			var weight:=clampf(1.0-maxf(0,gap-.03)/.10,0,1)
			desired=clampf(hit.position.y-actor.global_position.y,-.11,.14)*weight
			supports[side]=weight>.5
		corrections[side]=lerpf(corrections[side],desired,1-exp(-delta*18))
func _process_modification() -> void:
	var skeleton:=get_skeleton()
	if skeleton==null:return
	for side in ["L","R"]:
		var hip: int=bones[side][0];var knee: int=bones[side][1];var foot: int=bones[side][2]
		var a:=skeleton.get_bone_global_pose(hip);var b:=skeleton.get_bone_global_pose(knee);var c:=skeleton.get_bone_global_pose(foot)
		var amount: float=corrections[side]
		var free_swing:=motion!=null and motion.current_clip in motion.free_swing_clips
		if free_swing:amount*=motion.foot_contact(side)
		var world:=skeleton.global_transform*c.origin
		var locked:=false
		var contact_weight:=0.0
		if motion!=null and not free_swing and motion.strides.has(motion.current_clip) and not motion.action_active and motion.filtered_speed>.15:
			contact_weight=motion.foot_contact(side);locked=contact_weight>.05
		if locked:
			if not was_support[side]:anchors[side]=world
			var anchor: Vector3=anchors[side]
			var offset:=Vector2(anchor.x-world.x,anchor.z-world.z)
			if offset.length()>anchor_limit:
				offset=offset.limit_length(anchor_limit);anchors[side]=world+Vector3(offset.x,0,offset.y)
			world.x+=offset.x*contact_weight;world.z+=offset.y*contact_weight
		was_support[side]=locked
		var target:=skeleton.to_local(world+Vector3.UP*amount)
		if target.distance_to(c.origin)<.0002:continue
		var first:=a.origin.distance_to(b.origin);var second:=b.origin.distance_to(c.origin)
		var axis: Vector3=target-a.origin;var length:=clampf(axis.length(),.01,first+second-.001);axis=axis.normalized();target=a.origin+axis*length
		var pole: Vector3=b.origin-a.origin-axis*((b.origin-a.origin).dot(axis))
		if pole.length()<.001:continue
		var along: float=(first*first-second*second+length*length)/(2*length)
		var joint:=a.origin+axis*along+pole.normalized()*sqrt(maxf(.000001,first*first-along*along))
		var turn:=Quaternion((b.origin-a.origin).normalized(),(joint-a.origin).normalized())
		var lower:=Quaternion((turn*(c.origin-b.origin)).normalized(),(target-joint).normalized())
		skeleton.set_bone_global_pose(hip,Transform3D(Basis(turn)*a.basis,a.origin))
		skeleton.set_bone_global_pose(knee,Transform3D(Basis(lower)*Basis(turn)*b.basis,joint))
		skeleton.set_bone_global_pose(foot,Transform3D(c.basis,target))
