extends Node
var checks := 0
var failures: Array[String] = []
var app: Node

func check(condition: bool,description: String) -> void:
	checks += 1
	print("PASS " if condition else "FAIL ",description)
	if not condition: failures.append(description)

func frames(count := 3) -> void:
	for i in count: await get_tree().process_frame

func mode(ps1: bool,high := false,scale := 2,vertices := 1,affine := 1) -> void:
	Preferences.ps1_mode=ps1;Preferences.ps1_high_resolution=high;Preferences.pixel_scale=scale
	Preferences.psx_vertices=vertices;Preferences.psx_affine=affine;Preferences.apply()
	await frames()

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func run() -> void:
	Preferences.frame_limit=0
	check(Preferences.psx_vertices==1 and Preferences.psx_affine==1,"preferências antigas recebem intensidade Suave por padrão")
	await mode(false,false,1)
	Session.new_shift()
	app=load("res://scenes/main/main.tscn").instantiate();add_child(app)
	await frames()
	var settings:=SettingsPanel.new();add_child(settings)
	var vertices: OptionButton=settings.find_child("PSXVertices",true,false)
	var affine: OptionButton=settings.find_child("PSXAffine",true,false)
	check(vertices!=null and affine!=null,"Configurações expõe os dois efeitos separadamente")
	check(vertices.item_count==3 and vertices.get_item_text(0)=="Desligada" and vertices.get_item_text(1)=="Suave" and vertices.get_item_text(2)=="Marcada","cada efeito oferece Desligada, Suave e Marcada")
	settings.queue_free()
	var mesh: MeshInstance3D=app.world.depot.find_children("*","MeshInstance3D",true,false)[0]
	var geometry: Mesh=mesh.mesh
	var original: Material=mesh.material_override
	var position: Vector3=app.world.player.position
	var collision: Array[Node]=app.world.find_children("*","CollisionShape3D",true,false)
	var shapes:=[]
	for node in collision: shapes.append(node.shape)
	var skeleton: Skeleton3D=app.world.characters.Dery.find_children("*","Skeleton3D",true,false)[0]
	var bones:=skeleton.get_bone_count()
	var animator: AnimationPlayer=app.world.characters.Dery.find_children("*","AnimationPlayer",true,false)[0]
	var animations:=animator.get_animation_list()
	await mode(true)
	check(app.viewport.size==Vector2i(320,240),"PS1 mantém cenário em 320×240")
	check(app.interface.get_viewport()==get_viewport() and app.interface.get_viewport()!=app.viewport,"HUD continua no viewport em resolução plena")
	check(not app.psx.bindings.is_empty(),"PS1 aplica efeitos às superfícies do cenário")
	var adapted: ShaderMaterial=mesh.material_override
	check(adapted!=null and adapted.get_shader_parameter("snap_pixels")==.5,"Suave usa grade de meio pixel para vértices")
	check(adapted.get_shader_parameter("affine_strength")==.35,"Suave mistura interpolação afim a 35%")
	await mode(true,false,2,2,2);adapted=mesh.material_override
	check(adapted.get_shader_parameter("snap_pixels")==1.5 and adapted.get_shader_parameter("affine_strength")==1.0,"Marcada usa grade de 1,5 pixel e interpolação afim completa")
	await mode(true,false,2,0,2);adapted=mesh.material_override
	check(adapted.get_shader_parameter("snap_pixels")==0.0 and adapted.get_shader_parameter("affine_strength")==1.0,"precisão desligada preserva a seleção de texturas afins")
	await mode(true,false,2,2,0);adapted=mesh.material_override
	check(adapted.get_shader_parameter("snap_pixels")==1.5 and adapted.get_shader_parameter("affine_strength")==0.0,"texturas afins desligadas preservam a precisão selecionada")
	await mode(true,false,2,0,0)
	check(mesh.material_override==original and app.psx.bindings.is_empty(),"desligar os dois efeitos restaura os materiais originais")
	await mode(true,true)
	check(app.viewport.size==Vector2i(640,480),"PS1/2 mantém cenário em 640×480")
	check(mesh.material_override is ShaderMaterial and not app.psx.bindings.is_empty(),"PS1/2 recebe os mesmos efeitos 3D")
	await mode(false,false,1)
	check(mesh.material_override==original,"Nítida restaura o material original")
	await mode(false,false,2)
	check(mesh.material_override==original,"Retrô restaura o material original")
	await mode(false,false,3)
	check(mesh.material_override==original,"Econômica restaura o material original")
	await mode(true)
	check(mesh.mesh==geometry,"efeitos não reconstroem nem modificam a geometria")
	check(skeleton.get_bone_count()==bones and animator.get_animation_list()==animations,"rig e animações publicados permanecem intactos")
	var unchanged: bool=position==app.world.player.position
	for i in collision.size(): unchanged=unchanged and collision[i].shape==shapes[i]
	check(unchanged,"trocas de intensidade preservam posição e formas de colisão")
	var power: FridayShift=app.world.friday
	var emitter: StandardMaterial3D=power.emitters[0]
	var live: ShaderMaterial=app.psx.adapters[emitter.get_instance_id()].material
	check(emitter.emission_enabled and live.get_shader_parameter("glow_energy")>0,"salão energizado mantém emissão no material adaptado")
	Session.campaign.phase="outage";power.apply_power();await frames(5)
	live=app.psx.adapters[emitter.get_instance_id()].material
	check(not emitter.emission_enabled and live.get_shader_parameter("glow_energy")==0.0,"apagão desliga a emissão original e a adaptada")
	check(power.batteries[0].visible and not power.lights[0].get_meta("circuit_on"),"apagão preserva circuitos de luz e baterias")
	Session.campaign.phase="restored";power.apply_power();await frames(5)
	live=app.psx.adapters[emitter.get_instance_id()].material
	check(emitter.emission_enabled and live.get_shader_parameter("glow_energy")>0 and not power.batteries[0].visible,"restabelecer energia religa materiais e desliga baterias")
	var replacement:=Geo.material(Color("79b570"),"",.45)
	mesh.material_override=replacement;await frames(5)
	await mode(false,false,1)
	check(mesh.material_override==replacement,"atribuição de material durante jogo é preservada ao sair de PS1")
	await mode(true)
	var preview:=StandardMaterial3D.new();preview.albedo_color=Color(.32,.85,.48,.8)
	var added:=Geo.box(app.world,Vector3(0,10,0),Vector3.ONE,preview,false);await frames(5)
	preview.albedo_color=Color(.95,.28,.20,.8);await frames(3)
	check(added.material_override is ShaderMaterial and added.material_override.get_shader_parameter("base_color")==preview.albedo_color,"objetos novos recebem efeitos e marcador de apoio acompanha a cor válida/bloqueada")
	app.build_world();await frames(5)
	check(app.psx.root==app.world and not app.psx.bindings.is_empty() and not app.world.friday.emitters.is_empty(),"reconstruir o mundo renova efeitos e circuitos")
	Preferences.psx_vertices=2;Preferences.psx_affine=0;Preferences.save()
	var saved:=ConfigFile.new();saved.load("user://settings.cfg")
	check(saved.get_value("settings","psx_vertices")==2 and saved.get_value("settings","psx_affine")==0,"intensidades independentes persistem em settings.cfg")
	app.queue_free();await frames(5)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	print("PSX RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
