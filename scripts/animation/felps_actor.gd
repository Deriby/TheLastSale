class_name FelpsActor
extends Node3D
var model: Node3D
var motion: LivingMotion
var routine_time:=0.0
var routine_index:=0
var talking:=false
var listening:=false
var speaker:=""
func _ready() -> void:
	model=load("res://assets/models/characters/Felps.glb").instantiate();add_child(model)
	motion=LivingMotion.new();add_child(motion);motion.setup(model,self);motion.play("cashier_idle",0)
	var body:=StaticBody3D.new();add_child(body)
	var col:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.height=1.75;shape.radius=.25;col.shape=shape;col.position.y=.87;body.add_child(col)
	Dialogue.spoken.connect(on_spoken)
func on_spoken(who: String,_text: String) -> void:
	speaker=who
	talking=who=="Felps";listening=not who.is_empty() and not talking
	if talking:motion.play("talk",.28)
	elif listening:motion.play("cashier_idle",.30)
	else:routine_time=0;motion.play("cashier_idle",.4)
func _process(delta: float) -> void:
	var player:=get_tree().get_first_node_in_group("player") as Node3D
	if talking or listening:
		var target: Node3D=player
		for client in get_tree().get_nodes_in_group("customers"):
			if global_position.distance_to(client.global_position)<3.0 and (speaker=="Cliente" or talking):target=client;break
		if target!=null:motion.look_at_position(target.global_position+Vector3.UP*1.6)
		return
	if motion.current_clip.is_empty():motion.play("cashier_idle",.35)
	routine_time+=delta
	if player!=null and player.global_position.distance_to(global_position)<3.0:
		motion.look_at_position(player.global_position+Vector3.UP*1.6)
	else:motion.look_at_position(Vector3.ZERO,false)
	if routine_time>6.5:
		routine_time=0;routine_index+=1
		var routine: Array[String]=["cashier","cashier_idle","idle_shift","cashier_idle","idle_look"]
		motion.play(routine[routine_index%routine.size()],.45)
