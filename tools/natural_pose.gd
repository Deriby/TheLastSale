extends RefCounted
## Offline pose authoring in Skeleton3D coordinates (+Y up, +Z forward).
## Saved libraries keep all pose solving out of the runtime frame loop.
const GAITS: Dictionary={"walk":1.28,"walk_back":.90,"strafe_left":.94,"strafe_right":.94,"run":2.15,"crouch_walk":.69,"carry_walk":1.06}
const LOOPS: Dictionary={"idle":8.0,"idle_tired":6.0,"idle_shift":6.0,"idle_look":5.0,"idle_adjust":4.0,"walk":1.0,"walk_back":1.0,"strafe_left":1.0,"strafe_right":1.0,"run":1.0,"crouch_idle":6.0,"crouch_walk":1.0,"carry":6.0,"carry_walk":1.0,"talk":5.0,"cashier":6.0,"cashier_idle":7.0,"hold_bottle":6.0,"browse":4.0,"pay":3.0,"look":5.0}
var skeleton: Skeleton3D
var identity: String
var rests: Array[Transform3D]=[]
var parents: Array[int]=[]
var names: Dictionary={}
var poses: Dictionary={}
var soles: Dictionary={"L":[],"R":[]}
var stride_scale:=1.0
var actor_scale:=1.0
var profile: Dictionary={}
func stride(clip: String) -> float:
	return float(GAITS[clip])*float(profile.run_scale if clip=="run" else profile.walk_scale if clip in ["walk","walk_back","strafe_left","strafe_right"] else 1.0)
func init(sk: Skeleton3D,visual: Node3D,id: String) -> void:
	skeleton=sk;identity=id;actor_scale=sk.global_basis.get_scale().x
	profile=MotionProfiles.for_actor(id,visual.scene_file_path)
	for i in sk.get_bone_count():
		rests.append(sk.get_bone_global_rest(i));parents.append(sk.get_bone_parent(i));names[sk.get_bone_name(i)]=i
	var length:=0.0
	for side in ["L","R"]:length+=leg_length(side)
	stride_scale=clampf(length*.5/.725,.85,1.3)
	if id=="Velha1":stride_scale*=.90
	collect_soles(visual)
func leg_length(side: String) -> float:
	return rests[names["thigh_"+side]].origin.distance_to(rests[names["shin_"+side]].origin)+rests[names["shin_"+side]].origin.distance_to(rests[names["foot_"+side]].origin)
func below(index: int,ancestor: int) -> bool:
	while index>=0:
		if index==ancestor:return true
		index=parents[index]
	return false
func collect_soles(visual: Node3D) -> void:
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		if mesh.skin==null:continue
		var mapped: Array[int]=[]
		for i in mesh.skin.get_bind_count():
			var id: int=mesh.skin.get_bind_bone(i)
			if id<0:id=skeleton.find_bone(mesh.skin.get_bind_name(i))
			mapped.append(id)
		var to_skeleton: Transform3D=skeleton.global_transform.affine_inverse()*mesh.global_transform
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_BONES]==null:continue
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var influences:=bones.size()/vertices.size()
			for v in vertices.size():
				var at: Vector3=to_skeleton*vertices[v]
				if at.y>.32:continue
				for side in ["L","R"]:
					var foot: int=names["foot_"+side];var weight:=0.0
					for j in influences:
						var bind: int=bones[v*influences+j]
						if bind<mapped.size() and below(mapped[bind],foot):weight+=weights[v*influences+j]
					if weight>.55:soles[side].append(at-rests[foot].origin)
	for side in ["L","R"]:
		if soles[side].is_empty():soles[side]=[Vector3(0,-rests[names["foot_"+side]].origin.y,0)]
func inherit(index: int) -> Transform3D:
	if not poses.has(index):poses[index]=rests[index] if parents[index]<0 else inherit(parents[index])*skeleton.get_bone_rest(index)
	return poses[index]
func fk(bone: String,angles: Vector3) -> void:
	if not names.has(bone):return
	var index: int=names[bone];var base:=inherit(index)
	poses[index]=Transform3D(Basis.from_euler(angles)*base.basis,base.origin)
func child_head(bone: String) -> Vector3:
	var index: int=names[bone]
	return (inherit(parents[index])*skeleton.get_bone_rest(index)).origin
func segment(bone: String,a: Vector3,b: Vector3,child: String) -> void:
	var index: int=names[bone]
	var original: Vector3=rests[names[child]].origin-rests[index].origin
	var q:=Quaternion(original.normalized(),(b-a).normalized())
	poses[index]=Transform3D(Basis(q)*rests[index].basis,a)
func solve(a: Vector3,target: Vector3,l1: float,l2: float,pole: Vector3) -> Array[Vector3]:
	var axis:=target-a;var distance:=clampf(axis.length(),.001,l1+l2-.0001);axis=axis.normalized()
	var projected:=pole-a-axis*(pole-a).dot(axis)
	if projected.length()<.0001:projected=Vector3.FORWARD
	var along: float=(l1*l1-l2*l2+distance*distance)/(2*distance)
	return [a+axis*along+projected.normalized()*sqrt(maxf(.000001,l1*l1-along*along)),a+axis*distance]
func floor_height(side: String,rotation: Basis) -> float:
	var lowest:=INF
	for point in soles[side]:lowest=minf(lowest,(rotation*point).y)
	return -lowest
func eased(value: float) -> float:return smoothstep(0,1,value)
func sample(clip: String,time: float) -> Array[Transform3D]:
	poses.clear()
	var moving:=GAITS.has(clip);var running:=clip=="run";var crouch:=clip.begins_with("crouch");var carrying:=clip in ["carry","carry_walk"]
	var phase:=time*TAU;var breath:=sin(time*TAU*2) if not moving else 0.0
	var drunk: bool=profile.style=="drunk"
	var child: bool=profile.style=="restless_child"
	var sway: float=float(profile.sway)*sin(phase) if moving else float(profile.sway)*.45*sin(phase)
	if drunk:sway+=.012*sin(phase*2+.4)
	var root: int=names.pelvis
	var root_at: Vector3=rests[root].origin+Vector3(sway,-.012,0)
	if clip=="idle_shift":root_at.x+=.014*sin(phase);root_at.y-=.004*pow(sin(phase),2)
	if crouch:root_at.y-=.42
	var ankles: Dictionary={};var rolls: Dictionary={};var stance:=.36 if running else .61
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="L" else -1.0
		var foot: int=names["foot_"+side];var thigh: int=names["thigh_"+side]
		var at:=Vector3(sign_value*clampf(absf(rests[thigh].origin.x)+float(profile.width),.092,.17),0,rests[foot].origin.z)
		var roll:=0.0
		if moving:
			var t:=fposmod(time+(0 if side=="L" else .5),1.0)
			var cycle_stride: float=stride(clip)*stride_scale
			var front:=cycle_stride*stance*.5;var back: float=-front;var distance:=0.0
			if t<stance:
				var u:=t/stance;distance=lerpf(front,back,u)
				roll=lerpf(-.12,0,eased(u/.15))+(.46 if running else .24)*eased((u-.68)/.32)
			else:
				var u: float=(t-stance)/(1-stance);var tangent: float=-cycle_stride*(1-stance)
				distance=(2*u*u*u-3*u*u+1)*back+(u*u*u-2*u*u+u)*tangent+(-2*u*u*u+3*u*u)*front+(u*u*u-u*u)*tangent
				roll=(.46 if running else .24)*(1-eased(u/.28))-.12*eased((u-.72)/.28)
				at.y+=(.13 if running else .035 if crouch else .045 if carrying else float(profile.lift))*pow(sin(PI*u),1.35)
				if drunk:at.x+=sign_value*.045*sin(PI*u)
			if clip.begins_with("strafe"):at.x+=distance*(-1 if clip=="strafe_left" else 1)
			else:at.z+=distance*(-1 if clip=="walk_back" else 1)
		if child and not moving:roll=.065*maxf(0,sin(phase*2+sign_value*PI*.5))
		var rotation:=Basis.from_euler(Vector3(roll,sign_value*(.045 if drunk else .018),0))
		at.y+=floor_height(side,rotation);ankles[side]=at;rolls[side]=rotation
	# Raise the body between contacts, lowering only as far as the measured legs require.
	# This replaces the same low hip height for every uploaded rig.
	if moving and not crouch:root_at.y+=(.014 if child else .008)*(1-cos(phase*2))
	if child and not moving:root_at.y-=.008*(1-cos(phase*4))
	for side in ["L","R"]:
		var hip: Vector3=rests[names["thigh_"+side]].origin+(root_at-rests[root].origin)
		var foot: Vector3=ankles[side];var horizontal:=Vector2(hip.x-foot.x,hip.z-foot.z).length()
		var length:=leg_length(side)*.995
		var maximum:=foot.y+sqrt(maxf(.001,length*length-horizontal*horizontal))-(rests[names["thigh_"+side]].origin.y-rests[root].origin.y)
		var softness:=maxf(.018-absf(root_at.y-maximum),0)/.018
		root_at.y=minf(root_at.y,maximum)-softness*softness*.0045
	var pelvis_rotation:=Vector3(0,float(profile.twist)*cos(phase) if moving else .004*breath,-.016*sin(phase) if moving else .003*breath)
	if drunk:pelvis_rotation.z+=.08*sin(phase+.3)
	poses[root]=Transform3D(Basis.from_euler(pelvis_rotation)*rests[root].basis,root_at)
	var lean: float=.12 if running else .45 if crouch else .025 if carrying else float(profile.lean) if moving else .005
	if profile.style=="older_woman" and not moving:lean+=.035
	if drunk:lean+=.028*sin(phase*2+.4)
	fk("waist",Vector3(lean*.30,0,.006*sin(phase)))
	fk("spine",Vector3(lean*.32,-pelvis_rotation.y*.5,0))
	fk("chest",Vector3(lean*.25+.005*breath,-pelvis_rotation.y*.45,.005*breath))
	var rib: int=names.chest
	poses[rib].basis=poses[rib].basis.scaled(Vector3(1+.0025*breath,1,1+.003*breath))
	fk("upper_chest",Vector3(lean*.13,-pelvis_rotation.y*.2,0))
	fk("neck",Vector3(-lean*.3,0,0))
	var look:=.18*sin(phase)*pow(sin(PI*time),2) if clip in ["idle_look","look"] else .018*sin(phase)
	if child:look+=.10*sin(phase*3)
	fk("head",Vector3(.055 if clip in ["cashier","cashier_idle"] else .012*breath,look,.12*sin(phase-.5) if drunk else 0.0))
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="L" else -1.0
		fk("shoulder_"+side,Vector3(.003*breath,-sign_value*.012*cos(phase) if moving else 0,0))
		var hip:=child_head("thigh_"+side);var foot: Vector3=ankles[side]
		var l1:=rests[names["thigh_"+side]].origin.distance_to(rests[names["shin_"+side]].origin)
		var l2:=rests[names["shin_"+side]].origin.distance_to(rests[names["foot_"+side]].origin)
		var leg:=solve(hip,foot,l1,l2,hip+Vector3(sign_value*.025,0,1))
		segment("thigh_"+side,hip,leg[0],"shin_"+side);segment("shin_"+side,leg[0],leg[1],"foot_"+side)
		poses[names["foot_"+side]]=Transform3D(rolls[side]*rests[names["foot_"+side]].basis,leg[1])
		var shoulder:=child_head("arm_"+side)
		l1=rests[names["arm_"+side]].origin.distance_to(rests[names["forearm_"+side]].origin)
		l2=rests[names["forearm_"+side]].origin.distance_to(rests[names["hand_"+side]].origin)
		var swing: float=cos(phase+(0 if side=="L" else PI))
		var hand:=Vector3(shoulder.x+sign_value*(.12 if drunk else .035),shoulder.y-(l1+l2)*float(profile.arm_reach),shoulder.z+.04)
		if moving:
			hand.z-=(.21 if running else float(profile.arm_swing))*swing
			hand.y+=(.19 if running else .016)+(.055 if running else .012)*(1-swing)
		if drunk:
			hand.x+=sign_value*.035*sin(phase+.8);hand.y+=.045*sin(phase*2+sign_value)
		if child and not moving:
			hand.z+=.055*sin(phase*4+sign_value);hand.y+=.045*(1+sin(phase*3+sign_value))
		if crouch:hand=Vector3(sign_value*.25,.62,.26)
		if carrying:hand=Vector3(sign_value*.335+sway,1.07+.004*breath,.26)
		if clip in ["cashier","cashier_idle"]:hand=Vector3(.08+sign_value*.14,1.22+(.009*sin(phase*10+sign_value) if clip=="cashier" else .003*breath),.27)
		if clip=="talk" and side=="L":hand=Vector3(.25,(shoulder.y-.12 if child else 1.0)+.055*sin(phase*2),(.32 if child else .17)+.045*sin(phase))
		if clip=="idle_adjust" and side=="R":hand=hand.lerp(Vector3(-.08,shoulder.y-.04,.10) if child else Vector3(-.19,1.02,.13),pow(sin(PI*time),2))
		if clip in ["hold_bottle","browse","pay"] and side=="R":hand=Vector3(-.23,1.02 if clip=="hold_bottle" else 1.14,.16+(.07*pow(sin(PI*time),2) if clip!="hold_bottle" else 0))
		var arm:=solve(shoulder,hand,l1,l2,shoulder+Vector3(sign_value*.065,-.25,-.13))
		segment("arm_"+side,shoulder,arm[0],"forearm_"+side);segment("forearm_"+side,arm[0],arm[1],"hand_"+side)
		var wrist: int=names["hand_"+side]
		# Preserve a neutral wrist rather than forcing the palm into the forearm's axis.
		var arm_rotation: Basis=poses[names["forearm_"+side]].basis*rests[names["forearm_"+side]].basis.inverse()
		poses[wrist]=Transform3D(arm_rotation*rests[wrist].basis,arm[1])
	var result: Array[Transform3D]=[]
	for i in rests.size():inherit(i)
	for i in rests.size():result.append(poses[i] if parents[i]<0 else poses[parents[i]].affine_inverse()*poses[i])
	return result
