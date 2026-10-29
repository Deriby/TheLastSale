class_name CharacterModels
extends RefCounted
## Derived FBX assets retain the supplied skin; measurements travel with each actor.
static var profiles: Dictionary = {}
static var imported_materials: Dictionary = {}
static var costume_materials: Dictionary = {}
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
	var cast_profile:=NPCCast.profile(identity)
	var model_path: String=cast_profile.get("model","res://assets/models/characters/"+identity+".glb")
	var visual: Node3D=load(model_path).instantiate()
	visual.set_meta("character_identity",identity)
	visual.set_meta("placeholder",bool(cast_profile.get("placeholder",false)))
	visual.set_meta("motion_style",str(cast_profile.get("motion","living")))
	for key in profiles.get(identity,{}):visual.set_meta(key,profiles[identity][key])
	var colors: Dictionary=cast_profile.get("colors",{})
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var material: Material=mesh.mesh.surface_get_material(surface)
			if material is StandardMaterial3D:
				var part:=material.resource_name.get_slice(".",0)
				if colors.has(part):
					var costume_key:=identity+":"+str(material.get_instance_id())
					if not costume_materials.has(costume_key):
						var tinted: StandardMaterial3D=material.duplicate()
						tinted.albedo_color=Color(str(colors[part]));costume_materials[costume_key]=tinted
					material=costume_materials[costume_key]
					mesh.set_surface_override_material(surface,material)
			register_material(material)
	return visual
