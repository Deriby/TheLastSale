class_name ShopSale
extends RefCounted
## Prices and payments use integer centavos, including saved transactions.
enum Phase {REGISTER, PAYMENT, CHANGE, READY, COMPLETE}
const CATALOG: Dictionary={
	"water":{"name":"Água mineral 500 ml","price":350},
	"soda_1":{"name":"Refrigerante 2 L","price":750},
	"beer_0":{"name":"Retornável 600 ml","price":850},
	"snack_0":{"name":"Salgadinho","price":450},
	"case_returnable":{"name":"Caixa de retornáveis • 12 un","price":7200}}
const COINS: Array[int]=[2000,1000,500,200,100,50,25,10,5]
var id:=1
var order: Dictionary={}
var registered: Dictionary={}
var phase: Phase=Phase.REGISTER
var tendered:=0
var change_coins: Array[int]=[]
var bulk_supplied:=false
var message:="Confira o pedido e registre os produtos."
var errors:=0
static func money(cents: int) -> String:
	return "R$ %d,%02d"%[int(cents/100.0),cents%100]
static func create(number: int,warning := false) -> ShopSale:
	var sale:=ShopSale.new();sale.id=number
	var orders: Array[Dictionary]=[{"water":2,"snack_0":1},{"case_returnable":1},{"soda_1":2,"beer_0":2},{"beer_0":4,"snack_0":2},{"water":1,"soda_1":1,"snack_0":2}]
	sale.order={"water":1} if warning else orders[posmod(number-1,orders.size())].duplicate()
	for value in [500,1000,2000,5000,10000,20000]:
		if value>=sale.total():sale.tendered=value;break
	return sale
func total() -> int:return sum_items(order)
static func sum_items(items: Dictionary) -> int:
	var amount:=0
	for sku in items:
		if CATALOG.has(sku):amount+=int(CATALOG[sku].price)*int(items[sku])
	return amount
func needs_bulk() -> bool:return order.has("case_returnable")
func supply_id() -> String:return "order_"+str(id)
func change_due() -> int:return tendered-total()
func selected_change() -> int:
	var amount:=0
	for coin in change_coins:amount+=coin
	return amount
func describe() -> String:
	var lines: PackedStringArray=[]
	for sku in order:lines.append("%d × %s"%[int(order[sku]),str(CATALOG[sku].name)])
	return "\n".join(lines)
func reject(text: String) -> bool:
	errors+=1;message=text;return false
func register(sku: String,quantity := 1) -> bool:
	if phase!=Phase.REGISTER or not CATALOG.has(sku) or quantity not in [-1,1]:return false
	var amount:=clampi(int(registered.get(sku,0))+quantity,0,12)
	if amount==0:registered.erase(sku)
	else:registered[sku]=amount
	message="Produto registrado." if quantity>0 else "Registro corrigido."
	return true
func confirm_items() -> bool:
	if phase!=Phase.REGISTER:return false
	if registered!=order:return reject("Cliente: confere os produtos e as quantidades, por favor.")
	if needs_bulk() and not bulk_supplied:return reject("A caixa fechada ainda precisa chegar do estoque com Deryk.")
	phase=Phase.PAYMENT;message="Compra conferida. Receba o dinheiro do cliente.";return true
func receive_cash() -> bool:
	if phase!=Phase.PAYMENT:return false
	phase=Phase.CHANGE;message="Separe o troco na gaveta.";return true
func add_coin(cents: int) -> bool:
	if phase!=Phase.CHANGE or cents not in COINS or change_coins.size()>=80:return false
	change_coins.append(cents);message="Troco separado: "+money(selected_change());return true
func undo_coin() -> bool:
	if phase!=Phase.CHANGE or change_coins.is_empty():return false
	change_coins.pop_back();message="Última cédula/moeda retirada.";return true
func clear_change() -> bool:
	if phase!=Phase.CHANGE:return false
	change_coins.clear();message="Troco separado: "+money(0);return true
func confirm_change() -> bool:
	if phase!=Phase.CHANGE:return false
	if selected_change()!=change_due():return reject("Cliente: acho que o troco não bate. Pode conferir?")
	phase=Phase.READY;message="Troco correto. Entregue a compra ao cliente.";return true
func receipt() -> Dictionary:
	return {"id":id,"items":order.duplicate(),"total":total(),"cash":tendered,"change":selected_change()}
func snapshot() -> Dictionary:
	return {"id":id,"order":order.duplicate(),"registered":registered.duplicate(),"phase":int(phase),"tendered":tendered,"change_coins":change_coins.duplicate(),"bulk_supplied":bulk_supplied,"errors":errors}
static func restore(data: Dictionary) -> ShopSale:
	var sale:=ShopSale.new();sale.id=maxi(1,int(data.get("id",1)))
	for field in ["order","registered"]:
		var items: Variant=data.get(field,{})
		if items is Dictionary:
			for sku in items:
				if CATALOG.has(sku) and int(items[sku])>0:sale.get(field)[sku]=clampi(int(items[sku]),1,12)
	if sale.order.is_empty():return null
	sale.phase=clampi(int(data.get("phase",0)),0,4) as Phase
	sale.tendered=maxi(sale.total(),int(data.get("tendered",sale.total())))
	var coins: Variant=data.get("change_coins",[])
	if coins is Array:
		for coin in coins:
			if int(coin) in COINS and sale.change_coins.size()<80:sale.change_coins.append(int(coin))
	sale.bulk_supplied=bool(data.get("bulk_supplied",false));sale.errors=maxi(0,int(data.get("errors",0)))
	sale.message="Pedido retomado. Continue o atendimento."
	return sale
