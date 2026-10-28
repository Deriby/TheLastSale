class_name NeighborhoodLights
extends RefCounted
static func halo(parent: Node3D,at: Vector3,size: float) -> void:
	var mat:=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/textures/mood/lamp_halo.png")
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var quad:=QuadMesh.new();quad.size=Vector2.ONE*size
	var node:=MeshInstance3D.new();node.mesh=quad;node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);node.position=at
static func porch(parent: Node3D,at: Vector3) -> void:
	var iron:=StreetDetail.material(Color("313b39"))
	Geo.box(parent,at,Vector3(.16,.21,.13),iron,false)
	Geo.box(parent,at+Vector3(0,-.05,.075),Vector3(.11,.09,.02),Geo.material(Color("dfc79f"),"",1.4),false)
	var light:=SpotLight3D.new();light.name="PorchLight";parent.add_child(light);light.position=at+Vector3(0,-.1,.12)
	light.look_at_from_position(light.position,at+Vector3(0,-2,.6));light.light_color=Color("e5c898");light.light_energy=1.4;light.spot_range=3.2;light.spot_angle=58
	light.light_cull_mask=2
	halo(parent,at+Vector3(0,-.05,.10),.5)
static func warm_window(parent: Node3D,at: Vector3,size: Vector2) -> void:
	var panel:=mood_panel(parent,at,size,"curtain")
	panel.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	# Set the glow behind the bars; no transparent window sorting or room simulation.
	panel.material_override.albedo_color=Color("c4a078")
static func mood_panel(parent: Node3D,at: Vector3,size: Vector2,id: String) -> MeshInstance3D:
	var mat:=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/textures/mood/"+id+".png");mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var quad:=QuadMesh.new();quad.size=size;var node:=MeshInstance3D.new();node.mesh=quad;node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);node.position=at
	return node
static func wall_wear(parent: Node3D,width: float) -> void:
	var panel:=mood_panel(parent,Vector3(0,.42,.105),Vector2(width,.84),"wall_base")
	panel.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
