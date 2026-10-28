class_name Interaction
extends Node3D
@export_enum("crate","fridge","door","pallet","talk","note","switch") var kind := "crate"
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
			if player.carried!=null:return "Mãos ocupadas • Q para soltar"
			return "Pegar caixa" if global_position.distance_to(player.global_position)<=.95 else "Aproxime-se para pegar a caixa"
		"fridge":
			if player.carried != null and Session.stage in [1,2] and Session.carried_id.begins_with("stock_"):
				return "Colocar bebidas" if open else "Abrir geladeira"
			return "Fechar geladeira" if open else "Abrir geladeira"
		"door": return "Fechar porta" if open else "Abrir porta do estoque"
		"pallet": return "Guardar caixa no palete" if Session.carried_id == "loose" else "Palete • organizar após a reposição"
		"talk": return "Conversar com Felps"
		"note": return "Examinar a porta antiga" if Session.stage != 6 else "Verificar o ruído"
		"switch": return "Acender luz" if not open else "Apagar luz"
	return "Interagir"
func activate(player: Node3D) -> bool:
	if busy or player.motion.action_active: return false
	match kind:
		"crate":
			if player.carried != null or global_position.distance_to(player.global_position)>.95:return false
			player.pick_up(get_parent(),identity)
			return true
		"fridge":
			if not open or player.carried == null:
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
		"note":
			if Session.stage == 6:
				Session.end_slice()
			else: Dialogue.play("old_door",[["Dery","Esse depósito velho tá trancado faz tempo. Melhor deixar quieto."]])
			return true
	return false
