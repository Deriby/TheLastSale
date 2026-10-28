class_name DepotShell
extends Node3D
## Photographic envelope: tiled floor, pale high walls, steel trusses and dome fixtures.
var blockers: Array[Rect2] = []
var stock_door: Node3D
var fluorescent: OmniLight3D
func _ready() -> void:
	build_envelope();build_roof();build_partition();build_services()
func solid(at: Vector3,size: Vector3,mat: Material,nav := true) -> MeshInstance3D:
	if nav and at.y-size.y/2<1.8:blockers.append(Rect2(Vector2(at.x-size.x/2,at.z-size.z/2),Vector2(size.x,size.z)))
	return Geo.box(self,at,size,mat)
func build_envelope() -> void:
	var wall:=Geo.material(Color.WHITE,"res://assets/textures/depot/wall.png")
	wall.uv1_scale=Vector3.ONE*.55
	var floor_mat:=Geo.material(Color.WHITE,"res://assets/textures/depot/floor.png")
	floor_mat.uv1_scale=Vector3.ONE/0.60;floor_mat.roughness=.72;floor_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	solid(Vector3(0,-.14,-7.8),Vector3(12.2,.28,16.4),floor_mat,false)
	for x in [-6,6]:solid(Vector3(x,2.8,-8),Vector3(.24,5.6,16),wall)
	solid(Vector3(0,2.8,-16),Vector3(12,5.6,.24),wall)
	# Low tile skirting and a worn black entrance threshold from the entrance photograph.
	for x in [-5.86,5.86]:Geo.box(self,Vector3(x,.065,-8),Vector3(.035,.13,16),Geo.material(Color("8b9487")),false)
	Geo.box(self,Vector3(1.8,.007,-.10),Vector3(7.9,.014,.24),Geo.material(Color("323c36")),false)
	for x in [-6,-2.1,2.1,6]:solid(Vector3(x,1.9,0),Vector3(.28,3.8,.35),wall)
	solid(Vector3(0,4.7,0),Vector3(12.3,1.8,.35),Geo.material(Color("88908a"),"res://assets/textures/depot/wall.png"))
	var shutter:=Geo.material(Color("67716a"),"res://assets/textures/metal.png");shutter.uv1_scale=Vector3(1,3,1)
	solid(Vector3(-4.05,1.9,0),Vector3(3.65,3.8,.12),shutter)
	for x in [-5.92,-2.25,2.25,5.87]:Geo.box(self,Vector3(x,1.85,-.15),Vector3(.075,3.7,.075),Geo.material(Color("464f48")),false)
	for x in [0,4.05]:
		Geo.box(self,Vector3(x,3.65,0),Vector3(3.8,.3,.43),shutter,false)
		for y in [3.52,3.60,3.68,3.76]:Geo.box(self,Vector3(x,y,.225),Vector3(3.8,.018,.025),Geo.material(Color("404943")),false)
	Geo.sign_text(self,"DEPÓSITO DE BEBIDAS",Vector3(0,5.2,.23),60)
	Geo.sign_text(self,"JA",Vector3(0,4.38,.25),137,Color("c69e7b"))
	Geo.sign_text(self,"LOJA 2",Vector3(-4.2,4.4,.24),32)
	Geo.sign_text(self,"BEBIDAS • GELO • CONVENIÊNCIA",Vector3(4,4.45,.23),19)
func build_roof() -> void:
	var steel:=Geo.material(Color("697873"))
	var roof_mat:=Geo.material(Color.WHITE,"res://assets/textures/depot/roof.png");roof_mat.uv1_scale=Vector3.ONE*.65;roof_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	for side in [-1,1]:
		var sheet:=Geo.box(self,Vector3(side*3.02,5.72,-8),Vector3(6.1,.10,16.4),roof_mat,false)
		sheet.rotation.z=side*-.09
	for x in [-5.6,-3.8,-1.9,0,1.9,3.8,5.6]:
		Geo.box(self,Vector3(x,5.95-absf(x)*.09,-8),Vector3(.055,.10,16.3),steel,false)
	for z in [-.5,-3.5,-6.5,-9.5,-12.5,-15.5]:
		Geo.beam(self,Vector3(-5.9,5.05,z),Vector3(5.9,5.05,z),.065,steel)
		Geo.beam(self,Vector3(-5.9,5.42,z),Vector3(0,5.96,z),.07,steel)
		Geo.beam(self,Vector3(0,5.96,z),Vector3(5.9,5.42,z),.07,steel)
		for j in range(12):
			var x: float=-5.9+j*.9833
			var next: float=x+.9833
			Geo.beam(self,Vector3(x,5.05,z),Vector3(next,5.96-absf(next)*.091,z),.028,steel)
			Geo.beam(self,Vector3(x,5.05,z),Vector3(x,5.96-absf(x)*.091,z),.025,steel)
	# The reference has suspended domes, not flat glowing cylinders.
	for x in [-3.3,2.7]:
		for z in [-2.0,-5.7,-9.0]:
			var top_y:=5.95-absf(x)*.09
			Geo.cylinder(self,Vector3(x,(top_y+4.77)*.5,z),.009,top_y-4.77,steel)
			Geo.cylinder(self,Vector3(x,4.68,z),.255,.20,Geo.material(Color("adb9ad")),.07)
			Geo.cylinder(self,Vector3(x,4.575,z),.226,.025,Geo.material(Color("e8eee0"),"",1.0))
			var lamp:=Geo.light(self,Vector3(x,4.39,z),Color("e7eee3"),.85,6.3)
			lamp.omni_attenuation=1.2
			lamp.set_meta("normal_energy",.85)
			if x<0 and z==-9.0:fluorescent=lamp
			if z==-5.7:
				var spot:=SpotLight3D.new();add_child(spot);spot.position=Vector3(x,4.36,z);spot.rotation.x=-PI/2
				spot.light_color=Color("e7eee3");spot.light_energy=.5;spot.spot_range=6.8;spot.spot_angle=72
				spot.shadow_enabled=true;spot.shadow_bias=.04
func build_partition() -> void:
	var wall:=Geo.material(Color.WHITE,"res://assets/textures/depot/wall.png")
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
	# TV and cable on the wall, as photographed. The display stays off at night.
	var tv:=Geo.box(self,Vector3(-5.83,3.1,-6.6),Vector3(.09,.63,1.1),Geo.material(Color("202d29")),false)
	Geo.box(self,Vector3(-5.775,3.1,-6.6),Vector3(.008,.55,1.0),Geo.material(Color("2e3e39")),false)
	Geo.beam(self,Vector3(-5.8,3.4,-6.6),Vector3(-5.8,4.05,-6.6),.014,Geo.material(Color("3b4940")))
	Geo.box(self,Vector3(5.85,2.8,-.95),Vector3(.04,1.0,.72),Geo.material(Color("597e83"),"",.12),false)
	for y in range(8):Geo.box(self,Vector3(5.80,2.37+y*.12,-.95),Vector3(.06,.035,.78),conduit,false)
	RetailDetails.panel(self,Vector3(5.865,2.5,-5.1),Vector2(.76,1.14),"poster",-PI/2)
