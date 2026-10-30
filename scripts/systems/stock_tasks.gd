class_name StockTasks
extends RefCounted
## Stable crate identities keep earlier saves compatible. R1/R2 share the G1 cabinet.
const REQUIRED: Array[String]=["stock_1","stock_2"]
const JOBS: Dictionary={
	"stock_1":{"code":"R1","product":"Retornáveis 600 ml","destination":"G1 • geladeira da esquerda","target":"G1","required":true},
	"stock_2":{"code":"R2","product":"Retornáveis 600 ml","destination":"G1 • geladeira da esquerda","target":"G1","required":true},
	"stock_shelf":{"code":"R3","product":"Salgadinhos","destination":"P1 • prateleira da entrada","target":"P1","required":false}}
static func required_count() -> int:
	var count:=0
	for id in REQUIRED:
		if id in Session.stocked:count+=1
	return count
static func crate_name(id: String) -> String:
	if JOBS.has(id):return str(JOBS[id].code)+" • "+str(JOBS[id].product)+" • REPOSIÇÃO"
	if id.begins_with("order_"):return "VENDA #%03d • caixa fechada de retornáveis"%int(id.trim_prefix("order_"))
	if id=="loose":return "CASCOS VAZIOS • DEVOLUÇÕES"
	return "Caixa"
static func destination(id: String) -> String:
	if JOBS.has(id):return str(JOBS[id].destination)
	if id.begins_with("order_"):return "balcão • área ENTREGA DE PEDIDOS"
	return "palete DEVOLUÇÕES" if id=="loose" else ""
static func pending() -> String:
	for id in REQUIRED:
		if id not in Session.stocked:return id
	return ""
