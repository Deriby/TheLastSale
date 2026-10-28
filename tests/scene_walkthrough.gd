extends Node
## A camera tour of the actual running scene, with original ambient game audio.
var app: Node
var camera: Camera3D
var label: Label
var frame:=0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("start")
func start() -> void:
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.has_started=true;app.interface.set_paused(false);app.interface.root.hide();app.world.active=false
	app.world.player.process_mode=Node.PROCESS_MODE_DISABLED;app.world.player.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;camera.far=110;app.world.add_child(camera);camera.current=true
	var layer:=CanvasLayer.new();layer.layer=20;add_child(layer);label=Label.new();layer.add_child(label);label.position=Vector2(22,18);label.add_theme_font_size_override("font_size",19);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
func _process(_delta: float) -> void:
	if camera==null:return
	frame+=1
	var t:=frame/30.0;var stage:=mini(5,int(t/5));var u:=smoothstep(0,1,fmod(t,5.0)/5)
	var at:=Vector3.ZERO;var target:=Vector3.ZERO;var title:=""
	app.world.depot.felps.visible=stage!=1 and stage!=2
	match stage:
		0:at=Vector3(-2.6,1.7,-1.6).lerp(Vector3(-2.9,1.65,-2.1),u);target=Vector3(-4.45,1.25,-2.9);title="Balcão esquerdo • vista do cliente";camera.fov=67
		1:at=Vector3(-5.14,1.68,-2.5).lerp(Vector3(-5.14,1.6,-3.15),u);target=Vector3(-4.08,1.17,-2.84);title="Posto do funcionário • caixa e equipamentos";camera.fov=68
		2:at=Vector3(-4.95,1.72,-2.25).lerp(Vector3(-3.7,1.72,-1.95),u);target=Vector3(3.4,1.95,10.5);title="De dentro para fora • portas abertas e rua";camera.fov=76
		3:at=Vector3(3.8,1.68,-2.9).lerp(Vector3(3.8,1.68,-4.2),u);target=Vector3(-1.8,1.4,-6.0);title="Salão • bebidas, copos e iluminação";camera.fov=72
		4:at=Vector3(-1,1.9,6.6).lerp(Vector3(-5,1.9,6.6),u);target=Vector3(-50,-.2,6.6);title="Exterior • horizonte com neblina";camera.fov=65
		5:at=Vector3(.4,2.15,8.1).lerp(Vector3(-1,2.0,7.6),u);target=Vector3(.4,3.0,0);title="Fachada • luz da loja sobre a calçada";camera.fov=64
	camera.position=at;camera.look_at(target);label.text="0.5.0 • PASSEIO DE CÂMERA\n"+title
	if frame==900:
		set_process(false);app.queue_free();call_deferred("finish")
func finish() -> void:
	for i in 20:await get_tree().process_frame
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();get_tree().quit()
