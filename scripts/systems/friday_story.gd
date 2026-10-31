class_name FridayStory
extends Node
## Optional Friday memories carry into Saturday without becoming required clues.
var world: ShiftWorld
const OBSERVATIONS: Array[String]=["return_intruder","stock_handle","observer_seen","empty_chime","stock_steps","car_noticed","customer_back_door"]
func state() -> Dictionary:return Session.campaign.friday_story
func done(id: String) -> bool:return bool(state().events.get(id,false))
func save_event(id: String) -> void:
	state().events[id]=true
	Session.changed.emit()
	if world.active:Session.save_shift(world.player.global_position)
func _ready() -> void:
	for note in Session.campaign.experience.notes:
		if not note is Dictionary or int(note.get("night",-1))!=0:continue
		var id:=str(note.get("id","")).get_slice(":",1)
		if id in OBSERVATIONS:state().observations[id]=true
	if int(Session.campaign.night)==0:
		for id in OBSERVATIONS:
			if world.everyday.done(id):remember(id)
	Dialogue.spoken.connect(on_spoken)
	Dialogue.completed.connect(on_completed)
func begin_arrival() -> bool:
	if int(Session.campaign.night)!=0 or Session.stage!=0 or done("arrival") or Dialogue.active:return false
	save_event("arrival")
	return Dialogue.play("friday_arrival",[["Dery","A mãe perguntou se a gente passa lá depois."],["Felps","Os dois? Então hoje tu me ajuda a fechar cedo."],["Dery","Eu? Quem fica conversando com todo cliente é tu."]])
func remember(id: String) -> void:
	if int(Session.campaign.night)==0 and id in OBSERVATIONS:state().observations[id]=true
func noticed(id: String) -> bool:
	return bool(state().observations.get(id,false)) or int(Session.campaign.night)==0 and world.everyday.done(id)
func try_remark(actor: DepotPlayer) -> bool:
	if int(Session.campaign.night)!=0 or Dialogue.active or world.cashier_open or world.surveillance_open or Session.campaign.phase!="routine":return false
	for id in OBSERVATIONS:
		if not noticed(id) or done("remark_"+id):continue
		var lines: Array
		match id:
			"return_intruder":lines=[["Dery","Eu vi ele passando. Não era sombra da lanterna."],["Felps","Eu acredito em ti. Fica aqui perto de mim."],["Dery","Na hora de fechar a gente sai junto."]]
			"stock_handle":lines=[["Dery","A maçaneta da porta velha mexeu, Felps."],["Felps","Tu não encostou nela?"],["Dery","Eu tava do outro lado do estoque."]]
			"observer_seen":lines=[["Dery","Tem um cara do outro lado olhando pra cá faz tempo."],["Felps","Ele entrou?"],["Dery","Não. É isso que tá me incomodando."]]
			"empty_chime":lines=[["Dery","Na hora do sino, tu viu alguém entrando?"],["Felps","Olhei na mesma hora. Só vi a porta."],["Dery","Se tocar de novo, me chama antes de sair do caixa."]]
			"stock_steps":lines=[["Dery","Tu passou lá atrás agora?"],["Felps","Não saí daqui. Por quê?"],["Dery","Ouvi passo. Vou deixar a porta do estoque na minha vista."]]
			"car_noticed":lines=[["Dery","Esse carro tá ligado aí há um tempão."],["Felps","Achei que era gente esperando pedido."],["Dery","Não veio buscar nada."]]
			_:lines=[["Felps","O cliente quis saber da porta dos fundos."],["Dery","Pra quê?"],["Felps","Foi o que eu perguntei. Ele desconversou."]]
		save_event("remark_"+id)
		return Dialogue.play("friday_remark_"+id,lines)
	var work_done:=Session.organized and StockTasks.required_count()==2
	return Dialogue.play("smalltalk",[[actor.identity,"Hoje a mãe vai esperar acordada de novo."],["Felps" if actor.identity=="Dery" else "Dery","Já terminei minha parte. Falta tu." if work_done else "Então anda com essas caixas, que eu seguro a frente."],[actor.identity,"Tu usa essa desde que a gente era pequeno."]])
func order_lines(who: Customer,request: String) -> Array:
	var lines: Array=[]
	var label: String="Cliente"
	match who.identity:
		"Garota1":
			label="Cliente";lines=[[label,"Se eu ouvir mais uma buzina hoje, largo o carro e vou a pé."],["Felps","Sexta na avenida. Eu escuto daqui."]]
		"Garota2":
			label="Cliente";lines=[[label,"O motorista cancelou a corrida na esquina. Agora é esperar outro."],["Felps","Pode esperar na frente, debaixo da luz."]]
		"Velha1":
			label="Senhora";lines=[[label,"Sua mãe ainda deixa comida pros dois quando chegam?"],["Felps","Deixa. E briga se a gente esquenta errado."]]
		"ClienteTrabalho":
			label="Cliente de uniforme";lines=[[label,"Se o caminhão atrasar amanhã, eu ligo antes. Não fica esperando no portão."],["Felps","Combinado. Entrega a essa hora eu nem abro."]]
		"ClienteBone":label="Cliente de boné"
	lines.append([label,request])
	if who.identity=="ClienteBone" and not done("door_question"):
		lines.append([label,"Quando chega entrega, vocês deixam a porta dos fundos aberta?"])
		lines.append(["Felps","Por que você quer saber?"] if noticed("observer_seen") or noticed("empty_chime") else ["Felps","Entrega é de dia. Por quê?"])
		lines.append([label,"Só perguntei."])
	lines.append(["Felps","O Deryk pega a caixa lá atrás pra você." if world.sale.needs_bulk() and not world.sale.bulk_supplied else "Só um instante que eu registro."])
	return lines
func warning_lines() -> Array:
	var lines: Array=JSON.parse_string(FileAccess.get_file_as_string("res://resources/warning.json"))
	if noticed("observer_seen"):
		lines.insert(5,["Dery","Eu vi um cara do outro lado da rua olhando pra cá."])
		lines.insert(6,["Cliente","Eu vi foi nos fundos. Não sei se é o mesmo."])
	elif noticed("empty_chime"):
		lines.insert(5,["Felps","O sino tocou antes, mas não tinha ninguém na entrada."])
	return lines
func familiar_lines(identity: String,actor: DepotPlayer,visits: int) -> Array:
	if identity=="Bryan":
		if world.scary!=null and world.scary.done("bryan_prank") and not world.scary.done("bryan_left"):return [["Bryan","Hahaha! Cê pulou igual quando a mãe te chama bravo!"],[actor.identity,"Quer me matar do coração, menino?"],["Felps","Por hoje deu de brincadeira. Vai pra casa antes que escureça mais."]]
		if visits==0:return [["Bryan","Posso apertar um botão do caixa? Um só."],["Felps","Da última vez tu abriu a gaveta três vezes."],["Bryan","Tava testando se funcionava!"],[actor.identity,"Testa ir pra casa antes da tua mãe vir te buscar."]]
		return [["Bryan","Se eu levar uma garrafinha, vocês me dão desconto?"],[actor.identity,"Se tu devolver as que tão na tua mochila, a gente conversa."],["Bryan","Cês lembram de tudo, hein."]]
	if noticed("empty_chime"):return [["Zirico","Quem entrou quando o sino tocou? Eu tava olhando pra porta."],[actor.identity,"Não entrou ninguém, Zirico."],["Zirico","Então não foi só eu que achei esquisito."]]
	return [["Zirico","Essa lâmpada tá balançando ou sou eu?"],[actor.identity,"A lâmpada tá quieta. Quer uma água?"],["Zirico","Quero. Mas sem essa cara de preocupação aí."]]
func begin_closing_hook() -> bool:
	if int(Session.campaign.night)!=0 or done("closing_hook") or Dialogue.active:return false
	var lines: Array=[["Felps","Pera. Escuta."]]
	if noticed("return_intruder"):
		lines=[["Dery","Tranca direito. E não volta aí sozinho."],["Felps","Amanhã a gente confere a câmera. Hoje nós dois vamos pra casa."]]
	elif noticed("observer_seen"):
		lines.append(["Dery","O cara da rua não chegou a entrar, né?"])
		lines.append(["Felps","Não. E agora tá todo mundo aqui fora."])
	elif noticed("empty_chime"):
		lines.append(["Dery","Foi lá dentro de novo. Igual quando o sino tocou."])
		lines.append(["Felps","Amanhã eu confiro a câmera. Hoje a gente vai junto."])
	else:
		lines.append(["Dery","Pareceu passo. Tu conferiu o salão?"])
		lines.append(["Felps","Conferi. Amanhã a gente olha a gravação. Vamos juntos."])
	state().recap="Na calçada, os dois ouviram passos no salão que acabavam de esvaziar. Felps combinou conferir o gravador no sábado."
	if noticed("return_intruder"):state().recap="Uma pessoa atravessou o salão após a volta do gerador e seguiu para os fundos. Os irmãos decidiram conferir as imagens no sábado."
	save_event("closing_hook")
	if not noticed("return_intruder"):world.sound.play_spatial("res://assets/audio/everyday/stock_steps.ogg",Vector3(.7,.15,-1.3),-14,true)
	return Dialogue.play("friday_closing_hook",lines)
func saturday_memory() -> Array:
	var lines: Array=[]
	if done("closing_hook"):lines.append(["Felps","Fiquei pensando naqueles passos depois que a gente saiu."])
	if noticed("return_intruder"):
		lines=[["Felps","Vamos conferir as câmeras antes de entrar nos fundos."],["Dery","Quero saber de onde saiu o cara que eu vi ontem."]]
	elif noticed("observer_seen"):lines.append(["Dery","E no cara do outro lado da rua. Quero ver a hora em que ele chegou."])
	elif noticed("empty_chime"):lines.append(["Dery","Confere também a hora do sino. Eu tava no estoque, lembra?"])
	elif noticed("customer_back_door"):lines.append(["Dery","E se aquele cliente voltar a perguntar dos fundos, me chama."])
	return lines
func on_spoken(who: String,text: String) -> void:
	# Record what was actually heard, rather than a queued line the player might
	# not reach before saving or closing a conversation.
	if int(Session.campaign.night)!=0 or who!="Cliente de boné" or not text.begins_with("Quando chega entrega,"):return
	if done("door_question"):return
	remember("customer_back_door");save_event("door_question")
	world.everyday.record("customer_back_door","O cliente de boné perguntou se a porta dos fundos fica aberta nas entregas.")
func on_completed(id: String) -> void:
	if id=="friday_closing_hook" and world.friday.phase()=="closing" and world.friday.ready_to_leave() and world.friday.both_outside() and not world.friday.finishing:world.friday.finish_friday()
