class_name Street
extends Node3D
## Alfredo Oliviere frontage from exterior1-7. Dimensions/grade remain estimates.
const NEAR_CURB:=2.45
const ROAD_START:=2.65
const ROAD_END:=10.45
const FAR_CURB:=10.65
const FAR_FRONT:=12.40
var blockers: Array[Rect2] = []
var details: PropBatch
static func grade(x: float) -> float:
	return signf(x)*maxf(0,absf(x)-6.0)*.045
static func surface_height(x: float,z: float) -> float:
	var level:=grade(x)
	if z<=NEAR_CURB:return level
	if z<ROAD_START:return level-lerpf(0,.14,(z-NEAR_CURB)/(ROAD_START-NEAR_CURB))
	if z<=ROAD_END:return level-.14
	if z<FAR_CURB:return level-lerpf(.14,0,(z-ROAD_END)/(FAR_CURB-ROAD_END))
	return level
func _ready() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	details=PropBatch.new();details.name="StreetDetails";add_child(details)
	build_ground();build_frontages();build_utilities();build_wear();build_limits();details.flush()
	add_child(StreetAccents.new())
func ground_strip(x0: float,x1: float,z0: float,z1: float,offset0: float,offset1: float,mat: Material) -> void:
	var points:=PackedVector3Array([Vector3(x0,grade(x0)+offset0,z0),Vector3(x1,grade(x1)+offset0,z0),Vector3(x1,grade(x1)+offset1,z1),Vector3(x0,grade(x0)+offset1,z1)])
	var normal: Vector3=(points[3]-points[0]).cross(points[1]-points[0]).normalized()
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,1,2,0,2,3]:st.set_normal(normal);st.set_uv(Vector2(points[index].x,points[index].z));st.add_vertex(points[index])
	var node:=MeshInstance3D.new();node.mesh=st.commit();node.material_override=mat;add_child(node)
	var body:=StaticBody3D.new();add_child(body);var collision:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new()
	var volume:=points.duplicate()
	for p in points:volume.append(p-Vector3.UP*.25)
	shape.points=volume;collision.shape=shape;body.add_child(collision)
func build_ground() -> void:
	var asphalt:=StreetDetail.material(Color.WHITE,"asphalt",.45)
	var pavement:=StreetDetail.material(Color("c3bfae"),"sidewalk",.7)
	var curb:=StreetDetail.material(Color("bebda8"),"render")
	# Shared grade knots keep the storefront apron flat and the street continuous downhill.
	for pair in [Vector2(-160,-6),Vector2(-6,6),Vector2(6,160)]:
		ground_strip(pair.x,pair.y,0,NEAR_CURB,0,0,pavement)
		ground_strip(pair.x,pair.y,NEAR_CURB,ROAD_START,0,-.14,curb)
		ground_strip(pair.x,pair.y,ROAD_START,ROAD_END,-.14,-.14,asphalt)
		ground_strip(pair.x,pair.y,ROAD_END,FAR_CURB,-.14,0,curb)
		ground_strip(pair.x,pair.y,FAR_CURB,FAR_FRONT,0,0,pavement)
	# A few different slab widths, repairs and joints replace the former uniform plaza.
	var joint:=StreetDetail.material(Color("737a6b"))
	for x in range(-48,49,2):
		for a in [Vector2(.08,NEAR_CURB-.03),Vector2(FAR_CURB+.03,FAR_FRONT-.02)]:
			StreetDetail.beam(details,Vector3(x,grade(x)+.004,a.x),Vector3(x,grade(x)+.004,a.y),.009,joint)
	for x in [-22,-13,9,17,25]:
		var y:=grade(x)
		details.add_box(Vector3(x,y+.006,1.20),Vector3(1.7,.012,2.30),StreetDetail.material(Color("b1aa8e"),"sidewalk"))
func add_frontage(name: String,x: float,opposite: bool,kind: String,width: float) -> Node3D:
	var z: float=FAR_FRONT if opposite else 0
	var node:=StreetBuildings.create(self,name,x,z,grade(x),opposite,kind)
	blockers.append(Rect2(Vector2(x-width*.5,z-.1 if opposite else -7),Vector2(width,7.2)))
	return node
func build_frontages() -> void:
	add_frontage("OppositeGreyHouse",3.2,true,"gray",5.6)
	add_frontage("OppositePeachHouse",-3.1,true,"peach",7.0)
	StreetBuildings.create(self,"RearCreamUpperFloor",-6.7,18.6,grade(-6.7),true,"two_storey")
	add_frontage("OppositeYellowHouse",8.8,true,"yellow",5.2)
	add_frontage("OppositeGreenMarket",16.5,true,"market",8.0)
	add_frontage("OppositeDownhillGarage",-10.1,true,"default",5.4)
	add_frontage("OppositePaleGreenHouse",-15.6,true,"green",5.4)
	add_frontage("OppositeDownhillHouse",-21.1,true,"default",5.4)
	add_frontage("OppositeUphillShops",23.5,true,"green",5.4)
	add_frontage("CassianoGasShop",10.2,false,"cassiano",6.8)
	add_frontage("UphillTwoStoreyHouse",16.9,false,"two_storey",6.3)
	add_frontage("UphillYellowGarage",23.2,false,"default",5.4)
	# The dark fence, shrubs and stump beside the low annex are visible in exterior5/6.
	var fence:=StreetDetail.material(Color("77847b"))
	for i in 30:details.add_box(Vector3(-6.15-i*.07,grade(-7.15)+1.25,-.02),Vector3(.025,2.5,.035),fence)
	for y in [.45,1.65,2.5]:details.add_box(Vector3(-7.15,grade(-7.15)+y,-.02),Vector3(2.2,.04,.06),fence)
	RetailDetails.collision(self,Vector3(-7.15,grade(-7.15)+1.25,-.02),Vector3(2.2,2.5,.10));blockers.append(Rect2(-8.25,-.15,2.2,.3))
	StreetFurniture.tree(self,Vector3(-7.2,grade(-7.2),-1),3.4)
	Geo.cylinder(self,Vector3(-7.15,grade(-7.15)+.17,1.25),.30,.34,StreetDetail.material(Color("77775c")),.23)
	add_frontage("DownhillGreyWorkshop",-12.75,false,"industrial",9.0)
	add_frontage("DownhillSideGarage",-21.75,false,"industrial",5.5)
	# Beyond the playable block the same street continues, rather than ending in grey walls.
	for x in [-51,-44,-37,-30,30,37,44,51]:
		StreetBuildings.create(self,"DistantFrontage",x,FAR_FRONT,grade(x),true,"green" if int(absf(x))%2 else "default")
		StreetBuildings.create(self,"DistantSideFrontage",x,0,grade(x),false,"default")
	for x in [-133,-121,-109,-97,-85,-73,-61,61,73,85,97,109,121,133]:
		for z in [0.0,FAR_FRONT]:
			var block:=Geo.box(self,Vector3(x,grade(x)+1.8,z+(-3 if z==0 else 3)),Vector3(12,3.6,6),StreetDetail.material(Color("8e998e"),"render"),false)
			block.name="FoggedDistantBlock"
	StreetFurniture.tree(self,Vector3(.15,grade(.15),12.08),3.6)
	blockers.append(Rect2(.03,11.96,.24,.24))
	StreetFurniture.tree(self,Vector3(-8.1,grade(-8.1),14.2),4.0)
	StreetFurniture.handcart(self,Vector3(8.0,grade(8.0),.65))
	StreetFurniture.car(self,Vector3(10.4,surface_height(10.4,9.55),9.55),Color("4b5554"),PI)
	StreetFurniture.car(self,Vector3(3.0,surface_height(3.0,9.55),9.55),Color("909c9b"))
	blockers.append(Rect2(8.5,8.70,3.8,1.7));blockers.append(Rect2(1.1,8.70,3.8,1.7))
	# Sparse plants by the grey house, not a regular row of invented avenue trees.
	for x in [1.1,1.3,1.5]:
		Geo.cylinder(self,Vector3(x,grade(x)+.13,12.05),.13,.26,StreetDetail.material(Color("9d7961")),.17)
		for i in 4:StreetDetail.leaf(details,Vector3(x+sin(i*2)*.10,grade(x)+.48,12.03+cos(i*2)*.08),Vector3(.08,.33,.07),StreetDetail.material(Color("526b42")))
func build_utilities() -> void:
	var poles: Array[Vector3]=[Vector3(-7.25,grade(-7.25),2.08),Vector3(.2,grade(.2),11.92),Vector3(17.4,grade(17.4),2.08)]
	for at in poles:
		StreetFurniture.pole(self,at,1 if at.z<5 else -1)
		blockers.append(Rect2(Vector2(at.x-.15,at.z-.15),Vector2(.3,.3)))
	var wire:=StreetDetail.material(Color("252e2d"))
	var spans: Array[Vector3]=[Vector3(-49,grade(-49),2.08),poles[0],poles[2],Vector3(49,grade(49),2.08)]
	for i in range(spans.size()-1):
		for row in 7:wire_span(spans[i]+Vector3((row%3-1)*.18,8.55+row*.13,0),spans[i+1]+Vector3((row%3-1)*.18,8.55+row*.13,0),.45,wire)
	for row in 9:wire_span(poles[0]+Vector3(0,7.2+row*.14,0),poles[1]+Vector3(0,7.2+row*.14,0),.35,wire)
	for row in 5:wire_span(poles[1]+Vector3(0,8.4+row*.16,0),Vector3(36,grade(36)+8.4+row*.16,11.9),.55,wire)
	for x in [-1.0,.78,3.15,4.95]:
		Geo.cylinder(self,Vector3(x,.43,.64),.065,.86,StreetDetail.material(Color("313b3b")))
		Geo.cylinder(self,Vector3(x,.866,.64),.07,.015,StreetDetail.material(Color("92988d")))
		RetailDetails.collision(self,Vector3(x,.43,.64),Vector3(.13,.86,.13));blockers.append(Rect2(x-.08,.56,.16,.16))
func wire_span(a: Vector3,b: Vector3,sag: float,mat: Material) -> void:
	for i in 12:
		var u:=i/12.0;var v:=(i+1)/12.0
		StreetDetail.beam(details,a.lerp(b,u)-Vector3.UP*(4*sag*u*(1-u)),a.lerp(b,v)-Vector3.UP*(4*sag*v*(1-v)),.015,mat)
func build_wear() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=558
	for i in 26:
		var x:=rng.randf_range(-35,35);var z:=rng.randf_range(2.9,10.15);var radius:=rng.randf_range(.18,.65)
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var center:=Vector3(x,surface_height(x,z)+.004,z)
		var ring: Array[Vector3]=[]
		for j in 8:
			var angle:=j*TAU/8;var p:=Vector3(x+sin(angle)*radius*rng.randf_range(.6,1.2),0,z+cos(angle)*radius*.45);p.y=surface_height(p.x,p.z)+.004;ring.append(p)
		for j in 8:
			for p in [center,ring[(j+1)%8],ring[j]]:st.set_normal(Vector3.UP);st.add_vertex(p)
		var node:=MeshInstance3D.new();node.mesh=st.commit();node.material_override=StreetDetail.material(Color("d1d5cf") if i%3 else Color("ededdf"),"asphalt");add_child(node)
	for x in [-5.2,-2.2,7.6,12.1,-13.0]:
		var z:=2.30 if x>0 else 11.1
		StreetDetail.rotated_box(details,Vector3(x,surface_height(x,z)+.012,z),Vector3(.12,.008,.20),Vector3(0,x*.42,0),StreetDetail.material(Color("b1b2a0")))
func build_limits() -> void:
	# Collision-only edges preserve a continuous view along the neighborhood.
	for x in [-27.75,27.75]:RetailDetails.collision(self,Vector3(x,grade(x)+2.0,4),Vector3(.25,6,40))
