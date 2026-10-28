class_name StreetFurniture
extends RefCounted
static func tree(parent: Node3D,at: Vector3,height:=3.8) -> void:
	var root:=Node3D.new();root.name="StreetTree";parent.add_child(root);root.position=at
	var bark:=StreetDetail.material(Color("777669"),"render")
	Geo.cylinder(root,Vector3(0,height*.30,0),.065,height*.60,bark)
	RetailDetails.collision(root,Vector3(0,height*.30,0),Vector3(.13,height*.60,.13))
	var batch:=PropBatch.new();root.add_child(batch)
	for i in 5:
		var angle:=i*2.4
		var end:=Vector3(sin(angle)*.6,height*(.68+i*.045),cos(angle)*.45)
		StreetDetail.beam(batch,Vector3(0,height*.43,0),end,.04,bark)
	for i in 15:
		var angle:=i*2.4
		var pos:=Vector3(sin(angle)*(.3+(i%3)*.25),height*.68+sin(i*1.7)*.55,cos(angle)*.65)
		StreetDetail.leaf(batch,pos,Vector3(.53,.65,.48),StreetDetail.material([Color("667454"),Color("4d6347"),Color("7a8258")][i%3]))
	batch.flush()
static func car(parent: Node3D,at: Vector3,color: Color,angle:=0.0) -> void:
	var root:=Node3D.new();root.name="ParkedCompact";parent.add_child(root);root.position=at;root.rotation.y=angle
	var batch:=PropBatch.new();root.add_child(batch);var paint:=StreetDetail.material(color)
	batch.add_box(Vector3(0,.58,0),Vector3(3.70,.62,1.56),paint)
	batch.add_box(Vector3(1.24,.89,0),Vector3(1.2,.10,1.5),paint)
	batch.add_box(Vector3(-1.42,.9,0),Vector3(.7,.08,1.48),paint)
	batch.add_box(Vector3(-.12,1.43,0),Vector3(1.28,.08,1.35),paint)
	var glass:=StreetDetail.material(Color("435353"))
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var front: Array[Vector3]=[Vector3(.80,.91,-.70),Vector3(.80,.91,.70),Vector3(.48,1.4,.65),Vector3(.48,1.4,-.65)]
	var rear: Array[Vector3]=[Vector3(-1.1,.94,.70),Vector3(-1.1,.94,-.70),Vector3(-.72,1.4,-.65),Vector3(-.72,1.4,.65)]
	for face in [front,rear]:
		StreetDetail.triangle(root,face[0],face[1],face[2],glass);StreetDetail.triangle(root,face[0],face[2],face[3],glass)
	for side in [-1,1]:
		var a:=Vector3(.80,.92,side*.71);var b:=Vector3(-1.1,.94,side*.71);var c:=Vector3(-.72,1.4,side*.66);var d:=Vector3(.48,1.4,side*.66)
		# Both side normals face out; no transparent window sorting on older drivers.
		if side>0:StreetDetail.triangle(root,a,b,c,glass);StreetDetail.triangle(root,a,c,d,glass)
		else:StreetDetail.triangle(root,a,c,b,glass);StreetDetail.triangle(root,a,d,c,glass)
		StreetDetail.beam(batch,Vector3(-.12,.90,side*.725),Vector3(-.12,1.42,side*.67),.055,paint)
		batch.add_box(Vector3(.12,.62,side*.79),Vector3(.04,.48,.018),StreetDetail.material(Color("5a625a")))
		batch.add_box(Vector3(.43,.85,side*.795),Vector3(.18,.035,.022),StreetDetail.material(Color("8d938a")))
		for x in [-1.17,1.15]:
			var wheel:=Geo.cylinder(root,Vector3(x,.34,side*.79),.31,.20,StreetDetail.material(Color("202927")));wheel.rotation.x=PI/2
			var hub:=Geo.cylinder(root,Vector3(x,.34,side*.90),.17,.015,StreetDetail.material(Color("8a8f82")));hub.rotation.x=PI/2
	for x in [-1.87,1.87]:batch.add_box(Vector3(x,.43,0),Vector3(.10,.13,1.48),StreetDetail.material(Color("595f57")))
	for side in [-1,1]:
		batch.add_box(Vector3(.60,.97,side*.85),Vector3(.17,.10,.14),paint)
		batch.add_box(Vector3(side*1.93,.56,0),Vector3(.012,.12,.38),StreetDetail.material(Color("b3baac")))
		for i in 4:batch.add_box(Vector3(side*1.94,.56,-.11+i*.07),Vector3(.013,.04,.025),StreetDetail.material(Color("4d574f")))
	for z in [-.25,.25]:StreetDetail.beam(batch,Vector3(.82,.94,z),Vector3(.68,1.12,z+.14),.012,StreetDetail.material(Color("39423e")))
	for z in [-.55,.55]:
		batch.add_box(Vector3(1.887,.76,z),Vector3(.022,.18,.29),StreetDetail.material(Color("d0c7a3")))
		batch.add_box(Vector3(-1.887,.76,z),Vector3(.022,.18,.24),StreetDetail.material(Color("995649")))
	RetailDetails.collision(root,Vector3(0,.72,0),Vector3(3.8,1.44,1.65));batch.flush()
static func pole(parent: Node3D,at: Vector3,arm_side: float) -> void:
	var root:=Node3D.new();root.name="UtilityPole";parent.add_child(root);root.position=at
	Geo.cylinder(root,Vector3(0,4.35,0),.115,8.7,StreetDetail.material(Color("9a9e91"),"render"))
	RetailDetails.collision(root,Vector3(0,4.2,0),Vector3(.25,8.4,.25))
	var batch:=PropBatch.new();root.add_child(batch);var steel:=StreetDetail.material(Color("5d6864"))
	StreetDetail.beam(batch,Vector3(0,8.15,0),Vector3(0,8.15,arm_side*1.65),.07,steel)
	batch.add_box(Vector3(0,8.12,arm_side*1.65),Vector3(.30,.10,.52),StreetDetail.material(Color("bac0a9")))
	batch.add_box(Vector3(0,8.06,arm_side*1.65),Vector3(.23,.025,.37),Geo.material(Color("efd29c"),"",1.0))
	batch.add_box(Vector3(0,8.75,0),Vector3(1.85,.10,.10),StreetDetail.material(Color("6e7062")))
	for x in [-.77,-.26,.26,.77]:
		for y in [8.85,8.92]:batch.add_box(Vector3(x,y,0),Vector3(.12,.05,.11),StreetDetail.material(Color("747466")))
	batch.add_box(Vector3(.16,5.90,0),Vector3(.23,.5,.20),StreetDetail.material(Color("454d48")))
	var light:=Geo.light(root,Vector3(0,7.82,arm_side*1.65),Color("ebca94"),3.1,14.0);light.omni_attenuation=1.1
	batch.flush()
static func handcart(parent: Node3D,at: Vector3) -> void:
	var root:=Node3D.new();root.name="GasShopHandcart";parent.add_child(root);root.position=at;root.rotation.z=-.12
	var batch:=PropBatch.new();root.add_child(batch);var steel:=StreetDetail.material(Color("94745c"))
	for x in [-.24,.24]:StreetDetail.beam(batch,Vector3(x,.12,0),Vector3(x,1.20,-.24),.035,steel)
	for y in [.16,.48,.85,1.2]:StreetDetail.beam(batch,Vector3(-.24,y,-y*.2),Vector3(.24,y,-y*.2),.03,steel)
	batch.add_box(Vector3(0,.1,.17),Vector3(.52,.035,.4),steel)
	for x in [-.31,.31]:
		var wheel:=Geo.cylinder(root,Vector3(x,.18,0),.18,.07,StreetDetail.material(Color("343b32")));wheel.rotation.z=PI/2
	batch.flush()
