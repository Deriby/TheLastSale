extends Node
## Play the uploaded MP3 through the actual paused title/menu lifecycle.
var app: Node
var checks:=0
var failures: Array[String]=[]
func _ready() -> void:process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1;print("PASS " if value else "FAIL ",message)
 if not value:failures.append(message)
func frames(count:=3) -> void:
 for i in count:await get_tree().process_frame
func seconds(value: float) -> void:await get_tree().create_timer(value,true,false,true).timeout
func key(code: Key) -> void:
 var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
 event=event.duplicate();event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await frames()
func run() -> void:
 Preferences.frame_limit=60;Preferences.music_volume=.35;Preferences.effects_volume=.8;Preferences.volume=.7;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);await frames()
 var ui: ShiftInterface=app.interface;var title: TitlePresentation=ui.presentation
 check(not title.drone.playing,"música não começa fora da abertura")
 ui.begin_title(app.world);await frames();await seconds(.12)
 check(title.intro_active and title.drone.playing and get_tree().paused,"MP3 toca durante a intro mesmo com o jogo pausado")
 check(title.drone.stream is AudioStreamMP3 and title.drone.stream.loop and title.drone.stream.get_length()>150,"faixa completa usa repetição nativa do MP3")
 check(title.music_gain>0 and title.music_gain<1,"música entra gradualmente na abertura")
 await seconds(.85)
 check(is_equal_approx(title.music_gain,1) and title.drone.volume_db>-40,"entrada termina em volume estável")
 var position_before:=title.drone.get_playback_position();var player_id:=title.drone.get_instance_id();title.finish_intro();await seconds(.18)
 check(ui.menu.visible and title.drone.playing and title.drone.get_instance_id()==player_id and title.drone.get_playback_position()>position_before,"intro e menu compartilham a faixa sem reiniciar ou duplicar o player")
 check(Session.stage==0 and Session.world_seconds==0 and not app.world.active,"música e menu não avançam o expediente")
 position_before=title.drone.get_playback_position();ui.open_settings();await seconds(.15)
 check(ui.settings!=null and title.drone.playing and not title.drone.stream_paused and title.drone.get_playback_position()>position_before,"configurações mantêm a música contínua")
 await key(KEY_ESCAPE);check(ui.settings==null and title.drone.playing,"Esc volta ao menu mantendo a faixa")
 Preferences.music_volume=0;Preferences.apply();check(title.drone.volume_db<=-80,"controle Música silencia a faixa")
 Preferences.music_volume=.35;Preferences.effects_volume=0;Preferences.apply()
 check(title.drone.volume_db>-40 and title.select_audio.volume_db<=-80,"Música e Efeitos têm volumes independentes")
 Preferences.volume=.4;Preferences.apply();check(absf(AudioServer.get_bus_volume_db(0)-linear_to_db(.4))<.01,"volume geral também controla a saída da música")
 title.drone.seek(title.drone.stream.get_length()-.15);await seconds(.55)
 check(title.drone.playing and title.drone.get_playback_position()<1.2,"fim da faixa volta ao começo sem parar o menu")
 ui.begin_title(app.world);await frames();await seconds(.55);position_before=title.drone.get_playback_position();await key(KEY_SPACE)
 check(not title.intro_active and ui.menu.visible and title.drone.playing and title.drone.get_playback_position()>=position_before,"Espaço pula a intro sem cortar ou reiniciar a música")
 var level:=title.drone.volume_db;ui.start_from_title();await seconds(.14)
 check(title.departing and title.drone.playing and title.menu_gain>0 and title.menu_gain<1 and title.drone.volume_db<level,"começar expediente reduz a música durante a transição")
 await seconds(.5)
 check(ui.has_started and app.world.active and not title.drone.playing and not title.title_active,"música do menu para antes da jogabilidade")
 ui.set_paused(true);await seconds(.12);check(not title.drone.playing and not title.intro_active,"pausa do expediente não reinicia a música da abertura")
 Dialogue.clear();Session.save_shift(app.world.player.position);ui.has_started=false;ui.begin_title(app.world);await frames();await seconds(.25);title.finish_intro();ui.continue_from_title();await seconds(.5)
 check(ui.has_started and not title.drone.playing and not title.title_active,"Continuar também encerra a música ao restaurar o turno")
 app.world.sound.stop_all();await seconds(.2);app.queue_free();await frames(4);await seconds(.25)
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
 print("MUSIC RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures);get_tree().quit(0 if failures.is_empty() else 1)
