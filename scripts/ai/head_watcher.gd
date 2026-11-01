class_name HeadWatcher
extends CharacterBody3D
## The full original killer stays behind cover; only the head leans into a sightline.
signal withdrawn
signal prepared
signal rejected
var world: ShiftWorld
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
func _ready() -> void:
	add_to_group("atmosphere_actor");collision_layer=2;collision_mask=3
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.7;capsule.radius=.22;shape.shape=capsule;shape.position.y=.85;add_child(shape)
	visual=CharacterModels.create("Enemy");add_child(visual)
	for mesh in visual.find_children("*","MeshInstance3D",true,false):mesh.layers=2
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	visual.rotation.y=float(site.get("facing",0))
	lean=WatcherLean.new();lean.direction=site.get("lean",Vector3.RIGHT);motion.skeleton.add_child(lean)
	visual.hide();set_amount(1)
	if not resume.is_empty():
		phase=str(resume.get("phase","emerging"));age=float(resume.get("age",0));hold=float(resume.get("hold",.26));amount=float(resume.get("amount",0));started=true;set_amount(amount);visual.show()
func set_amount(value: float) -> void:
	amount=clampf(value,0,1)
	lean.amount=amount if site.get("style","")=="lean" else 0.0
	lean.crouch=lerpf(float(site.get("base_crouch",1.0)),float(site.get("peak_crouch",0.0)),amount) if site.get("style","")=="rise" else 0.0
func _physics_process(delta: float) -> void:
	if not world.active or world.is_queued_for_deletion():return
	var director: WatchingPresence=world.presence
	frames+=1
	if phase=="peak_probe":
		if lean.revision<pose_revision+2:return
		if not director.peak_allowed(self):rejected.emit();queue_free();return
		phase="base_probe";frames=0;pose_revision=lean.revision;set_amount(0);return
	if phase=="base_probe":
		if lean.revision<pose_revision+2:return
		if director.any_clear(body_points()+head_points()) or director.witnesses(self):director.last_rejection="base_visible_or_witness";rejected.emit();queue_free();return
		phase="emerging";started=true;age=0;visual.show();prepared.emit();return
	if not director.safe() or director.witnesses(self) or world.player.position.distance_to(position)<3.9:retreating=true
	if retreating and phase!="withdrawing":phase="withdrawing";age=0
	age+=delta
	match phase:
		"emerging":
			set_amount(smoothstep(0,.24,age))
			if age>=.24:phase="holding";age=0
		"holding":
			if age>=hold:phase="withdrawing";age=0
		"withdrawing":
			set_amount(move_toward(amount,0,delta/.20))
			if amount<=.001 and not director.any_visible(body_points()+head_points()) and not director.witnesses(self):started=false;withdrawn.emit();queue_free()
func snapshot() -> Dictionary:
	return {"site":str(site.id),"phase":phase,"age":age,"hold":hold,"amount":amount}
func bone_world(id: String) -> Vector3:
	if lean!=null and lean.points.has(id):return lean.points[id]
	return motion.skeleton.global_transform*motion.skeleton.get_bone_global_pose(motion.skeleton.find_bone(id)).origin
func body_points() -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for id in ["waist","chest","upper_chest","shoulder_L","shoulder_R","arm_L","arm_R","forearm_L","forearm_R","hand_L","hand_R","thigh_L","thigh_R","shin_L","shin_R","foot_L","foot_R"]:
		if motion.skeleton.find_bone(id)>=0:result.append(bone_world(id))
	return result
func head_points() -> Array[Vector3]:
	var center:=bone_world("head")
	var at:=center+lean.head_up*.12
	return [at,center+lean.head_up*.25,at+visual.global_basis.x*.09,at-visual.global_basis.x*.09]
