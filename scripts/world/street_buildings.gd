class_name StreetBuildings
extends RefCounted
## Recognizable frontage sequence; depths and unphotographed backs remain estimates.
static func roof(root: Node3D,batch: PropBatch,width: float,depth: float,eaves: float,rise: float,color: Color) -> void:
	var tile:=StreetDetail.material(Color.WHITE,"terracotta",1.1)
	var half:=width*.5;var length:=sqrt(half*half+rise*rise)
	for side in [-1,1]:StreetDetail.rotated_box(batch,Vector3(side*half*.5,eaves+rise*.5,-depth*.5+.12),Vector3(length+.25,.10,depth+.55),Vector3(0,0,-side*atan2(rise,half)),tile)
	StreetDetail.triangle(root,Vector3(-half,eaves,.015),Vector3(half,eaves,.015),Vector3(0,eaves+rise,.015),StreetDetail.material(color,"render"))
	StreetDetail.beam(batch,Vector3(-half-.10,eaves,.26),Vector3(0,eaves+rise,.26),.065,StreetDetail.material(Color("ac7653")))
	StreetDetail.beam(batch,Vector3(0,eaves+rise,.26),Vector3(half+.10,eaves,.26),.065,StreetDetail.material(Color("ac7653")))
	RoofTiles.add_to(batch,width,depth,eaves,rise)
static func create(parent: Node3D,name: String,x: float,z: float,elevation: float,opposite: bool,kind: String) -> Node3D:
	if NeighborhoodFrontages.TYPES.has(kind):return NeighborhoodFrontages.create(parent,name,x,z,elevation,opposite,kind)
	var root:=Node3D.new();root.name=name;root.set_meta("frontage_kind",kind);parent.add_child(root);root.position=Vector3(x,elevation,z)
	if opposite:root.rotation.y=PI
	var batch:=PropBatch.new();root.add_child(batch)
	var cream:=StreetDetail.material(Color("e0dac0"),"cream")
	var gray:=StreetDetail.material(Color("b9bdba"),"render")
	match kind:
		"gray":
			Geo.box(root,Vector3(0,1.38,-2.8),Vector3(5.6,2.76,5.6),gray)
			batch.add_box(Vector3(0,2.84,-.06),Vector3(5.68,.16,.22),gray)
			StreetDetail.gate(batch,Vector3(-1.65,1.05,.06),.83,2.10,Color("b1a981"),true)
			StreetDetail.window(batch,Vector3(.72,1.73,.065),Vector2(1.58,.92))
			batch.add_box(Vector3(-1.1,.02,.26),Vector3(1.8,.04,.5),StreetDetail.material(Color("a8a185")))
			for i in 12:
				var a:=Vector3(-2.6+i*.44,3.01,-.03)
				for j in 8:
					var p:=TAU*j/8;var q:=TAU*(j+1)/8
					StreetDetail.beam(batch,a+Vector3(cos(p)*.25,sin(p)*.18,0),a+Vector3(cos(q)*.25,sin(q)*.18,0),.012,StreetDetail.material(Color("676e66")))
		"peach":
			var peach:=Color("c59379")
			Geo.box(root,Vector3(0,1.5,-3.3),Vector3(6.9,3.0,5.0),StreetDetail.material(peach,"render"))
			roof(root,batch,7.2,5.7,3.0,.86,peach)
			var wall:=StreetDetail.material(Color("b9b29a"),"stained")
			for pair in [Vector2(-2.75,1.35),Vector2(.1,2.5),Vector2(2.85,1.3)]:Geo.box(root,Vector3(pair.x,1.08,.05),Vector3(pair.y,2.16,.18),wall)
			StreetDetail.gate(batch,Vector3(-1.65,1.0,.15),.92,2.0,Color("b8b68d"))
			StreetDetail.gate(batch,Vector3(1.72,1.02,.15),1.9,2.04,Color("c2c1a1"))
			batch.add_box(Vector3(0,2.22,.05),Vector3(7.0,.10,.30),StreetDetail.material(Color("7f806c")))
		"yellow":
			Geo.box(root,Vector3(0,1.36,-2.8),Vector3(5.2,2.72,5.6),cream)
			roof(root,batch,5.45,5.8,2.7,.75,Color("d9d1b1"))
			StreetDetail.gate(batch,Vector3(-.65,1.22,.07),1.6,2.44,Color("b5b7a3"))
			StreetDetail.window(batch,Vector3(1.5,1.58,.07),Vector2(1.03,.8))
			StreetDetail.rotated_box(batch,Vector3(-.55,2.55,.48),Vector3(2.65,.07,1.1),Vector3(.13,0,0),StreetDetail.material(Color("787b65")))
		"market":
			var green:=StreetDetail.material(Color("bbceb2"),"render")
			Geo.box(root,Vector3(0,1.65,-3),Vector3(8.0,3.3,6.0),green)
			batch.add_box(Vector3(0,.45,.04),Vector3(8.03,.9,.08),StreetDetail.material(Color("487e62")))
			StreetDetail.panel(root,Vector3(0,2.88,.1),Vector2(7.85,.86),"market_sign")
			for door_x in [-2.05,1.82]:
				batch.add_box(Vector3(door_x,1.21,.08),Vector3(2.25,2.35,.09),StreetDetail.material(Color("343f38")))
				StreetDetail.gate(batch,Vector3(door_x,1.16,.14),2.12,2.20,Color("7f9180"),true)
				StreetDetail.rotated_box(batch,Vector3(door_x,2.38,.46),Vector3(2.5,.065,.88),Vector3(.15,0,0),StreetDetail.material(Color("5a7454")))
			for i in 5:
				batch.add_box(Vector3(-3.2+i*.47,.28,.42),Vector3(.42,.5,.4),StreetDetail.material(Color("596b44")))
				for j in 4:StreetDetail.leaf(batch,Vector3(-3.35+i*.47+(j%2)*.16,.55,.35+(j/2)*.14),Vector3(.07,.065,.065),StreetDetail.material(Color("bda24c") if i%2 else Color("677c3a")))
		"cassiano":
			Geo.box(root,Vector3(0,1.62,-3),Vector3(6.8,3.24,6),cream)
			batch.add_box(Vector3(0,.54,.055),Vector3(6.82,1.08,.07),StreetDetail.material(Color("5e8267"),"stained"))
			StreetDetail.gate(batch,Vector3(-2.1,1.1,.10),1.35,2.2,Color("c4c5af"))
			StreetDetail.panel(root,Vector3(.8,1.94,.105),Vector2(3.9,1.55),"cassiano")
			batch.add_box(Vector3(0,3.28,-.02),Vector3(6.95,.10,.35),StreetDetail.material(Color("b6b8a4")))
		"two_storey":
			Geo.box(root,Vector3(0,2.65,-3.2),Vector3(6.3,5.3,6.4),cream)
			batch.add_box(Vector3(0,1.35,.05),Vector3(6.3,2.7,.09),StreetDetail.material(Color("ad7c79"),"render"))
			StreetDetail.gate(batch,Vector3(0,1.2,.12),4.7,2.4,Color("b17f7c"))
			StreetDetail.window(batch,Vector3(-1.5,4.22,.05),Vector2(1.35,1.0))
			StreetDetail.window(batch,Vector3(1.55,4.22,.05),Vector2(1.25,1.0),true)
			batch.add_box(Vector3(.2,3.05,.42),Vector3(6.7,.14,1.2),gray)
			for i in 22:batch.add_box(Vector3(-3.05+i*.29,3.52,.92),Vector3(.025,.95,.025),StreetDetail.material(Color("70756a")))
			for y in [3.1,3.96]:batch.add_box(Vector3(.05,y,.92),Vector3(6.3,.035,.035),StreetDetail.material(Color("70756a")))
			roof(root,batch,6.65,6.6,5.3,.55,Color("d6ceb0"))
		"industrial":
			Geo.box(root,Vector3(0,1.88,-3.3),Vector3(9.0,3.76,6.6),StreetDetail.material(Color("aaa89b"),"render"))
			batch.add_box(Vector3(0,.9,.055),Vector3(9.02,1.8,.10),StreetDetail.material(Color("555d59"),"render"))
			StreetDetail.gate(batch,Vector3(-1.7,1.4,.12),4.9,2.8,Color("616d68"))
			batch.add_box(Vector3(0,3.82,0),Vector3(9.15,.1,.45),StreetDetail.material(Color("a6a391")))
		_:
			var c: Color=Color("a9b69b") if kind=="green" else Color("c6bb9c")
			Geo.box(root,Vector3(0,1.55,-3),Vector3(5.4,3.1,6),StreetDetail.material(c,"render"))
			StreetDetail.gate(batch,Vector3(-.55,1.25,.08),3.0,2.5,Color("969b83"))
			StreetDetail.window(batch,Vector3(1.8,1.83,.08),Vector2(.9,.65))
			batch.add_box(Vector3(0,3.17,0),Vector3(5.6,.12,.35),StreetDetail.material(c))
	batch.add_box(Vector3(0,-.12,-.05),Vector3(5.6,.25,.35),StreetDetail.material(Color("858775")))
	if kind=="yellow":
		NeighborhoodLights.porch(root,Vector3(-.65,2.43,.62))
		NeighborhoodLights.warm_window(root,Vector3(1.5,1.58,.126),Vector2(1.03,.8))
	if kind=="two_storey":NeighborhoodLights.warm_window(root,Vector3(1.55,4.22,.106),Vector2(1.25,1.0))
	if kind in ["gray","peach","industrial","cassiano"]:NeighborhoodLights.wall_wear(root,5.4 if kind!="peach" else 6.8)
	batch.flush();return root
