class_name FamiliarNPC
extends CharacterBody3D
## Optional familiar faces; their conversations never advance the work objectives.
var identity:="Bryan"
var visual: Node3D
var motion: LivingMotion
var interaction: Interaction
var visit_time:=0.0
var watching:=false
var leaving:=false
var exit_path:=PackedVector3Array()
func depart(path: PackedVector3Array) -> void:
	leaving=true;watching=false;exit_path=path
	interaction.process_mode=Node.PROCESS_MODE_DISABLED
func _ready() -> void:
	add_to_group("familiar_npcs")
	collision_layer=2;collision_mask=1|2
	visual=CharacterModels.create(identity);add_child(visual)
	var height: float=visual.get_meta("height_m",1.7)
	var col:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=height;capsule.radius=.19 if identity=="Bryan" else .24
	col.shape=capsule;col.position.y=height*.5;add_child(col)
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	interaction=Interaction.new();interaction.kind="familiar";interaction.identity=identity;add_child(interaction)
	# This actor is the collider itself, rather than a fixture with collider children.
	set_meta("interaction",interaction)
	Dialogue.spoken.connect(on_spoken)
	Dialogue.completed.connect(on_completed)
func on_spoken(who: String,_text: String) -> void:
	watching=who in [identity,"Dery","Felps"] and Dialogue.sequence=="familiar_"+identity
	if watching:motion.play("talk" if who==identity else "idle",.28)
func on_completed(_id: String) -> void:
	watching=false
func _physics_process(delta: float) -> void:
	if leaving:
		while not exit_path.is_empty() and Vector2(exit_path[0].x-position.x,exit_path[0].z-position.z).length()<.12:exit_path.remove_at(0)
		if exit_path.is_empty():queue_free();return
		var direction: Vector3=(exit_path[0]-position)*Vector3(1,0,1);direction=direction.normalized()
		velocity=direction*1.1;velocity.y=-2;move_and_slide()
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*8)
		motion.locomotion(delta,1.1,false,false,false);return
	velocity=Vector3(0,-2,0);move_and_slide()
	if watching:
		var player:=get_tree().get_first_node_in_group("player") as Node3D
		if player:motion.look_at_position(player.global_position+Vector3.UP*1.6)
		return
	visit_time+=delta
	motion.locomotion(delta,0,false,false,false)
	if identity=="Zirico":
		# Restrained, uneven timing; the feet stay supported instead of falling over.
		motion.animator.speed_scale=.82+.08*sin(visit_time*.63)
	motion.look_at_position(Vector3.ZERO,false)
