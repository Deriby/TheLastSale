class_name Geo
extends RefCounted
static var materials: Dictionary = {}
static func material(color: Color, texture: String = "", emission := 0.0) -> StandardMaterial3D:
	var key := str(color)+texture+str(emission)
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if not texture.is_empty():
		m.albedo_texture = load(texture)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 0.8
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	materials[key] = m
	return m
static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid := true) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	o.mesh = mesh
	o.material_override = mat
	parent.add_child(o)
	o.position = pos
	if solid:
		var body := StaticBody3D.new()
		o.add_child(body)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
	return o
static func cylinder(parent: Node3D,pos: Vector3,radius: float,height: float,mat: Material,top := -1.0) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	o.mesh = mesh
	o.material_override = mat
	parent.add_child(o)
	o.position = pos
	return o
static func sign_text(parent: Node3D, text: String,pos: Vector3,size := 40,color := Color("eee6d0")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.006
	l.modulate = color
	l.outline_size = 0
	l.no_depth_test = false
	parent.add_child(l)
	l.position = pos
	return l
static func beam(parent: Node3D,a: Vector3,b: Vector3,width: float,mat: Material) -> MeshInstance3D:
	var o := box(parent,(a+b)*.5,Vector3(width,width,a.distance_to(b)),mat,false)
	o.look_at_from_position((a+b)*.5,b,Vector3.UP if absf((b-a).normalized().y) < .99 else Vector3.RIGHT)
	return o
static func light(parent: Node3D,pos: Vector3,color: Color,energy: float,radius: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	parent.add_child(l)
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = radius
	l.shadow_enabled = false
	return l
