class_name Interaction
extends Node3D
@export_enum("crate","fridge","door","pallet","talk","note","switch","familiar","checkout","campaign","investigation","sunday","shelf") var kind := "crate"
@export var identity := ""
var open := false
var busy := false
func _ready() -> void:
	add_to_group("interactables")
	for body in get_parent().find_children("*","CollisionObject3D",true,false):
		body.set_meta("interaction", self)
func prompt(player: Node3D) -> String:
	if int(Session.campaign.night)==2:
		var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
		if world!=null and world.sunday!=null:
			if kind=="sunday":return world.sunday.prompt(identity,player)
			if kind=="checkout":return world.sunday.prompt("counter",player)
			if kind=="note":return world.sunday.prompt("old",player)
			if kind=="campaign":return world.sunday.prompt("shutter" if identity=="exit" else identity,player)
			if kind=="door" and identity!="service" and Session.campaign.phase=="sunday_escape" and not Session.flag("stock_released"):return "Estoque travado • Felps precisa liberar pelo salão"
	match kind:
		"crate":
			if player.identity!="Dery":return "[Tab] Deryk cuida das caixas e da reposição"
			if player.carried!=null:return "Mãos ocupadas • Q para apoiar a caixa"
			return ("Pegar "+StockTasks.crate_name(identity)) if global_position.distance_to(player.global_position)<=.95 else "Aproxime-se: "+StockTasks.crate_name(identity)
		"fridge","shelf":
			var target: String="G1" if kind=="fridge" and get_parent().needs_restock else "P1" if kind=="shelf" else ""
			if player.carried!=null:
				if StockTasks.JOBS.has(player.carried_id) and StockTasks.JOBS[player.carried_id].target==target:
					return "Repor "+target+" • "+str(StockTasks.JOBS[player.carried_id].code) if kind=="shelf" or get_parent().opened else "Abrir G1 para repor • use E novamente após abrir"
				return "Esta caixa vai para "+StockTasks.destination(player.carried_id)
			if kind=="shelf":return "P1 abastecida" if "stock_shelf" in Session.stocked else "Faltam salgadinhos na P1 • pegue R3 no estoque"
			if target=="G1" and StockTasks.required_count()<2:return ("Fechar G1" if get_parent().opened else "Abrir G1")+" • faltam retornáveis: R1 / R2 no estoque"
			return ("Fechar geladeira" if get_parent().opened else "Abrir geladeira")+" • abastecida"
		"door":
			if identity=="service" and int(Session.campaign.night)==1:return "Pátio trancado • nenhuma entrega autorizada"
			return "Fechar porta" if open else "Abrir porta do pátio" if identity=="service" else "Abrir porta do estoque"
		"pallet": return "Guardar CASCOS VAZIOS no palete" if player.carried_id=="loose" else "DEVOLUÇÕES • somente cascos vazios"
		"talk": return "Conversar com "+("Deryk" if identity=="Dery" else "Felps")
		"checkout":
			var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
			if world!=null and world.friday!=null and world.friday.phase() in ["outage","closing"]:return world.friday.prompt("counter",player)
			if world!=null and world.can_supply_order(player):return "Deixar a caixa do pedido no balcão"
			if int(Session.campaign.night)==1 and world!=null and not world.can_checkout(player):return "Câmeras e caderno [C]" if Session.campaign.phase!="saturday_intro" else "Conferir a noite com Deryk"
			return "Continuar atendimento" if world!=null and world.can_checkout(player) and world.customer.service_started else ("Atender cliente" if world!=null and world.can_checkout(player) else "Caixa • aguarde um cliente")
		"familiar": return "Conversar com "+identity
		"note": return "Conferir estoque e porta antiga" if Session.campaign.phase=="closing" else "Examinar a porta antiga"
		"investigation":return "Examinar caixas deslocadas • Deryk"
		"campaign":
			var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
			if identity=="exit" and Session.campaign.phase=="saturday_decisions":return "Conferir saída e combinar ponto de encontro"
			return world.friday.prompt(identity,player) if world!=null and world.friday!=null else "Interagir"
		"switch": return "Acender luz" if not open else "Apagar luz"
	return "Interagir"
func available_for(player: DepotPlayer) -> bool:
	if kind=="checkout":return int(Session.campaign.night)==2 or player.identity=="Felps" or player.carried_id.begins_with("order_")
	if kind=="talk":return get_parent()!=player
	if kind=="familiar":return not get_parent().leaving
	return true
func activate(player: Node3D) -> bool:
	if busy or player.motion.action_active: return false
	var chapter:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
	if chapter!=null and (chapter.surveillance_open or chapter.sunday!=null and chapter.sunday.desk_open):return false
	if int(Session.campaign.night)==2 and chapter!=null and chapter.sunday!=null:
		if kind=="talk":
			if global_position.distance_to(player.global_position)>2.65:return false
			return chapter.sunday.introduce(player)
		if kind in ["sunday","checkout","note","campaign"]:
			if global_position.distance_to(player.global_position)>2.65:return false
			var action: String=identity if kind=="sunday" or kind=="campaign" else "counter" if kind=="checkout" else "old"
			return chapter.sunday.activate("shutter" if action=="exit" else action,player)
		if kind=="door":
			var id: String="service" if identity=="service" else "stock"
			if chapter.sunday.phase()=="sunday_escape" and id=="stock" and not Session.flag("stock_released"):return false
			if global_position.distance_to(player.position)>2.65:return false
			chapter.sunday.change_door(id,not chapter.sunday.door_open(id));chapter.sunday.save();return true
	if int(Session.campaign.night)==1 and chapter!=null and chapter.saturday!=null:
		if kind=="campaign" and identity=="exit" and Session.campaign.phase=="saturday_decisions":return chapter.saturday.prepare_exit(player)
		if kind=="talk" or kind=="checkout" and Session.campaign.phase=="saturday_intro":
			if global_position.distance_to(player.global_position)>2.65:return false
			return chapter.saturday.introduce(player)
		if kind=="familiar":
			if get_parent().leaving or global_position.distance_to(player.global_position)>2.65:return false
			return chapter.saturday.familiar(identity,player)
		if kind=="investigation":return chapter.saturday.inspect("boxes",player)
		if kind=="note" and Session.campaign.phase!="closing":return chapter.saturday.inspect("door",player)
		if kind=="door" and identity=="service":
			chapter.notice.emit("Pátio trancado. Nenhuma entrega autorizada hoje; a dupla vai sair pela frente.");return false
		if kind=="checkout" and Session.campaign.phase!="closing" and not chapter.can_checkout(player):return chapter.try_surveillance()
	if kind in ["campaign","checkout","note","talk"]:
		var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
		if world!=null and world.friday!=null:
			if kind=="campaign":
				if global_position.distance_to(player.global_position)>2.65:return false
				return world.friday.activate(identity,player)
			if kind=="checkout" and world.friday.phase() in ["outage","closing"]:return world.friday.activate("counter",player)
			if kind=="note" and world.friday.phase()=="closing":return world.friday.activate("stock",player)

	match kind:
		"crate":
			if player.identity!="Dery":return false
			if player.carried != null:return reject("Apoie a caixa atual com Q antes de pegar outra.")
			if global_position.distance_to(player.global_position)>.95:return reject("Aproxime-se da caixa para pegá-la.")
			player.pick_up(get_parent(),identity)
			return true
		"fridge","shelf":
			if global_position.distance_to(player.global_position)>1.8:return reject("Aproxime-se da frente da geladeira/prateleira para repor.")
			if player.carried==null:
				if kind=="fridge":get_parent().toggle();open=get_parent().opened;return true
				return reject("Faltam salgadinhos na P1. Pegue a caixa R3 no estoque." if "stock_shelf" not in Session.stocked else "P1 já está abastecida.")
			if player.identity!="Dery":return reject("[Tab] Deryk faz a reposição.")
			var id: String=player.carried_id
			var target: String="G1" if kind=="fridge" and get_parent().needs_restock else "P1" if kind=="shelf" else ""
			if not StockTasks.JOBS.has(id) or StockTasks.JOBS[id].target!=target:
				return reject("Esta caixa não repõe aqui. Destino: "+StockTasks.destination(id)+".")
			if kind=="fridge" and not get_parent().opened:get_parent().toggle();open=get_parent().opened;return true
			if not Session.deliver(id):return reject("Esta reposição já foi feita ou está suspensa durante o fechamento/apagão.")
			var at: Vector3=get_parent().to_global(Vector3(.12,.88,.10)) if kind=="fridge" else get_parent().to_global(Vector3(-.68,.88,0))
			var destination: Node3D=get_parent()
			player.consume_carried(at,func():
				if target=="G1":destination.replenish(StockTasks.REQUIRED.find(id))
				else:destination.replenish())
			reject("Reposição concluída: "+target+" • "+str(StockTasks.JOBS[id].product)+".");return true
		"door":
			open = not open
			busy = true
			var tween := create_tween()
			tween.tween_property(get_parent(),"rotation:y",(1.45 if identity=="service" else -1.45) if open else 0.0,.5)
			tween.finished.connect(func(): busy=false)
			return true
		"pallet":
			if player.identity!="Dery" or player.carried_id!="loose" or player.carried==null:return reject("O palete recebe a caixa CASCOS VAZIOS; as caixas R1/R2/R3 e VENDA têm outros destinos.")
			if global_position.distance_to(player.position)>1.8:return reject("Aproxime-se do palete DEVOLUÇÕES.")
			if Session.organize():
				player.place_carried(get_parent().global_position+Vector3(0,.23,0))
				return true
		"talk":
			if Dialogue.active or global_position.distance_to(player.global_position)>2.65:return false
			if Session.greet():
				Dialogue.play("greeting",[["Felps","Ô Dery. Dá uma completada na água pra mim? Separei duas caixas verdes lá atrás." if StockTasks.required_count()<2 else "A água já tá no jeito. Valeu, Dery."],["Dery","Pode deixar. Hoje a gente fecha no horário, hein."],["Felps","Se depender de mim... As devoluções tão no caminho. Anotei o resto no caderno."]])
			else:
				var shift:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
				if shift!=null:shift.story.try_remark(player)
			return true
		"checkout":
			var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
			return world!=null and (world.supply_order(player) if player.identity=="Dery" else world.try_checkout(player))
		"familiar":
			if Dialogue.active:return false
			var lines: Array
			var visits:=int(Session.familiar_visits.get(identity,0));Session.familiar_visits[identity]=visits+1
			var shift:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
			if int(Session.campaign.night)==0 and shift!=null:
				Dialogue.play("familiar_"+identity,shift.story.familiar_lines(identity,player,visits));Session.save_shift(player.global_position);return true
			if identity=="Bryan":
				if player.identity=="Felps":lines=[["Bryan","Ô, Felps! O Deryk tá aí também?"],["Felps","Tá cuidando do estoque. Fica aqui perto, Bryan."],["Dery","Já volto aí, moleque!"]]
				elif visits>0:lines=[["Bryan","Vocês vão trabalhar até tarde hoje?"],["Dery","Até meia-noite. Tá uma correria, viu?"],["Felps","Depois a gente conversa com calma, Bryan."]]
				else:lines=[["Bryan","Oi, Dery! O Felps tá trabalhando também?"],["Dery","Tá ali no caixa. Bom te ver, Bryan."],["Felps","Ô, Bryan! Chega mais. Fica aqui perto da gente."]]
			else:
				if player.identity=="Felps":lines=[["Zirico","Felps, cê não larga esse caixa hoje, hein?"],["Felps","Alguém tem que trabalhar, Zirico! O Deryk tá lá atrás."],["Zirico","Vocês dois se ajudam... isso é bom."]]
				elif visits>0:lines=[["Zirico","Passei pra dar mais um boa-noite, meus amigos."],["Dery","Boa-noite, Zirico. Vai com calma."],["Felps","Se cuida no caminho, viu?"]]
				else:lines=[["Zirico","Boa noite, meus amigos... hoje o turno tá comprido, hein?"],["Dery","Boa noite, Zirico. Vai com calma por aí."],["Felps","Bom te ver, Zirico. Se cuida, viu?"]]
			Dialogue.play("familiar_"+identity,lines)
			return true
		"note":
			Dialogue.play("old_door",[["Dery","Esse depósito velho tá trancado faz tempo. Melhor deixar quieto."]])
			return true
	return false

func reject(text: String) -> bool:
	var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
	if world!=null:world.notice.emit(text)
	return false
