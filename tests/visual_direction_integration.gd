extends "res://tests/everyday_integration.gd"
func run() -> void:
 Preferences.pixel_scale=1;Preferences.ps1_mode=false;Preferences.frame_limit=60;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);world=app.world;world.spawn_wait=999;Session.greet();Dialogue.clear();world.presence.state().next_at=99999;await ticks(6)
 var finish: AnalogFinish=world.depot.get_node("AnalogFinish")
 check(finish!=null and finish.find_children("*","CollisionObject3D",true,false).is_empty(),"acabamento novo não cria colisões no percurso")
 check(finish.find_children("*","MeshInstance3D",true,false).filter(func(mesh):return mesh.get_meta("visual_role","")=="paint_band").size()==5,"pintura antiga fica em cinco trechos sólidos das paredes")
 check(finish.details.size()==7 and finish.details.all(func(node):return node.visible and node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF),"patina e marcas de passagem são camadas visuais estáticas")
 var pools:=world.depot.find_children("*","SpotLight3D",true,false).filter(func(light):return light.get_meta("mood_shadow",false))
 check(pools.size()==3 and pools.all(func(light):return light.light_cull_mask==1),"três luzes principais continuam restritas ao salão")
 var warm:=false
 for light in pools:if light.light_color.r>light.light_color.b+.1 and light.light_energy>1.1:warm=true
 check(warm,"balcão recebe luz quente de intensidade local")
 var env: Environment=world.get_node("Atmosphere").environment
 check(env.ambient_light_color.b>env.ambient_light_color.r and env.ambient_light_energy>=.055,"ar frio mantém detalhes nas sombras sem apagar o cenário")
 check(env.fog_depth_begin>=16 and env.fog_depth_end>60,"neblina continua longe da área de interação")
 var shadows:=0
 for light in world.find_children("*","Light3D",true,false):if light.shadow_enabled:shadows+=1
 check(shadows==5,"direção visual mantém o orçamento de cinco luzes com sombras")
 var cabinet:=world.depot.find_children("CabinetLight","OmniLight3D",true,false)
 check(cabinet.size()==12 and cabinet.all(func(light):return light.light_cull_mask==16 and not light.shadow_enabled),"geladeiras não ganham luz sobre piso ou novos mapas de sombra")
 check(finish.bounce_lights.size()==2 and finish.bounce_lights.all(func(light):return not light.shadow_enabled and world.friday.lights.has(light)),"rebates suaves pertencem aos circuitos existentes")
 check(world.depot.get_node("StockLight").light_cull_mask==3,"luz de serviço também alcança a cabeça original nos fundos")
 check(world.depot.old_door.find_child("OldHandlePlate",true,false)!=null and world.depot.old_door.find_child("OldHandlePlate",true,false).find_children("*","CollisionObject3D",true,false).is_empty(),"placa metálica da maçaneta preserva a porta física")
 check(world.depot.find_children("OldDisplayOffer","MeshInstance3D",true,false).size()==1,"cartaz usa a arte já presente no expositor da loja")
 var at:=world.player.position;var zoom:=world.player.camera_rig.target_distance;var grain:=Preferences.grain;var vhs:=Preferences.vhs
 Preferences.pixel_scale=3;Preferences.apply();await ticks(3)
 check(finish.details.all(func(node):return not node.visible) and finish.bounce_lights.all(func(light):return not light.visible),"Econômica recolhe transparências e luzes extras")
 shadows=0
 for light in world.find_children("*","Light3D",true,false):if light.shadow_enabled:shadows+=1
 check(shadows==0 and float(app.retro.get_shader_parameter("bloom_strength"))==0,"Econômica mantém desligadas sombras e halo")
 Preferences.pixel_scale=1;Preferences.apply();await ticks(3)
 check(finish.details.all(func(node):return node.visible) and finish.bounce_lights.all(func(light):return light.visible),"qualidade normal restaura os detalhes sem reconstruir o mundo")
 check(world.player.position.distance_to(at)<.03 and world.player.camera_rig.target_distance==zoom and Preferences.grain==grain and Preferences.vhs==vhs,"trocar qualidade não muda posição, câmera ou preferências analógicas")
 check(world.friday.begin_outage(),"pane original continua iniciando pelo sistema da campanha");Dialogue.clear();await ticks(3)
 check(finish.bounce_lights.all(func(light):return not light.visible) and not world.depot.get_node("StockLight").visible,"acabamento não deixa luz comercial acesa durante pane")
 Session.campaign.flags.counter_secured=true;Session.campaign.flags.generator_key=true
 check(world.friday.activate("generator",world.characters.Dery),"gerador original restaura a energia pelas mesmas condições");Dialogue.clear();await ticks(4)
 check(finish.bounce_lights.all(func(light):return light.visible) and world.sound.compressors.all(func(player):return player.playing),"luz e refrigeração retornam juntas sem desligar circuitos")
 Session.advance_to_sunday();app.build_world();world=app.world;world.active=true;world.spawn_wait=999;Dialogue.clear();world.sunday.stopped=true;Session.campaign.phase="sunday_escape";world.sunday.state().generator_mode="stock";Session.campaign.flags.generator_running=true;world.sunday.apply_scene();await ticks(3)
 finish=world.depot.get_node("AnalogFinish")
 check(not finish.get_node("CounterBounce").visible and finish.get_node("StockBounce").visible,"domingo respeita separação entre salão e estoque")
 Preferences.pixel_scale=3;Preferences.apply();await ticks(3)
 check(finish.bounce_lights.all(func(light):return not light.visible),"Econômica também respeita circuito parcial no domingo")
 Preferences.pixel_scale=1;Preferences.apply();await ticks(3)
 check(not finish.get_node("CounterBounce").visible and finish.get_node("StockBounce").visible,"restaurar qualidade não religa o setor sem energia")
 await finish_test()
func finish_test() -> void:
 Dialogue.clear();get_tree().paused=false;world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free();await ticks(6);await get_tree().create_timer(.25,true,false,true).timeout
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("VISUAL RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
