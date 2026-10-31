class_name MotionProfiles
extends RefCounted
## Shared by the offline clip author and runtime controller; never changes a model.
static var data: Dictionary = {}
static func for_actor(identity: String,model_path := "") -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://resources/locomotion_profiles.json"))
	var result: Dictionary=data.default.duplicate()
	var model:=model_path.get_file().get_basename()
	var key:=identity if data.characters.has(identity) else model
	result.merge(data.characters.get(key,{}),true)
	return result
