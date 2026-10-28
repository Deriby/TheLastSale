extends Node
signal spoken(speaker: String, text: String)
signal completed(id: String)
var queue: Array = []
var remaining := 0.0
var sequence := ""
var active := false
func play(id: String, lines: Array) -> bool:
	if active: return false
	sequence = id
	queue = lines.duplicate(true)
	active = true
	next_line()
	return true
func next_line() -> void:
	if queue.is_empty():
		active = false
		spoken.emit("", "")
		completed.emit(sequence)
		return
	var line: Array = queue.pop_front()
	remaining = maxf(3.2, str(line[1]).length() * 0.055)
	spoken.emit(line[0],line[1])
func _process(delta: float) -> void:
	if not active: return
	remaining -= delta
	if remaining <= 0: next_line()
func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("dialogue_next"): next_line()
func clear() -> void:
	active = false
	queue.clear()
	spoken.emit("", "")
