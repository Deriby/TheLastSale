class_name NeighborhoodProps
extends RefCounted
## Original modeled residential/service objects, baked as ordinary meshes.
static var cylinder: CylinderMesh
static var tire_ring: ArrayMesh
static var metal_ring: ArrayMesh
static var grass_mesh: ArrayMesh
static func street_position(parent: Node3D,at: Vector3) -> Vector3:
	if at.z<=0:return at
	var world:=parent.to_global(at)
	var level:=signf(world.x)*maxf(0,absf(world.x)-6.0)*.045
	at.y=level-parent.global_position.y+.004
	return at
static func tube(batch: PropBatch,a: Vector3,b: Vector3,radius: float,mat: Material) -> void:
	if cylinder==null:
		cylinder=CylinderMesh.new();cylinder.top_radius=1;cylinder.bottom_radius=1;cylinder.height=1;cylinder.radial_segments=12
	var y:=(b-a).normalized();var x:=y.cross(Vector3.UP if absf(y.y)<.95 else Vector3.RIGHT).normalized();var z:=x.cross(y)
	batch.add_instance("round_tube:"+str(mat.get_instance_id()),cylinder,mat,Transform3D(Basis(x*radius,y*a.distance_to(b),z*radius),(a+b)*.5))
static func ring_mesh(thickness: float) -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 32:
		for j in 8:
			var points: Array[Vector3]=[]
			for pair in [Vector2(i,j),Vector2(i+1,j),Vector2(i+1,j+1),Vector2(i,j+1)]:
				var a: float=pair.x*TAU/32;var b: float=pair.y*TAU/8;points.append(Vector3(sin(a)*(1+cos(b)*thickness),cos(a)*(1+cos(b)*thickness),sin(b)*thickness))
			for index in [0,2,1,0,3,2]:st.add_vertex(points[index])
	st.generate_normals();return st.commit()
static func ring(batch: PropBatch,at: Vector3,radius: float,mat: Material,rubber:=false,rotation:=Vector3.ZERO) -> void:
	if tire_ring==null:tire_ring=ring_mesh(.067);metal_ring=ring_mesh(.020)
	batch.add_instance(("tire:" if rubber else "rim:")+str(mat.get_instance_id()),tire_ring if rubber else metal_ring,mat,Transform3D(Basis.from_euler(rotation).scaled(Vector3.ONE*radius),at))
static func obstacle(parent: Node3D,at: Vector3,size: Vector3) -> void:
	var body:=RetailDetails.collision(parent,at,size);body.add_to_group("street_detail_obstacles");body.set_meta("nav_center",at);body.set_meta("nav_size",size)
static func label(parent: Node3D,words: String,at: Vector3,size:=22,pixel:=.003,color:=Color("ded9c6")) -> void:
	var text:=Geo.sign_text(parent,words,at,size,color);text.pixel_size=pixel
static func bicycle(parent: Node3D,at: Vector3) -> void:
	var root:=Node3D.new();root.name="ParkedBicycle";parent.add_child(root);root.position=street_position(parent,at);root.rotation=Vector3(-.15,0,atan(.045*parent.global_basis.x.x))
	var batch:=PropBatch.new();root.add_child(batch)
	var paint:=SurfaceMaterials.make("painted_metal",Color("5e7777"));var alloy:=SurfaceMaterials.make("steel",Color("b6bbb9"));var rubber:=SurfaceMaterials.make("rubber",Color("24292a"))
	for x in [-.58,.58]:
		var center:=Vector3(x,.33,0);ring(batch,center,.31,rubber,true);ring(batch,center,.281,alloy)
		for i in 16:
			var angle:=i*TAU/16;tube(batch,center,center+Vector3(sin(angle)*.277,cos(angle)*.277,0),.0027,alloy)
		tube(batch,center+Vector3(0,0,-.035),center+Vector3(0,0,.035),.027,alloy)
	var crank:=Vector3(-.02,.35,0);var seat:=Vector3(-.19,.81,0);var head:=Vector3(.41,.83,0)
	for ends in [[Vector3(-.58,.33,0),crank],[Vector3(-.58,.33,0),seat],[crank,seat],[seat,head],[crank,head],[head,Vector3(.58,.33,0)]]:tube(batch,ends[0],ends[1],.018,paint)
	tube(batch,seat,seat+Vector3(0,.13,0),.014,alloy);batch.add_box(seat+Vector3(-.045,.15,0),Vector3(.25,.055,.14),rubber)
	tube(batch,head,head+Vector3(0,.17,0),.014,alloy);tube(batch,head+Vector3(0,.17,-.22),head+Vector3(0,.17,.22),.012,alloy)
	for side in [-1,1]:tube(batch,head+Vector3(0,.17,side*.22),head+Vector3(-.10,.17,side*.22),.018,rubber)
	ring(batch,crank,.085,alloy);tube(batch,crank+Vector3(0,-.10,-.08),crank+Vector3(0,.10,.08),.012,alloy)
	for side in [-1,1]:batch.add_box(crank+Vector3(0,side*.10,side*.11),Vector3(.10,.025,.08),rubber)
	tube(batch,Vector3(-.50,.35,.035),Vector3(-.03,.29,.035),.006,alloy);batch.flush();obstacle(root,Vector3(0,.60,0),Vector3(1.85,1.2,.53))
static func aerial(parent: Node3D,at: Vector3,angle:=0.0) -> void:
	var root:=Node3D.new();root.name="TelevisionAerial";parent.add_child(root);root.position=at;root.rotation.y=angle
	var batch:=PropBatch.new();root.add_child(batch);var metal:=SurfaceMaterials.make("steel",Color("9baba6"))
	tube(batch,Vector3.ZERO,Vector3(0,1.2,0),.018,metal);tube(batch,Vector3(-.64,1.15,0),Vector3(.62,1.15,0),.012,metal)
	for i in 7:
		var x: float=-.55+i*.17;var span: float=.46-i*.035;tube(batch,Vector3(x,1.15,-span),Vector3(x,1.15,span),.007,metal)
	tube(batch,Vector3(-.64,1.10,-.40),Vector3(-.64,1.10,.40),.008,metal);batch.flush()
static func dish(parent: Node3D,at: Vector3) -> void:
	var root:=Node3D.new();root.name="SatelliteDish";parent.add_child(root);root.position=at;root.rotation=Vector3(-.20,.40,.04)
	var batch:=PropBatch.new();root.add_child(batch);var metal:=SurfaceMaterials.make("painted_metal",Color("bac3bd"),true)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 6:
		for col in 32:
			var points: Array[Vector3]=[]
			for pair in [Vector2(row,col),Vector2(row+1,col),Vector2(row+1,col+1),Vector2(row,col+1)]:
				var r: float=pair.x/6*.40;var a: float=pair.y*TAU/32;points.append(Vector3(sin(a)*r,cos(a)*r,(r*r/.16-1)*.11))
			for i in [0,2,1,0,3,2]:st.add_vertex(points[i])
	st.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=metal;root.add_child(mesh)
	var iron:=SurfaceMaterials.make("painted_metal",Color("69716c"));ring(batch,Vector3.ZERO,.40,iron)
	tube(batch,Vector3(0,-.65,-.14),Vector3(0,-.10,-.14),.027,iron)
	for x in [-.27,.27]:tube(batch,Vector3(x,-.20,-.04),Vector3(0,-.08,.31),.009,iron)
	batch.add_box(Vector3(0,-.08,.32),Vector3(.075,.085,.11),metal);batch.flush()
static func water_tank(parent: Node3D,at: Vector3) -> void:
	var root:=Node3D.new();root.name="RoofWaterTank";parent.add_child(root);root.position=at
	var blue:=SurfaceMaterials.make("plastic",Color("567d92"));var concrete:=SurfaceMaterials.make("paving",Color("b3b2a3"))
	Geo.box(root,Vector3(0,.04,0),Vector3(1.0,.08,1.0),concrete,false)
	for x in [-.36,.36]:
		for z in [-.36,.36]:Geo.box(root,Vector3(x,-.20,z),Vector3(.085,.40,.085),concrete,false)
	var tank:=Geo.cylinder(root,Vector3(0,.41,0),.43,.72,blue,.37);tank.mesh.radial_segments=24
	var lid:=Geo.cylinder(root,Vector3(0,.79,0),.40,.055,blue,.24);lid.mesh.radial_segments=24
	var batch:=PropBatch.new();root.add_child(batch);var pipe:=SurfaceMaterials.make("plastic",Color("a5b1a5"));tube(batch,Vector3(.35,.18,.15),Vector3(.70,.18,.15),.025,pipe);tube(batch,Vector3(.70,.18,.15),Vector3(.70,-.35,.15),.025,pipe);batch.flush()
static func pot(parent: Node3D,at: Vector3,kind: int,color:=Color("a77a5c")) -> void:
	var root:=Node3D.new();root.name="CourtyardPlant";parent.add_child(root);root.position=street_position(parent,at)
	var clay:=SurfaceMaterials.make("plaster",color);var soil:=SurfaceMaterials.make("paving",Color("554c3c"))
	var shape:=Geo.cylinder(root,Vector3(0,.17,0),.16,.34,clay,.235);shape.mesh.radial_segments=20
	var top:=Geo.cylinder(root,Vector3(0,.335,0),.218,.018,soil);top.mesh.radial_segments=20
	var batch:=PropBatch.new();root.add_child(batch);ring(batch,Vector3(0,.35,0),.233,clay,false,Vector3(PI/2,0,0))
	var green:=Geo.material(Color("5f7850") if kind%2==0 else Color("738663"));green.cull_mode=BaseMaterial3D.CULL_DISABLED
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in (11 if kind%2==0 else 7):
		var angle: float=i*2.399;var length: float=.43+.11*sin(i*1.7);var width: float=.05 if kind%2==0 else .12
		for j in 6:
			var corners: Array[Vector3]=[]
			for pair in [Vector2(j,-1),Vector2(j,1),Vector2(j+1,1),Vector2(j+1,-1)]:
				var t: float=pair.x/6;var radius:=sin(t*1.5)*length*.72;var height:=.34+sin(t*1.7)*length
				corners.append(Vector3(sin(angle)*radius+cos(angle)*pair.y*width*(1-t),height,cos(angle)*radius-sin(angle)*pair.y*width*(1-t)))
			for index in [0,2,1,0,3,2]:st.add_vertex(corners[index])
	st.generate_normals();var leaves:=MeshInstance3D.new();leaves.mesh=st.commit();leaves.material_override=green;root.add_child(leaves);batch.flush();obstacle(root,Vector3(0,.18,0),Vector3(.46,.36,.46))
static func gas_cage(parent: Node3D,at: Vector3) -> void:
	var root:=Node3D.new();root.name="GasCylinderCage";parent.add_child(root);root.position=street_position(parent,at)
	var batch:=PropBatch.new();root.add_child(batch);var iron:=SurfaceMaterials.make("painted_metal",Color("747e76"));var blue:=SurfaceMaterials.make("painted_metal",Color("4b7b91"))
	batch.add_box(Vector3(0,.065,0),Vector3(1.50,.04,.64),iron)
	for x in [-.74,.74]:
		for z in [-.30,.30]:
			tube(batch,Vector3(x,0,z),Vector3(x,1.17,z),.017,iron)
			batch.add_box(Vector3(x,.015,z),Vector3(.11,.12,.11),SurfaceMaterials.make("paving",Color("a5a99b")))
	for y in [.06,.63,1.16]:
		for z in [-.30,.30]:tube(batch,Vector3(-.74,y,z),Vector3(.74,y,z),.015,iron)
	for i in 13:tube(batch,Vector3(-.72+i*.12,.05,.30),Vector3(-.72+i*.12,1.16,.30),.006,iron)
	for i in 4:
		var x: float=-.54+i*.36;var bottle:=Geo.cylinder(root,Vector3(x,.37,0),.16,.58,blue,.145);bottle.mesh.radial_segments=20
		var shoulder:=Geo.cylinder(root,Vector3(x,.70,0),.145,.10,blue,.07);shoulder.mesh.radial_segments=20
		tube(batch,Vector3(x,.74,0),Vector3(x,.82,0),.026,iron);ring(batch,Vector3(x,.85,0),.072,blue,false,Vector3(PI/2,0,0))
	batch.flush();obstacle(root,Vector3(0,.59,0),Vector3(1.53,1.18,.66))
static func grass(batch: PropBatch,at: Vector3,angle: float) -> void:
	if grass_mesh==null:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 6:
			var a: float=i*2.399;var base:=Vector3(sin(a)*.045,0,cos(a)*.045)
			var tip:=base+Vector3(sin(a)*.045,.11+.025*sin(i),cos(a)*.045);var cross:=Vector3(cos(a),0,-sin(a))*.009
			for p in [base-cross,tip,base+cross]:st.add_vertex(p)
		st.generate_normals();grass_mesh=st.commit()
	var mat:=Geo.material(Color("87946a"));mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	batch.add_instance("curb_grass",grass_mesh,mat,Transform3D(Basis(Vector3.UP,angle),at))
