extends "res://tests/supply_integration.gd"
func _ready() -> void:process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func ticks(count: int) -> void:
 for frame in count:await get_tree().physics_frame
 await get_tree().process_frame
func aim_sheet() -> void:
 await stand(Vector3(-3.05,.01,-2.12),PI/2)
 var toward: Vector3=world.supplies.shift_sheet.global_position-world.player.camera_rig.global_position
 world.player.camera_rig.pitch=atan2(toward.y,Vector2(toward.x,toward.z).length());await ticks(8)
func wheel(button: MouseButton,count: int) -> void:
 for index in count:
  var event:=InputEventMouseButton.new();event.button_index=button;event.pressed=true;event.position=Vector2(640,360);Input.parse_input_event(event);Input.flush_buffered_events();await ticks(1)
 await ticks(25)
func run() -> void:
 Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.immersive_hud=true;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.active=true;player=world.player;world.spawn_wait=999;world.presence.state().next_at=99999;await ticks(15)
 check(is_instance_valid(world.supplies.shift_sheet) and world.supplies.sheet_interaction.kind=="guidance","sexta tem uma lista física de reposição no balcão")
 var hitbox: StaticBody3D=world.supplies.shift_sheet.find_children("*","StaticBody3D",true,false)[0]
 check(hitbox.collision_layer==4 and hitbox.collision_mask==0,"papel tem apenas alvo de interação, sem bloquear corpos ou navegação")
 check(not world.supplies.sheet_interaction.available_for(player),"nota pequena usa mira direta e não rouba a conversa pelo foco assistido")
 check(not app.interface.supply_marker.visible,"chegada discreta não desenha seta de caminho para o caixa")
 await aim_sheet()
 check(world.player.target==world.supplies.sheet_interaction,"olhar diretamente para a lista encontra o alvo físico")
 var at:=player.position;var yaw: float=player.camera_rig.yaw;var receipts:=Session.receipts.size();var money:=Session.sales_cents
 await key_press(KEY_E)
 check(Dialogue.sequence=="shift_sheet" and JSON.stringify(Dialogue.queue).contains("G1") and JSON.stringify(Dialogue.queue).contains("R1"),"E na lista oferece uma orientação curta com os códigos e o lugar")
 check(Session.stage==0 and Session.stocked.is_empty() and not Session.organized and Session.receipts.size()==receipts and Session.sales_cents==money,"ler a lista não conclui conversa de abertura, trabalho ou venda")
 check(player.position.distance_to(at)<.04 and is_equal_approx(player.camera_rig.yaw,yaw),"consulta não move o corpo nem vira a câmera")
 clear_dialogue();await ticks(30)
 check(not Dialogue.active,"orientação não se repete automaticamente ao continuar olhando")
 await stand(CheckoutFixture.CUSTOMER_POSITION,PI/2)
 check(player.target==world.depot.staff_talk,"balcão continua priorizando Felps ao olhar para ele")
 var spoken: Array[String]=[];Dialogue.spoken.connect(func(_who,value):spoken.append(value));await key_press(KEY_E)
 check(Session.stage==1 and Dialogue.sequence=="greeting" and spoken.any(func(value):return value.contains("G1") and value.contains("estoque")),"conversa de trabalho apresenta destinos e referências do cenário")
 clear_dialogue();await ticks(3)
 check(app.interface.objective.text.contains("R1") and app.interface.objective.modulate.a==0 and not app.interface.supply_marker.visible,"tarefa completa continua disponível sem novo aviso ou seta sobre a reposição")
 world.supplies.refresh()
 check(world.supplies.boards.G1.billboard==BaseMaterial3D.BILLBOARD_DISABLED and world.supplies.boards.P1.billboard==BaseMaterial3D.BILLBOARD_DISABLED,"G1 e P1 usam placas fixas em vez de texto virando para a câmera")
 check(not world.supplies.boards.G1.no_depth_test and not world.supplies.boards.P1.no_depth_test,"placas respeitam paredes e objetos à frente")
 var label: Label3D=world.depot.crates.stock_1.get_node("SupplyLabel")
 check(label.billboard==BaseMaterial3D.BILLBOARD_DISABLED and is_equal_approx(label.position.y,.29) and label.outline_size==0,"identificação R1 fica impressa na caixa sem nome flutuante")
 Preferences.immersive_hud=false;Preferences.apply();world.supplies.refresh();await ticks(4)
 check(app.interface.objective.modulate.a==1 and app.interface.supply_marker.visible and label.billboard==BaseMaterial3D.BILLBOARD_ENABLED,"desligar HUD discreto conserva orientação completa e identificação ampliada")
 check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.supply_marker.get_global_rect()),"indicação completa permanece dentro da interface")
 Preferences.immersive_hud=true;Preferences.apply();world.supplies.refresh();await ticks(3)
 check(not app.interface.supply_marker.visible and label.billboard==BaseMaterial3D.BILLBOARD_DISABLED,"voltar ao modo discreto restaura etiquetas físicas sem duplicar objetos")
 await take("stock_1")
 check(player.carried_id=="stock_1" and app.interface.objective.text.contains("G1") and not app.interface.supply_marker.visible,"carregar R1 mantém destino consultável e não cria uma seta automática")
 check(world.supplies.work_line(player).contains("G1"),"ajuda contextual reconhece a caixa carregada")
 await stand(Vector3(-4.1,0,-4.8),-PI/2)
 await key_press(KEY_E);await ticks(30);var notices: Array[String]=[];world.notice.connect(func(value):notices.append(value));await key_press(KEY_E);await handled()
 check("stock_1" in Session.stocked and player.carried==null and world.depot.fridge_target.restock_count==1,"etiqueta e ausência de marcador preservam a reposição física por E")
 check(not notices.any(func(value):return value.contains("Reposição concluída")),"entrega correta no modo discreto não gera confirmação repetida na tela")
 check(world.supplies.work_line(player).contains("R2") and world.supplies.work_line(player).contains("Falta só"),"consulta passa a indicar somente a caixa que ainda falta")
 await key_press(KEY_J)
 var notebook: FieldNotebook=app.interface.notebook
 check(notebook!=null and get_tree().paused and notebook.find_child("CurrentTask",true,false).text.contains("R2"),"J mantém a tarefa completa acessível e pausa a rotina")
 if notebook!=null:
  var content:=""
  for line in notebook.find_children("*","Label",true,false):content+=line.text
  check(content.contains("PELO DEPÓSITO") and content.contains("primeira geladeira") and content.contains("DEVOLUÇÕES"),"caderno reúne referências físicas para encontrar os lugares")
 await key_press(KEY_J)
 check(app.interface.notebook==null and app.interface.objective.modulate.a==0,"fechar caderno devolve a cena sem reabrir o aviso de tarefa")
 Session.save_shift(player.position);app.start_saved();world=app.world;world.active=true;player=world.player;world.spawn_wait=999;await ticks(4)
 check(Session.stage==2 and "stock_1" in Session.stocked and not is_instance_valid(world.depot.crates.get("stock_1")),"save preserva serviço concluído sem recriar a caixa usada")
 check(world.supplies.boards.G1.text.contains("FALTAM 1") and world.supplies.work_line(player).contains("R2"),"placa e orientação retomam o progresso real do turno")
 await take("stock_shelf");await stand(Vector3(-4.1,0,-4.8),-PI/2)
 check(not find_interaction(world.depot.fridge_target,"fridge").activate(player) and app.interface.notice_label.text.contains("P1") and player.carried_id=="stock_shelf","erro de destino ainda explica P1 e preserva a mercadoria")
 player.drop_carried();await handled();await take("stock_2")
 Session.campaign.phase="outage";Session.changed.emit();world.friday.apply_power();await ticks(3)
 check(world.supplies.goal().is_empty() and not app.interface.supply_marker.visible,"pane suspende indicação de reposição em vez de apontar para trabalho bloqueado")
 check(app.interface.objective.text.contains("chave") and not app.interface.objective.text.contains("Destino:"),"objetivo da pane tem prioridade sobre a caixa ainda nas mãos")
 check(world.supplies.work_line(player).contains("gerador") and world.supplies.work_line(player).contains("chave"),"lista também orienta o próximo lugar durante a pane sem concluir a ação")
 check(world.supplies.work_line(world.characters.Felps).contains("Suspende o atendimento") and world.supplies.work_line(world.characters.Felps).contains("eu pego a chave"),"orientação ao controlar Felps respeita a divisão do caixa e do gerador")
 check(not Session.deliver("stock_2") and player.carried_id=="stock_2","orientação não muda regras de energia nem consome caixa no apagão")
 Session.advance_to_saturday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;await ticks(4);await get_tree().create_timer(.15,true,false,true).timeout
 check(world.supplies.shift_sheet==null and world.supplies.boards.is_empty(),"sábado conserva sua investigação sem lista de reposição da sexta")
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;await ticks(4);await get_tree().create_timer(.15,true,false,true).timeout
 check(world.supplies.shift_sheet==null and not app.interface.supply_marker.visible,"domingo conserva a fuga e o terminal sem orientações de trabalho antigo")
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(world.player.camera_rig.target_distance>1.5,"rodinha continua oferecendo terceira pessoa")
 await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(5)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("GUIDANCE RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
