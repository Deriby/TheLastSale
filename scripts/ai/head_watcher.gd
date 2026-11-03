class_name HeadWatcher
extends CharacterBody3D
## The full original killer stays behind cover; only the head leans into a sightline.
signal withdrawn
signal prepared
signal rejected
signal contact_seen
var world: ShiftWorld
var director: WatchingPresence
var site: Dictionary={}
var visual: Node3D
var motion: LivingMotion
var lean: WatcherLean
var age:=0.0
var hold:=.26
var amount:=0.0
var retreating:=false
var phase:="peak_probe"
var frames:=0
var pose_revision:=0
var started:=false
var resume: Dictionary={}
var directed:=false
var peak_point:=Vector3.ZERO
var contact_fired:=false
var contact_age:=0.0
var contact_light: OmniLight3D
func _ready() -> void:
	if director==null:director=world.presence
	add_to_group("atmosphere_actor");collision_layer=2;collision_mask=3
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.7;capsule.radius=.22;shape.shape=capsule;shape.position.y=.85;add_child(shape)
	visual=CharacterModels.create("Enemy");add_child(visual)
	for mesh in visual.find_children("*","MeshInstance3D",true,false):mesh.layers=2
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	visual.rotation.y=float(site.get("facing",0))
	if bool(site.get("contact",false)):
		motion.look_at_position(world.player.camera_rig.camera.global_position)
		var local:=visual.global_basis.inverse()*(world.player.camera_rig.camera.global_position-(visual.global_position+Vector3.UP*motion.attention.eye_height))
		motion.attention.yaw=clampf(atan2(local.x,local.z),-.65,.65)
		motion.attention.pitch=clampf(-atan2(local.y,maxf(.1,Vector2(local.x,local.z).length())),-.18,.18)
	lean=WatcherLean.new();lean.direction=site.get("lean",Vector3.RIGHT);lean.shift=float(site.get("shift",0.0));motion.skeleton.add_child(lean)
	lean.waist_angle=float(site.get("lean_waist",.46));lean.neck_angle=float(site.get("lean_neck",.45))
	visual.hide();set_amount(1)
	if bool(site.get("contact",false)):
		contact_light=OmniLight3D.new();contact_light.name="ContactReadability";contact_light.light_cull_mask=2;contact_light.light_color=Color("c8d0c0");contact_light.omni_range=1.8;contact_light.shadow_enabled=false;contact_light.visible=false;add_child(contact_light)
	if not resume.is_empty():
		contact_fired=bool(resume.get("contact_fired",false))
		contact_age=float(resume.get("contact_age",0.0))
		directed=bool(resume.get("directed",false));phase=str(resume.get("phase","emerging"));age=float(resume.get("age",0));hold=float(resume.get("hold",.26));amount=float(resume.get("amount",0));started=true;set_amount(amount);visual.show()
func set_amount(value: float) -> void:
	amount=clampf(value,0,1)
	lean.amount=amount if site.get("style","")=="lean" else 0.0
	lean.crouch=lerpf(float(site.get("base_crouch",1.0)),float(site.get("peak_crouch",0.0)),amount) if site.get("style","")=="rise" else 0.0
func _physics_process(delta: float) -> void:
	if not world.active or world.is_queued_for_deletion():return
	frames+=1
	if contact_fired and contact_light!=null:
		contact_age+=delta
		var face: Vector3=lean.points.get("face",global_position+Vector3.UP*1.6)
		contact_light.global_position=face+(world.player.camera_rig.camera.global_position-face).normalized()*.4
		contact_light.light_energy=.65*(1.0-smoothstep(.10,.85,contact_age));contact_light.visible=contact_age<.85
	if phase=="peak_probe":
		if lean.revision<pose_revision+2:return
		if not director.peak_allowed(self):rejected.emit();queue_free();return
		peak_point=head_points()[0];phase="base_probe";frames=0;pose_revision=lean.revision;set_amount(0);return
	if phase=="base_probe":
		if lean.revision<pose_revision+2:return
		if director.any_clear(body_points()+head_points()) or director.witnesses(self):director.last_rejection="base_visible_or_witness";rejected.emit();queue_free();return
		var contact: bool=site.get("contact",false)
		if directed and not contact and not world.horror.focus("watching_"+str(site.id),peak_point,2.25,9):rejected.emit();queue_free();return
		phase="aiming" if directed and not contact else "emerging";started=true;age=0;visual.show();prepared.emit();return
	if not director.safe() or director.witnesses(self) or world.player.position.distance_to(position)<float(site.get("minimum_distance",3.9)):retreating=true
	if retreating and phase!="withdrawing":phase="withdrawing";age=0
	age+=delta
	match phase:
		"aiming":
			if age>.25:phase="emerging";age=0
		"emerging":
			var duration:=.12 if bool(site.get("contact",false)) else .24
			set_amount(smoothstep(0,duration,age))
			if age>=duration:phase="holding";age=0
		"holding":
			if age>=hold:phase="withdrawing";age=0
		"withdrawing":
			set_amount(move_toward(amount,0,delta/.20))
			if amount<=.001 and not director.any_visible(body_points()+head_points()) and not director.witnesses(self):
				started=false
				if directed and world.horror.focused_event in ["watching_"+str(site.id),"contact_"+str(site.id)]:world.player.camera_rig.cancel_focus()
				withdrawn.emit();queue_free()
	if bool(site.get("contact",false)) and not contact_fired and phase in ["emerging","holding"] and amount>.65:
		var face: Vector3=lean.points.get("face",bone_world("head")+lean.head_up*.10)
		if director.clear_face_view(face) and world.horror.focus("contact_"+str(site.id),face,1.25,3.6):
			contact_fired=true;world.horror.follow_face(motion.skeleton,.10,lean);world.horror.contact_hit(.92,.42);contact_seen.emit()
func snapshot() -> Dictionary:
	return {"directed":directed,"site":str(site.id),"phase":phase,"age":age,"hold":hold,"amount":amount,"contact_fired":contact_fired,"contact_age":contact_age}
func bone_world(id: String) -> Vector3:
	if lean!=null and lean.points.has(id):return lean.points[id]
	return motion.skeleton.global_transform*motion.skeleton.get_bone_global_pose(motion.skeleton.find_bone(id)).origin
func body_points() -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for id in ["waist","chest","upper_chest","shoulder_L","shoulder_R","arm_L","arm_R","forearm_L","forearm_R","hand_L","hand_R","thigh_L","thigh_R","shin_L","shin_R","foot_L","foot_R"]:
		if motion.skeleton.find_bone(id)>=0:result.append(bone_world(id))
	return result
func head_points() -> Array[Vector3]:
	if bool(site.get("contact",false)) and lean.points.has("face"):
		var face: Vector3=lean.points.face
		return [face,face+lean.head_up*.12,face+visual.global_basis.x*.09,face-visual.global_basis.x*.09]
	var center:=bone_world("head")
	var at:=center+lean.head_up*.12
	return [at,center+lean.head_up*.25,at+visual.global_basis.x*.09,at-visual.global_basis.x*.09]
func face_points() -> Array[Vector3]:
	var center: Vector3=lean.points.get("face",bone_world("head")+lean.head_up*.09) if bool(site.get("contact",false)) else bone_world("head")+lean.head_up*.09
	return [center,center+visual.global_basis.x*.065,center-visual.global_basis.x*.065,center-lean.head_up*.045]
