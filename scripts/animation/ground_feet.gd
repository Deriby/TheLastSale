class_name GroundFeet
extends SkeletonModifier3D
## Small terrain correction after animation. Authored support/swing phases remain intact.
var actor: Node3D
var clearance:=.1335
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
		var amount: float=corrections[side]
		if absf(amount)<.0001:continue
		var hip:=skeleton.find_bone("thigh_"+side);var knee:=skeleton.find_bone("shin_"+side);var foot:=skeleton.find_bone("foot_"+side)
		var a:=skeleton.get_bone_global_pose(hip);var b:=skeleton.get_bone_global_pose(knee);var c:=skeleton.get_bone_global_pose(foot)
		var target:=c.origin+skeleton.global_basis.inverse()*(Vector3.UP*amount)
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
