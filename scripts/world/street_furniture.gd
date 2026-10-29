class_name StreetFurniture
extends RefCounted
static func tree(parent: Node3D,at: Vector3,height:=3.8,variation:=0) -> void:
	var root:=Node3D.new();root.name="StreetTree";parent.add_child(root);root.position=at
	var bark:=SurfaceMaterials.make("bark")
	var trunk:=Geo.cylinder(root,Vector3(0,height*.30,0),.065,height*.60,bark);trunk.mesh.radial_segments=16
	NeighborhoodProps.obstacle(root,Vector3(0,height*.30,0),Vector3(.13,height*.60,.13))
	var batch:=PropBatch.new();root.add_child(batch)
	var wind:=FoliageWind.new()
	for color in [Color("667454"),Color("4d6347"),Color("7a8258")]:
		var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/foliage.gdshader");mat.set_shader_parameter("leaf_color",color);mat.set_shader_parameter("leaf_texture",load("res://assets/textures/mood/leaves.png"));wind.materials.append(mat)
	var seed_angle:=fposmod(at.x*1.71+at.z*.43,TAU)
	var crown_width: float=[1.0,.65,1.35][posmod(variation,3)]
	for i in 5:
		var angle:=i*2.4+seed_angle
		var end:=Vector3(sin(angle)*.6*crown_width,height*(.68+i*.045),cos(angle)*.45*crown_width)
		NeighborhoodProps.tube(batch,Vector3(0,height*.43,0),end,.021,bark)
	var leaf_mesh:=QuadMesh.new();leaf_mesh.size=Vector2(1.2,1.0)
	for i in 23:
		var angle:=i*2.4+seed_angle
		var pos:=Vector3(sin(angle)*(.24+(i%4)*.18)*crown_width,height*.68+sin(i*1.7+seed_angle)*(.8 if variation==1 else .67),cos(angle)*.63*crown_width)
		for crossed in 2:
			var basis:=Basis.from_euler(Vector3(.25*sin(i),angle+crossed*PI/2,.18*cos(i)))
			batch.add_instance("leaf_cards_"+str(i%3),leaf_mesh,wind.materials[i%3],Transform3D(basis,pos))
	batch.flush();root.add_child(wind)
static func car(parent: Node3D,at: Vector3,_color: Color,angle:=0.0,kind:="hatchback") -> void:
	NeighborhoodCar.create(parent,at,kind,angle)
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
	var light:=SpotLight3D.new();light.name="StreetLamp";root.add_child(light);light.position=Vector3(0,7.98,arm_side*1.65)
	light.look_at_from_position(light.global_position,root.to_global(Vector3(0,-.10,arm_side*3.0)))
	light.light_color=Color("efd0a3");light.light_energy=4.8;light.spot_range=14.5;light.spot_angle=35;light.spot_attenuation=1.15
	light.set_meta("normal_energy",4.8)
	light.shadow_enabled=at.x<10;light.shadow_bias=.10;light.shadow_normal_bias=.8
	light.light_cull_mask=11
	light.set_meta("mood_shadow",at.x<10);light.set_meta("unstable_lamp",at.x>10)
	NeighborhoodLights.halo(root,Vector3(0,7.95,arm_side*1.65),1.0)
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
