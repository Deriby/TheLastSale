extends "res://tests/cast_review.gd"
## Twelve seconds of the actual controller, exported for motion review.
func _process(delta: float) -> void:
	frame+=1
	var seconds:=frame/30.0
	var speed:=0.0 if seconds<4 else (1.55 if seconds<8 else 1.15)
	for i in 2:
		actors[i].position.z+=speed*delta
		actors[i].motion.locomotion(delta,speed,false,seconds>=8,false)
		boxes[i].visible=seconds>=8
	var focus: Vector3=(actors[0].position+actors[1].position)*.5
	view(focus+Vector3(.7,1.1,4.6),focus+Vector3.UP*.94)
	label.text="Dery e Felps • respiração e postura" if seconds<4 else ("Caminhada • quadril e torso" if seconds<8 else "Transporte • caixa acompanha as mãos")
	if frame>=360:
		set_process(false);call_deferred("finish")
