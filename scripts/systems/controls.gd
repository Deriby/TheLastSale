class_name Controls
extends RefCounted
static func install() -> void:
	var keys := {"forward":KEY_W,"backward":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"interact":KEY_E,"drop":KEY_Q,"pause":KEY_ESCAPE,"flashlight":KEY_F,"dialogue_next":KEY_SPACE,"switch_character":KEY_TAB}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = keys[action]
		if not InputMap.action_has_event(action,key):InputMap.action_add_event(action,key)
