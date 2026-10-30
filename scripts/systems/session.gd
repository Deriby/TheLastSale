extends Node
## Persistent narrative state. Completion is driven by actions, never by time alone.
signal changed
signal event_triggered(id: String)
signal saving
var active_character:="Dery"
var character_states: Dictionary={}
var crate_states: Dictionary={}
var sale_state: Dictionary={}
var customer_state: Dictionary={}
var next_sale_id:=1
var sales_cents:=0
var receipts: Array=[]
var familiar_visits: Dictionary={}
var campaign: Dictionary=default_campaign()
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
func default_campaign() -> Dictionary:
	return {"night":0,"phase":"routine","flags":{},"clues":{},"completed_nights":[],"reports":{}}
func flag(id: String) -> bool:return bool(campaign.flags.get(id,false))
func night_title() -> String:return ["SEXTA-FEIRA","SÁBADO","DOMINGO"][clampi(int(campaign.night),0,2)]
func campaign_objective() -> String:
	match str(campaign.phase):
		"outage":
			if not flag("counter_secured"):return "Felps: suspenda o atendimento no caixa. Deryk: pegue a chave do gerador junto à porta do estoque. [F] lanterna."
			if not flag("generator_key"):return "Deryk: pegue a chave do gerador no suporte junto à porta, dentro do estoque. [F] lanterna."
			return "Deryk: abra a porta do pátio nos fundos do estoque e ligue o gerador."
		"restored":return "A energia voltou. Conclua o atendimento antes de fechar o depósito."
		"closing":
			if not flag("till_closed") or not flag("stock_checked"):return "Fechamento: Felps confere o caixa; Deryk verifica a porta antiga no estoque."
			if not flag("lights_off"):return "Desligue a iluminação do salão no quadro junto à porta do estoque."
			return "Reúna a dupla na calçada: use E no comando das portas, à direita da entrada."
		"complete":return "Sexta-feira concluída. O sábado começa na próxima cena."
		"saturday_preview":return "Prévia de sábado: converse com Felps sobre a pane de ontem."
		"saturday_preview_done":return "Abertura de sábado concluída. Investigação e domingo estão em desenvolvimento."
	return ""
func advance_to_saturday() -> void:
	campaign.night=1;campaign.phase="saturday_preview";campaign.flags={}
	stage=0;stocked.clear();organized=false;customers_served=0;warning_delivered=false;finale_seen=false;world_seconds=0
	character_states.clear();crate_states.clear();sale_state.clear();customer_state.clear();receipts.clear();sales_cents=0
	carried_id="";active_character="Dery";saved_position=Vector3(3.8,.01,1.8)
	changed.emit()
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
	active_character="Dery";character_states.clear();crate_states.clear()
	sale_state.clear();customer_state.clear();next_sale_id=1;sales_cents=0;receipts.clear();familiar_visits.clear()
	campaign=default_campaign()
	changed.emit()
func objective() -> String:
	if campaign.phase!="routine":return campaign_objective()
	return OBJECTIVES[clampi(stage, 0, OBJECTIVES.size()-1)]
func greet() -> bool:
	if stage != 0 or int(campaign.night)!=0: return false
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
func record_sale(receipt: Dictionary) -> bool:
	for previous in receipts:
		if int(previous.id)==int(receipt.id):return false
	receipts.append(receipt.duplicate(true));sales_cents+=int(receipt.total)
	serve_customer();return true
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
	saving.emit()
	saved_position = position_value
	if character_states.has(active_character):character_states[active_character].position=[position_value.x,position_value.y,position_value.z]
	var data := {"version":3,"stage":stage,"stocked":stocked,"organized":organized,"customers":customers_served,"warning":warning_delivered,"finale":finale_seen,"seconds":world_seconds,"position":[saved_position.x,saved_position.y,saved_position.z],"carried":carried_id,"active_character":active_character,"characters":character_states,"crates":crate_states,"sale":sale_state,"customer_state":customer_state,"next_sale_id":next_sale_id,"sales_cents":sales_cents,"receipts":receipts,"familiar_visits":familiar_visits}
	data.version=4;data.campaign=campaign
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null: return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data))
	return OK
func load_shift() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or int(data.get("version",0)) not in [1,2,3,4]: return false
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
	active_character="Felps" if data.get("active_character", "Dery")=="Felps" else "Dery"
	character_states=data.get("characters",{}).duplicate(true) if data.get("characters",{}) is Dictionary else {}
	crate_states=data.get("crates",{}).duplicate(true) if data.get("crates",{}) is Dictionary else {}
	sale_state=data.get("sale",{}).duplicate(true) if data.get("sale",{}) is Dictionary else {}
	customer_state=data.get("customer_state",{}).duplicate(true) if data.get("customer_state",{}) is Dictionary else {}
	next_sale_id=maxi(1,int(data.get("next_sale_id",customers_served+1)));sales_cents=maxi(0,int(data.get("sales_cents",0)))
	receipts=data.get("receipts",[]).duplicate(true) if data.get("receipts",[]) is Array else []
	familiar_visits=data.get("familiar_visits",{}).duplicate(true) if data.get("familiar_visits",{}) is Dictionary else {}
	campaign=default_campaign()
	if int(data.version)==4 and data.get("campaign") is Dictionary:
		for key in campaign:campaign[key]=data.campaign.get(key,campaign[key])
		campaign.night=clampi(int(campaign.night),0,2)
	elif stage>=6:
		stage=6;finale_seen=false;campaign.phase="outage"
	changed.emit()
	return true
func read_position(value: Variant,fallback: Vector3) -> Vector3:
	if not value is Array or value.size()!=3:return fallback
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)):return fallback
	return Vector3(float(value[0]),float(value[1]),float(value[2]))
