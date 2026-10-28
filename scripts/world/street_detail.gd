class_name StreetDetail
extends RefCounted
const ART:="res://assets/textures/street/"
static var cube: BoxMesh
static var sphere: SphereMesh
static func material(color: Color,art: String="",scale_value:=.7) -> StandardMaterial3D:
	var path:=ART+art+".png" if not art.is_empty() else ""
	if art in ["asphalt","render","sidewalk"]:path="res://assets/textures/mood/"+{"asphalt":"asphalt","render":"plaster","sidewalk":"paving"}[art]+".png"
	var m:=Geo.material(color,path)
	m.uv1_scale=Vector3.ONE*scale_value;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m
static func panel(parent: Node3D,at: Vector3,size: Vector2,art: String,angle:=0.0,cutout:=false) -> MeshInstance3D:
	var m:=StandardMaterial3D.new();m.albedo_texture=load(ART+art+".png");m.roughness=.95;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if cutout:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;m.alpha_scissor_threshold=.3
	var node:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=size;node.mesh=mesh;node.material_override=m;parent.add_child(node);node.position=at;node.rotation.y=angle
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
static func text(parent: Node3D,words: String,at: Vector3,size:=40,color:=Color("e8e7dc")) -> Label3D:
	var label:=Geo.sign_text(parent,words,at,size,color);label.pixel_size=.006;return label
static func rotated_box(batch: PropBatch,at: Vector3,size: Vector3,rotation: Vector3,mat: Material) -> void:
	if cube==null:cube=BoxMesh.new();cube.size=Vector3.ONE
	var basis:=Basis.from_euler(rotation)
	basis=Basis(basis.x*size.x,basis.y*size.y,basis.z*size.z)
	batch.add_instance("rot_"+str(mat.get_instance_id()),cube,mat,Transform3D(basis,at))
static func beam(batch: PropBatch,a: Vector3,b: Vector3,width: float,mat: Material) -> void:
	if cube==null:cube=BoxMesh.new();cube.size=Vector3.ONE
	var direction:=b-a
	var basis:=Basis.looking_at(direction.normalized(),Vector3.UP if absf(direction.normalized().y)<.98 else Vector3.RIGHT)
	basis=Basis(basis.x*width,basis.y*width,basis.z*direction.length())
	batch.add_instance("beam_"+str(mat.get_instance_id()),cube,mat,Transform3D(basis,(a+b)*.5))
static func leaf(batch: PropBatch,at: Vector3,size: Vector3,mat: Material) -> void:
	if sphere==null:sphere=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=6;sphere.rings=3
	batch.add_instance("leaf_"+str(mat.get_instance_id()),sphere,mat,Transform3D(Basis.IDENTITY.scaled(size),at))
static func triangle(parent: Node3D,a: Vector3,b: Vector3,c: Vector3,mat: Material) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal: Vector3=(b-a).cross(c-a).normalized()
	for p in [a,c,b]:st.set_normal(normal);st.add_vertex(p)
	var node:=MeshInstance3D.new();node.mesh=st.commit();node.material_override=mat;parent.add_child(node)
static func gate(batch: PropBatch,at: Vector3,width: float,height: float,color: Color,bars:=false) -> void:
	var metal:=material(color,"gate")
	if not bars:batch.add_box(at,Vector3(width,height,.09),metal)
	else:
		batch.add_box(at+Vector3(0,0,-.07),Vector3(width,height,.04),material(Color("454b42")))
		for i in range(ceili(width/.13)+1):batch.add_box(at+Vector3(-width*.5+i*.13,0,.015),Vector3(.025,height,.03),metal)
	for x in [-width*.5,width*.5]:batch.add_box(at+Vector3(x,0,.06),Vector3(.045,height+.05,.035),metal)
	for y in [-height*.5,height*.5,0]:batch.add_box(at+Vector3(0,y,.06),Vector3(width,.045,.035),metal)
	batch.add_box(at+Vector3(width*.28,0,.09),Vector3(.04,.12,.03),material(Color("4a5048")))
static func window(batch: PropBatch,at: Vector3,size: Vector2,warm:=false) -> void:
	var frame:=material(Color("c1bd9e"));var iron:=material(Color("777c70"))
	batch.add_box(at,Vector3(size.x+.12,size.y+.12,.07),frame)
	batch.add_box(at+Vector3(0,0,.045),Vector3(size.x,size.y,.015),Geo.material(Color("615e48") if warm else Color("394947"),"",.10 if warm else 0.0))
	for i in 5:batch.add_box(at+Vector3(0,-size.y*.5+i*size.y/4,.09),Vector3(size.x+.04,.024,.025),iron)
	for x in [-size.x*.35,0,size.x*.35]:batch.add_box(at+Vector3(x,0,.085),Vector3(.02,size.y,.025),iron)
