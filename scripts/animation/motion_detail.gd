class_name MotionDetail
extends SkeletonModifier3D
## Small independent breathing and weight response. Hands keep their authored grips.
var speed:=0.0
var carrying:=false
var phase:=0.0
var lean:=0.0
var bank:=0.0
var visual: Node3D
var last_speed:=0.0
var last_yaw:=0.0
var indices: Dictionary={}
func _ready() -> void:
	var sk:=get_skeleton()
	for bone in ["waist","spine","chest","upper_chest"]:
		var index:=sk.find_bone(bone)
		if index>=0:indices[bone]=index
	if visual!=null:last_yaw=visual.global_rotation.y
func _process(delta: float) -> void:
	phase+=delta*(3.0 if speed>2.5 else 1.25)
	var acceleration:=clampf((speed-last_speed)/maxf(delta,.001),-4,4);last_speed=speed
	lean=lerpf(lean,acceleration*.006,1-exp(-delta*8))
	if visual!=null:
		var yaw:=visual.global_rotation.y
		var turn:=clampf(angle_difference(last_yaw,yaw)/maxf(delta,.001),-2,2);last_yaw=yaw
		bank=lerpf(bank,-turn*minf(speed,3.0)*.009,1-exp(-delta*7))
func _process_modification() -> void:
	var sk:=get_skeleton()
	var breath:=sin(phase)*(.0015 if speed>.1 else .001)
	for bone in indices:
		var index: int=indices[bone]
		var ratio: float=.35 if bone in ["waist","spine"] else .15
		var rotation:=Basis.from_euler(Vector3((lean+breath)*ratio,0,bank*ratio))
		var pose:=sk.get_bone_pose_rotation(index)
		sk.set_bone_pose_rotation(index,(rotation*Basis(pose)).get_rotation_quaternion())
		if bone=="chest":sk.set_bone_pose_scale(index,sk.get_bone_pose_scale(index)*Vector3(1+sin(phase)*.0025,1,1+sin(phase)*.003))
