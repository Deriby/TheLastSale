extends "res://tools/natural_pose.gd"
## Retarget authored CC0 animation onto the existing rigs. Meshes, bind poses and
## weights are untouched. Two-bone IK only adapts foot contact to each shoe.
const MAP := {"pelvis":"DEF-hips","waist":"DEF-spine.001","spine":"DEF-spine.002","chest":"DEF-spine.003","upper_chest":"DEF-spine.003","neck":"DEF-neck","head":"DEF-head","shoulder_L":"DEF-shoulder.L","shoulder_R":"DEF-shoulder.R","arm_L":"DEF-upper_arm.L","arm_R":"DEF-upper_arm.R","forearm_L":"DEF-forearm.L","forearm_R":"DEF-forearm.R","hand_L":"DEF-hand.L","hand_R":"DEF-hand.R","thigh_L":"DEF-thigh.L","thigh_R":"DEF-thigh.R","shin_L":"DEF-shin.L","shin_R":"DEF-shin.R","foot_L":"DEF-foot.L","foot_R":"DEF-foot.R"}
var source: Dictionary
var reference: Dictionary={}
var source_names: Dictionary={}
var leg_ratio:=1.0
var contacts: Dictionary={}
var contact_vertices: Dictionary={"L":[],"R":[]}
func init(sk: Skeleton3D,visual: Node3D,id: String) -> void:
	super.init(sk,visual,id)
	source=JSON.parse_string(FileAccess.get_file_as_string("res://tools/motion_reference/quaternius.json"))
	for i in source.bones.size():source_names[source.bones[i]]=i
	for name in source_names:reference[name]=unpack(source.rest[source_names[name]])
	var source_length: float=reference["DEF-thigh.L"].origin.distance_to(reference["DEF-shin.L"].origin)+reference["DEF-shin.L"].origin.distance_to(reference["DEF-foot.L"].origin)
	leg_ratio=(leg_length("L")+leg_length("R"))*.5/source_length
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		if mesh.skin==null:continue
		var joints: Array[int]=[];var binds: Array[Transform3D]=[]
		for i in mesh.skin.get_bind_count():joints.append(sk.find_bone(mesh.skin.get_bind_name(i)));binds.append(mesh.skin.get_bind_pose(i))
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_BONES]==null:continue
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var count: int=bones.size()/vertices.size()
			for v in vertices.size():
				var rest_point: Vector3=sk.global_transform.affine_inverse()*mesh.global_transform*vertices[v]
				if rest_point.y>.26:continue
				for side in ["L","R"]:
					var influence:=0.0
					for k in count:
						if below(joints[bones[v*count+k]],names["foot_"+side]):influence+=weights[v*count+k]
					if influence<.7:continue
					var item: Array=[]
					for k in count:
						if weights[v*count+k]>.001:
							var bind: int=bones[v*count+k];item.append([joints[bind],binds[bind]*vertices[v],weights[v*count+k]])
					contact_vertices[side].append(item)
func unpack(value: Array) -> Transform3D:
	return Transform3D(Basis(Quaternion(value[3],value[4],value[5],value[6]).normalized()),Vector3(value[0],value[1],value[2]))
func source_clip(clip: String) -> String:
	if clip=="run":return "Sprint_Loop"
	if clip=="crouch_walk":return "Crouch_Fwd_Loop"
	if clip=="crouch_idle":return "Crouch_Idle_Loop"
	if GAITS.has(clip):return "Walk_Formal_Loop" if identity in ["Felps","Garota2","Customer2"] else "Walk_Loop"
	return "Idle_Talking_Loop" if clip=="talk" else "Idle_Loop"
func duration(clip: String) -> float:
	return float(source.clips[source_clip(clip)].length) if GAITS.has(clip) or clip in ["idle","crouch_idle","talk"] else LOOPS[clip]
func stride(clip: String) -> float:
	var multiplier:=float(profile.run_scale if clip=="run" else profile.walk_scale)
	if clip=="run":multiplier*=.60
	if clip=="carry_walk":multiplier*=.88
	if clip=="crouch_walk":multiplier=1.0
	if clip in ["strafe_left","strafe_right"]:multiplier*=.65
	if clip=="walk_back":multiplier*=.72
	# The baker applies the historical stride_scale after this return value.
	return float(source.clips[source_clip(clip)].stride)*leg_ratio*multiplier/stride_scale
func contact_weights(clip: String,time: float) -> Vector2:
	var data: Dictionary=source.clips[source_clip(clip)]
	var at: float=(1.0-time if clip=="walk_back" else time)*(data.soles.size()-1)
	var low:=mini(int(at),data.soles.size()-1);var high:=mini(low+1,data.soles.size()-1)
	return Vector2(1.0-smoothstep(.004,.018,lerpf(data.soles[low][0],data.soles[high][0],at-low)),1.0-smoothstep(.004,.018,lerpf(data.soles[low][1],data.soles[high][1],at-low)))
func sample(clip: String,time: float) -> Array[Transform3D]:
	poses.clear()
	var key:=source_clip(clip);var data: Dictionary=source.clips[key]
	var reverse:=clip=="walk_back"
	var progress:=1.0-time if reverse else time
	var at: float=progress*(data.frames.size()-1);var low:=mini(int(at),data.frames.size()-1);var high:=mini(low+1,data.frames.size()-1);var weight:=at-low
	var frame: Dictionary={}
	for name in source_names:
		frame[name]=unpack(data.frames[low][source_names[name]]).interpolate_with(unpack(data.frames[high][source_names[name]]),weight)
	var moving:=GAITS.has(clip);var carrying:=clip in ["carry","carry_walk"]
	var phase:=time*TAU
	var relaxed:=clip in ["idle","idle_tired","idle_shift","idle_look","idle_adjust","look"]
	var drunk:=identity=="Zirico";var child:=identity=="Bryan"
	var multiplier:=float(profile.run_scale if clip=="run" else profile.walk_scale) if moving else 1.0
	if clip=="run":multiplier*=.60
	if clip=="carry_walk":multiplier*=.88
	if clip=="crouch_walk":multiplier=1.0
	var root_delta: Vector3=(frame["DEF-hips"].origin-reference["DEF-hips"].origin)*leg_ratio
	if relaxed:root_delta.y*=.55
	root_delta.x*=.65 if identity.begins_with("Garota") else .50
	if drunk:root_delta.x+=.035*sin(phase)+.008*sin(phase*2)
	var additions: Dictionary={}
	if not moving:
		additions["waist"]=Vector3(.006*sin(phase),0,.003*sin(phase))
		additions["upper_chest"]=Vector3(-.008*sin(phase),.003*cos(phase),0)
	if drunk:
		additions["pelvis"]=Vector3(.015*sin(phase*2),.025*sin(phase),.075*sin(phase+.35))
		additions["chest"]=Vector3(.018,.015*sin(phase),-.025*sin(phase+.6))
		additions["head"]=Vector3(.025*sin(phase),.035*sin(phase*2),.08*sin(phase-.4))
	if child:
		additions["chest"]=Vector3(.025,.025*sin(phase),0)
		additions["head"]=Vector3(.018*sin(phase*2),.065*sin(phase*3),.018*sin(phase))
	if identity=="Velha1":additions["chest"]=Vector3(.08,0,0)
	if identity=="Felps":additions["chest"]=Vector3(.025,0,0)
	if identity.begins_with("Garota"):additions["pelvis"]=Vector3(0,.012*cos(phase),.013*sin(phase))
	var base: Dictionary={}
	for i in rests.size():
		var name:=skeleton.get_bone_name(i);var parent:=parents[i]
		var global_pose: Transform3D=rests[i] if parent<0 else base[parent]*skeleton.get_bone_rest(i)
		if MAP.has(name):global_pose.basis=frame[MAP[name]].basis*reference[MAP[name]].basis.inverse()*rests[i].basis
		if name=="pelvis":global_pose.origin=rests[i].origin+root_delta
		base[i]=global_pose
		var pose:=global_pose
		if parent>=0:
			var correction: Basis=poses[parent].basis*base[parent].basis.inverse()
			pose.basis=correction*pose.basis
			pose.origin=poses[parent]*skeleton.get_bone_rest(i).origin
		if name=="pelvis":pose.origin+=root_delta
		if additions.has(name):pose.basis=Basis.from_euler(additions[name])*pose.basis
		if name=="chest" and not moving:pose.basis=pose.basis*Basis().scaled(Vector3(1+.0016*sin(phase),1,1+.0022*sin(phase)))
		if identity.begins_with("Customer") and name in ["arm_L","arm_R"]:
			# The modular sleeves begin at x=0.13, but the legacy rig pivot is
			# x=0.258. Rotate the existing skin around the actual sleeve root;
			# otherwise the inner half swings upward beside the character's face.
			var pivot:=Vector3(.13 if name=="arm_L" else -.13,1.34,0)
			var local_pivot:=skeleton.get_bone_rest(i).origin+rests[parent].basis.inverse()*(pivot-rests[i].origin)
			pose.origin=poses[parent]*local_pivot+pose.basis*rests[i].basis.inverse()*(rests[i].origin-pivot)
		poses[i]=pose
	var ankles: Dictionary={};var foot_rotations: Dictionary={}
	for side in ["L","R"]:
		var k:=0 if side=="L" else 1;var sign_value:=1.0 if side=="L" else -1.0
		var name: String="foot_"+side;var foot: int=names[name]
		var delta: Vector3=(frame[MAP[name]].origin-reference[MAP[name]].origin)*leg_ratio
		if relaxed:delta.z*=.30
		var target:=rests[foot].origin+delta
		target.x=rests[foot].origin.x+delta.x*.65
		if relaxed:target.x=sign_value*clampf(absf(rests[names["thigh_"+side]].origin.x)+.025,.10,.14)
		if drunk:target.x+=sign_value*.028+.018*sin(phase+(0 if side=="L" else PI))
		if identity.begins_with("Garota"):target.x-=sign_value*.013
		target.z=rests[foot].origin.z+delta.z*multiplier
		if clip.begins_with("strafe"):
			target.x+=delta.z*multiplier*(1 if clip=="strafe_right" else -1)*.65;target.z=rests[foot].origin.z+delta.x
		if clip=="walk_back":target.z=rests[foot].origin.z+delta.z*multiplier*.72
		var rotation: Basis=poses[foot].basis*rests[foot].basis.inverse()
		var lift: float=lerpf(data.soles[low][k],data.soles[high][k],weight)*leg_ratio
		# Keep a readable heel/toe roll but avoid the high stylized swing of the
		# reference on these realistic shoes. This does not change support timing.
		if moving and clip!="run":lift*=.70 if child else .55 if identity=="Velha1" else .70
		target.y=floor_height(side,rotation)+lift
		ankles[side]=target;foot_rotations[side]=poses[foot].basis
		if not contacts.has(clip):contacts[clip]=[]
	# Respect limb reach without stretching bones. A single pelvis offset adapts
	# different hip/thigh proportions; the authored knee plane remains intact.
	var lower:=0.0
	for side in ["L","R"]:
		var hip: Vector3=poses[names["thigh_"+side]].origin;var target: Vector3=ankles[side]
		var horizontal:=Vector2(hip.x-target.x,hip.z-target.z).length();var reach:=leg_length(side)*.997
		lower=minf(lower,target.y+sqrt(maxf(.001,reach*reach-horizontal*horizontal))-hip.y)
	if lower<0:
		for i in poses:poses[i].origin.y+=lower
	for side in ["L","R"]:
		var thigh: int=names["thigh_"+side];var shin: int=names["shin_"+side];var foot: int=names["foot_"+side]
		var hip: Vector3=poses[thigh].origin;var knee: Vector3=poses[shin].origin;var target: Vector3=ankles[side]
		var l1:=rests[thigh].origin.distance_to(rests[shin].origin);var l2:=rests[shin].origin.distance_to(rests[foot].origin)
		var solved:=solve(hip,target,l1,l2,knee+Vector3(0,0,.15))
		var turn:=Quaternion((knee-hip).normalized(),(solved[0]-hip).normalized())
		var lower_turn:=Quaternion((turn*(poses[foot].origin-knee)).normalized(),(solved[1]-solved[0]).normalized())
		poses[thigh]=Transform3D(Basis(turn)*poses[thigh].basis,hip)
		poses[shin]=Transform3D(Basis(lower_turn)*Basis(turn)*poses[shin].basis,solved[0])
		poses[foot]=Transform3D(foot_rotations[side],solved[1])
		# Lower arms stay loose; Zirico opens his elbows for balance, Bryan keeps
		# a more alert bend. Hand IK is reserved for actual grips and gestures.
		var arm: int=names["arm_"+side];var forearm: int=names["forearm_"+side];var wrist: int=names["hand_"+side]
		var sign_value:=1.0 if side=="L" else -1.0
		var hand: Vector3=poses[wrist].origin
		if relaxed:
			var arm_length:=rests[arm].origin.distance_to(rests[forearm].origin)+rests[forearm].origin.distance_to(rests[wrist].origin)
			hand=poses[arm].origin+Vector3(sign_value*.035,-arm_length*.975,.025)
		if drunk:hand.x+=sign_value*.08;hand.y+=.035+.02*sin(phase*2+sign_value)
		if child:hand.y+=.065;hand.z+=.04
		if child and not moving:hand+=Vector3(0,.025*(1+sin(phase*3+sign_value)),.035*sin(phase*4+sign_value))
		var gesture:=pow(sin(PI*time),2)
		if clip=="idle_adjust" and side=="R":hand=hand.lerp(Vector3(-.12,poses[arm].origin.y-.03,.16),gesture)
		if carrying:hand=Vector3(sign_value*.335+root_delta.x,1.07,.26)
		if clip in ["cashier","cashier_idle"]:hand=Vector3(.08+sign_value*.14,1.22+(.008*sin(phase*10+sign_value) if clip=="cashier" else 0),.27)
		if clip in ["hold_bottle","browse","pay"] and side=="R":hand=Vector3(-.23,1.02 if clip=="hold_bottle" else 1.14,.16+.05*gesture)
		if relaxed or drunk or child or carrying or clip in ["cashier","cashier_idle","hold_bottle","browse","pay"]:
			var shoulder: Vector3=poses[arm].origin;var elbow: Vector3=poses[forearm].origin
			var reach:=solve(shoulder,hand,rests[arm].origin.distance_to(rests[forearm].origin),rests[forearm].origin.distance_to(rests[wrist].origin),elbow+Vector3(sign_value*.05,0,-.08))
			var turn_arm:=Quaternion((elbow-shoulder).normalized(),(reach[0]-shoulder).normalized())
			var turn_lower:=Quaternion((turn_arm*(poses[wrist].origin-elbow)).normalized(),(reach[1]-reach[0]).normalized())
			poses[arm]=Transform3D(Basis(turn_arm)*poses[arm].basis,shoulder)
			poses[forearm]=Transform3D(Basis(turn_lower)*Basis(turn_arm)*poses[forearm].basis,reach[0])
			poses[wrist]=Transform3D(Basis(turn_lower)*Basis(turn_arm)*poses[wrist].basis,reach[1])
	# Reattach unmapped twist/finger/toe bones to their newly retargeted parent.
	for i in rests.size():
		if not MAP.has(skeleton.get_bone_name(i)) and parents[i]>=0:poses[i]=poses[parents[i]]*skeleton.get_bone_rest(i)
	# Verify the actual weighted shoe surface, including calf blends. A rigid
	# ankle offset alone can put a weighted heel under the floor on Bryan's rig.
	for side in ["L","R"]:
		var minimum:=INF
		for item in contact_vertices[side]:
			var point:=Vector3.ZERO
			for influence in item:point+=(poses[influence[0]]*influence[1])*influence[2]
			minimum=minf(minimum,point.y)
		var k:=0 if side=="L" else 1
		var lift: float=lerpf(data.soles[low][k],data.soles[high][k],weight)*leg_ratio
		if moving and clip!="run":lift*=.70 if child else .55 if identity=="Velha1" else .70
		var adjustment:=lift-minimum+.001
		if absf(adjustment)>.0003:
			var thigh: int=names["thigh_"+side];var shin: int=names["shin_"+side];var foot: int=names["foot_"+side]
			var hip: Vector3=poses[thigh].origin;var knee: Vector3=poses[shin].origin;var ankle: Vector3=poses[foot].origin
			var target:=ankle+Vector3.UP*adjustment
			var corrected:=solve(hip,target,hip.distance_to(knee),knee.distance_to(ankle),knee+Vector3(0,0,.15))
			var turn:=Quaternion((knee-hip).normalized(),(corrected[0]-hip).normalized())
			var lower_turn:=Quaternion((turn*(ankle-knee)).normalized(),(corrected[1]-corrected[0]).normalized())
			poses[thigh]=Transform3D(Basis(turn)*poses[thigh].basis,hip)
			poses[shin]=Transform3D(Basis(lower_turn)*Basis(turn)*poses[shin].basis,corrected[0])
			poses[foot].origin=corrected[1]
	for i in rests.size():
		if not MAP.has(skeleton.get_bone_name(i)) and parents[i]>=0:poses[i]=poses[parents[i]]*skeleton.get_bone_rest(i)
	var result: Array[Transform3D]=[]
	for i in rests.size():result.append(poses[i] if parents[i]<0 else poses[parents[i]].affine_inverse()*poses[i])
	return result
