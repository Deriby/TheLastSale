extends Node
var checks:=0
var failures: Array[String]=[]
var app: Node
var world: ShiftWorld
func check(value: bool,message: String) -> void:
 checks+=1;print("PASS " if value else "FAIL ",message)
 if not value:failures.append(message)
func ticks(count: int) -> void:
 for frame in count:await get_tree().physics_frame
 await get_tree().process_frame
func clear_dialogue() -> void:
 while Dialogue.active:Dialogue.next_line()
func key(code: Key) -> void:
 var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();await ticks(2)
 event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await ticks(2)
func wheel(button: MouseButton,count: int) -> void:
 for index in count:
  var event:=InputEventMouseButton.new();event.button_index=button;event.pressed=true;event.position=Vector2(640,360);event.global_position=event.position
  Input.parse_input_event(event);Input.flush_buffered_events();await ticks(1)
 await ticks(28)
func stand(at: Vector3,yaw:=0.0) -> void:
 world.player.global_position=at;world.player.velocity=Vector3.ZERO;world.player.reset_physics_interpolation()
 world.player.camera_rig.yaw=yaw;world.player.camera_rig.pitch=-.12;world.player.camera_rig.reset_follow();await ticks(8)
func discard_customer() -> void:
 if is_instance_valid(world.customer):world.customer.queue_free()
 world.customer=null;world.sale=null;world.spawn_wait=999;Session.customer_state.clear();Session.sale_state.clear()
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func run() -> void:
 check(is_zero_approx(Preferences.camera_distance),"a revisão inicia em primeira pessoa por padrão")
 Preferences.camera_distance=0;Preferences.frame_limit=60;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
 app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;await ticks(25)
 check(world.player.camera_rig.first_person and world.player.visual.find_child("Dery_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"primeira pessoa mostra o corpo e mantém a cabeça fora da própria câmera")
 check(app.viewport.audio_listener_enable_3d,"viewport do jogo realmente recebe os sons posicionais 3D")
 await wheel(MOUSE_BUTTON_WHEEL_DOWN,8)
 check(not world.player.camera_rig.first_person and world.player.camera_rig.target_distance>1.5,"rodinha para baixo afasta e entrega terceira pessoa pelo caminho real de entrada")
 var dery_distance:=world.player.camera_rig.target_distance
 check(world.switch_player(),"Tab continua trocando os protagonistas")
 await ticks(24)
 check(world.player.identity=="Felps" and world.player.camera_rig.first_person,"Felps também começa em primeira pessoa com câmera independente")
 world.switch_player();await ticks(24)
 check(world.player.identity=="Dery" and is_equal_approx(world.player.camera_rig.target_distance,dery_distance),"trocar de volta preserva a distância escolhida na rodinha")
 await wheel(MOUSE_BUTTON_WHEEL_UP,12)
 check(world.player.camera_rig.first_person and world.player.camera_rig.target_distance==0,"rodinha para cima volta suavemente à primeira pessoa")
 await key(KEY_J)
 check(app.interface.notebook!=null and get_tree().paused and not app.interface.hud.visible,"J abre caderno nativo e pausa o expediente")
 if app.interface.notebook!=null:
  check(not app.interface.notebook.find_child("CurrentTask",true,false).text.is_empty(),"caderno mantém o objetivo completo disponível")
 var before:=world.player.global_position;var seconds:=Session.world_seconds;var identity:=world.player.identity
 Input.action_press("forward");await key(KEY_TAB);await ticks(5);Input.action_release("forward")
 check(world.player.position.distance_to(before)<.001 and is_equal_approx(Session.world_seconds,seconds) and world.player.identity==identity,"ler o caderno não move personagens, não troca Tab e não avança eventos")
 await key(KEY_ESCAPE)
 check(app.interface.notebook==null and not get_tree().paused and app.interface.hud.visible,"Esc fecha o caderno e devolve controle sem abrir pausa por baixo")
 Preferences.immersive_hud=true;app.interface.objective_remaining=0;app.interface.character_remaining=0;app.interface.hud_seconds=30;await ticks(2)
 check(app.interface.objective.modulate.a==0 and app.interface.hud.get_node("ControlsHint").text.contains("CADERNO"),"HUD discreto recolhe objetivo repetido e mantém acesso ao caderno")
 Preferences.immersive_hud=false;Preferences.apply();await ticks(2)
 check(app.interface.objective.modulate.a==1,"configuração permite voltar às instruções persistentes")
 Preferences.immersive_hud=true;Preferences.apply()
 var bounds:=Rect2(Vector2.ZERO,app.interface.root.size)
 check(bounds.encloses(app.interface.hud.get_node("Subtitles").get_global_rect()) and bounds.encloses(app.interface.hud.get_node("ControlsHint").get_global_rect()),"legendas retrô e lembrete cabem na tela nativa")
 Session.stage=4;Session.organized=true;Session.stocked.assign(["stock_1","stock_2"]);Session.customers_served=2;Session.world_seconds=80;world.spawn_wait=0
 await ticks(3)
 check(Session.can_warn() and not world.everyday.warning_ready() and is_instance_valid(world.customer) and not world.customer.warned,"rotina continua com venda comum antes dos cinco minutos, sem liberar aviso cedo")
 discard_customer();Session.world_seconds=300
 check(world.everyday.warning_ready(),"aviso fica disponível após cinco minutos quando tarefas e vendas já permitem")
 world.spawn_customer(Session.can_warn() and world.everyday.warning_ready())
 check(world.customer.warned,"atendimento do aviso continua usando a mecânica original")
 discard_customer();Session.world_seconds=150;Session.stage=1;Session.organized=false;Session.stocked.clear();Session.customers_served=0
 await stand(Vector3(4.75,.01,-13.0));world.everyday.tick(.25)
 check(world.everyday.done("empty_chime") and Dialogue.sequence=="everyday_empty_chime","sino toca com Deryk no estoque e Felps pergunta se ele voltou")
 check(world.sound.voices.any(func(player):return player.stream!=null and player.stream.resource_path.contains("entry_chime")),"a cena usa sino posicional da entrada, sem mover os protagonistas")
 var note_count: int=Session.campaign.experience.notes.size();clear_dialogue();world.everyday.tick(.25)
 check(not Dialogue.active and Session.campaign.experience.notes.size()==note_count,"acontecimento e anotação são únicos durante a mesma sessão")
 Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(4);world.everyday.tick(.25)
 check(world.everyday.done("empty_chime") and not Dialogue.active and Session.campaign.experience.notes.size()==note_count,"continuar preserva o sino já ouvido e não repete a cena")
 Session.world_seconds=225;Session.customers_served=1;await stand(Vector3(3.3,.01,-5.5));world.everyday.tick(.25)
 check(is_instance_valid(world.everyday.observer) and not world.everyday.done("observer_seen"),"pessoa aparece fora da visão no lado oposto da rua sem anotar algo ainda não visto")
 var observer:=world.everyday.observer
 if is_instance_valid(observer):
  check(not observer.is_in_group("customers") and world.customer==null,"observador não vira cliente, não ocupa atendimento e não altera recibos")
  await stand(Vector3(3.0,.01,.9),atan2(-(observer.position.x-3.0),-(observer.position.z-.9)))
  world.everyday.tick(.25)
  check(world.everyday.done("observer_seen"),"olhar para a pessoa com linha de visão registra a observação")
  await stand(Vector3(3.3,.01,-1.0),0);world.everyday.present_time=20;world.everyday.unseen_time=2.5;world.everyday.tick(.25)
  var at:=observer.position;await ticks(70)
  check(observer.leaving and observer.position.distance_to(at)>.4,"pessoa sai andando pela rua, sem desaparecer ou saltar de posição")
  var saved_at:=observer.position;Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(3)
  check(is_instance_valid(world.everyday.observer) and world.everyday.observer.leaving and world.everyday.observer.position.distance_to(saved_at)<.4,"save retoma a pessoa em sua posição e trajetória de saída")
  observer=world.everyday.observer
  if is_instance_valid(observer):
   observer.global_position=observer.destination+Vector3(.1,0,0);observer.waypoints.clear();observer.reset_physics_interpolation();await ticks(4)
   check(world.everyday.done("observer_gone") and world.everyday.state().observer.get("state")=="gone","chegar à saída conclui a presença sem salvar um fantasma em movimento")
   Session.save_shift(world.player.position);app.start_saved();world=app.world;world.spawn_wait=999;await ticks(3)
   check(not is_instance_valid(world.everyday.observer) and world.everyday.done("observer_gone"),"observador concluído não reaparece ao continuar")
 clear_dialogue();var volume:=Preferences.effects_volume;Preferences.effects_volume=0;Preferences.apply()
 check(world.sound.compressors.all(func(player):return player.volume_db<=-80) and world.sound.engine.volume_db<=-75,"novos ambientes respeitam volume de efeitos")
 Preferences.effects_volume=volume;Preferences.apply()
 check(world.friday.begin_outage(),"apagão original permanece acionável")
 check(world.sound.compressors.all(func(player):return not player.playing) and not world.sound.hum.playing,"apagão silencia refrigeração comercial além das luzes")
 clear_dialogue();Session.campaign.flags.counter_secured=true;Session.campaign.flags.generator_key=true
 check(world.friday.activate("generator",world.characters.Dery),"gerador restaura energia pela ação original")
 check(world.sound.compressors.all(func(player):return player.playing),"gerador restaura também os compressores posicionais")
 clear_dialogue();Session.campaign.phase="closing";Session.campaign.flags.lights_off=true;world.friday.apply_power()
 check(not world.sound.radio.playing and world.sound.compressors.all(func(player):return player.playing),"apagar salão mantém refrigeração no circuito correto")
 Session.advance_to_saturday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;world.saturday.introduce(world.characters.Dery);clear_dialogue();world.select_player("Felps")
 Session.customers_served=1;world.spawn_customer(false)
 var visitor:=world.customer;visitor.waypoints.clear();visitor.global_position=CheckoutFixture.CUSTOMER_POSITION;visitor.state=Customer.State.WAITING;visitor.wait=0;visitor.purchase_complete=true;visitor.bag.show();visitor.product.hide();world.sale.phase=ShopSale.Phase.COMPLETE
 var cash_before:=Session.sales_cents;visitor._physics_process(.016)
 check(visitor.quiet_pause and visitor.state==Customer.State.PAYING and visitor.wait>6,"cliente de boné demora a sair após receber a compra")
 var visitor_state:=visitor.snapshot();visitor.restore(visitor_state)
 check(visitor.quiet_pause and visitor.wait>6 and Session.sales_cents==cash_before,"hesitação retoma pelo save sem repetir recebimento ou entrega")
 discard_customer();await ticks(2)
 world.everyday.spawn_observer();world.everyday.record("observer_arrived");await ticks(3);app.interface.open_surveillance(world);await ticks(16)
 check(app.interface.surveillance!=null and app.interface.surveillance.page==0 and world.everyday.done("observer_seen"),"pessoa também pode ser percebida na câmera ao vivo da fachada")
 if app.interface.surveillance!=null:
  check(not app.interface.surveillance.feed.audio_listener_enable_3d,"DVR não desloca a escuta do jogador para a câmera de segurança")
  app.interface.surveillance.show_page(2);check(world.everyday.watched_camera==null,"ler outra página não conta como observar a imagem ao vivo")
 app.interface.close_surveillance();check(world.everyday.watched_camera==null,"fechar DVR remove a câmera observadora")
 clear_dialogue();Dialogue.play("everyday_pause_test",[["Felps","Só um instante."],["Dery","Beleza."]]);Dialogue.remaining=0;Dialogue._process(.01)
 check(Dialogue.between_lines and Dialogue.queue.size()==1,"falas automáticas têm uma pausa curta entre respostas")
 Dialogue.next_line();check(not Dialogue.between_lines and Dialogue.queue.is_empty(),"Espaço continua permitindo avançar falas sem esperar a pausa")
 clear_dialogue();var legacy:=Session.snapshot_data();legacy.campaign.erase("experience");legacy.characters.Dery.camera_distance=2.4;Session.write_save(legacy)
 check(Session.load_shift() and Session.campaign.experience.events is Dictionary and Session.campaign.experience.notes is Array,"saves versão 5 anteriores recebem anotações opcionais sem perder campanha")
 check(Session.character_states.Dery.camera_distance==0,"checkpoint anterior adota primeira pessoa uma vez, preservando posição e restante da campanha")
 app.queue_free();await ticks(5);await get_tree().create_timer(.12,true).timeout
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("EVERYDAY RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
 get_tree().quit(0 if failures.is_empty() else 1)
