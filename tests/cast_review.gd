extends Node3D
## Render the actual imported skins, authored clips and live box socket.
class Actor extends Node3D:
	var visual: Node3D
	var motion: LivingMotion
	var socket: Node3D
var actors: Array[Actor] = []
var camera: Camera3D
var label: Label
var frame:=0
var prefix:="cast"
var boxes: Array[Node3D] = []
const IDS=["Dery","Felps","Bryan","Zirico","Garota1","Garota2","Velha1","Enemy"]
func _ready() -> void:
	if OS.get_cmdline_user_args().size()>0:prefix=OS.get_cmdline_user_args()[0]
	Preferences.pixel_scale=1
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("283238");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d8e1df");env.environment.ambient_light_energy=.7;add_child(env)
	var light:=DirectionalLight3D.new();add_child(light);light.rotation_degrees=Vector3(-38,-24,0);light.light_energy=1.05;light.shadow_enabled=true
	Geo.box(self,Vector3(0,-.12,0),Vector3(40,.24,40),Geo.material(Color("626a66")))
	for i in IDS.size():
		var actor:=Actor.new();add_child(actor);actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		actor.visual=CharacterModels.create(IDS[i]);actor.add_child(actor.visual)
		actor.motion=LivingMotion.new();actor.add_child(actor.motion);actor.motion.setup(actor.visual,actor);actor.motion.animator.speed_scale=0
		actor.socket=Node3D.new();actor.add_child(actor.socket)
		var grip:=BoxHandling.new();actor.add_child(grip);grip.setup(actor);actor.motion.pose_updated.connect(grip.sync_grip)
		var box: Node3D=load("res://scenes/world/props/crate.tscn").instantiate();actor.socket.add_child(box);box.position=Vector3(0,-.23,0);box.hide();boxes.append(box)
		actor.position=Vector3(-.65+i*1.3,0,0);actor.visible=i<2;actors.append(actor)
	camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=40
	var ui:=CanvasLayer.new();add_child(ui);label=Label.new();ui.add_child(label);label.position=Vector2(24,18);label.add_theme_font_size_override("font_size",21)
	view(Vector3(0,1.1,4.6),Vector3(0,.94,0));label.text="Novos Dery e Felps • rig recebido / repouso"
func view(at: Vector3,target: Vector3) -> void:
	camera.position=at;camera.look_at(target)
func pose(clip: String,phase: float) -> void:
	for actor in actors:
		if not actor.motion.clips.has(clip):continue
		actor.motion.play(clip,0);actor.motion.animator.speed_scale=0
		actor.motion.animator.seek(actor.motion.animator.current_animation_length*phase,true);actor.motion.animator.advance(0)
func _process(_delta: float) -> void:
	frame+=1
	match frame:
		10:pose("idle",.15)
		20:call_deferred("capture","pair_idle")
		25:view(Vector3(3.8,1.15,2.5),Vector3(0,.95,0))
		35:call_deferred("capture","pair_side")
		40:
			view(Vector3(0,1.1,4.7),Vector3(0,.94,0));pose("carry",.15)
			for i in 2:boxes[i].show()
			label.text="Transporte • caixa ligada às mãos"
		50:call_deferred("capture","pair_carry")
		55:
			for box in boxes:box.hide()
			pose("walk",.20);label.text="Caminhada • transferência de peso"
		65:call_deferred("capture","pair_walk")
		70:pose("run",.18);label.text="Corrida"
		80:call_deferred("capture","pair_run")
		85:
			pose("idle",.2);label.text="Dery / Felps / Bryan / Zirico / Garotas / Velha / Killer"
			for i in actors.size():actors[i].show();actors[i].position.x=(i-3.5)*1.08
			view(Vector3(0,2.4,12),Vector3(0,.9,0))
		95:call_deferred("capture","lineup")
		100:
			for i in actors.size():actors[i].visible=i==2 or i==3
			actors[2].position.x=-.6;actors[3].position.x=.6
			view(Vector3(0,1.0,4.8),Vector3(0,.86,0));pose("talk",.34);label.text="Bryan e Zirico • conversa"
		110:call_deferred("capture","friends")
		120:call_deferred("finish")
func finish() -> void:
	for child in get_children():child.queue_free()
	actors.clear();boxes.clear()
	for i in 5:await get_tree().process_frame
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear()
	for i in 4:await get_tree().process_frame
	get_tree().quit()
func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var path:="/tmp/"+prefix+"_"+id+".png"
	get_viewport().get_texture().get_image().save_png(path);print("CAPTURE ",path)
