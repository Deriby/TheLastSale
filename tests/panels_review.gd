extends Node
## Native interface captures; transaction buttons are real, campaign state is staged between clips.
var app: Node
var world: ShiftWorld
var output:=""
var shots: Array=[]
var movie:=false
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func frames(count: int=5) -> void:
 for i in count:await get_tree().process_frame
func hold(seconds: float=1.8) -> void:
 if movie:await get_tree().create_timer(seconds,true,false,true).timeout
 else:await frames(4)
func shot(id: String) -> void:
 await frames(6);await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+"/"+id+".png");shots.append(id);print("PANEL SHOT ",id)
func press(id: String) -> void:
 var button:=app.interface.checkout.find_child(id,true,false) as Button
 button.pressed.emit();await frames(3)
func clear_dialogue() -> void:
 while Dialogue.active:Dialogue.next_line()
func run() -> void:
 output=OS.get_environment("PANELS_REVIEW_PATH");if output.is_empty():output="/tmp/panels-review"
 DirAccess.make_dir_recursive_absolute(output);movie="movie" in OS.get_cmdline_user_args()
 Preferences.camera_distance=0;Preferences.ps1_mode=false;Preferences.pixel_scale=2;Preferences.frame_limit=30;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.spawn_wait=999;Session.greet();clear_dialogue();world.select_player("Felps")
 world.sale=ShopSale.create(1);world.spawn_customer(false,{"position":[-3.1,0,-2.7],"state":int(Customer.State.WAITING),"service_started":true,"identity":"Garota1","appearance":0});app.interface.open_checkout(world);clear_dialogue();await hold();await shot("caixa_produtos")
 await press("Register_water");await hold(.5);await press("Register_water");await hold(.5);await press("Register_snack_0");await press("ConfirmItems");await hold();await shot("caixa_pagamento")
 await press("ReceiveCash");await press("Coin_500");await press("ConfirmChange");await hold();await shot("caixa_troco")
 for id in ["Coin_200","Coin_100","Coin_50"]:await press(id)
 await press("ConfirmChange");await hold();await shot("caixa_entrega")
 app.interface.close_checkout();world.select_player("Dery");Session.deliver("stock_1");Session.campaign.phase="routine";Session.campaign.experience.notes.append({"night":0,"time":"22:16","text":"A maçaneta da porta antiga mexeu quando me aproximei. O arrasto do outro lado tinha acabado de parar."});app.interface.open_journal();await hold();await shot("missoes")
 app.interface.notebook.show_page(1);await hold();await shot("registros")
 app.interface.close_journal();app.interface.set_paused(true);app.interface.open_settings();await hold();await shot("configuracoes")
 app.interface.settings.closed.emit();Session.campaign.reports.friday={"customers":3,"sales_cents":14500};app.interface.show_night_summary();await hold();await shot("relatorio")
 app.interface.night_panel.queue_free();app.interface.night_panel=null;app.interface.set_paused(false);Session.advance_to_sunday();app.build_world();world=app.world;world.active=false;clear_dialogue();world.sunday.state().proof="offsite";app.interface.show_campaign("escape");await hold();await shot("saida")
 print("PANELS REVIEW ",JSON.stringify({"shots":shots,"speed":1,"native_controls":true,"staged_campaign_between_clips":true}))
 Dialogue.clear();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await frames(6);await get_tree().create_timer(.25,true,false,true).timeout
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
