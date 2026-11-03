class_name ContactThreatPose
extends SkeletonModifier3D
## A short reaching pose layered on the original rig. Never changes animation resources.
var amount:=0.0
var target:=Vector3.ZERO
var waist_angle:=.22
var neck_angle:=.12
var head_point:=Vector3.ZERO
var head_up:=Vector3.UP
var revision:=0
var face_point:=Vector3.ZERO
var face_in_skeleton:=Vector3.ZERO
var face_local:=Vector3.ZERO
var pose_enabled:=true
func _ready() -> void:face_local=FaceAnchor.local_point(get_skeleton())
func _process_modification() -> void:
	var sk:=get_skeleton()
	if sk==null:return
	if not pose_enabled or amount<=0:record_face(sk);return
	var direction: Vector3=(target-sk.global_position)*Vector3(1,0,1)
	if direction.length()<.01:return
	var axis: Vector3=sk.global_basis.inverse()*(Vector3.UP.cross(direction.normalized()))
	for item in [["waist",waist_angle],["neck",neck_angle]]:
		var bone:=sk.find_bone(item[0])
		if bone<0:continue
		var pose:=sk.get_bone_global_pose(bone)
		pose.basis=Basis(axis.normalized(),float(item[1])*amount)*pose.basis
		sk.set_bone_global_pose(bone,pose)
	for side in ["L","R"]:
		var arm:=sk.find_bone("arm_"+side);var elbow:=sk.find_bone("forearm_"+side);var hand:=sk.find_bone("hand_"+side)
		if mini(arm,mini(elbow,hand))<0:continue
		var a:=sk.get_bone_global_pose(arm);var b:=sk.get_bone_global_pose(elbow)
		var local_target: Vector3=sk.global_transform.affine_inverse()*(target+sk.global_basis.x.normalized()*(.16 if side=="L" else -.16)-Vector3.UP*.12)
		var turn:=Quaternion((b.origin-a.origin).normalized(),(local_target-a.origin).normalized())
		a.basis=Basis(Quaternion.IDENTITY.slerp(turn,amount*.86))*a.basis
		sk.set_bone_global_pose(arm,a)
		b=sk.get_bone_global_pose(elbow)
		var c:=sk.get_bone_global_pose(hand)
		turn=Quaternion((c.origin-b.origin).normalized(),(local_target-b.origin).normalized())
		b.basis=Basis(Quaternion.IDENTITY.slerp(turn,amount*.65))*b.basis
		sk.set_bone_global_pose(elbow,b)
	record_face(sk)
func record_face(sk: Skeleton3D) -> void:
	var head:=sk.find_bone("head")
	head_point=sk.global_transform*sk.get_bone_global_pose(head).origin
	face_in_skeleton=sk.get_bone_global_pose(head)*face_local;face_point=sk.global_transform*face_in_skeleton
	var rest_basis: Basis=sk.global_basis*sk.get_bone_global_rest(head).basis
	var current_basis: Basis=sk.global_basis*sk.get_bone_global_pose(head).basis
	head_up=(current_basis.orthonormalized()*rest_basis.orthonormalized().inverse()*Vector3.UP).normalized();revision+=1
