class_name DepotShell
extends Node3D
## Photographic envelope: tiled floor, pale high walls, steel trusses and dome fixtures.
var blockers: Array[Rect2] = []
var stock_door: Node3D
var fluorescent: OmniLight3D
var service_door: Node3D
func _init() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	build_envelope();build_roof();build_partition();build_services()
func solid(at: Vector3,size: Vector3,mat: Material,nav := true) -> MeshInstance3D:
	if nav and at.y-size.y/2<1.8:blockers.append(Rect2(Vector2(at.x-size.x/2,at.z-size.z/2),Vector2(size.x,size.z)))
	return Geo.box(self,at,size,mat)
func build_envelope() -> void:
	var wall:=SurfaceMaterials.make("wall")
	var floor_mat:=SurfaceMaterials.make("ceramic")
	var floor:=solid(Vector3(0,-.14,-8.0),Vector3(12.2,.28,16.0),floor_mat,false)
	floor.name="DepotFloor"
	floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	solid(Vector3(6,2.71,-8),Vector3(.24,5.42,16),wall)
	solid(Vector3(-6,2.2,-8),Vector3(.24,4.4,16),wall)
	solid(Vector3(-4.05,2.2,-16),Vector3(3.9,4.4,.24),wall)
	solid(Vector3(.875,2.71,-16),Vector3(5.95,5.42,.24),wall)
	solid(Vector3(5.875,2.71,-16),Vector3(.25,5.42,.24),wall)
	solid(Vector3(4.8,4.01,-16),Vector3(1.9,2.82,.24),wall)
	service_door=Node3D.new();service_door.name="ServiceDoor";add_child(service_door);service_door.position=Vector3(3.85,0,-16)
	Geo.box(service_door,Vector3(.95,1.3,0),Vector3(1.86,2.6,.10),Geo.material(Color("53685f"),"res://assets/textures/metal.png"))
	Geo.box(service_door,Vector3(1.65,1.15,.09),Vector3(.13,.04,.08),Geo.material(Color("c3bca7")),false)
	Geo.sign_text(service_door,"PÁTIO / GERADOR",Vector3(.95,1.8,.065),23)
	# Low tile skirting and a worn black entrance threshold from the entrance photograph.
	for x in [-5.86,5.86]:Geo.box(self,Vector3(x,.065,-8),Vector3(.035,.13,16),Geo.material(Color("8b9487")),false)
	Geo.box(self,Vector3(1.8,.007,-.10),Vector3(7.9,.014,.24),Geo.material(Color("323c36")),false)
	var facade:=DepotFacade.new();facade.name="Facade";add_child(facade);blockers.append_array(facade.blockers)
func build_roof() -> void:
	add_child(DepotRoof.new())
	var steel:=Geo.material(Color("697873"))
	# The reference has suspended domes, not flat glowing cylinders.
	for x in [-3.3,2.7]:
		for z in [-2.0,-5.7,-9.0]:
			var top_y:=DepotRoof.height_at(x,z)-.10
			var mid_y:=top_y-(.55 if top_y<5 else .97)
			var cable:=Geo.cylinder(self,Vector3(x,(top_y+mid_y+.09)*.5,z),.009,top_y-mid_y-.09,steel)
			cable.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;cable.add_to_group("non_shadow_cables")
			Geo.cylinder(self,Vector3(x,mid_y,z),.255,.20,Geo.material(Color("adb9ad")),.07)
			Geo.cylinder(self,Vector3(x,mid_y-.105,z),.226,.025,Geo.material(Color("e8eee0"),"",1.0))
			var lamp:=Geo.light(self,Vector3(x,mid_y-.29,z),Color("d2ddd0"),.16,3.8)
			lamp.name="CeilingFill";lamp.omni_attenuation=1.4
			lamp.set_meta("normal_energy",.16)
			if x<0 and z==-9.0:fluorescent=lamp
			if z==-5.7 or x<0 and z==-2.0:
				var spot:=SpotLight3D.new();add_child(spot);spot.position=Vector3(x,mid_y-.32,z);spot.rotation.x=-PI/2
				spot.name="CeilingPool";spot.light_color=Color("e8dfc9") if x<0 else Color("d1dfd5")
				spot.light_energy=.68 if x<0 else .95;spot.spot_range=6.8;spot.spot_angle=46;spot.spot_attenuation=1.3
				if x<0 and z==-2.0:
					spot.light_energy=.82;spot.look_at_from_position(spot.position,Vector3(-4.35,1.0,-2.8))
				spot.shadow_enabled=true;spot.shadow_bias=.06;spot.shadow_normal_bias=.7;spot.set_meta("mood_shadow",true)
				spot.light_cull_mask=1
func build_partition() -> void:
	var wall:=SurfaceMaterials.make("wall")
	# Fictitious stock/cold-room volume, made explicit in the reference notes.
	solid(Vector3(-1.1,1.6,-11.1),Vector3(9.8,3.2,.18),wall)
	solid(Vector3(5.85,1.6,-11.1),Vector3(.3,3.2,.18),wall)
	solid(Vector3(4.8,2.94,-11.1),Vector3(1.8,.52,.18),wall)
	Geo.box(self,Vector3(-1.1,3.24,-11.4),Vector3(9.9,.08,.7),Geo.material(Color("bfc9bd")),false)
	for x in [-5.2,-2.9,-.6,1.7]:Geo.box(self,Vector3(x,1.7,-10.996),Vector3(.018,2.98,.016),Geo.material(Color("bec5ba")),false)
	stock_door=Node3D.new();stock_door.name="StockDoor";add_child(stock_door);stock_door.position=Vector3(3.85,0,-11.05)
	Geo.box(stock_door,Vector3(.87,1.3,0),Vector3(1.7,2.6,.08),Geo.material(Color("89998b"),"res://assets/textures/metal.png"))
	for x in [.06,1.68]:Geo.box(stock_door,Vector3(x,1.3,.055),Vector3(.035,2.58,.025),Geo.material(Color("5c7062")),false)
	Geo.box(stock_door,Vector3(1.55,1.17,.085),Vector3(.12,.04,.06),Geo.material(Color("bdc3ae")),false)
	Geo.sign_text(stock_door,"ESTOQUE",Vector3(.87,1.9,.06),24,Color("d6ddce"))
	# A small compressor on top of the cold-room volume is visible in the photographs.
	Geo.box(self,Vector3(1.4,3.47,-11.3),Vector3(.78,.40,.45),Geo.material(Color("69766a")),false)
	for x in range(10):Geo.box(self,Vector3(1.09+x*.067,3.48,-11.061),Vector3(.025,.30,.012),Geo.material(Color("293c31")),false)
	Geo.beam(self,Vector3(1.6,3.52,-11.3),Vector3(1.6,4.0,-11.3),.025,Geo.material(Color("414d42")))
func build_services() -> void:
	var conduit:=Geo.material(Color("a6b2a3"))
	for x in [-5.84,5.84]:
		Geo.beam(self,Vector3(x,2.8,-.45),Vector3(x,2.8,-10.8),.025,conduit)
		Geo.beam(self,Vector3(x,2.8,-9),Vector3(x,5.35,-9),.025,conduit)
		Geo.box(self,Vector3(x,2.8,-9),Vector3(.04,.12,.12),conduit,false)
	# The photographed wall television and its cable are built by ShopDetails.
	Geo.box(self,Vector3(5.85,2.8,-.95),Vector3(.04,1.0,.72),Geo.material(Color("597e83"),"",.12),false)
	for y in range(8):Geo.box(self,Vector3(5.80,2.37+y*.12,-.95),Vector3(.06,.035,.78),conduit,false)
	RetailDetails.panel(self,Vector3(5.865,2.5,-5.1),Vector2(.76,1.14),"poster",-PI/2)
