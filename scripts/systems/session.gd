extends Node
## Persistent narrative state. Completion is driven by actions, never by time alone.
signal changed
signal event_triggered(id: String)
var stage := 0
var stocked: Array[String] = []
var organized := false
var customers_served := 0
var warning_delivered := false
var finale_seen := false
var world_seconds := 0.0
var saved_position := Vector3(3.8, 0.1, 1.8)
var carried_id := ""
const SAVE_PATH := "user://shift.json"
const OBJECTIVES = ["Converse com Felps no caixa.", "Busque uma caixa no estoque e reponha a geladeira da esquerda.  0/2", "Reponha mais uma caixa na geladeira.  1/2", "Guarde a caixa solta no palete do estoque.", "Volte ao caixa. O expediente continua.", "Escute o cliente no caixa.", "Confira o ruído no estoque.", "Fim da demonstração — o turno ainda não acabou."]
func new_shift() -> void:
	stage = 0
	stocked.clear()
	organized = false
	customers_served = 0
	warning_delivered = false
	finale_seen = false
	world_seconds = 0.0
	carried_id = ""
	saved_position = Vector3(3.8, 0.1, 1.8)
	changed.emit()
func objective() -> String:
	return OBJECTIVES[clampi(stage, 0, OBJECTIVES.size()-1)]
func greet() -> bool:
	if stage != 0: return false
	stage = 1
	changed.emit()
	event_triggered.emit("greeted")
	return true
func deliver(id: String) -> bool:
	if stage not in [1, 2] or id in stocked or not id.begins_with("stock_"): return false
	stocked.append(id)
	carried_id = ""
	stage = 2 if stocked.size() == 1 else 3
	changed.emit()
	event_triggered.emit("stocked")
	return true
func organize() -> bool:
	if stage != 3 or carried_id != "loose": return false
	organized = true
	carried_id = ""
	stage = 4
	changed.emit()
	event_triggered.emit("organized")
	return true
func serve_customer() -> void:
	customers_served += 1
	changed.emit()
func can_warn() -> bool:
	return stage == 4 and customers_served >= 2 and not warning_delivered
func finish_warning() -> void:
	if not can_warn(): return
	warning_delivered = true
	stage = 6
	changed.emit()
	event_triggered.emit("warning")
func end_slice() -> void:
	if stage != 6: return
	finale_seen = true
	stage = 7
	changed.emit()
	event_triggered.emit("finale")
func save_shift(position_value: Vector3) -> Error:
	saved_position = position_value
	var data := {"version":1,"stage":stage,"stocked":stocked,"organized":organized,"customers":customers_served,"warning":warning_delivered,"finale":finale_seen,"seconds":world_seconds,"position":[saved_position.x,saved_position.y,saved_position.z],"carried":carried_id}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null: return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data))
	return OK
func load_shift() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1: return false
	if not data.get("position") is Array or data.position.size() != 3: return false
	stage = clampi(int(data.get("stage",0)),0,7)
	stocked.assign(data.get("stocked", []))
	organized = bool(data.get("organized",false))
	customers_served = int(data.get("customers",0))
	warning_delivered = bool(data.get("warning",false))
	finale_seen = bool(data.get("finale",false))
	world_seconds = float(data.get("seconds",0))
	saved_position = Vector3(data.position[0],data.position[1],data.position[2])
	carried_id = str(data.get("carried",""))
	changed.emit()
	return true
