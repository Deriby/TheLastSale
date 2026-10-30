class_name Interaction
extends Node3D
@export_enum("crate","fridge","door","pallet","talk","note","switch","familiar","checkout","campaign","investigation","sunday") var kind := "crate"
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
			if player.carried!=null:return "Mãos ocupadas • Q para soltar"
			return ("Pegar caixa do pedido" if identity.begins_with("order_") else "Pegar caixa") if global_position.distance_to(player.global_position)<=.95 else "Aproxime-se para pegar a caixa"
		"fridge":
			if get_parent().needs_restock and player.carried != null and Session.stage in [1,2] and Session.carried_id.begins_with("stock_"):
				return "Colocar bebidas" if open else "Abrir geladeira"
			return "Fechar geladeira" if open else "Abrir geladeira"
		"door":
			if identity=="service" and int(Session.campaign.night)==1:return "Pátio trancado • nenhuma entrega autorizada"
			return "Fechar porta" if open else "Abrir porta do pátio" if identity=="service" else "Abrir porta do estoque"
		"pallet": return "Guardar caixa no palete" if Session.carried_id == "loose" else "Palete • organizar após a reposição"
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
			if player.carried != null or global_position.distance_to(player.global_position)>.95:return false
			player.pick_up(get_parent(),identity)
			return true
		"fridge":
			if not get_parent().needs_restock or not open or player.carried == null:
				get_parent().toggle();open=get_parent().opened
				return true
			if Session.deliver(Session.carried_id):
				player.consume_carried(get_parent().to_global(Vector3(.12,.88,.10)),get_parent().replenish)
				return true
		"door":
			open = not open
			busy = true
			var tween := create_tween()
			tween.tween_property(get_parent(),"rotation:y",(1.45 if identity=="service" else -1.45) if open else 0.0,.5)
			tween.finished.connect(func(): busy=false)
			return true
		"pallet":
			if Session.organize():
				player.place_carried(get_parent().global_position+Vector3(0,.23,0))
				return true
		"talk":
			if Dialogue.active: return false
			if Session.greet():
				Dialogue.play("greeting",[["Felps","Ô Dery, beleza? Tem duas caixas de retornável lá no estoque. Repõe a geladeira pra mim?"],["Dery","Já vou. Depois eu ajeito aquela caixa no caminho."],["Felps","Valeu! E deixa o corredor livre, hoje tá passando gente ainda."]])
			else: Dialogue.play("smalltalk",[["Felps","Sextou, hein... pra quem não tá trabalhando."],["Dery","Nem me fala. Ainda falta chão até meia-noite."]])
			return true
		"checkout":
			var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
			return world!=null and (world.supply_order(player) if player.identity=="Dery" else world.try_checkout(player))
		"familiar":
			if Dialogue.active:return false
			var lines: Array
			var visits:=int(Session.familiar_visits.get(identity,0));Session.familiar_visits[identity]=visits+1
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
