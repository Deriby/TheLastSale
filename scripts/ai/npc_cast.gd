class_name NPCCast
extends RefCounted
## Stable story/save identities are independent of the replaceable visual assets.
static var entries: Array = []
static var arrival_order: Array = []
static func customers() -> Array:
	if entries.is_empty():
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/npc_cast.json"))
		entries=data.customers
		arrival_order=data.arrival_order
	return entries
static func profile(identity: String) -> Dictionary:
	for entry in customers():
		if entry.id==identity:return entry
	return {}
static func customer_identity(appearance: int,saved_identity := "") -> String:
	if not profile(saved_identity).is_empty():return saved_identity
	var cast:=customers()
	return str(cast[posmod(appearance,cast.size())].id)
static func arrival_identity(number: int) -> String:
	customers()
	return str(arrival_order[posmod(number,arrival_order.size())])
