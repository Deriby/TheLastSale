extends Node
## Rendered regression: a single large floor crosses the camera/near plane.
## Periodic UV gradients measure movement without discontinuities at texture repeats.
var checks := 0
var failures: Array[String] = []
var measurements: Array[Dictionary] = []
var viewport: SubViewport
var camera: Camera3D
var adapted: ShaderMaterial
var controller: PSXMaterials
var output: String

func check(condition: bool,description: String) -> void:
	checks += 1
	print("PASS " if condition else "FAIL ",description)
	if not condition: failures.append(description)

func frames(count := 3) -> void:
	for i in count: await get_tree().process_frame

func image_at(strength: float) -> Image:
	adapted.set_shader_parameter("affine_strength",strength)
	await frames();await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()

func maximum_error(reference: Image,actual: Image) -> float:
	var error := 0.0
	for y in actual.get_height():
		for x in actual.get_width():
			var a:=actual.get_pixel(x,y);var b:=reference.get_pixel(x,y)
			error=maxf(error,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	return error

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("PSX motion regression requires a rendering display.");get_tree().quit(2);return
	Engine.max_fps=0
	Preferences.frame_limit=0;Preferences.ps1_mode=true;Preferences.psx_vertices=0;Preferences.psx_affine=2
	output=OS.get_environment("PSX_MOTION_PATH")
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(320,240);viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	var stage:=Node3D.new();stage.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;viewport.add_child(stage)
	var gradient:=Image.create(256,256,false,Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:gradient.set_pixel(x,y,Color(.5+.2*sin(TAU*float(x)/256.0),.5+.2*cos(TAU*float(x)/256.0),.5+.2*sin(TAU*float(y)/256.0)))
	var source:=StandardMaterial3D.new();source.albedo_texture=ImageTexture.create_from_image(gradient)
	source.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;source.cull_mode=BaseMaterial3D.CULL_DISABLED
	var floor_mesh:=MeshInstance3D.new();floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(80,80)
	floor_mesh.material_override=source;stage.add_child(floor_mesh)
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.near=.05;camera.fov=70;stage.add_child(camera);camera.current=true
	controller=PSXMaterials.new();controller.root=stage;add_child(controller)
	await frames(5)
	adapted=floor_mesh.material_override
	for mapping in ["uv","world"]:
		source.uv1_triplanar=mapping=="world";source.uv1_world_triplanar=mapping=="world"
		source.uv1_scale=Vector3.ONE/2.4 if mapping=="world" else Vector3.ONE
		for high in [false,true]:
			viewport.size=Vector2i(640,480) if high else Vector2i(320,240)
			for intensity in [1,2]:
				Preferences.psx_affine=intensity;Preferences.psx_vertices=intensity if mapping=="world" else 0;controller.refresh();adapted=floor_mesh.material_override
				var baseline:=OS.get_environment("PSX_MOTION_BASELINE_SHADER")
				if not baseline.is_empty():
					var old_shader:=Shader.new();old_shader.code=FileAccess.get_file_as_string(baseline);adapted.shader=old_shader
				for index in 6:
					var yaw:=deg_to_rad(float([-155,-90,-20,25,95,165][index]))
					camera.position=Vector3(sin(yaw)*1.3,1.7,cos(yaw)*.7)
					camera.look_at(camera.position+Vector3(-sin(yaw),-.65,-cos(yaw)))
					var reference:=await image_at(0.0)
					var actual:=await image_at(.35 if intensity==1 else 1.0)
					var error:=maximum_error(reference,actual)
					measurements.append({"mapping":mapping,"high_resolution":high,"intensity":intensity,"yaw_degrees":rad_to_deg(yaw),"maximum_color_error":error})
					check(error<(.001 if mapping=="world" else (.025 if intensity==1 else .05)),"%s %s %s giro %d: textura estável ao cruzar a câmera (erro %.5f)"%[mapping,"PS1/2" if high else "PS1","Suave" if intensity==1 else "Marcada",index,error])
					if not output.is_empty() and index==2:
						var prefix: String=mapping+("_ps12" if high else "_ps1")
						reference.save_png(output+"/"+prefix+"_reference.png")
						actual.save_png(output+"/"+prefix+("_soft" if intensity==1 else "_strong")+".png")
	if not output.is_empty():
		FileAccess.open(output+"/motion_validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"measurements":measurements},"  "))
	controller.queue_free();viewport.queue_free();await frames()
	print("PSX MOTION RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
