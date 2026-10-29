class_name HeadAttention
extends SkeletonModifier3D
var visual: Node3D
var target_global:=Vector3.ZERO
var following:=false
var yaw:=0.0
var pitch:=0.0
var eye_height:=1.57
func _process(delta: float) -> void:
	var goal_yaw:=0.0;var goal_pitch:=0.0
	if following and visual!=null:
		var local:=visual.global_basis.inverse()*(target_global-(visual.global_position+Vector3.UP*eye_height))
		goal_yaw=clampf(atan2(local.x,local.z),-.65,.65)
		goal_pitch=clampf(-atan2(local.y,maxf(.1,Vector2(local.x,local.z).length())),-.18,.18)
	yaw=lerpf(yaw,goal_yaw,1-exp(-delta*5));pitch=lerpf(pitch,goal_pitch,1-exp(-delta*5))
func _process_modification() -> void:
	var skeleton:=get_skeleton()
	if skeleton==null:return
	var index:=skeleton.find_bone("head")
	var pose:=skeleton.get_bone_global_pose(index)
	# Global skeleton axes avoid depending on glTF's local bone roll.
	var up:=(skeleton.global_basis.inverse()*Vector3.UP).normalized()
	var right:=(skeleton.global_basis.inverse()*visual.global_basis.x).normalized()
	pose.basis=Basis(up,yaw)*Basis(right,pitch)*pose.basis
	skeleton.set_bone_global_pose(index,pose)
