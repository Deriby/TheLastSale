class_name StreetHaze
extends Node3D
## Sparse, low-opacity outdoor sheets add local air without volumetric rendering.
var materials: Array[ShaderMaterial]=[]
var time:=0.0
func _init() -> void:name="StreetHaze";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	for x in [-15.0,3.0,21.0]:
		for angle in [0.0,PI/2]:
			var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/street_haze.gdshader");mat.set_shader_parameter("haze_noise",load("res://assets/textures/finish/haze_noise.png"));materials.append(mat)
			var quad:=QuadMesh.new();quad.size=Vector2(23,2.3);var node:=MeshInstance3D.new();node.mesh=quad;node.material_override=mat;node.layers=2;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(node);node.position=Vector3(x,Street.grade(x)+.95,6.6);node.rotation.y=angle
func _process(delta: float) -> void:
	time+=delta
	for mat in materials:mat.set_shader_parameter("drift",time)
