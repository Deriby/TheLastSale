class_name NeonFinish
extends Node3D
func _init() -> void:name="NeonFinish";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	var batch:=PropBatch.new();add_child(batch)
	var trim:=Geo.material(Color("262c31"));var red:=Geo.material(Color(1,.006,.025),"",1.4);var white:=Geo.material(Color("d4eee9"),"",1.8)
	# Concealed red edge and white entrance tubes retain the real JA facade.
	for pair in [Vector2(-5.80,-2.28),Vector2(-1.91,5.82)]:
		var x: float=(pair.x+pair.y)*.5;var width: float=pair.y-pair.x
		batch.add_box(Vector3(x,3.87,.29),Vector3(width,.13,.16),trim)
		batch.add_box(Vector3(x,3.89,.381),Vector3(width-.10,.035,.028),red)
		batch.add_box(Vector3(x,3.67,-.33),Vector3(width-.20,.025,.025),white)
	for x in [-4.1,3.4]:
		var light:=SpotLight3D.new();light.name="NeonRedSpill";add_child(light);light.position=Vector3(x,3.78,.48);light.look_at_from_position(light.position,Vector3(x,.3,2.7))
		light.light_color=Color(1,.045,.055);light.light_energy=1.2;light.spot_range=7;light.spot_angle=53;light.light_cull_mask=14
		var wall_wash:=Geo.light(self,Vector3(x,3.85,.70),Color(1,.035,.045),.30,2.1)
		wall_wash.name="NeonWallWash";wall_wash.light_cull_mask=4;wall_wash.set_meta("detail_light",true)
	# Illuminated original lettering, not a replacement business identity.
	var open:=SceneDetail.panel(self,Vector3(-3.1,2.48,-.18),Vector2(1.23,.41),"finish/open_sign",0,.85)
	var sign_material:=ShaderMaterial.new();sign_material.shader=load("res://shaders/illuminated_sign.gdshader");sign_material.set_shader_parameter("sign_art",load("res://assets/textures/finish/open_sign.png"));open.material_override=sign_material
	Geo.box(self,Vector3(-3.1,2.48,-.21),Vector3(1.28,.46,.035),trim,false)
	for x in [-3.63,-2.57]:StreetDetail.beam(batch,Vector3(x,2.70,-.21),Vector3(x,3.40,-.21),.006,trim)
	var cold:=SceneDetail.panel(self,Vector3(5.76,2.47,-2.9),Vector2(.85,.28),"finish/cold_sign",-PI/2,.55)
	batch.flush()
	for mesh in find_children("*","MeshInstance3D",true,false):mesh.layers=5
