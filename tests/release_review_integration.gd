extends "res://tests/desktop_integration.gd"
## Regressions found while reviewing the complete campaign and its menus.
func run() -> void:
 Preferences.frame_limit=60;Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);world=app.world;world.active=true;app.interface.has_started=true;app.interface.set_paused(true);await ticks(4)
 Preferences.fov=68;Preferences.save();app.interface.open_settings();await ticks(4)
 var sliders: Array=app.interface.settings.find_children("*","HSlider",true,false)
 sliders[4].value=77;await ticks(2);await key(KEY_ESCAPE)
 var saved:=ConfigFile.new();saved.load("user://settings.cfg")
 check(app.interface.settings==null and is_equal_approx(float(saved.get_value("settings","fov",0)),77),"Esc em Configurações conserva FOV alterado no arquivo de preferências")
 app.interface.open_settings();await ticks(3);sliders=app.interface.settings.find_children("*","HSlider",true,false);sliders[0].value=.45;sliders[3].value=.0032;await key(KEY_ESCAPE);saved.load("user://settings.cfg")
 check(is_equal_approx(float(saved.get_value("settings","volume",0)),.45) and is_equal_approx(float(saved.get_value("settings","sensitivity",0)),.0032),"volume e sensibilidade também persistem ao sair pelo teclado")
 var original_size:=get_window().size
 get_window().size=Vector2i(800,600);await ticks(4);app.interface.open_settings();await ticks(4)
 check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.settings.get_global_rect()),"configurações cabem em janela 800×600 com rolagem acessível")
 await key(KEY_ESCAPE);app.interface.set_paused(false)
 world.sale=ShopSale.create(1);world.spawn_customer(false,{"position":[-3.1,0,-2.7],"state":int(Customer.State.WAITING),"service_started":true,"identity":"Garota1","appearance":0});world.select_player("Felps");app.interface.open_checkout(world);await ticks(4)
 check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.checkout.get_global_rect()),"caixa cabe inteiro em janela 800×600")
 get_window().size=Vector2i(1600,900);await ticks(4)
 check(app.interface.checkout.get_global_rect().get_center().distance_to(app.interface.root.size*.5)<2,"redimensionar recentraliza o caixa")
 await key(KEY_ESCAPE);get_window().size=original_size;await ticks(3)
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.sunday.introduce(world.player);clear_dialogue();world.select_player("Felps");world.sunday.state().proof="carried";world.sunday.state().proof_carrier="Dery"
 app.interface.show_campaign("escape");await ticks(3)
 var text:=""
 for line in app.interface.campaign_panel.find_children("*","Label",true,false):text+=line.text+"\n"
 check(text.contains("Prova com o companheiro") and not text.contains("Prova preservada: sim"),"confirmação de saída explica quando a cópia está com o irmão que ficou no depósito")
 app.interface.close_campaign();world.sunday.state().proof="offsite";app.interface.show_campaign("escape");await ticks(3)
 text=""
 for line in app.interface.campaign_panel.find_children("*","Label",true,false):text+=line.text+"\n"
 check(text.contains("Prova preservada: sim"),"prova já enviada permanece confirmada mesmo com a dupla separada")
 get_window().size=Vector2i(800,600);await ticks(4)
 check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.campaign_panel.get_global_rect()),"confirmação de fuga acompanha janela menor")
 app.interface.close_campaign();app.interface.show_night_summary();await ticks(4)
 check(Rect2(Vector2.ZERO,app.interface.root.size).encloses(app.interface.night_panel.get_global_rect()),"relatório entre noites cabe na janela menor")
 app.interface.night_panel.queue_free();app.interface.night_panel=null;get_window().size=original_size;app.interface.set_paused(false)
 var actor: DepotPlayer=world.player;actor.position=Vector3(-20,Street.surface_height(-20,1.8),1.8);actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=-PI/2;actor.stamina=.055
 Input.action_press("forward");Input.action_press("sprint");await ticks(30)
 var tired_speed:=0.0
 for i in 12:await ticks(1);tired_speed=maxf(tired_speed,actor.actual_speed)
 check(tired_speed<1.9,"exaustão mantém caminhada estável em vez de alternar corrida e regeneração a cada quadro")
 await ticks(45)
 check(actor.actual_speed>3.4,"segurar Shift retoma a corrida depois de recuperar uma reserva de fôlego")
 Input.action_release("sprint");await ticks(90);Input.action_press("sprint");await ticks(20)
 check(actor.actual_speed>3.4,"recuperar fôlego permite voltar à velocidade normal de corrida")
 Input.action_release("forward");Input.action_release("sprint");await finish_test()
func finish_test() -> void:
 clear_dialogue();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(5)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("REVIEW RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
