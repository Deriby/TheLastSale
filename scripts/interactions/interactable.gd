class_name Interaction
extends Node3D
@export_enum("crate","fridge","door","pallet","talk","note","switch","familiar","checkout") var kind := "crate"
@export var identity := ""
var open := false
var busy := false
func _ready() -> void:
	add_to_group("interactables")
	for body in get_parent().find_children("*","CollisionObject3D",true,false):
		body.set_meta("interaction", self)
func prompt(player: Node3D) -> String:
	match kind:
		"crate":
			if player.identity!="Dery":return "[Tab] Deryk cuida das caixas e da reposição"
			if player.carried!=null:return "Mãos ocupadas • Q para soltar"
			return ("Pegar caixa do pedido" if identity.begins_with("order_") else "Pegar caixa") if global_position.distance_to(player.global_position)<=.95 else "Aproxime-se para pegar a caixa"
		"fridge":
			if get_parent().needs_restock and player.carried != null and Session.stage in [1,2] and Session.carried_id.begins_with("stock_"):
				return "Colocar bebidas" if open else "Abrir geladeira"
			return "Fechar geladeira" if open else "Abrir geladeira"
		"door": return "Fechar porta" if open else "Abrir porta do estoque"
		"pallet": return "Guardar caixa no palete" if Session.carried_id == "loose" else "Palete • organizar após a reposição"
		"talk": return "Conversar com "+("Deryk" if identity=="Dery" else "Felps")
		"checkout":
			var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
			if world!=null and world.can_supply_order(player):return "Deixar a caixa do pedido no balcão"
			return "Continuar atendimento" if world!=null and world.can_checkout(player) and world.customer.service_started else ("Atender cliente" if world!=null and world.can_checkout(player) else "Caixa • aguarde um cliente")
		"familiar": return "Conversar com "+identity
		"note": return "Examinar a porta antiga" if Session.stage != 6 else "Verificar o ruído"
		"switch": return "Acender luz" if not open else "Apagar luz"
	return "Interagir"
func available_for(player: DepotPlayer) -> bool:
	if kind=="checkout":return player.identity=="Felps" or player.carried_id.begins_with("order_")
	if kind=="talk":return get_parent()!=player
	return true
func activate(player: Node3D) -> bool:
	if busy or player.motion.action_active: return false
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
			tween.tween_property(get_parent(),"rotation:y",-1.45 if open else 0.0,.5)
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
			if Session.stage == 6:
				Session.end_slice()
			else: Dialogue.play("old_door",[["Dery","Esse depósito velho tá trancado faz tempo. Melhor deixar quieto."]])
			return true
	return false
