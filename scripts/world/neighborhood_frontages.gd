class_name NeighborhoodFrontages
extends RefCounted
## Six distinct original infill lots. The photographed frontage sequence is kept.
const TYPES:={"brick_garage":5.4,"garden_house":5.4,"corner_shop":5.4,"tile_house":5.4,"courtyard_house":5.4,"workshop_annex":5.5}
static func block(root: Node3D,batch: PropBatch,at: Vector3,size: Vector3,mat: Material,solid:=true) -> void:
	batch.add_box(at,size,mat)
	if solid:RetailDetails.collision(root,at,size)
static func shell(root: Node3D,batch: PropBatch,w: float,h: float,depth: float,holes: Array[Rect2],mat: Material,front:=0.0,base_mat: Material=null) -> void:
	block(root,batch,Vector3(0,-.12,front-depth*.5),Vector3(w,.30,depth),SurfaceMaterials.make("paving",Color("999b90")))
	for x in [-w*.5,w*.5]:block(root,batch,Vector3(x,h*.5,front-depth*.5),Vector3(.17,h,depth),mat)
	block(root,batch,Vector3(0,h*.5,front-depth),Vector3(w,h,.16),mat)
	block(root,batch,Vector3(0,h-.07,front-depth*.5),Vector3(w+.14,.10,depth+.12),SurfaceMaterials.make("painted_metal",Color("84908a")))
	var xs: Array[float]=[-w*.5,w*.5];var ys: Array[float]=[0.0,1.08,h]
	for hole in holes:xs.append(hole.position.x);xs.append(hole.end.x);ys.append(hole.position.y);ys.append(hole.end.y)
	xs.sort();ys.sort()
	for i in range(xs.size()-1):
		for j in range(ys.size()-1):
			var width:=xs[i+1]-xs[i];var height:=ys[j+1]-ys[j]
			if width<.004 or height<.004:continue
			var mid:=Vector2((xs[i]+xs[i+1])*.5,(ys[j]+ys[j+1])*.5);var open:=false
			for hole in holes:
				if hole.has_point(mid):open=true;break
			if not open:block(root,batch,Vector3(mid.x,mid.y,front),Vector3(width,height,.17),base_mat if base_mat!=null and mid.y<1.08 else mat)
static func gate(root: Node3D,batch: PropBatch,at: Vector3,size: Vector2,style: int,color: Color) -> void:
	var mat:=SurfaceMaterials.make("painted_metal",color);var dark:=SurfaceMaterials.make("painted_metal",color.darkened(.40))
	block(root,batch,at-Vector3(0,0,.055),Vector3(size.x,size.y,.045),dark)
	for x in [-size.x*.5,size.x*.5]:batch.add_box(at+Vector3(x,0,.06),Vector3(.045,size.y+.06,.075),mat)
	for y in [-size.y*.5,size.y*.5]:batch.add_box(at+Vector3(0,y,.06),Vector3(size.x+.06,.045,.075),mat)
	match style:
		0:
			for i in ceili(size.y/.085):batch.add_box(at+Vector3(0,-size.y*.5+i*.085,.025),Vector3(size.x,.014,.035),mat)
			batch.add_box(at+Vector3(0,-size.y*.5+.075,.055),Vector3(size.x,.10,.04),mat)
		1:
			for i in ceili(size.x/.115):NeighborhoodProps.tube(batch,at+Vector3(-size.x*.5+.04+i*.115,-size.y*.5,.03),at+Vector3(-size.x*.5+.04+i*.115,size.y*.5,.03),.010,mat)
			for y in [-size.y*.22,size.y*.22]:batch.add_box(at+Vector3(0,y,.04),Vector3(size.x,.027,.025),mat)
		2:
			for i in ceili(size.y/.105):StreetDetail.rotated_box(batch,at+Vector3(0,-size.y*.5+.03+i*.105,.03),Vector3(size.x,.075,.028),Vector3(.23,0,0),mat)
		3:
			for i in ceili(size.x/.35):
				var x: float=-size.x*.5+.175+i*.35
				for y in [-size.y*.28,0,size.y*.28]:
					for sign in [-1,1]:NeighborhoodProps.tube(batch,at+Vector3(x-.15,y-sign*.21,.045),at+Vector3(x+.15,y+sign*.21,.045),.008,mat)
		_:
			for i in ceili(size.x/.09):batch.add_box(at+Vector3(-size.x*.5+.025+i*.09,0,.035),Vector3(.065,size.y,.04),mat)
	batch.add_box(at+Vector3(size.x*.30,0,.08),Vector3(.045,.17,.045),dark)
static func window(root: Node3D,batch: PropBatch,at: Vector3,size: Vector2,warm:=false) -> void:
	var frame:=SurfaceMaterials.make("painted_metal",Color("c5c7b8"));var iron:=SurfaceMaterials.make("steel",Color("9ca89f"))
	for x in [-size.x*.5,size.x*.5]:batch.add_box(at+Vector3(x,0,.055),Vector3(.055,size.y+.10,.16),frame)
	for y in [-size.y*.5,size.y*.5]:batch.add_box(at+Vector3(0,y,.055),Vector3(size.x+.10,.055,.16),frame)
	batch.add_box(at+Vector3(0,-size.y*.5-.045,.09),Vector3(size.x+.22,.075,.24),frame)
	if warm:NeighborhoodLights.warm_window(root,at-Vector3(0,0,.045),size)
	else:batch.add_box(at-Vector3(0,0,.08),Vector3(size.x,size.y,.02),Geo.material(Color("263d3f")))
	for i in 5:NeighborhoodProps.tube(batch,at+Vector3(-size.x*.5,-size.y*.5+i*size.y/4,.12),at+Vector3(size.x*.5,-size.y*.5+i*size.y/4,.12),.008,iron)
	for x in [-size.x*.33,0,size.x*.33]:NeighborhoodProps.tube(batch,at+Vector3(x,-size.y*.5,.12),at+Vector3(x,size.y*.5,.12),.008,iron)
static func gable(root: Node3D,batch: PropBatch,w: float,d: float,eaves: float,rise: float,front: float,paint: Material) -> void:
	var half:=w*.5;var length:=sqrt(half*half+rise*rise);var clay:=StreetDetail.material(Color.WHITE,"terracotta")
	for side in [-1,1]:StreetDetail.rotated_box(batch,Vector3(side*half*.5,eaves+rise*.5,front-d*.5),Vector3(length+.15,.10,d+.35),Vector3(0,0,-side*atan2(rise,half)),clay)
	for z in [front+.025,front-d]:StreetDetail.triangle(root,Vector3(-half,eaves,z),Vector3(half,eaves,z),Vector3(0,eaves+rise,z),paint)
	var tiles:=Node3D.new();root.add_child(tiles);tiles.position.z=front;var tile_batch:=PropBatch.new();tiles.add_child(tile_batch);RoofTiles.add_to(tile_batch,w,d,eaves,rise);tile_batch.flush()
	NeighborhoodProps.tube(batch,Vector3(-half-.08,eaves,front+.14),Vector3(0,eaves+rise,front+.14),.028,SurfaceMaterials.make("painted_metal",Color("aa9980")))
	NeighborhoodProps.tube(batch,Vector3(0,eaves+rise,front+.14),Vector3(half+.08,eaves,front+.14),.028,SurfaceMaterials.make("painted_metal",Color("aa9980")))
static func sheet_roof(root: Node3D,batch: PropBatch,w: float,d: float,height: float,front: float) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var steps:=ceili(w/.06)*4
	for i in steps:
		var points: Array[Vector3]=[]
		for uv in [Vector2(i,0),Vector2(i+1,0),Vector2(i+1,1),Vector2(i,1)]:
			var x: float=-w*.5+uv.x/steps*w;var z: float=front-uv.y*d;points.append(Vector3(x,height-uv.y*.19+cos(x*TAU/.06)*.010,z))
		for index in [0,2,1,0,3,2]:st.add_vertex(points[index])
	st.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=SurfaceMaterials.make("painted_metal",Color("8b9891"),true);root.add_child(mesh)
	batch.add_box(Vector3(0,height-.06,front+.025),Vector3(w,.13,.08),SurfaceMaterials.make("painted_metal",Color("737d75")))
static func awning(root: Node3D,batch: PropBatch,at: Vector3,width: float) -> void:
	var iron:=SurfaceMaterials.make("painted_metal",Color("697167"))
	for i in ceili(width/.42):
		var mat:=Geo.material(Color("839188") if i%2 else Color("d4cdb5"));var x: float=-width*.5+.21+i*.42
		StreetDetail.rotated_box(batch,at+Vector3(x,-.10,.39),Vector3(.418,.035,.86),Vector3(.20,0,0),mat)
		batch.add_box(at+Vector3(x,-.26,.81),Vector3(.418,.19,.025),mat)
	for x in [-width*.5+.06,width*.5-.06]:NeighborhoodProps.tube(batch,at+Vector3(x,-.50,0),at+Vector3(x,-.20,.78),.012,iron)
static func create(parent: Node3D,name: String,x: float,z: float,elevation: float,opposite: bool,kind: String) -> Node3D:
	var root:=Node3D.new();root.name=name;root.set_meta("frontage_kind",kind);root.set_meta("frontage_width",TYPES[kind]);parent.add_child(root);root.position=Vector3(x,elevation,z)
	if opposite:root.rotation.y=PI
	var batch:=PropBatch.new();root.add_child(batch);var w: float=TYPES[kind]
	var ivory:=SurfaceMaterials.make("plaster",Color("d5d1be"));var gray:=SurfaceMaterials.make("plaster",Color("a9b2ab"))
	match kind:
		"brick_garage":
			var brick:=SurfaceMaterials.make("brick");shell(root,batch,w,3.15,4.8,[Rect2(-2.35,0,3.25,2.46),Rect2(1.35,0,.87,2.15)],brick)
			gate(root,batch,Vector3(-.725,1.23,.02),Vector2(3.25,2.46),0,Color("9ca9a3"));gate(root,batch,Vector3(1.785,1.075,.02),Vector2(.87,2.15),1,Color("667e7a"))
			block(root,batch,Vector3(-.45,3.26,-.04),Vector3(4.65,.22,.28),ivory)
			for i in 4:batch.add_box(Vector3(-1.8+i*.40,2.82,.10),Vector3(.23,.14,.04),Geo.material(Color("48554e")))
			NeighborhoodProps.bicycle(root,Vector3(-1.78,.01,.55));NeighborhoodProps.aerial(root,Vector3(1.9,3.25,-1.1),.6)
			NeighborhoodProps.label(root,"543",Vector3(2.34,1.9,.12))
		"garden_house":
			var green:=SurfaceMaterials.make("plaster",Color("b0c0aa"));shell(root,batch,w,2.90,4.0,[Rect2(-1.95,0,.85,2.13),Rect2(.35,1.10,1.5,1.02)],green,-.85)
			gate(root,batch,Vector3(-1.525,1.065,-.82),Vector2(.85,2.13),4,Color("b6b6a0"));window(root,batch,Vector3(1.1,1.61,-.82),Vector2(1.5,1.02),true)
			gable(root,batch,5.65,4.25,2.9,.72,-.65,green)
			block(root,batch,Vector3(0,-.07,-.42),Vector3(w,.20,.95),SurfaceMaterials.make("paving"))
			for pair in [Vector2(-2.34,.72),Vector2(.75,3.90)]:block(root,batch,Vector3(pair.x,.59,.02),Vector3(pair.y,1.18,.18),ivory)
			gate(root,batch,Vector3(-1.5,.90,.09),Vector2(.9,1.8),1,Color("8a9a88"))
			NeighborhoodProps.pot(root,Vector3(.15,.04,-.33),0);NeighborhoodProps.pot(root,Vector3(2.02,.04,-.32),1,Color("c3b69b"))
			NeighborhoodProps.water_tank(root,Vector3(1.55,3.5,-3.4));NeighborhoodProps.label(root,"537",Vector3(-2.28,1.4,.13))
		"corner_shop":
			var paint:=SurfaceMaterials.make("plaster",Color("b4b6a4"));shell(root,batch,w,3.55,4.9,[Rect2(-2.35,0,3.35,2.45),Rect2(1.42,0,.8,2.15)],paint)
			gate(root,batch,Vector3(-.675,1.225,.02),Vector2(3.35,2.45),0,Color("5c7874"));gate(root,batch,Vector3(1.82,1.075,.02),Vector2(.8,2.15),2,Color("8e9c86"))
			batch.add_box(Vector3(-.35,3.05,.13),Vector3(4.1,.49,.09),SurfaceMaterials.make("painted_metal",Color("b9b49e")))
			NeighborhoodProps.label(root,"CHAVES  /  CONSERTOS",Vector3(-.35,3.05,.185),28,.005,Color("455751"));awning(root,batch,Vector3(-.67,2.60,.12),3.40)
			batch.add_box(Vector3(0,3.67,-.04),Vector3(w+.1,.18,.34),gray);NeighborhoodProps.dish(root,Vector3(1.65,4.15,-.75))
		"tile_house":
			var blue:=SurfaceMaterials.make("plaster",Color("c6d1d0"));shell(root,batch,w,3.05,4.4,[Rect2(-2.30,0,2.8,2.22),Rect2(1.35,0,.8,2.16)],blue,0,SurfaceMaterials.make("azulejo"))
			gate(root,batch,Vector3(-.90,1.11,.02),Vector2(2.8,2.22),3,Color("789c9d"));gate(root,batch,Vector3(1.75,1.08,.02),Vector2(.8,2.16),2,Color("b7c7c2"))
			for i in 6:batch.add_box(Vector3(-1.8+i*.37,2.65,.095),Vector3(.22,.12,.045),Geo.material(Color("667f7b")))
			block(root,batch,Vector3(-.75,3.16,-.02),Vector3(4.1,.22,.28),ivory);block(root,batch,Vector3(2.0,3.28,-.02),Vector3(1.45,.46,.28),blue)
			NeighborhoodProps.pot(root,Vector3(2.4,.02,.30),1,Color("8b9590"));NeighborhoodProps.aerial(root,Vector3(-1.6,3.22,-1.2),-.8);NeighborhoodProps.label(root,"579",Vector3(.91,1.7,.12))
		"courtyard_house":
			shell(root,batch,w,3.08,4.15,[Rect2(-1.7,0,.85,2.14),Rect2(.3,1.1,1.5,1.0)],ivory,-1.25)
			gate(root,batch,Vector3(-1.275,1.07,-1.22),Vector2(.85,2.14),4,Color("b0a489"));window(root,batch,Vector3(1.05,1.6,-1.21),Vector2(1.5,1),true)
			block(root,batch,Vector3(0,-.075,-.58),Vector3(w,.22,1.4),SurfaceMaterials.make("paving"));sheet_roof(root,batch,w+.20,5.0,3.41,-.48)
			var brick:=SurfaceMaterials.make("brick");block(root,batch,Vector3(-2.45,.75,.03),Vector3(.40,1.5,.26),brick);block(root,batch,Vector3(1.4,.93,.03),Vector3(.28,1.86,.26),brick);block(root,batch,Vector3(2.5,.93,.03),Vector3(.30,1.86,.26),brick)
			gate(root,batch,Vector3(-.58,.76,.11),Vector2(3.33,1.52),2,Color("9b9f8b"));gate(root,batch,Vector3(1.96,.90,.11),Vector2(.83,1.8),1,Color("858f80"))
			NeighborhoodProps.pot(root,Vector3(2.1,.04,-.5),0);NeighborhoodProps.dish(root,Vector3(1.6,3.98,-2.0));NeighborhoodProps.label(root,"564",Vector3(1.4,1.5,.18))
		"workshop_annex":
			shell(root,batch,w,4.05,5.3,[Rect2(-1.65,0,3.8,3.0),Rect2(-2.48,1.6,.58,.95)],gray)
			gate(root,batch,Vector3(.25,1.50,.03),Vector2(3.8,3),4,Color("6f8588"));window(root,batch,Vector3(-2.19,2.075,.02),Vector2(.58,.95))
			for i in 15:batch.add_box(Vector3(-2.5+i*.35,3.60,.10),Vector3(.26,.32,.04),SurfaceMaterials.make("painted_metal",Color("657a7a")))
			block(root,batch,Vector3(0,4.19,-.02),Vector3(w+.18,.25,.36),ivory);sheet_roof(root,batch,w+.25,5.5,4.19,-.2)
			NeighborhoodProps.label(root,"538",Vector3(-2.2,1.25,.13));NeighborhoodProps.aerial(root,Vector3(-1.6,4.2,-3.4),.3)
	batch.flush();return root
static func distant(parent: Node3D,x: float,z: float,elevation: float,opposite: bool,index: int) -> void:
	var root:=Node3D.new();root.name="DistantResidentialLot";parent.add_child(root);root.position=Vector3(x,elevation,z)
	if opposite:root.rotation.y=PI
	var batch:=PropBatch.new();root.add_child(batch)
	var colors: Array[Color]=[Color("bac1b2"),Color("c6b5a5"),Color("a2b9b9"),Color("c7c4ac")];var paint:=SurfaceMaterials.make("plaster",colors[posmod(index,4)])
	var height: float=[2.8,3.6,4.9,3.1][posmod(index,4)];var width: float=[5.6,6.2,5.7,6.4][posmod(index,4)]
	batch.add_box(Vector3(0,height*.5,-3.3),Vector3(width,height,6.6),paint)
	batch.add_box(Vector3(-.65,1.1,.06),Vector3(2.6,2.2,.10),SurfaceMaterials.make("painted_metal",colors[posmod(index+2,4)].darkened(.3)))
	for i in 5:batch.add_box(Vector3(-1.75+i*.55,1.1,.12),Vector3(.022,2.15,.02),Geo.material(Color("7b8b7c")))
	StreetDetail.window(batch,Vector3(1.9,1.7,.08),Vector2(.76,.7))
	if index%2==0:
		for side in [-1,1]:StreetDetail.rotated_box(batch,Vector3(side*width*.25,height+.3,-3),Vector3(width*.54,.09,6.7),Vector3(0,0,-side*.20),StreetDetail.material(Color.WHITE,"terracotta"))
	else:batch.add_box(Vector3(0,height+.10,-.04),Vector3(width+.16,.22,.30),paint)
	if height>4:
		for px in [-1.6,1.4]:StreetDetail.window(batch,Vector3(px,3.9,.06),Vector2(.9,.9))
	batch.flush()
