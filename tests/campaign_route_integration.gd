extends "res://tests/sunday_integration.gd"
## One fresh campaign across all nights, without assigning progress, money or positions.
## The clock runs at 4x with 60 physical steps per game second; dialogue is advanced.
var route_data: Dictionary={"nights":[],"receipts":{},"max_step_m":0.0,"run_seconds":{"Dery":0.0,"Felps":0.0}}
var previous_world:=0
var previous_positions: Dictionary={}
func _ready() -> void:process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func _physics_process(delta: float) -> void:
 if not is_instance_valid(world) or not world.active or get_tree().paused:return
 if previous_world!=world.get_instance_id():previous_positions.clear();previous_world=world.get_instance_id()
 for actor in world.characters.values():
  if previous_positions.has(actor.identity):route_data.max_step_m=maxf(route_data.max_step_m,actor.position.distance_to(previous_positions[actor.identity]))
  previous_positions[actor.identity]=actor.position
  if actor.motion.current_clip=="run" and actor.actual_speed>3.2:route_data.run_seconds[actor.identity]+=delta
func ticks(count: int) -> void:
 for i in count:await get_tree().physics_frame
func move_to(at: Vector3,sprint:=false) -> bool:
 return await walk(at,sprint) if int(Session.campaign.night)==2 else await approach(at)
func settled() -> void:
 for i in 180:
  await ticks(1)
  if world.characters.values().all(func(actor):return not actor.motion.action_active and not actor.handling.busy):break
 await ticks(3)
func operate(parent: Node,id: String) -> bool:
 await get_tree().process_frame
 await ticks(2)
 var control:=parent.find_child(id,true,false) as Button
 if control==null or control.disabled or not control.is_visible_in_tree():print("ROUTE_BUTTON_UNAVAILABLE ",id);return false
 control.grab_focus();await get_tree().process_frame;await key_press(KEY_ENTER);await get_tree().process_frame;return true
func save_resume(label: String) -> bool:
 var before: Dictionary=Session.snapshot_data();Session.save_shift(world.player.position);app.start_saved();world=app.world;player=world.player;await ticks(5);clear_dialogue()
 var valid: bool=Session.campaign.phase==before.campaign.phase and Session.customers_served==before.customers and Session.sales_cents==before.sales_cents and Session.campaign.decisions==before.campaign.decisions
 check(valid,"retomada contínua: "+label);return valid
func pick(id: String) -> bool:
 var item: Node3D=world.depot.crates[id]
 if not await move_to(item.position+Vector3(0,0,.75)) or not interact(item,"crate"):return false
 await settled();return world.player.carried_id==id
func to_stock() -> bool:
 if world.player.position.z< -11.5:return true
 # Walk around the real opened leaf before crossing the doorway.
 if not await move_to(Vector3(4.95,0,-8.8)) or not await move_to(Vector3(4.85,0,-9.3)):return false
 var door:=find_interaction(world.depot.stock_door,"door")
 if not door.open:
  if not door.activate(world.player):return false
  await ticks(35)
 return await move_to(Vector3(4.95,0,-10.35)) and await move_to(Vector3(4.95,0,-11.8))
func from_stock() -> bool:
 return await move_to(Vector3(4.95,0,-11.8)) and await move_to(Vector3(4.95,0,-8.8))
func stock_friday() -> bool:
 if not await move_to(CheckoutFixture.CUSTOMER_POSITION) or not interact(world.depot.felps,"talk"):return false
 clear_dialogue();check(Session.stage==1,"campanha nova começa pela conversa real no balcão")
 for id in ["stock_1","stock_2"]:
  if not await to_stock() or not await pick(id) or not await from_stock() or not await move_to(Vector3(-4.1,0,-4.8)):return false
  var fridge:=find_interaction(world.depot.fridge_target,"fridge")
  if not world.depot.fridge_target.opened:fridge.activate(world.player);await ticks(35)
  if not fridge.activate(world.player):return false
  await settled();check(id in Session.stocked,"trajeto completo de reposição: "+id)
 if not await to_stock() or not await pick("loose") or not await move_to(Vector3(.2,0,-14.1)) or not await move_to(Vector3(-3.1,0,-13.6)):return false
 var pallet: Interaction
 for item in get_tree().get_nodes_in_group("interactables"):
  if item.kind=="pallet":pallet=item;break
 if pallet==null or not pallet.activate(world.player):return false
 clear_dialogue();await settled();check(Session.organized and Session.stage==4,"cascos no palete completam o trabalho por ações físicas")
 if not await from_stock() or not await move_to(Vector3(3.2,0,-8.8)):return false
 return await save_resume("sexta após reposição")
func customer_ready() -> bool:
 for i in 5000:
  await ticks(1)
  if Dialogue.active:clear_dialogue()
  if is_instance_valid(world.customer) and world.customer.state==Customer.State.WAITING and not world.customer.purchase_complete:return true
 print("ROUTE_CUSTOMER_BLOCKED ",Session.campaign.phase," ",world.customer.position if is_instance_valid(world.customer) else Vector3.ZERO);return false
func sale_by_keyboard() -> bool:
 if world.player.identity!="Felps" and not world.switch_player():return false
 if not await move_to(CheckoutFixture.STAFF_POSITION) or not world.try_checkout(world.player):return false
 clear_dialogue();await ticks(3)
 if world.sale.needs_bulk() and not world.sale.bulk_supplied:
  if not await operate(app.interface.checkout,"CallDeryk"):return false
  if not await to_stock() or not await pick(world.sale.supply_id()) or not await from_stock() or not await move_to(CheckoutFixture.CUSTOMER_POSITION+Vector3(.55,0,0)):return false
  if not interact(world.depot.counter,"checkout"):return false
  await settled()
  if not world.switch_player() or not world.try_checkout(world.player):return false
 for sku in world.sale.order:
  for i in int(world.sale.order[sku]):
   if not await operate(app.interface.checkout,"Register_"+sku):return false
 if not await operate(app.interface.checkout,"ConfirmItems") or not await operate(app.interface.checkout,"ReceiveCash"):return false
 var due:=world.sale.change_due()
 for coin in ShopSale.COINS:
  while due>=coin:
   if not await operate(app.interface.checkout,"Coin_"+str(coin)):return false
   due-=coin
 if not await operate(app.interface.checkout,"ConfirmChange") or not await operate(app.interface.checkout,"DeliverPurchase"):return false
 clear_dialogue();return world.customer.purchase_complete
func close_day() -> bool:
 clear_dialogue()
 if world.player.identity!="Felps" and not world.switch_player():return false
 if not await move_to(CheckoutFixture.STAFF_POSITION) or not interact(world.depot.counter,"checkout"):return false
 if not world.switch_player() or not await to_stock() or not await move_to(Vector3(.2,0,-14.75)) or not interact(world.depot.old_door,"note"):return false
 clear_dialogue()
 if not await move_to(Vector3(3.1,0,-12.1)) or not interact(world.friday.key_hook,"campaign"):return false
 check(world.friday.ready_to_leave() and not world.sound.radio.playing,"fechamento confere caixa, estoque e circuitos")
 if not world.switch_player() or not await move_to(Vector3(5.1,0,1.4)) or not interact(world.friday.exit_control,"campaign"):return false
 for i in 3000:
  await ticks(1)
  if world.friday.both_outside():break
 if not world.friday.both_outside() or not interact(world.friday.exit_control,"campaign"):return false
 clear_dialogue()
 for i in 220:
  await ticks(1)
  if app.interface.night_panel!=null:break
 if app.interface.night_panel==null:return false
 var day:=int(Session.campaign.night);route_data.nights.append(day);route_data.receipts[str(day)]=Session.receipts.size()
 check(Session.campaign.phase=="complete" and day in Session.campaign.completed_nights,"fechamento físico e resumo da noite "+str(day))
 var proceeded:=await operate(app.interface.night_panel,"NextNight");world=app.world;player=world.player;await ticks(3);return proceeded
func friday_route() -> bool:
 if not await stock_friday() or not world.switch_player():return false
 for sale_index in 12:
  if not await customer_ready() or not await sale_by_keyboard():return false
  if Session.receipts.size()!=Session.customers_served:return false
  for i in 3000:
   await ticks(1)
   if Dialogue.active:clear_dialogue()
   if not is_instance_valid(world.customer) or Session.campaign.phase=="outage":break
  if Session.campaign.phase=="outage":break
 check(Session.receipts.size()==Session.customers_served and Session.receipts.size()>=3,"atendimentos de sexta produzem recibos únicos na mesma campanha")
 check(Session.world_seconds>=300 and Session.warning_delivered and world.friday.is_outage(),"rotina respeita o intervalo do aviso e chega à pane sem forçar progresso")
 if not world.friday.is_outage():return false
 return await recover_friday()
func recover_friday() -> bool:
 clear_dialogue();await settled()
 if not interact(world.depot.counter,"checkout"):return false
 clear_dialogue();check(Session.flag("counter_secured"),"Felps suspende o caixa durante a pane contínua")
 if not world.switch_player() or not await to_stock() or not await move_to(Vector3(3.1,0,-12.1)) or not interact(world.friday.key_hook,"campaign"):return false
 if not await save_resume("pane com chave e caixa suspenso"):return false
 if not await move_to(Vector3(4.85,0,-14.8)) or not interact(world.depot.service_door,"door"):return false
 await ticks(35)
 if not await move_to(Vector3(4.85,0,-17.2)) or not await move_to(Vector3(4.4,0,-19.1)) or not interact(world.depot.yard.generator,"campaign"):return false
 clear_dialogue();await settled();check(Session.flag("generator_running") and world.sound.hum.playing,"gerador físico restaura refrigeração e permite encerrar sexta")
 return await finish_restored_friday()
func finish_restored_friday() -> bool:
 if world.player.identity!="Dery" and not world.switch_player():return false
 if world.player.position.z< -16:
  var patio_door:=find_interaction(world.depot.service_door,"door")
  if not patio_door.open:
   if not await move_to(Vector3(4.85,0,-18.1)) or not patio_door.activate(world.player):return false
   await ticks(35)
  if not await move_to(Vector3(4.85,0,-17.2)) or not await move_to(Vector3(4.85,0,-14.8)):return false
 if not world.switch_player() or not await customer_ready() or not await sale_by_keyboard():return false
 check(world.customer.purchase_complete,"atendimento após a pane permite encerrar a primeira noite")
 for i in 3000:
  await ticks(1)
  if Dialogue.active:clear_dialogue()
  if Session.campaign.phase=="closing":break
 if Session.campaign.phase!="closing":return false
 return await close_day()
func saturday_route() -> bool:
 if not await move_to(CheckoutFixture.CUSTOMER_POSITION) or not interact(world.depot.felps,"talk"):return false
 clear_dialogue()
 if not world.switch_player():return false
 for i in 2:
  if not await customer_ready() or not await sale_by_keyboard():return false
 for i in 3000:
  await ticks(1)
  if Dialogue.active:clear_dialogue()
  if Session.campaign.phase=="saturday_investigation":break
 check(Session.receipts.size()==2 and Session.campaign.phase=="saturday_investigation","sábado atende as duas visitas e só depois libera investigação")
 await key_press(KEY_C)
 if app.interface.surveillance==null:return false
 app.interface.surveillance.show_page(1)
 if not await operate(app.interface.surveillance,"ReviewEvents") or not await operate(app.interface.surveillance,"CompareReceipt"):return false
 await key_press(KEY_TAB)
 if not await to_stock() or not await move_to(Vector3(.2,0,-14.75)) or not interact(world.depot.old_door,"note"):return false
 clear_dialogue()
 if not interact(world.saturday.board,"investigation"):return false
 clear_dialogue();check(world.saturday.complete_clues(),"quatro pistas vêm do DVR, recibo e inspeções físicas")
 if not await save_resume("sábado com quatro pistas") or not world.switch_player():return false
 await key_press(KEY_C)
 if app.interface.surveillance==null:return false
 app.interface.surveillance.show_page(2)
 if not await operate(app.interface.surveillance,"CopyEvidence") or not await operate(app.interface.surveillance,"ContactHelp"):return false
 await key_press(KEY_ESCAPE)
 if not await move_to(Vector3(5.1,0,1.4)) or not interact(world.friday.exit_control,"campaign"):return false
 await ticks(3);return await close_day()
func sunday_route() -> bool:
 if not await walk(CheckoutFixture.CUSTOMER_POSITION) or not interact(world.depot.felps,"talk"):return false
 clear_dialogue();check(Session.flag("help_notified") and not Session.campaign.evidence_archive.is_empty(),"domingo recebe contato e cópia decididos no sábado real")
 if not await walk(Vector3(4.85,0,-10)) or not interact(world.depot.stock_door,"door"):return false
 if not await walk(Vector3(4.85,0,-12)) or not await walk(Vector3(.2,0,-14.7)) or not interact(world.depot.old_door,"note"):return false
 clear_dialogue()
 if not await walk(Vector3(.25,0,-18.8)) or not interact(world.depot.access.evidence,"sunday"):return false
 if not await save_resume("domingo com módulo recolhido"):return false
 if not await walk(Vector3(.2,0,-14.7)) or not await walk(Vector3(4.85,0,-12)) or not await walk(Vector3(4.85,0,-9.8)) or not await walk(CheckoutFixture.CUSTOMER_POSITION) or not interact(world.depot.counter,"checkout"):return false
 if not world.switch_player():return false
 await key_press(KEY_C)
 if app.interface.sunday_desk==null or not await operate(app.interface.sunday_desk,"RecoverRecording"):return false
 for i in 700:
  await ticks(1)
  if app.interface.sunday_desk.watched:break
 if not await operate(app.interface.sunday_desk,"AnalyzeRecording"):return false
 clear_dialogue();await key_press(KEY_C)
 if app.interface.sunday_desk==null or not await operate(app.interface.sunday_desk,"TakeProof") or not await operate(app.interface.sunday_desk,"SendProof"):return false
 await key_press(KEY_TAB)
 check(Session.campaign.phase=="sunday_prepare" and world.sunday.state().proof=="offsite","vídeo real, análise e envio preservam prova antes da fuga")
 if not await walk(Vector3(4.85,0,-9.8)) or not await walk(Vector3(4.85,0,-12)) or not await walk(Vector3(3.1,0,-12.1)) or not interact(world.friday.key_hook,"campaign"):return false
 clear_dialogue();return await escape_route()
func escape_route() -> bool:
 world.player.torch.hide();world.characters.Felps.torch.hide()
 if not await walk(Vector3(4.85,0,-14.8),true) or not interact(world.depot.service_door,"door"):return false
 if not await walk(Vector3(4.75,0,-17.2),true) or not await walk(Vector3(4.4,0,-19.1),true) or not interact(world.depot.yard.generator,"campaign"):return false
 await settled()
 if not await walk(Vector3(4.85,0,-17.1),true) or not await walk(Vector3(4.85,0,-14.8),true) or not await walk(Vector3(4.85,0,-12.2),true) or not world.switch_player():return false
 await key_press(KEY_C)
 if app.interface.sunday_desk==null or not await operate(app.interface.sunday_desk,"ReleaseStock"):return false
 await key_press(KEY_H)
 if not await walk(Vector3(3.3,0,-.8),true) or not interact(world.sunday.crank,"sunday"):return false
 await ticks(130)
 if not Session.flag("front_open") or not await walk(Vector3(4.8,0,1.5),true) or not await walk(Vector3(10,Street.surface_height(10,1.8),1.8),true):return false
 for i in 3000:
  await ticks(1)
  if world.sunday.together_at_exit() or app.interface.campaign_panel!=null:break
 check(world.sunday.together_at_exit(),"dupla foge por rotas reais com o perseguidor ativo")
 if not world.sunday.together_at_exit() or not interact(world.sunday.exits[0],"sunday") or not await operate(app.interface.campaign_panel,"EscapeTogether"):return false
 check(Session.campaign.ending.id=="resolved" and Session.campaign.completed_nights==[0,1,2],"uma mesma campanha nova chega ao final com dois sobreviventes e prova")
 route_data.nights.append(2);return await save_resume("epílogo da campanha completa")
func run() -> void:
 Engine.physics_ticks_per_second=240;Engine.time_scale=4;Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);await ticks(2)
 app.interface.finish_title_launch(false);world=app.world;player=world.player;await ticks(2);clear_dialogue()
 var friday_ok:=await friday_route();check(friday_ok,"percurso contínuo de sexta chega ao sábado")
 if not friday_ok:await finish_test();return
 var saturday_ok:=await saturday_route();check(saturday_ok,"percurso contínuo de sábado chega ao domingo")
 if not saturday_ok:await finish_test();return
 var sunday_ok:=await sunday_route();check(sunday_ok,"percurso contínuo de domingo chega ao epílogo")
 check(route_data.max_step_m<.25,"protagonistas não sofrem saltos de posição ao caminhar, correr ou acompanhar")
 check(route_data.run_seconds.Dery>3 and route_data.run_seconds.Felps>3,"os dois protagonistas usam corrida real durante a fuga")
 await finish_test()
func finish_test() -> void:
 if not failures.is_empty():print("ROUTE FAILURE active=",world.active," stopped=",world.sunday.stopped," caught=",world.sunday.caught_identity," modal=",app.interface.campaign_panel.kind if app.interface.campaign_panel!=null else ""," Dery=",world.characters.Dery.position," Felps=",world.characters.Felps.position," killer=",world.sunday.killer.position if is_instance_valid(world.sunday.killer) else Vector3.ZERO)
 print("CAMPAIGN ROUTE ",JSON.stringify(route_data))
 clear_dialogue();get_tree().paused=false;Input.action_release("forward");Input.action_release("sprint");world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await get_tree().process_frame;await get_tree().create_timer(.25,true,false,true).timeout;await ticks(5)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("ROUTE RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
