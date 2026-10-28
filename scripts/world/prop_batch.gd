class_name PropBatch
extends Node3D
## Bake static fixtures by shared material. Ordinary meshes avoid legacy GPU instancing.
## Retain source transforms for restocking and independent render verification.
var groups: Dictionary = {}
static var unit_cube: BoxMesh
func _init() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func add_product(id: String,at: Vector3,angle := 0.0,scale_value := Vector3.ONE) -> void:
	add_instance(id,ProductLibrary.mesh(id),ProductLibrary.material(id),Transform3D(Basis(Vector3.UP,angle).scaled(scale_value),at))
func add_box(at: Vector3,size: Vector3,mat: Material) -> void:
	if unit_cube==null:unit_cube=BoxMesh.new();unit_cube.size=Vector3.ONE
	add_instance("box_"+str(mat.get_instance_id()),unit_cube,mat,Transform3D(Basis.IDENTITY.scaled(size),at))
func add_instance(key: String,mesh: Mesh,mat: Material,transform_value: Transform3D) -> void:
	if not groups.has(key):
		var node:=MeshInstance3D.new();node.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		node.material_override=mat;add_child(node)
		groups[key]={"node":node,"source_mesh":mesh,"transforms":[],"dirty":true,"baked_count":0}
	groups[key].transforms.append(transform_value);groups[key].dirty=true
func flush() -> void:
	for data in groups.values():
		if not data.dirty:continue
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for at in data.transforms:surface.append_from(data.source_mesh,0,at)
		var combined:=surface.commit()
		data.node.mesh=combined
		data.node.custom_aabb=combined.get_aabb().grow(.002)
		data.baked_count=data.transforms.size();data.dirty=false
