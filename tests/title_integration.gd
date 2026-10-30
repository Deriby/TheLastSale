extends Node
var checks := 0
var failures: Array[String] = []
var app: Node
var intro_events := 0
var starts := 0
func check(condition: bool,description: String) -> void:
	checks+=1;print("PASS " if condition else "FAIL ",description)
	if not condition:failures.append(description)
func frames(count := 3) -> void:
	for i in count:await get_tree().process_frame
func key(code: Key) -> bool:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	var handled:=get_viewport().is_input_handled()
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
	return handled
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")
func run() -> void:
	var had_save:=FileAccess.file_exists(Session.SAVE_PATH)
	var old_save:=FileAccess.get_file_as_bytes(Session.SAVE_PATH) if had_save else PackedByteArray()
	Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app);await frames()
	var ui: ShiftInterface=app.interface
	var title_screen: TitlePresentation=ui.presentation
	var world_id: int=app.world.get_instance_id()
	var lights: int=app.world.find_children("*","Light3D",true,false).size()
	var viewports: int=app.find_children("*","SubViewport",true,false).size()
	check(not title_screen.intro_active,"cenas de revisão embutidas não iniciam a intro automaticamente")
	ui.new_game.connect(func():starts+=1)
	title_screen.intro_finished.connect(func():intro_events+=1)
	ui.begin_title(app.world);await frames()
	var before_step: float=title_screen.elapsed;title_screen._process(.8)
	check(absf(title_screen.elapsed-before_step-.8)<.001,"baixa taxa de quadros não prolonga artificialmente a intro")
	check(title_screen.intro_active and get_tree().paused and not app.world.active,"abertura pausa a campanha antes de qualquer interação")
	check(not ui.menu.visible and not ui.hud.visible,"intro oculta menu e HUD até terminar")
	check(app.viewport.get_camera_3d()==title_screen.camera,"abertura usa câmera externa do próprio depósito")
	check(not app.world.characters.Dery.visible and not app.world.characters.Felps.visible,"tela inicial mostra o depósito vazio sem remover os protagonistas")
	check(app.find_children("*","SubViewport",true,false).size()==viewports and app.world.find_children("*","Light3D",true,false).size()==lights,"apresentação não acrescenta viewports nem luzes")
	check(title_screen.get_viewport()==get_viewport() and title_screen.get_viewport()!=app.viewport,"tipografia da abertura permanece na resolução da interface")
	var time_before: float=Session.world_seconds
	var elapsed_before: float=title_screen.elapsed
	await get_tree().create_timer(.12,true).timeout
	check(Session.world_seconds==time_before and Session.stage==0,"tempo, objetivos e progresso da campanha não avançam na intro")
	check(title_screen.elapsed>elapsed_before,"animação da fita continua com o mundo pausado")
	ui.begin_title(app.world);title_screen._process(30.0)
	check(title_screen.elapsed==0 and title_screen.intro_active,"tempo gasto no primeiro carregamento não pula a abertura")
	await frames()
	title_screen.elapsed=2.3;title_screen.update_intro()
	check(title_screen.heading.text=="Two Brothers Lab" and title_screen.caption.text.replace(" ","")=="APRESENTA","intro apresenta o estúdio antes da localização")
	title_screen.elapsed=5.2;title_screen.update_intro()
	check(title_screen.heading.text=="FRANCA, SÃO PAULO" and title_screen.caption.text.contains("21:40"),"segundo cartão apresenta local e horário do jogo")
	title_screen.elapsed=.4
	var consumed:=key(KEY_ENTER);await frames()
	check(consumed and not title_screen.intro_active and ui.menu.visible,"Enter pula a intro e revela o menu")
	check(starts==0 and not ui.has_started and get_tree().paused,"tecla usada para pular não começa uma partida por acidente")
	check(intro_events==1 and title_screen.drone.playing and not title_screen.tape.playing,"menu conserva ambiente sonoro e encerra a fita da intro")
	var first: Button=ui.buttons.get_child(0)
	check(first.has_focus(),"primeira ação do menu recebe foco de teclado")
	var continue_button: Button=ui.buttons.get_child(1)
	check(continue_button.disabled==not had_save,"Continuar indica corretamente a disponibilidade do checkpoint")
	ui.open_settings();await frames()
	check(ui.settings!=null and not ui.menu.visible,"Configurações abre sobre o fundo do menu")
	key(KEY_ESCAPE);await frames()
	check(ui.settings==null and ui.menu.visible and get_tree().paused,"Esc fecha Configurações antes da partida sem sair do menu")
	Preferences.ps1_mode=true;Preferences.ps1_high_resolution=false;Preferences.pixel_scale=2;Preferences.apply();await frames()
	check(app.viewport.size==Vector2i(320,240) and title_screen.get_viewport()==get_viewport(),"PS1 não reduz a resolução do menu nem da intro")
	Preferences.ps1_high_resolution=true;Preferences.apply();await frames()
	check(app.viewport.size==Vector2i(640,480),"PS1/2 permanece disponível no fundo do menu")
	var original_size:=get_window().size
	get_window().size=Vector2i(800,600);await frames(5)
	check(Rect2(Vector2.ZERO,ui.root.size).encloses(ui.menu.get_global_rect()),"menu cabe em uma janela de 800×600")
	get_window().size=original_size;await frames()
	var old_music: float=Preferences.music_volume;var old_effects: float=Preferences.effects_volume
	Preferences.music_volume=0;Preferences.effects_volume=0;Preferences.apply()
	check(title_screen.drone.volume_db<=-80 and title_screen.tape.volume_db<=-74,"abertura e menu respeitam os controles de música e efeitos")
	Preferences.music_volume=old_music;Preferences.effects_volume=old_effects;Preferences.apply()
	ui.begin_title(app.world);title_screen.elapsed=.4;key(KEY_SPACE);await frames()
	check(not title_screen.intro_active and intro_events==2 and starts==0,"Espaço pula apenas a abertura")
	ui.begin_title(app.world);title_screen.elapsed=.4;key(KEY_ESCAPE);await frames()
	check(not title_screen.intro_active and intro_events==3 and starts==0,"Esc também pula a abertura sem iniciar o jogo")
	ui.begin_title(app.world);title_screen.elapsed=.4
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	Input.parse_input_event(click);Input.flush_buffered_events();click.pressed=false;Input.parse_input_event(click);Input.flush_buffered_events();await frames()
	check(not title_screen.intro_active and intro_events==4 and starts==0,"clique pula a abertura sem acionar um botão por baixo")
	ui.begin_title(app.world);title_screen.elapsed=TitlePresentation.DURATION+.01;await frames()
	check(not title_screen.intro_active and intro_events==5 and ui.menu.visible,"fim natural da sequência revela o menu uma única vez")
	title_screen.finish_intro()
	check(intro_events==5,"finalizar uma intro já encerrada não repete a transição")
	ui.start_from_title();await frames(5)
	check(starts==1 and ui.has_started and not get_tree().paused and app.world.active,"Iniciar expediente ativa o jogo normalmente")
	check(app.world.get_instance_id()==world_id and Session.stage==0,"início aproveita o mundo carregado sem alterar a progressão")
	check(app.viewport.get_camera_3d()==app.world.player.camera_rig.camera and title_screen.camera==null,"controle e câmera retornam ao protagonista")
	check(app.world.characters.Dery.visible and app.world.characters.Felps.visible,"visibilidade dos protagonistas é restaurada ao entrar no jogo")
	check(not title_screen.drone.playing and not title_screen.tape.playing and not title_screen.intro_active,"áudio e intro encerram ao entrar no jogo")
	await get_tree().create_timer(.6,true).timeout
	check(ui.hud.visible and not ui.menu.visible and not title_screen.visible,"transição libera o HUD sem uma camada preta residual")
	ui.set_paused(true);await frames()
	check(ui.menu.visible and not ui.hud.visible and not title_screen.title_active and not title_screen.intro_active,"pausa usa o novo menu sem repetir a abertura")
	check(app.viewport.get_camera_3d()==app.world.player.camera_rig.camera,"pausa conserva a câmera e a posição do jogador")
	var saved_position: Vector3=app.world.player.global_position
	check(Session.save_shift(saved_position)==OK,"salvamento continua disponível depois da nova abertura")
	ui.rebuild_buttons();ui.continue_from_title();await frames(5)
	check(app.world.get_instance_id()!=world_id and ui.has_started and app.world.player.global_position.distance_to(saved_position)<.08,"Continuar restaura o checkpoint e a câmera de jogo")
	check(not title_screen.intro_active and not title_screen.title_active,"Continuar não reproduz a intro outra vez")
	app.queue_free();await frames(5)
	# A main scene attached directly to the root follows the real F5/launch path.
	var launched: Node=load("res://scenes/main/main.tscn").instantiate();get_tree().root.add_child(launched);await frames()
	check(launched.interface.presentation.intro_active and get_tree().paused and not launched.interface.has_started,"executar a cena principal inicia a intro automaticamente antes do menu")
	launched.queue_free();await frames(5)
	if had_save:FileAccess.open(Session.SAVE_PATH,FileAccess.WRITE).store_buffer(old_save)
	elif FileAccess.file_exists(Session.SAVE_PATH):DirAccess.remove_absolute(ProjectSettings.globalize_path(Session.SAVE_PATH))
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	print("TITLE RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
