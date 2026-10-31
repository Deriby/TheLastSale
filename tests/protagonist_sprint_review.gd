extends "res://tests/locomotion_review.gd"
## Sustained movement with the shipped controller and interpolation enabled.
func _ready() -> void:
	super._ready();set_page(0);output=""
func _physics_process(delta: float) -> void:
	elapsed+=delta
	var mode:="walk" if elapsed<1.2 or elapsed>=7.2 and elapsed<8.2 else "run" if elapsed<7.2 else "idle"
	for actor in actors[0]:actor.mode=mode
	if elapsed>=9.2:set_physics_process(false);call_deferred("finish")
func _process(_delta: float) -> void:
	var focus: Vector3=(actors[0][0].get_global_transform_interpolated().origin+actors[0][1].get_global_transform_interpolated().origin)*.5
	var angle:=deg_to_rad(24+30*smoothstep(0,7.2,elapsed))
	camera.position=focus+Vector3(sin(angle)*6.1,1.45,cos(angle)*6.1);camera.look_at(focus+Vector3.UP*.9)
	caption.text="0.27.0 / DERYK E FELPS\n"+("Corrida contínua" if elapsed>=1.2 and elapsed<7.2 else "Caminhada e transição" if elapsed<8.2 else "Parada")
	var path:=OS.get_environment("SPRINT_REVIEW_PATH")
	if elapsed>4.0 and not path.is_empty() and not saved.has(0):saved[0]=true;output=path;call_deferred("capture","run")
