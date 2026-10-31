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
var retry_state: Dictionary={}
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
	return {"night":0,"phase":"routine","flags":{},"clues":{},"decisions":{},"evidence_archive":{},"records":[],"sunday":{},"ending":{},"completed_nights":[],"reports":{},"experience":default_experience(),"friday_story":default_friday_story(),"friday_scares":default_friday_scares()}
func default_friday_scares() -> Dictionary:return {"events":{},"last_event":-1000.0,"last_scare":-1000.0,"door_phase":"","door_time":0.0,"prank":{},"intruder":{},"return_armed":false,"dim_time":0.0}
func default_friday_story() -> Dictionary:return {"events":{},"observations":{},"recap":""}
func default_experience() -> Dictionary:return {"events":{},"event_times":{},"notes":[],"observer":{},"tension":0.0}
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
		"complete":return "Noite concluída. Confira o resumo para continuar."
		"saturday_intro":return "Converse com Felps no caixa sobre a pane de ontem."
		"saturday_routine":return "Felps: atenda os dois clientes. [C] no caixa: câmeras e caderno. Deryk pode conferir os fundos."
		"saturday_investigation":return "Felps: confira os eventos do DVR e o recibo [C no caixa]. Deryk: examine a porta antiga e as caixas deslocadas nos fundos."
		"saturday_decisions":return "No caderno do caixa [C], decida sobre a cópia e o contato. Confira a saída no comando das portas, à direita da entrada."
		"sunday_intro":return "Domingo: converse com Felps. Hoje o depósito não abre."
		"sunday_investigation":
			if not flag("module_found"):return "Deryk: examine a porta antiga e recupere o módulo do DVR na área de manutenção."
			if not flag("module_delivered"):return "Deryk: leve o módulo até o balcão. Felps recupera a gravação com C no caixa."
			return "Felps: use C no caixa, recupere e analise a gravação antiga."
		"sunday_prepare":return "Proteja a gravação e avise ajuda no caixa [C]. Deryk: confira o quadro dentro do estoque; Felps precisa ficar no posto."
		"sunday_escape":
			if not flag("generator_running"):return "Deryk: ligue o gerador no pátio. Felps: aguarde a energia para liberar a porta do estoque. F lanterna; H acompanhar/aguardar."
			if not flag("stock_released"):return "Gerador: selecione ESTOQUE. Felps: use C no terminal para destravar, ou o comando junto à porta do estoque."
			if not flag("front_open"):return "Abra a saída pelo comando manual na frente do salão. H chama o companheiro; agache e use E nas coberturas."
			return "Fuja pela calçada à direita. H chama o companheiro. E no ponto de encontro permite sair juntos ou confirmar saída sozinho."
		"campaign_complete":return "Campanha concluída. Confira o epílogo."
	return ""
func advance_to_saturday() -> void:
	start_day(1,"saturday_intro")
func advance_to_sunday() -> void:
	start_day(2,"sunday_intro")
func start_day(night: int,phase: String) -> void:
	var notes: Array=campaign.get("experience",default_experience()).get("notes",[]).duplicate(true)
	campaign.experience=default_experience();campaign.experience.notes=notes
	campaign.night=night;campaign.phase=phase;campaign.flags={};campaign.records=[]
	stage=0;stocked.clear();organized=false;customers_served=0;warning_delivered=false;finale_seen=false;world_seconds=0
	character_states.clear();crate_states.clear();sale_state.clear();customer_state.clear();receipts.clear();sales_cents=0
	carried_id="";active_character="Dery";saved_position=Vector3(3.8,.01,1.8)
	changed.emit()
func clock_minutes() -> int:
	var minutes:=21*60+40+int(world_seconds/8)
	if int(campaign.night)==0 and stage>=5:minutes=maxi(minutes,22*60+35)
	if campaign.phase in ["restored","closing","complete"]:minutes=maxi(minutes,23*60+40)
	return mini(minutes,23*60+59)
func clock_text() -> String:
	var minutes:=clock_minutes()
	return "%02d:%02d"%[minutes/60,minutes%60]
const OBJECTIVES = ["Converse com Felps no caixa.", "Reposição: pegue R1 e R2 no estoque e leve à geladeira G1, na parede esquerda. 0/2", "Reposição: leve a outra caixa R1/R2 à geladeira G1. 1/2", "Guarde a caixa CASCOS VAZIOS no palete DEVOLUÇÕES, no estoque.", "Volte ao caixa. O expediente continua.", "Escute o cliente no caixa.", "Confira o ruído no estoque.", "Fim da demonstração — o turno ainda não acabou."]
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
	campaign=default_campaign();retry_state.clear()
	changed.emit()
func objective() -> String:
	if campaign.phase!="routine":return campaign_objective()
	return OBJECTIVES[clampi(stage, 0, OBJECTIVES.size()-1)]
func greet() -> bool:
	if stage != 0 or int(campaign.night)!=0: return false
	stage = (4 if organized else 3) if StockTasks.required_count()==2 else 2 if StockTasks.required_count()==1 else 1
	changed.emit()
	event_triggered.emit("greeted")
	return true
func deliver(id: String) -> bool:
	if int(campaign.night)!=0 or campaign.phase not in ["routine","restored"] or id in stocked or not StockTasks.JOBS.has(id):return false
	stocked.append(id)
	if stage in [1,2]:stage=(4 if organized else 3) if StockTasks.required_count()==2 else 2 if StockTasks.required_count()==1 else 1
	changed.emit();event_triggered.emit("stocked");return true
func organize() -> bool:
	if int(campaign.night)!=0 or campaign.phase not in ["routine","restored"] or organized or carried_id!="loose":return false
	organized=true
	if stage==3:stage=4
	changed.emit();event_triggered.emit("organized");return true
func serve_customer() -> void:
	customers_served += 1
	changed.emit()
func record_sale(receipt: Dictionary) -> bool:
	for previous in receipts:
		if int(previous.id)==int(receipt.id):return false
	receipts.append(receipt.duplicate(true));sales_cents+=int(receipt.total)
	serve_customer();return true
func can_warn() -> bool:
	return int(campaign.night)==0 and stage == 4 and customers_served >= 2 and not warning_delivered
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
func snapshot_data() -> Dictionary:
	return {"version":5,"stage":stage,"stocked":stocked.duplicate(),"organized":organized,"customers":customers_served,"warning":warning_delivered,"finale":finale_seen,"seconds":world_seconds,"position":[saved_position.x,saved_position.y,saved_position.z],"carried":carried_id,"active_character":active_character,"characters":character_states.duplicate(true),"crates":crate_states.duplicate(true),"sale":sale_state.duplicate(true),"customer_state":customer_state.duplicate(true),"next_sale_id":next_sale_id,"sales_cents":sales_cents,"receipts":receipts.duplicate(true),"familiar_visits":familiar_visits.duplicate(true),"campaign":campaign.duplicate(true)}
func write_save(data: Dictionary) -> Error:
	var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f==null:return FileAccess.get_open_error()
	var complete:=data.duplicate(true);complete.retry=retry_state
	f.store_string(JSON.stringify(complete));return OK
func save_shift(position_value: Vector3) -> Error:
	saving.emit();saved_position=position_value
	if character_states.has(active_character):character_states[active_character].position=[position_value.x,position_value.y,position_value.z]
	return write_save(snapshot_data())
func checkpoint() -> void:
	saving.emit();retry_state=snapshot_data()
	write_save(retry_state)
func save_retry() -> void:
	if not retry_state.is_empty():write_save(retry_state)
func load_shift() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):return false
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or int(data.get("version",0)) not in [1,2,3,4,5]:return false
	if not data.get("position") is Array or data.position.size()!=3:return false
	var old_presentation: bool=not data.get("campaign") is Dictionary or not data.campaign.has("experience")
	retry_state=data.get("retry",{}).duplicate(true) if data.get("retry",{}) is Dictionary else {}
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
	if int(data.version)>=4 and data.get("campaign") is Dictionary:
		for key in campaign:campaign[key]=data.campaign.get(key,campaign[key])
		campaign.night=clampi(int(campaign.night),0,2)
		# JSON parses numbers as floats; Array.has distinguishes int/float values.
		var completed: Array[int]=[]
		if campaign.completed_nights is Array:
			for value in campaign.completed_nights:
				if value is float or value is int:
					var night:=int(value)
					if night>=0 and night<=2 and night not in completed:completed.append(night)
		campaign.completed_nights=completed
		if not campaign.friday_scares is Dictionary:campaign.friday_scares=default_friday_scares()
		for key in default_friday_scares():
			if not campaign.friday_scares.has(key):campaign.friday_scares[key]=default_friday_scares()[key]
		for key in ["events","prank","intruder"]:
			if not campaign.friday_scares[key] is Dictionary:campaign.friday_scares[key]={}
		if not campaign.friday_story is Dictionary:campaign.friday_story=default_friday_story()
		for key in ["events","observations"]:
			if not campaign.friday_story.get(key) is Dictionary:campaign.friday_story[key]={}
		campaign.friday_story.recap=str(campaign.friday_story.get("recap",""))
		if not campaign.experience is Dictionary:campaign.experience=default_experience()
		for key in default_experience():
			if not campaign.experience.has(key):campaign.experience[key]=default_experience()[key]
		if not campaign.experience.events is Dictionary:campaign.experience.events={}
		if not campaign.experience.event_times is Dictionary:campaign.experience.event_times={}
		if not campaign.experience.notes is Array:campaign.experience.notes=[]
		if not campaign.experience.observer is Dictionary:campaign.experience.observer={}
		if int(campaign.night)==1 and campaign.phase in ["saturday_preview","saturday_preview_done"]:
			campaign.phase="saturday_intro";stage=0
		if int(campaign.night)==2 and campaign.phase=="sunday_preview":campaign.phase="sunday_intro";stage=0
	elif stage>=6:
		stage=6;finale_seen=false;campaign.phase="outage"
	# Adopt the new default once for pre-0.28 checkpoints. Later saves retain
	# the camera distance each protagonist chose with the mouse wheel.
	if old_presentation:
		for identity in character_states:
			if character_states[identity] is Dictionary:character_states[identity].camera_distance=0.0
	changed.emit()
	return true
func read_position(value: Variant,fallback: Vector3) -> Vector3:
	if not value is Array or value.size()!=3:return fallback
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)):return fallback
	return Vector3(float(value[0]),float(value[1]),float(value[2]))
