class_name ShopDetails
extends Node3D
## Four new counter photographs: wood desk, spirits behind staff, ice and cups.
var fan: Node3D
func _init() -> void:
	name="ShopDetails";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	build_staff_wall();build_entrance();build_services();build_wear()
static func cup_display(parent: Node3D,at: Vector3) -> void:
	var root:=Node3D.new();root.name="ThermalCupDisplay";root.position=at;root.rotation.y=-PI/2;parent.add_child(root)
	var batch:=PropBatch.new();root.add_child(batch);var steel:=Geo.material(Color("242a29"))
	for x in [-.48,.48]:batch.add_box(Vector3(x,.98,0),Vector3(.035,1.96,.035),steel)
	batch.add_box(Vector3(0,1.03,-.13),Vector3(.98,1.88,.025),steel)
	for row in 5:
		var y:=.12+row*.37
		batch.add_box(Vector3(0,y,.025),Vector3(1.0,.035,.34),steel)
		for i in 5:batch.add_product("cup_"+str((i+row)%5),Vector3(-.38+i*.19,y+.018,.06),0,Vector3.ONE*(1.12 if row==4 else 1.0))
	SceneDetail.panel(root,Vector3(.21,1.46,.235),Vector2(.27,.38),"cup_offer")
	batch.flush();RetailDetails.collision(root,Vector3(0,.98,0),Vector3(1.02,1.96,.40))
func build_staff_wall() -> void:
	var root:=Node3D.new();root.name="CashierSpiritsWall";root.position=Vector3(-5.72,0,-2.75);root.rotation.y=PI/2;add_child(root)
	var batch:=PropBatch.new();root.add_child(batch);var wood:=SurfaceMaterials.make("wood",Color("b5aa8b"))
	for x in [-.91,.91]:SurfaceMaterials.wood_box(batch,Vector3(x,1.05,.02),Vector3(.045,2.1,.33),wood)
	SurfaceMaterials.wood_box(batch,Vector3(0,1.05,-.13),Vector3(1.84,2.1,.035),wood)
	for row in 5:
		var y:=.12+row*.40;SurfaceMaterials.wood_box(batch,Vector3(0,y,.03),Vector3(1.84,.035,.34),wood)
		for i in 12:batch.add_product(("spirits_"+str(i/4%3) if row==1 or row==2 else "spirits"),Vector3(-.79+i*.14,y+.018,.06),0,Vector3.ONE*1.07)
	batch.flush()
	RetailDetails.collision(root,Vector3(0,1.05,.03),Vector3(1.84,2.1,.34))
	# Upright ice freezer at the entrance end of the employee's wall.
	var freezer:=Node3D.new();freezer.name="UprightIceFreezer";freezer.position=Vector3(-5.45,0,-.65);freezer.rotation.y=PI/2;add_child(freezer)
	Geo.box(freezer,Vector3(0,1.05,0),Vector3(.83,2.10,.67),SurfaceMaterials.make("painted_metal",Color("d0d5c8")))
	SceneDetail.panel(freezer,Vector3(0,1.12,.344),Vector2(.72,1.67),"ice_freezer")
	Geo.box(freezer,Vector3(.32,1.16,.38),Vector3(.025,.38,.025),Geo.material(Color("656f65")),false)
	for y in [.10,.14,.18]:Geo.box(freezer,Vector3(0,y,.34),Vector3(.65,.012,.015),Geo.material(Color("71796e")),false)
	# A tucked employee chair: no additional obstruction in the working corridor.
	var chair:=PropBatch.new();chair.name="CashierChair";add_child(chair)
	var plastic:=Geo.material(Color("949e90"))
	chair.add_box(Vector3(-5.20,.47,-3.93),Vector3(.41,.05,.40),plastic)
	chair.add_box(Vector3(-5.41,.77,-3.93),Vector3(.04,.56,.40),plastic)
	for x in [-5.36,-5.04]:
		for z in [-4.08,-3.78]:StreetDetail.beam(chair,Vector3(x,.45,z),Vector3(x,.03,z),.025,plastic)
	chair.flush()
func build_entrance() -> void:
	var batch:=PropBatch.new();batch.name="EntranceHardware";add_child(batch)
	var steel:=Geo.material(Color("333a37"));var conduit:=Geo.material(Color("a2a698"))
	# Roller motors, drive shafts, tracks and the small camera visible over the doors.
	for x in [0.0,4.05]:
		batch.add_box(Vector3(x,3.64,-.30),Vector3(3.7,.12,.10),steel)
		for end in [-1.74,1.74]:
			Geo.cylinder(self,Vector3(x+end,3.72,-.28),.085,.17,Geo.material(Color("8c7352")))
		batch.add_box(Vector3(x+1.45,3.72,-.27),Vector3(.26,.18,.24),steel)
		StreetDetail.beam(batch,Vector3(x+1.45,3.70,-.38),Vector3(x+1.45,4.02,-.38),.025,conduit)
	var camera:=Node3D.new();camera.name="DecorativeDoorCamera";add_child(camera);camera.position=Vector3(-1.78,3.25,-.34);camera.rotation=Vector3(-.3,.6,0)
	Geo.box(camera,Vector3.ZERO,Vector3(.15,.12,.24),Geo.material(Color("bdc3b4")),false)
	Geo.box(camera,Vector3(0,0,.125),Vector3(.09,.07,.01),steel,false)
	StreetDetail.beam(batch,Vector3(-1.78,3.28,-.36),Vector3(-1.78,3.65,-.36),.035,conduit)
	# Blue cylinders grouped by the centre pier, as in the inside-to-outside photo.
	for x in [1.76,2.38]:
		for level in 2:
			var y:=.04+level*.52
			Geo.cylinder(self,Vector3(x,y+.23,-.37),.22,.40,Geo.material(Color("426d8b") if level else Color("929c9b")),.19)
			Geo.cylinder(self,Vector3(x,y+.45,-.37),.10,.08,Geo.material(Color("52788d")),.12)
			batch.add_box(Vector3(x,y+.49,-.37),Vector3(.14,.055,.10),Geo.material(Color("3f5e6a")))
	# Worn entrance mat and a light switch/outlets near the worker.
	batch.add_box(Vector3(.30,.006,-.52),Vector3(1.20,.012,.58),Geo.material(Color("3f4c49")))
	for z in [-2.85,-.50]:
		batch.add_box(Vector3(-5.855,1.32,z),Vector3(.025,.16,.10),Geo.material(Color("afb7a8")))
		batch.add_box(Vector3(-5.836,1.32,z),Vector3(.018,.07,.035),steel)
	batch.flush()
func build_services() -> void:
	var batch:=PropBatch.new();batch.name="InteriorConduits";add_child(batch);var cable:=Geo.material(Color("5e685f"))
	for x in [-5.83,5.83]:
		StreetDetail.beam(batch,Vector3(x,2.63,-.30),Vector3(x,2.63,-10.7),.025,cable)
		for z in [-1,-4,-7,-10]:batch.add_box(Vector3(x,2.63,z),Vector3(.05,.08,.08),cable)
	StreetDetail.beam(batch,Vector3(-5.82,1.35,-2.85),Vector3(-5.82,2.63,-2.85),.02,cable)
	# Wall television observed above the refrigerated row.
	var tv:=Node3D.new();tv.name="WallTelevision";add_child(tv);tv.position=Vector3(-5.82,3.0,-6.0);tv.rotation.y=PI/2
	Geo.box(tv,Vector3.ZERO,Vector3(.94,.56,.06),Geo.material(Color("272f2b")),false)
	SceneDetail.panel(tv,Vector3(0,0,.035),Vector2(.87,.49),"tv_screen",0,.05)
	StreetDetail.beam(batch,Vector3(-5.82,2.74,-6),Vector3(-5.82,2.64,-6),.012,cable)
	# Small wall fan gives the lit shop a quiet continuous movement.
	var support:=Node3D.new();support.name="WallFan";add_child(support);support.position=Vector3(5.78,3.10,-4.0);support.rotation.y=-PI/2
	var guard:=Geo.material(Color("727c70"));var motor:=Geo.material(Color("4c5750"))
	Geo.box(support,Vector3(0,-.22,-.08),Vector3(.10,.20,.13),guard,false)
	for ring in [0.25,0.30]:
		for i in 24:StreetDetail.beam(batch,support.to_global(Vector3(sin(i*TAU/24)*ring,cos(i*TAU/24)*ring,.08)),support.to_global(Vector3(sin((i+1)*TAU/24)*ring,cos((i+1)*TAU/24)*ring,.08)),.009,guard)
	fan=Node3D.new();support.add_child(fan)
	for i in 3:
		var blade:=Geo.box(fan,Vector3(sin(i*TAU/3)*.12,cos(i*TAU/3)*.12,0),Vector3(.095,.23,.012),motor,false);blade.rotation.z=-i*TAU/3+.25
	for i in 8:StreetDetail.beam(batch,support.to_global(Vector3.ZERO),support.to_global(Vector3(sin(i*TAU/8)*.30,cos(i*TAU/8)*.30,.08)),.006,guard)
	batch.flush()
	for data in batch.groups.values():
		data.node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;data.node.add_to_group("non_shadow_cables")
func build_wear() -> void:
	for at in [Vector3(-3.12,.012,-2.8),Vector3(.2,.012,-1.4),Vector3(4.6,.012,-8.2)]:SceneDetail.decal(self,at,Vector2(1.8,1.1),"floor_wear",.4)
	# Hanging white wire hooks and a few empty positions on the snack end.
	var hooks:=PropBatch.new();hooks.name="SnackHooks";add_child(hooks);var white:=Geo.material(Color("c1c6b4"))
	for row in 4:
		for x in [-2.16,-1.92,-1.68]:
			var y:=.45+row*.30
			StreetDetail.beam(hooks,Vector3(x,y,-3.36),Vector3(x,y,-3.10),.009,white)
			StreetDetail.beam(hooks,Vector3(x,y,-3.10),Vector3(x,y+.035,-3.10),.009,white)
			if row%2==0:hooks.add_product("snack_"+str(row+1),Vector3(x,y-.17,-3.23),0,Vector3.ONE*.75)
	hooks.flush()
func _process(delta: float) -> void:
	if fan!=null:fan.rotation.z=fposmod(fan.rotation.z+delta*7.5,TAU)
