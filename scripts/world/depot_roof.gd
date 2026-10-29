class_name DepotRoof
extends Node3D
## Closed roof slabs and step flashings. Shared heights prevent the old annex gaps.
static func height_at(x: float,z: float) -> float:
	return 4.48 if x< -2.1 and z> -6.0 else 6.0-absf(x)*.09
func _init() -> void:
	name="Roof";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func quad(st: SurfaceTool,p: Array[Vector3]) -> void:
	var n: Vector3=(p[1]-p[0]).cross(p[2]-p[0]).normalized()
	for i in [0,2,1,0,3,2]:st.set_normal(n);st.set_uv(Vector2(p[i].x+p[i].y,p[i].z));st.add_vertex(p[i])
func slab(id: String,points: Array[Vector3],offset: Vector3,mat: Material) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	quad(st,points)
	quad(st,[points[3]+offset,points[2]+offset,points[1]+offset,points[0]+offset])
	for i in 4:
		var next: int=(i+1)%4;quad(st,[points[i],points[i]+offset,points[next]+offset,points[next]])
	var node:=MeshInstance3D.new();node.name=id;node.mesh=st.commit();node.material_override=mat;add_child(node)
	var body:=StaticBody3D.new();node.add_child(body);var col:=CollisionShape3D.new();col.shape=node.mesh.create_trimesh_shape();col.shape.backface_collision=true;body.add_child(col)
func patch(id: String,x0: float,x1: float,z0: float,z1: float,annex: bool,mat: Material) -> void:
	var a:=4.48 if annex else 6.0-absf(x0)*.09;var b:=4.48 if annex else 6.0-absf(x1)*.09
	slab(id,[Vector3(x0,a,z0),Vector3(x0,a,z1),Vector3(x1,b,z1),Vector3(x1,b,z0)],Vector3.DOWN*.10,mat)
func _ready() -> void:
	var roof:=Geo.material(Color("d5d9d4"),"res://assets/textures/depot/roof.png");roof.uv1_scale=Vector3.ONE*.65;roof.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;roof.cull_mode=BaseMaterial3D.CULL_DISABLED
	var steel:=SurfaceMaterials.make("painted_metal",Color("62716e"));var flashing:=SurfaceMaterials.make("steel",Color("899690"))
	patch("MainRightDeck",0,6.12,-16.12,.06,false,roof)
	patch("MainRearLeftDeck",-6.12,0,-16.12,-6,false,roof)
	patch("MainFrontLeftDeck",-2.1,0,-6,.06,false,roof)
	patch("AnnexDeck",-6.12,-2.1,-6,.06,true,roof)
	# Back gable meets the same ridge instead of leaving a triangular opening.
	var gable:=SurfaceTool.new();gable.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [Vector3(-6.0,5.40,-16.02),Vector3(0,5.96,-16.02),Vector3(6.0,5.40,-16.02)]:gable.set_normal(Vector3.BACK);gable.add_vertex(p)
	var rear:=MeshInstance3D.new();rear.name="RearGable";rear.mesh=gable.commit();rear.material_override=SurfaceMaterials.make("wall",Color.WHITE,true);add_child(rear)
	# Two risers were missing before: both the longitudinal and rear annex joints.
	slab("AnnexSideRiser",[Vector3(-2.1,4.38,-6),Vector3(-2.1,5.811,-6),Vector3(-2.1,5.811,.06),Vector3(-2.1,4.38,.06)],Vector3.LEFT*.10,roof)
	slab("AnnexRearRiser",[Vector3(-6.12,4.38,-6),Vector3(-2.1,4.38,-6),Vector3(-2.1,5.811,-6),Vector3(-6.12,5.4492,-6)],Vector3.FORWARD*.10,roof)
	var batch:=PropBatch.new();batch.name="RoofStructure";add_child(batch)
	for i in 29:
		var x: float=-5.9+i*.42
		if x< -2.1:
			StreetDetail.beam(batch,Vector3(x,4.494,-5.98),Vector3(x,4.494,.03),.018,flashing)
			StreetDetail.beam(batch,Vector3(x,6-absf(x)*.09+.014,-16.05),Vector3(x,6-absf(x)*.09+.014,-6.02),.018,flashing)
		else:StreetDetail.beam(batch,Vector3(x,6-absf(x)*.09+.014,-16.05),Vector3(x,6-absf(x)*.09+.014,.03),.018,flashing)
	for x in [-5.6,-3.8,-1.9,0,1.9,3.8,5.6]:
		if x< -2.1:
			batch.add_box(Vector3(x,4.32,-3),Vector3(.06,.12,6),steel)
			batch.add_box(Vector3(x,6-absf(x)*.09-.16,-11),Vector3(.06,.12,10),steel)
		else:batch.add_box(Vector3(x,6-absf(x)*.09-.16,-8),Vector3(.06,.12,16),steel)
	for z in [-.5,-3.5,-6.5,-9.5,-12.5,-15.5]:
		var first: float=-2.1 if z> -6 else -5.9
		StreetDetail.beam(batch,Vector3(first,5.05,z),Vector3(5.9,5.05,z),.07,steel)
		var count:=8 if z> -6 else 12
		for i in count:
			var x:=lerpf(first,5.9,float(i)/count);var next:=lerpf(first,5.9,float(i+1)/count)
			StreetDetail.beam(batch,Vector3(x,5.05,z),Vector3(next,6-absf(next)*.09-.13,z),.031,steel)
			StreetDetail.beam(batch,Vector3(x,5.05,z),Vector3(x,6-absf(x)*.09-.13,z),.028,steel)
		if z> -6:StreetDetail.beam(batch,Vector3(-5.9,4.22,z),Vector3(-2.1,4.22,z),.06,steel)
	StreetDetail.beam(batch,Vector3(-2.14,5.82,-6),Vector3(-2.14,5.82,.06),.08,flashing)
	StreetDetail.beam(batch,Vector3(-2.14,4.48,-6),Vector3(-2.14,4.48,.06),.08,flashing)
	StreetDetail.beam(batch,Vector3(-6.1,5.45,-6.05),Vector3(-2.1,5.82,-6.05),.075,flashing)
	StreetDetail.beam(batch,Vector3(0,6.02,-16.1),Vector3(0,6.02,.04),.12,flashing)
	# Gutters and downpipe at the photographed lower annex.
	batch.add_box(Vector3(-6.15,4.40,-3),Vector3(.16,.11,6.1),flashing)
	StreetDetail.beam(batch,Vector3(-6.13,4.37,-.24),Vector3(-6.13,.10,-.24),.075,flashing)
	batch.flush()
