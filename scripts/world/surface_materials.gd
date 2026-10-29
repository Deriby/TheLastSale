class_name SurfaceMaterials
extends RefCounted
## Metric original surface maps. Cache includes scale/tint; settings never leak
## between independent fixtures. Shared Geo cache already has scene QA cleanup.
const ART:="res://assets/textures/surfaces/"
const METERS:={"wood":2.4,"ceramic":2.4,"wall":2.8,"plaster":2.8,"asphalt":4.0,"paving":2.0,"painted_metal":.85,"steel":.6,"plastic":.6,"rubber":.5,"carpaint":1.2,"glass":1.4}
static func make(id: String,tint:=Color.WHITE,two_sided:=false) -> StandardMaterial3D:
	var key:="surface:"+id+str(tint)+str(two_sided)
	if Geo.materials.has(key):return Geo.materials[key]
	var mat:=StandardMaterial3D.new();mat.albedo_color=tint
	mat.albedo_texture=load(ART+id+"_albedo.png")
	configure(mat,id)
	if two_sided:mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	Geo.materials[key]=mat
	return mat
static func configure(mat: StandardMaterial3D,id: String) -> void:
	var orm: Texture2D=load(ART+id+"_orm.png")
	mat.roughness=1;mat.roughness_texture=orm;mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic=1;mat.metallic_texture=orm;mat.metallic_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.ao_texture=orm;mat.ao_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;mat.ao_light_affect=0
	mat.normal_texture=load(ART+id+"_normal.png");mat.normal_scale=.65 if id in ["wall","glass","carpaint"] else 1.0
	mat.uv1_triplanar=id!="wood";mat.uv1_world_triplanar=id!="wood";mat.uv1_scale=Vector3.ONE/float(METERS[id])
	if id=="wood":mat.uv1_scale=Vector3.ONE
	mat.set_meta("surface_profile",id)
	quality(mat)
static func quality(mat: StandardMaterial3D) -> void:
	var detailed:=Preferences.pixel_scale<3
	mat.normal_enabled=detailed and mat.get_meta("surface_profile","")!="glass"
	mat.ao_enabled=detailed
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC if detailed else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
static func apply_quality() -> void:
	for mat in Geo.materials.values():
		if mat is StandardMaterial3D and mat.has_meta("surface_profile"):quality(mat)
static func wood_box_mesh(size: Vector3) -> ArrayMesh:
	# UVs are in metres, and the grain follows the long local X axis. Baking a
	# fixture into a PropBatch retains the same UVs as its independent reference.
	var box:=BoxMesh.new();box.size=size
	var arrays:=box.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var uv:=PackedVector2Array()
	for i in vertices.size():
		var p:=vertices[i];var n:=normals[i]
		var coordinate:=Vector2(p.z,p.y) if absf(n.x)>.5 else Vector2(p.x,p.z if absf(n.y)>.5 else p.y)
		uv.append(coordinate/Vector2(2.4,1.2)+Vector2(.37,.16))
	arrays[Mesh.ARRAY_TEX_UV]=uv
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tool:=SurfaceTool.new();tool.create_from(mesh,0);tool.generate_tangents();return tool.commit()
static func wood_box(batch: PropBatch,at: Vector3,size: Vector3,mat: Material) -> void:
	batch.add_instance("wood:"+str(at),wood_box_mesh(size),mat,Transform3D(Basis.IDENTITY,at))
