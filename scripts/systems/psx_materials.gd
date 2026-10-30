class_name PSXMaterials
extends Node
## View-only material adapters. Gameplay keeps the original resources and meshes.
## In particular FridayShift owns the original emissive materials throughout outages.
var root: Node
var bindings: Array[Dictionary] = []
var adapters: Dictionary = {}
var shaders: Dictionary = {}
var scan_pending := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(on_node_added)
	Preferences.changed.connect(refresh)
	refresh()

func enabled() -> bool:
	return Preferences.ps1_mode and (Preferences.psx_vertices > 0 or Preferences.psx_affine > 0)

func on_node_added(node: Node) -> void:
	if root != null and node is MeshInstance3D and root.is_ancestor_of(node) and enabled() and not scan_pending:
		scan_pending = true
		call_deferred("refresh")

func restore() -> void:
	for item in bindings:
		if not is_instance_valid(item.node): continue
		# A circuit or interaction may have assigned a newer original since binding.
		if item.surface < 0:
			if item.node.material_override == item.adapted: item.node.material_override = item.original
		elif item.node.get_surface_override_material(item.surface) == item.adapted:
			item.node.set_surface_override_material(item.surface,item.original)
	bindings.clear()
	adapters.clear()

func refresh() -> void:
	scan_pending = false
	restore()
	if root == null or not is_instance_valid(root) or not enabled():
		set_process(false)
		return
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		if mesh.material_override != null:
			bind_material(mesh,-1,mesh.material_override,mesh.material_override)
		else:
			for surface in mesh.mesh.get_surface_count():
				bind_material(mesh,surface,mesh.get_surface_override_material(surface),mesh.get_active_material(surface))
	for entry in adapters.values(): sync_material(entry)
	set_process(true)

func bind_material(mesh: MeshInstance3D,surface: int,original: Material,source: Material) -> void:
	if not source is StandardMaterial3D and not source is ShaderMaterial: return
	# Keep camera-facing light halos on the engine's billboard path.
	if source is StandardMaterial3D and source.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED: return
	# Haze is a translucent atmospheric volume; leave its native shader intact.
	if source is ShaderMaterial and source.shader.resource_path.ends_with("street_haze.gdshader"): return
	var id := source.get_instance_id()
	if not adapters.has(id):
		var adapted := ShaderMaterial.new()
		adapted.shader = make_shader(source)
		if adapted.shader == null: return
		adapted.render_priority = source.render_priority
		adapters[id] = {"source":source,"material":adapted}
	var adapted: ShaderMaterial = adapters[id].material
	bindings.append({"node":mesh,"surface":surface,"original":original,"adapted":adapted})
	if surface < 0: mesh.material_override = adapted
	else: mesh.set_surface_override_material(surface,adapted)

func make_shader(source: Material) -> Shader:
	var code: String
	if source is StandardMaterial3D:
		code = FileAccess.get_file_as_string("res://shaders/psx_surface.gdshader")
		var modes := "diffuse_burley, specular_schlick_ggx"
		if source.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED: modes += ", unshaded"
		if source.cull_mode == BaseMaterial3D.CULL_DISABLED: modes += ", cull_disabled"
		elif source.cull_mode == BaseMaterial3D.CULL_FRONT: modes += ", cull_front"
		if source.blend_mode == BaseMaterial3D.BLEND_MODE_ADD: modes += ", blend_add"
		var alpha_line := "if (alpha_scissor) { ALPHA = color.a; ALPHA_SCISSOR_THRESHOLD = alpha_threshold; }"
		if source.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			code = code.replace(alpha_line,"ALPHA = color.a;" if source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA else "")
		code = code.replace("diffuse_burley, specular_schlick_ggx;",modes+";")
		if source.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST,BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS]:
			code = code.replace("filter_linear_mipmap","filter_nearest_mipmap" if source.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS else "filter_nearest")
	else:
		# Preserve the sign art and foliage wind shader, adding only clip snapping / UV interpolation.
		code = source.shader.code
		var world_coords := code.contains("world_vertex_coords")
		var fragment_start := code.find("void fragment(){")
		code = code.substr(0,fragment_start)+code.substr(fragment_start).replace("UV","psx_sample_uv")
		code = code.replace("void fragment(){","void fragment(){\n vec2 psx_delta=psx_uv/max(psx_w,0.0001)-UV;\n float psx_limit=max(affine_limit,0.00001);\n psx_delta*=inversesqrt(1.0+dot(psx_delta,psx_delta)/(psx_limit*psx_limit));\n vec2 psx_sample_uv=UV+psx_delta*affine_strength;\n")
		var body := "\n vec4 psx_clip=PROJECTION_MATRIX*"+("VIEW_MATRIX" if world_coords else "MODELVIEW_MATRIX")+"*vec4(VERTEX,1.0);\n psx_w=psx_clip.w;psx_uv=UV*psx_w;\n if(snap_pixels>0.0 && psx_clip.w>0.01){vec2 grid=VIEWPORT_SIZE/(2.0*snap_pixels);psx_clip.xy=floor(psx_clip.xy/psx_clip.w*grid+0.5)/grid*psx_clip.w;}\n POSITION=psx_clip;\n"
		var start := code.find("void vertex(){")
		if start < 0: code += "\nvoid vertex(){"+body+"}\n"
		else:
			var end := code.find("}",start)
			code = code.insert(end,body)
		code = code.replace("shader_type spatial;","shader_type spatial;\nuniform float snap_pixels=0.5;uniform float affine_strength=0.35;uniform float affine_limit=0.008;varying vec2 psx_uv;varying float psx_w;")
	if not shaders.has(code):
		var shader := Shader.new();shader.code = code;shaders[code] = shader
	return shaders[code]

func channel(index: int) -> Vector4:
	if index == BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE: return Vector4(.333333,.333333,.333333,0)
	var mask := Vector4.ZERO;mask[clampi(index,0,3)] = 1.0;return mask

func sync_material(entry: Dictionary) -> void:
	var source: Material = entry.source
	var mat: ShaderMaterial = entry.material
	mat.set_shader_parameter("snap_pixels",[0.0,0.5,1.5][Preferences.psx_vertices])
	mat.set_shader_parameter("affine_strength",[0.0,0.35,1.0][Preferences.psx_affine])
	mat.set_shader_parameter("affine_limit",[0.0,0.008,0.02][Preferences.psx_affine])
	if source is ShaderMaterial:
		for parameter in source.shader.get_shader_uniform_list(): mat.set_shader_parameter(parameter.name,source.get_shader_parameter(parameter.name))
		return
	mat.set_shader_parameter("base_color",source.albedo_color)
	mat.set_shader_parameter("base_texture",source.albedo_texture)
	mat.set_shader_parameter("has_base",source.albedo_texture != null)
	mat.set_shader_parameter("vertex_color",source.vertex_color_use_as_albedo)
	mat.set_shader_parameter("uv_scale",source.uv1_scale)
	mat.set_shader_parameter("uv_offset",source.uv1_offset)
	mat.set_shader_parameter("triplanar",source.uv1_triplanar)
	mat.set_shader_parameter("world_triplanar",source.uv1_world_triplanar)
	mat.set_shader_parameter("triplanar_sharpness",source.uv1_triplanar_sharpness)
	mat.set_shader_parameter("surface_roughness",source.roughness)
	mat.set_shader_parameter("surface_metallic",source.metallic)
	mat.set_shader_parameter("surface_specular",source.metallic_specular)
	for kind in ["roughness","metallic"]:
		mat.set_shader_parameter(kind+"_texture",source.get(kind+"_texture"))
		mat.set_shader_parameter("has_"+kind,source.get(kind+"_texture") != null)
		mat.set_shader_parameter(kind+"_channel",channel(source.get(kind+"_texture_channel")))
	mat.set_shader_parameter("has_occlusion",source.ao_enabled and source.ao_texture != null)
	mat.set_shader_parameter("occlusion_texture",source.ao_texture)
	mat.set_shader_parameter("occlusion_channel",channel(source.ao_texture_channel))
	mat.set_shader_parameter("occlusion_light_affect",source.ao_light_affect)
	mat.set_shader_parameter("has_normal",source.normal_enabled and source.normal_texture != null)
	mat.set_shader_parameter("normal_texture",source.normal_texture)
	mat.set_shader_parameter("normal_depth",source.normal_scale)
	mat.set_shader_parameter("glow_color",source.emission)
	mat.set_shader_parameter("glow_texture",source.emission_texture)
	mat.set_shader_parameter("has_glow_texture",source.emission_texture != null)
	mat.set_shader_parameter("alpha_scissor",source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
	mat.set_shader_parameter("alpha_threshold",source.alpha_scissor_threshold)
	mat.set_shader_parameter("coat",source.clearcoat if source.clearcoat_enabled else 0.0)
	mat.set_shader_parameter("coat_roughness",source.clearcoat_roughness)
	sync_live(entry)

func sync_live(entry: Dictionary) -> void:
	var source: Material = entry.source
	if source is StandardMaterial3D:
		# Box placement updates its green/red tint without assigning a new material.
		if entry.get("live_color") != source.albedo_color:
			entry.material.set_shader_parameter("base_color",source.albedo_color)
			entry.live_color = source.albedo_color
		if entry.get("live_glow_color") != source.emission:
			entry.material.set_shader_parameter("glow_color",source.emission)
			entry.live_glow_color = source.emission
		var energy: float = source.emission_energy_multiplier if source.emission_enabled else 0.0
		if entry.get("live_energy") != energy:
			entry.material.set_shader_parameter("glow_energy",energy)
			entry.live_energy = energy
	else:
		for parameter in source.shader.get_shader_uniform_list(): entry.material.set_shader_parameter(parameter.name,source.get_shader_parameter(parameter.name))

func _process(_delta: float) -> void:
	for entry in adapters.values(): sync_live(entry)
	for item in bindings:
		if not is_instance_valid(item.node): continue
		var current: Material = item.node.material_override if item.surface < 0 else item.node.get_surface_override_material(item.surface)
		if current != item.adapted and not scan_pending:
			scan_pending = true
			call_deferred("refresh")

func _exit_tree() -> void:
	restore()
