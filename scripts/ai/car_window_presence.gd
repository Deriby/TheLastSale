class_name CarWindowPresence
extends Node3D
## A single late Saturday encounter inside an existing parked car.
signal finished
var world: ShiftWorld
var owner_event: SaturdayUnease
var resume: Dictionary={}
var visual: Node3D
var motion: LivingMotion
var pose: WatcherLean
var phase:="preparing"
var next_phase:="waiting"
var age:=0.0
var amount:=0.0
func _ready() -> void:
	visual=CharacterModels.create("Enemy");add_child(visual)
	for mesh in visual.find_children("*","MeshInstance3D",true,false):mesh.layers=8;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	pose=WatcherLean.new();motion.skeleton.add_child(pose);visual.hide()
	if not resume.is_empty():next_phase=str(resume.get("phase","waiting"));age=float(resume.get("age",0));amount=float(resume.get("amount",0))
	pose.crouch=lerpf(2.3,1.05,amount)
func _physics_process(delta: float) -> void:
	if not world.active or world.is_queued_for_deletion():return
	if phase=="preparing":
		if pose.revision<2:return
		phase=next_phase;visual.show();return
	age+=delta
	if not owner_event.base_safe() and phase!="withdrawing":phase="withdrawing";age=0
	match phase:
		"waiting":
			if owner_event.window_visible():phase="rising";age=0
			elif age>3.0:phase="withdrawing";age=0
		"rising":
			amount=smoothstep(0,.12,age)
			if age>=.12:phase="holding";age=0
		"holding":
			if age>.42:phase="withdrawing";age=0
		"withdrawing":
			amount=move_toward(amount,0,delta/.22)
			if amount<.001 and pose.revision>2:
				var head: Vector3=pose.points.get("head",global_position)
				if get_parent().to_local(head+pose.head_up*.28).y<.94 or not owner_event.window_visible():phase="done";finished.emit();queue_free()
	pose.crouch=lerpf(2.3,1.05,amount)
func snapshot() -> Dictionary:
	return {"phase":next_phase if phase=="preparing" else phase,"age":age,"amount":amount}
