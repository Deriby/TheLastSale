class_name PropBatch
extends Node3D
## Batch by shared mesh/material. Flush once after placement; retain transforms for restocks.
var groups: Dictionary = {}
static var unit_cube: BoxMesh
func add_product(id: String,at: Vector3,angle := 0.0,scale_value := Vector3.ONE) -> void:
	add_instance(id,ProductLibrary.mesh(id),ProductLibrary.material(id),Transform3D(Basis(Vector3.UP,angle).scaled(scale_value),at))
func add_box(at: Vector3,size: Vector3,mat: Material) -> void:
	if unit_cube==null:unit_cube=BoxMesh.new();unit_cube.size=Vector3.ONE
	add_instance("box_"+str(mat.get_instance_id()),unit_cube,mat,Transform3D(Basis.IDENTITY.scaled(size),at))
func add_instance(key: String,mesh: Mesh,mat: Material,transform_value: Transform3D) -> void:
	if not groups.has(key):
		var node:=MultiMeshInstance3D.new();node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=mesh;node.material_override=mat;add_child(node)
		groups[key]={"node":node,"transforms":[]}
	groups[key].transforms.append(transform_value)
func flush() -> void:
	for data in groups.values():
		var mm: MultiMesh=data.node.multimesh
		mm.instance_count=data.transforms.size()
		for i in data.transforms.size():mm.set_instance_transform(i,data.transforms[i])
