class_name SceneDetail
extends RefCounted
const ART:="res://assets/textures/details/"
static func material(id: String,color:=Color.WHITE,emission:=0.0) -> StandardMaterial3D:
	var m:=Geo.material(color,ART+id+".png",emission)
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m
static func panel(parent: Node3D,at: Vector3,size: Vector2,id: String,angle:=0.0,emission:=0.0) -> MeshInstance3D:
	var m:=StandardMaterial3D.new();m.albedo_texture=load(ART+id+".png");m.roughness=.82
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if emission>0:m.emission_enabled=true;m.emission_texture=m.albedo_texture;m.emission=Color.WHITE;m.emission_energy_multiplier=emission
	var node:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=size;node.mesh=mesh;node.material_override=m;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node);node.position=at;node.rotation.y=angle
	return node
static func decal(parent: Node3D,at: Vector3,size: Vector2,id: String,angle:=0.0) -> void:
	var node:=panel(parent,at,size,id);node.rotation=Vector3(-PI/2,angle,0)
	node.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
