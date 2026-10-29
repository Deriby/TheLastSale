class_name CharacterModels
extends RefCounted
## Derived FBX assets retain the supplied skin; measurements travel with each actor.
static var profiles: Dictionary = {}
static var imported_materials: Dictionary = {}
static func register_material(material: Material) -> void:
	if not material is StandardMaterial3D:return
	var key:=material.get_instance_id()
	if not imported_materials.has(key):imported_materials[key]={"material":material,"normal":material.normal_enabled}
	material.normal_enabled=bool(imported_materials[key].normal) and Preferences.pixel_scale<3
static func apply_quality() -> void:
	for entry in imported_materials.values():entry.material.normal_enabled=bool(entry.normal) and Preferences.pixel_scale<3
static func create(identity: String) -> Node3D:
	if profiles.is_empty() and FileAccess.file_exists("res://resources/character_profiles.json"):
		profiles=JSON.parse_string(FileAccess.get_file_as_string("res://resources/character_profiles.json"))
	var visual: Node3D=load("res://assets/models/characters/"+identity+".glb").instantiate()
	visual.set_meta("character_identity",identity)
	for key in profiles.get(identity,{}):visual.set_meta(key,profiles[identity][key])
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():register_material(mesh.mesh.surface_get_material(surface))
	return visual
