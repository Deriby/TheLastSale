extends Node3D
## The shipped skeleton controller, real floor collisions and measured movement.
class ReviewActor extends CharacterBody3D:
	var visual: Node3D
	var motion: LivingMotion
	var socket: Node3D
	var box: Node3D
	var mode := "idle"
	var pace := 1.15
	func _physics_process(delta: float) -> void:
		var speed:=3.9 if mode=="run" else 1.15 if mode=="carry_walk" else pace if mode=="walk" else 0.0
		velocity=Vector3(0,-2,move_toward(velocity.z,speed,delta*(10.0 if mode=="run" else 6.5)))
		var before:=global_position;move_and_slide()
		var actual:=Vector2(global_position.x-before.x,global_position.z-before.z).length()/delta
		if mode in ["talk","fidget"]:motion.play("idle_adjust" if mode=="fidget" else "talk",.25)
		else:motion.locomotion(delta,actual,false,mode=="carry_walk",false)
		box.visible=mode=="carry_walk"

const GROUPS := [["Dery","Felps"],["Garota1","Garota2","Customer2"],["Zirico"],["Bryan"],["Velha1"]]
const HEADINGS := ["PROTAGONISTAS / DERYK E FELPS","GAROTAS / CLIENTE HOMEM","ZIRICO / EQUILÍBRIO DE BÊBADO","BRYAN / CRIANÇA INQUIETA","SENHORA / PASSOS CURTOS"]
var groups: Array[Node3D]=[]
var actors: Array[Array]=[]
var camera: Camera3D
var caption: Label
var elapsed := 0.0
var page := -1
var saved: Dictionary={}
var output := ""
func _ready() -> void:
	Engine.max_fps=30;output=OS.get_environment("LOCOMOTION_REVIEW_PATH")
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("222d34")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("cfd6db");environment.environment.ambient_light_energy=.7;add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-42,-27,0);light.light_energy=1.15;light.shadow_enabled=true;add_child(light)
	Geo.box(self,Vector3(0,-.08,20),Vector3(50,.16,100),Geo.material(Color("6e7774"),"res://assets/textures/depot/floor.png"))
	for index in GROUPS.size():
		var group:=Node3D.new();add_child(group);groups.append(group);var members: Array=[]
		for number in GROUPS[index].size():
			var identity: String=GROUPS[index][number]
			var actor:=ReviewActor.new();group.add_child(actor)
			actor.position=Vector3((number-(GROUPS[index].size()-1)*.5)*1.35,.01,0)
			var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.20;capsule.height=1.1 if identity=="Bryan" else 1.65;shape.shape=capsule;shape.position.y=capsule.height*.5;actor.add_child(shape);actor.collision_layer=2;actor.collision_mask=1
			actor.visual=CharacterModels.create(identity);actor.add_child(actor.visual)
			actor.motion=LivingMotion.new();actor.add_child(actor.motion);actor.motion.setup(actor.visual,actor)
			actor.socket=Node3D.new();actor.add_child(actor.socket)
			var grip:=BoxHandling.new();actor.add_child(grip);grip.setup(actor);actor.motion.pose_updated.connect(grip.sync_grip)
			actor.box=load("res://scenes/world/props/crate.tscn").instantiate();actor.socket.add_child(actor.box);actor.box.position=Vector3(0,-.23,0);actor.box.hide()
			for collision in actor.box.find_children("*","CollisionShape3D",true,false):collision.disabled=true
			actor.pace=1.55 if index==0 else 1.1 if identity in ["Zirico","Bryan"] else 1.15
			var nameplate:=Label3D.new();actor.add_child(nameplate);nameplate.text="Deryk" if identity=="Dery" else "Garota 1" if identity=="Garota1" else "Garota 2" if identity=="Garota2" else "Cliente" if identity=="Customer2" else identity
			nameplate.position.y=float(actor.visual.get_meta("height_m",1.78))+.12;nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED;nameplate.font_size=25;nameplate.pixel_size=.0035
			members.append(actor)
		group.hide();group.process_mode=Node.PROCESS_MODE_DISABLED;actors.append(members)
	camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=42
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(32,24);caption.add_theme_font_size_override("font_size",22)
	caption.add_theme_font_override("font",preload("res://assets/fonts/title/retro/SpecialElite-Regular.ttf"));caption.add_theme_color_override("font_color",Color("eee3c8"))
	caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_y",2)
	set_page(0)
func set_page(index: int) -> void:
	if page>=0:groups[page].hide();groups[page].process_mode=Node.PROCESS_MODE_DISABLED
	page=index;groups[page].show();groups[page].process_mode=Node.PROCESS_MODE_INHERIT
func _physics_process(delta: float) -> void:
	elapsed+=delta
	var index:=mini(GROUPS.size()-1,int(elapsed/6.0))
	if index!=page:set_page(index)
	var local:=fmod(elapsed,6.0)
	var mode:="idle" if local<1.4 else "walk" if local<5.2 else "talk"
	if page==0:mode="idle" if local<1 else "walk" if local<3.3 else "run" if local<4.5 else "carry_walk"
	if page==3:mode="idle" if local<1 else "fidget" if local<2.4 else "walk" if local<5.2 else "talk"
	for actor in actors[page]:actor.mode=mode
	if not output.is_empty() and local>=2.7 and not saved.has(page):saved[page]=true;call_deferred("capture",str(page))
	if elapsed>=30:set_physics_process(false);call_deferred("finish")
func _process(_delta: float) -> void:
	if page<0:return
	var focus:=Vector3.ZERO
	for actor in actors[page]:focus+=actor.position
	focus/=actors[page].size()
	var child:=page==3
	var distance:=6.4 if actors[page].size()>2 else 5.0 if actors[page].size()>1 else 3.8
	var angle:=deg_to_rad(18.0+48.0*smoothstep(0,6.0,fmod(elapsed,6.0)))
	camera.position=focus+Vector3(sin(angle)*distance,1.2 if child else 1.45,cos(angle)*distance)
	camera.look_at(focus+Vector3.UP*(.66 if child else .91))
	caption.text="0.26.0  /  "+HEADINGS[page]+"\n"+{"idle":"Repouso","walk":"Caminhada real","run":"Corrida","carry_walk":"Transporte","talk":"Conversa","fidget":"Gesto inquieto"}.get(actors[page][0].mode,"")
func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/profile_"+id+".png");print("LOCOMOTION CAPTURE ",id)
func finish() -> void:
	set_process(false)
	for group in groups:group.queue_free()
	for frame in 5:await get_tree().process_frame
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
