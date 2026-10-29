extends Node
## Automated WASD route through the actual player controller and first-person camera.
## Records geometry, shadows, ground transitions and the game's spatial audio.
var app: Node
var player: DepotPlayer
var label: Label
var elapsed:=0.0
var moving:=false
var finishing:=false
var marks: Dictionary={}
var failures: Array[String]=[]
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("start")
func start() -> void:
	Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.has_started=true;app.interface.set_paused(false);app.interface.root.hide();app.world.active=true
	player=app.world.player;player.position=Vector3(0,.01,-2.8);player.velocity=Vector3.ZERO;player.reset_physics_interpolation()
	var rig:=player.camera_rig;rig.target_distance=0;rig.distance=0;rig.shoulder=0;rig.arm.spring_length=0;rig.arm.position.x=0;rig.camera.position.z=0;rig.yaw=PI;rig.pitch=-.015;rig.reset_follow()
	var layer:=CanvasLayer.new();layer.layer=20;add_child(layer);label=Label.new();layer.add_child(label);label.position=Vector2(22,18);label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
func walk(value: bool) -> void:
	if moving==value:return
	moving=value
	if moving:Input.action_press("forward")
	else:Input.action_release("forward")
func mark(id: String,condition: bool) -> void:
	if marks.has(id):return
	marks[id]=[player.position.x,player.position.y,player.position.z]
	if not condition:failures.append(id)
	print("WALK ",id," ","PASS " if condition else "FAIL ",marks[id])
func _physics_process(delta: float) -> void:
	if player==null or finishing:return
	elapsed+=delta
	var t:=elapsed;var title:=""
	var rig:=player.camera_rig
	if t<2:
		walk(false);rig.yaw=PI;title="Loja • visão para a rua"
	elif t<8:
		walk(true);rig.yaw=PI;title="Saída • do piso à calçada e ao asfalto"
	elif t<9.5:
		walk(false);rig.yaw=lerp_angle(PI,PI/2,smoothstep(8,9.5,t));title="Rua • luz do poste e sombras"
	elif t<17.5:
		walk(true);rig.yaw=PI/2;title="Descida • a luz termina antes da neblina"
	elif t<19:
		walk(false);rig.yaw=lerp_angle(PI/2,-PI/2,smoothstep(17.5,19,t));title="Bairro • fachadas e silêncio"
	elif t<27:
		walk(true);rig.yaw=-PI/2;title="Retorno • contraste entre os trechos iluminados"
	elif t<28.5:
		walk(false);rig.yaw=lerp_angle(-PI/2,0,smoothstep(27,28.5,t));rig.pitch=lerpf(-.015,.12,smoothstep(27,28.5,t));title="Depósito • a loja permanece acesa"
	elif t<32:
		walk(true);rig.yaw=0;rig.pitch=lerpf(.12,-.015,smoothstep(28.5,32,t));title="Entrada • luz da loja sobre o caminho"
	else:
		walk(false);rig.yaw=lerp_angle(0,.70,smoothstep(32,34,t));title="Caixa esquerdo • fim da caminhada"
	label.text="0.8.0 • CAMINHADA NO JOGO\n"+title
	if t>=8:mark("crossed_curbs",player.is_on_floor() and player.position.z>5.5 and player.position.z<7.2)
	if t>=17.5:mark("downhill",player.is_on_floor() and player.position.x< -11 and absf(player.position.z-6.3)<.7)
	if t>=27:mark("returned",player.is_on_floor() and absf(player.position.x)<1)
	if t>=34:
		mark("shop_entrance",player.is_on_floor() and player.position.z<1.5 and player.position.y>-.05)
		finishing=true;walk(false);print("WALK_RESULT ",JSON.stringify({"checks":marks.size(),"failures":failures,"positions":marks}));call_deferred("finish")
func finish() -> void:
	player.foot_audio.stop();player.foot_audio.stream=null;app.world.sound.stop_all()
	app.queue_free()
	for i in 20:await get_tree().process_frame
	await get_tree().create_timer(.2).timeout
	# Fixed-fps headless runs can outrun the audio mixer; let its stop queue retire.
	OS.delay_msec(200)
	player=null;app=null
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear()
	for i in 4:await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
