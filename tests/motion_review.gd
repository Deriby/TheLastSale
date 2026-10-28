extends Node3D
## Deterministic render of the shipped models, LivingMotion controller and hand grip.
class ShowcaseActor extends Node3D:
	var visual: Node3D
	var motion: LivingMotion
	var socket: Node3D
	var handling: BoxHandling
var actors: Array[ShowcaseActor] = []
var camera: Camera3D
var frame:=0
var label: Label
var boxes: Array[Node3D] = []
func _ready() -> void:
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("252e30");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("dce1d6");env.environment.ambient_light_energy=.7;add_child(env)
	var light:=DirectionalLight3D.new();add_child(light);light.rotation_degrees=Vector3(-40,-25,0);light.light_energy=1.2;light.shadow_enabled=true
	Geo.box(self,Vector3(0,-.1,25),Vector3(150,.2,150),Geo.material(Color("686f63"),"res://assets/textures/depot/floor.png"))
	for i in 2:
		var actor:=ShowcaseActor.new();add_child(actor);actor.position=Vector3(-.60+i*1.20,0,0)
		actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		var name: String="Dery" if i==0 else "Felps"
		actor.visual=load("res://assets/models/characters/"+name+".glb").instantiate();actor.add_child(actor.visual)
		actor.motion=LivingMotion.new();actor.add_child(actor.motion);actor.motion.setup(actor.visual,actor)
		actor.socket=Node3D.new();actor.add_child(actor.socket);actor.socket.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		actor.handling=BoxHandling.new();actor.add_child(actor.handling);actor.handling.setup(actor);actor.motion.pose_updated.connect(actor.handling.sync_grip)
		var box: Node3D=load("res://scenes/world/props/crate.tscn").instantiate();actor.socket.add_child(box);box.position=Vector3(0,-.23,0);box.hide();boxes.append(box)
		actors.append(actor)
	camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=43
	var ui:=CanvasLayer.new();add_child(ui);label=Label.new();ui.add_child(label);label.position=Vector2(24,18);label.add_theme_font_size_override("font_size",20);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
func _process(delta: float) -> void:
	frame+=1
	var seconds:=frame/30.0
	var speed:=0.0;var carrying:=false;var crouch:=false
	var title: String="Respiração e postura de repouso"
	if seconds>=8 and seconds<14:speed=1.55;title="Caminhada • passada sincronizada"
	elif seconds>=14 and seconds<19:speed=3.9;title="Corrida • braços e quadril"
	elif seconds>=19 and seconds<25:speed=1.15;carrying=true;title="Transporte • caixa acompanha as mãos"
	elif seconds>=25 and seconds<33:title="Repouso • variações e transferência de peso"
	elif seconds>=33 and seconds<38:speed=.85;crouch=true;title="Caminhada agachada"
	for i in actors.size():
		var actor:=actors[i]
		actor.position.z+=speed*delta
		if seconds>26 and seconds<31:
			actor.motion.play("idle_shift" if i==0 else "talk",.3)
		else:
			actor.motion.locomotion(delta,speed,crouch,carrying,false)
		boxes[i].visible=carrying
	var focus: Vector3=(actors[0].position+actors[1].position)*.5
	camera.position=focus+Vector3(1.3,1.25,4.7);camera.look_at(focus+Vector3.UP*.93)
	label.text="0.3 • DERYK / FELPS\n"+title
	if frame==90:call_deferred("capture","idle")
	if frame==610:call_deferred("capture","carry")
	if frame==790:call_deferred("capture","living")
	if frame>=1140:get_tree().quit()
func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/03_"+id+".png")
