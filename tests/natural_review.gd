extends Node3D
## Actual animated skeletons. Old exported walk beside the new measured walk.
class ReviewActor extends Node3D:
	var visual: Node3D
	var motion: LivingMotion
	var socket: Node3D
var actors: Array[Node3D]=[]
var boxes: Array[Node3D]=[]
var motions: Array[LivingMotion]=[]
var camera: Camera3D
var caption: Label
var frames:=0
var saved: Array[String]=[]
func _ready() -> void:
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("4e5556");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d4d4c9");env.environment.ambient_light_energy=.8;add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-25,0);light.light_energy=1.5;add_child(light)
	Geo.box(self,Vector3(0,-.06,15),Vector3(30,.12,60),Geo.material(Color("79817d")))
	for i in 4:
		var actor:=ReviewActor.new();actor.position=Vector3((i-1.5)*1.35,0,0);add_child(actor)
		var identity: String="Dery" if i<2 else "Felps"
		var visual:=CharacterModels.create(identity);actor.visual=visual;actor.add_child(visual)
		var motion:=LivingMotion.new();actor.add_child(motion);motion.setup(visual,actor);actor.motion=motion
		actor.socket=Node3D.new();actor.add_child(actor.socket)
		var grip:=BoxHandling.new();actor.add_child(grip);grip.setup(actor);motion.pose_updated.connect(grip.sync_grip)
		var box: Node3D=load("res://scenes/world/props/crate.tscn").instantiate();actor.socket.add_child(box);box.position=Vector3(0,-.23,0);box.hide();boxes.append(box)
		if i%2==0:
			for clip in motion.clips.keys():
				if motion.animator.has_animation(clip):motion.clips[clip]=clip
			motion.strides={"walk":1.12,"run":2.35,"carry_walk":.86,"crouch_walk":.62};motion.feet.active=false;motion.detail.active=false
			for key in motion.strides:motion.strides[key]*=float(visual.get_meta("stride_scale",1.0))
			motion.current_clip="";motion.play("idle",0)
		var text:=Geo.sign_text(actor,("ANTERIOR" if i%2==0 else "NOVA")+" • "+identity,Vector3(0,2.05,0),25);text.pixel_size=.0035;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		actors.append(actor);motions.append(motion)
	camera=Camera3D.new();camera.fov=40;add_child(camera)
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(30,25);caption.add_theme_font_size_override("font_size",22)
func _physics_process(delta: float) -> void:
	frames+=1
	var seconds:=13.0 if OS.get_cmdline_user_args().has("crouch-only") else frames/60.0
	var clip: String="idle" if seconds<2 else "walk" if seconds<6 else "run" if seconds<9 else "carry_walk" if seconds<12 else "crouch_walk"
	var speed: float=0 if clip=="idle" else 1.55 if clip=="walk" else 3.9 if clip=="run" else 1.15 if clip=="carry_walk" else .85
	for i in actors.size():
		boxes[i].visible=clip=="carry_walk"
		actors[i].position.z+=speed*delta;motions[i].locomotion(delta,speed,clip=="crouch_walk",clip=="carry_walk",false)
	var center: Vector3=(actors[0].position+actors[3].position)*.5
	camera.position=center+Vector3(2.0,1.45,5.2);camera.look_at(center+Vector3.UP*.95)
	caption.text="Comparação • "+clip+" • antes / nova • Deryk e Felps"
	if frames>=(120 if OS.get_cmdline_user_args().has("crouch-only") else 900):call_deferred("finish");set_physics_process(false)
func _process(_delta: float) -> void:
	var key: String="crouch" if OS.get_cmdline_user_args().has("crouch-only") and frames in range(60,66) else "idle" if frames in range(60,66) else "walk" if frames in range(200,206) else "run" if frames in range(430,436) else "carry" if frames in range(620,626) else "crouch" if frames in range(800,806) else ""
	if key.is_empty() or key in saved:return
	saved.append(key);call_deferred("capture",key)
func capture(key: String) -> void:
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("REVIEW_OUTPUT_DIR");DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder.path_join(key+".png"));print("NATURAL_CAPTURE ",key)
func finish() -> void:
	for actor in actors:actor.queue_free()
	await get_tree().process_frame;Geo.materials.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit()
