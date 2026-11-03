class_name WatcherLean
extends SkeletonModifier3D
## Local pose for the watching figure only; authored character libraries stay intact.
var direction:=Vector3.RIGHT
var amount:=0.0
var crouch:=0.0
var shift:=0.0
var waist_angle:=.46
var neck_angle:=.45
var points: Dictionary={}
var head_up:=Vector3.UP
var revision:=0
var face_local:=Vector3.ZERO
var face_in_skeleton:=Vector3.ZERO
func _ready() -> void:face_local=FaceAnchor.local_point(get_skeleton())
func _process_modification() -> void:
	var sk:=get_skeleton()
	if sk==null:return
	if crouch>0 or shift>0:
		var feet: Dictionary={}
		for side in ["L","R"]:feet[side]=sk.get_bone_global_pose(sk.find_bone("foot_"+side))
		var pelvis:=sk.find_bone("pelvis")
		var hip_pose:=sk.get_bone_global_pose(pelvis)
		hip_pose.origin+=sk.global_basis.inverse()*(direction.normalized()*shift*amount-Vector3.UP*.42*crouch)
		sk.set_bone_global_pose(pelvis,hip_pose)
		for side in feet:plant_foot(sk,side,feet[side])
	var axis: Vector3=sk.global_basis.inverse()*(Vector3.UP.cross(direction.normalized()))
	for item in [["waist",waist_angle],["neck",neck_angle]]:
		var index:=sk.find_bone(item[0])
		if index<0:continue
		var pose:=sk.get_bone_global_pose(index)
		pose.basis=Basis(axis.normalized(),float(item[1])*amount)*pose.basis
		sk.set_bone_global_pose(index,pose)
	for index in sk.get_bone_count():points[str(sk.get_bone_name(index))]=sk.global_transform*sk.get_bone_global_pose(index).origin
	var head:=sk.find_bone("head")
	var rest_basis: Basis=sk.global_basis*sk.get_bone_global_rest(head).basis
	var current_basis: Basis=sk.global_basis*sk.get_bone_global_pose(head).basis
	head_up=(current_basis.orthonormalized()*rest_basis.orthonormalized().inverse()*Vector3.UP).normalized()
	face_in_skeleton=sk.get_bone_global_pose(head)*face_local;points.face=sk.global_transform*face_in_skeleton
	revision+=1
func plant_foot(sk: Skeleton3D,side: String,original: Transform3D) -> void:
	var hip:=sk.find_bone("thigh_"+side);var knee:=sk.find_bone("shin_"+side);var foot:=sk.find_bone("foot_"+side)
	var a:=sk.get_bone_global_pose(hip);var b:=sk.get_bone_global_pose(knee);var c:=sk.get_bone_global_pose(foot)
	var target:=original.origin
	var first:=a.origin.distance_to(b.origin);var second:=b.origin.distance_to(c.origin)
	var axis:=target-a.origin;var length:=clampf(axis.length(),.001,first+second-.001);axis=axis.normalized()
	var pole:=b.origin-a.origin-axis*((b.origin-a.origin).dot(axis))
	if pole.length()<.001:pole=sk.global_basis.inverse()*Vector3.FORWARD
	var along: float=(first*first-second*second+length*length)/(2*length)
	var joint:=a.origin+axis*along+pole.normalized()*sqrt(maxf(.000001,first*first-along*along))
	var turn:=Quaternion((b.origin-a.origin).normalized(),(joint-a.origin).normalized())
	var lower:=Quaternion((turn*(c.origin-b.origin)).normalized(),(target-joint).normalized())
	sk.set_bone_global_pose(hip,Transform3D(Basis(turn)*a.basis,a.origin))
	sk.set_bone_global_pose(knee,Transform3D(Basis(lower)*Basis(turn)*b.basis,joint))
	sk.set_bone_global_pose(foot,original)
