extends Node
## Nighttime review camera in the actual game scene, not a concept render.
var app: Node
var camera: Camera3D
var label: Label
var frame:=0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	call_deferred("start")
func start() -> void:
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	app.interface.root.hide();app.world.player.hide();app.world.depot.felps.hide()
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;app.world.add_child(camera);camera.current=true
	var layer:=CanvasLayer.new();layer.layer=20;add_child(layer);label=Label.new();layer.add_child(label);label.position=Vector2(22,18);label.add_theme_font_size_override("font_size",20);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
func _process(_delta: float) -> void:
	if camera==null:return
	frame+=1
	var t:=frame/30.0;var stage:=mini(3,int(t/8));var u:=smoothstep(0,1,fmod(t,8.0)/8)
	var at:=Vector3.ZERO;var target:=Vector3.ZERO;var title:=""
	match stage:
		0:at=Vector3(2,2.0,10).lerp(Vector3(-1.2,1.9,8.5),u);target=Vector3(1,3.1,0);title="Fachada JA • anexo e duas entradas";camera.fov=58
		1:at=Vector3(0,1.9,4.0).lerp(Vector3(2.5,1.9,4.2),u);target=Vector3(1,1.65,12.4);title="Casas em frente • muros, portões e telhados";camera.fov=68
		2:at=Vector3(-1,1.9,6.6).lerp(Vector3(-7,1.9+Street.grade(-7),6.7),u);target=Vector3(-35,Street.grade(-35)+1.5,6.6);title="Rua Alfredo Oliviere • sentido de descida";camera.fov=68
		3:at=Vector3(0,1.9,6.5).lerp(Vector3(6,1.9,6.5),u);target=Vector3(35,Street.grade(35)+1.6,6.6);title="Comércios vizinhos • sentido de subida";camera.fov=68
	camera.position=at;camera.look_at(target);label.text="0.4.0 • EXTERIOR\n"+title
	if frame==960:
		set_process(false);app.queue_free();call_deferred("finish")
func finish() -> void:
	for i in 20:await get_tree().process_frame
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();get_tree().quit()
