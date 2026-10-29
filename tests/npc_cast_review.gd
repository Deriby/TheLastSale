extends Node3D
## Visual check for temporary skins; behavior remains the real Customer controller.
var animators: Array[AnimationPlayer]=[]
var frame:=0
func _ready() -> void:
	Preferences.pixel_scale=1
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("252f34")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d8e1df");env.environment.ambient_light_energy=.7;add_child(env)
	var light:=DirectionalLight3D.new();add_child(light);light.rotation_degrees=Vector3(-38,-24,0);light.light_energy=1.05
	Geo.box(self,Vector3(0,-.12,-1),Vector3(16,.24,10),Geo.material(Color("626a66")))
	var entries:=NPCCast.customers()
	for i in entries.size():
		var entry: Dictionary=entries[i]
		var model:=CharacterModels.create(entry.id);add_child(model)
		model.position=Vector3((i-1)*2.6,0,-3.4) if i<3 else Vector3((i-5.5)*1.65,0,.25)
		var animator: AnimationPlayer=model.find_child("AnimationPlayer",true,false)
		animators.append(animator)
		var label:=Label3D.new();add_child(label)
		label.text=str(entry.label).replace("Cliente de camiseta ","Camiseta\n").replace("Cliente de ","Cliente\n")
		label.font_size=32;label.pixel_size=.004;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=model.position+Vector3(0,2.12,0);label.modulate=Color("d4c6a4")
	var camera:=Camera3D.new();add_child(camera);camera.current=true;camera.fov=41
	camera.position=Vector3(0,3.4,9.9);camera.look_at(Vector3(0,1.0,-1.0))
	var ui:=CanvasLayer.new();add_child(ui);var heading:=Label.new();ui.add_child(heading)
	heading.position=Vector2(24,18);heading.add_theme_font_size_override("font_size",22)
	heading.text="Elenco • modelos do autor ao fundo / seis clientes provisórios à frente"
func pose(clip: String,phase: float) -> void:
	for animator in animators:
		animator.play(clip,0);animator.speed_scale=0
		animator.seek(animator.current_animation_length*phase,true);animator.advance(0)
func _process(_delta: float) -> void:
	frame+=1
	match frame:
		12:pose("idle",.2)
		24:call_deferred("capture","idle")
		34:pose("walk",.22)
		46:call_deferred("capture","walk")
		60:call_deferred("finish")
func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var path:="/tmp/npc_cast_"+id+".png"
	get_viewport().get_texture().get_image().save_png(path);print("CAPTURE ",path)
func finish() -> void:
	for child in get_children():child.queue_free()
	animators.clear()
	for i in 5:await get_tree().process_frame
	CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();Geo.materials.clear()
	for i in 4:await get_tree().process_frame
	get_tree().quit()
