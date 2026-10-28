class_name DepotProp
extends Node3D
@export_enum("shelf", "fridge", "crate", "pallet") var kind := "shelf"
@export var tint := Color("465347")
var hinge: Node3D
var opened := false
var batches: Dictionary = {}
func _ready() -> void:
	match kind:
		"shelf": make_shelf()
		"fridge": make_fridge()
		"crate": make_crate()
		"pallet": make_pallet()
func make_shelf() -> void:
	var metal := Geo.material(Color("292d2a"))
	for x in [-.55,.55]:
		for z in [-1.4,1.4]:Geo.box(self,Vector3(x,.8,z),Vector3(.055,1.6,.055),metal,false)
	for y in [.16,.61,1.07,1.53]:
		Geo.box(self,Vector3(0,y,0),Vector3(1.15,.06,2.9),metal,y==.16)
		for x in [-.34,.34]:
			for z in range(8): bottle(Vector3(x,y+.18,-1.22+z*.35),Color.from_hsv(float(z%4)/5,.55,.65))
	Geo.box(self,Vector3(0,.75,0),Vector3(.06,1.5,2.9),metal,false)
	Geo.sign_text(self,"BEBIDAS  •  OFERTAS",Vector3(0,1.7,1.48),22)
func bottle(pos: Vector3, color: Color) -> void:
	batch_cylinder(pos,.065,.28,color)
	batch_cylinder(pos+Vector3(0,.17,0),.025,.09,Color("c5b67d"))
	batch_cylinder(pos,.067,.09,Color("d8cc9d"))
func batch_cylinder(pos: Vector3,radius: float,height: float,color: Color) -> void:
	var key:=str(radius)+str(color)
	if not batches.has(key):
		var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=8
		var node:=MultiMeshInstance3D.new();node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=mesh;node.material_override=Geo.material(color);add_child(node)
		batches[key]={"node":node,"positions":[]}
	var data: Dictionary=batches[key]
	data.positions.append(pos)
	var multimesh: MultiMesh=data.node.multimesh
	multimesh.instance_count=data.positions.size()
	for i in data.positions.size():multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,data.positions[i]))
func make_fridge() -> void:
	var white := Geo.material(Color("d4d1bd"))
	Geo.box(self,Vector3(0,1.02,0),Vector3(1.04,2.04,.75),white)
	Geo.box(self,Vector3(0,1.08,.386),Vector3(.9,1.66,.018),Geo.material(Color("1e3434")),false)
	for y in [.45,.85,1.25,1.65]:
		Geo.box(self,Vector3(0,y,.44),Vector3(.87,.025,.2),white,false)
		for x in [-.32,-.16,0,.16,.32]:bottle(Vector3(x,y+.15,.46),tint)
	Geo.box(self,Vector3(0,2.0,.43),Vector3(1.04,.22,.1),Geo.material(tint, "",.4),false)
	Geo.sign_text(self,"GELADA",Vector3(0,2,.492),27)
	hinge = Node3D.new();add_child(hinge);hinge.position=Vector3(-.49,0,.6)
	var frame := Geo.material(Color("a3aba2"))
	for x in [0,.98]:Geo.box(hinge,Vector3(x,1.02,0),Vector3(.035,1.86,.04),frame,false)
	for y in [.09,1.95]:Geo.box(hinge,Vector3(.49,y,0),Vector3(1,.035,.04),frame,false)
	Geo.box(hinge,Vector3(.87,1.1,.05),Vector3(.035,.32,.04),frame,false)
	Geo.light(self,Vector3(0,1.3,.78),Color("c0e9e1"),.5,2.3)
func toggle() -> void:
	if hinge == null:return
	opened = not opened
	create_tween().tween_property(hinge,"rotation:y",-1.35 if opened else 0.0,.4)
func make_crate() -> void:
	Geo.box(self,Vector3(0,.23,0),Vector3(.65,.46,.44),Geo.material(Color.WHITE,"res://assets/textures/cardboard.png"))
	Geo.sign_text(self,"RETORNÁVEIS",Vector3(0,.26,.228),14,Color("332c23"))
func make_pallet() -> void:
	var wood:=Geo.material(Color("786446"))
	for x in [-.6,0,.6]:Geo.box(self,Vector3(x,.08,0),Vector3(.12,.16,1.1),wood,false)
	for z in [-.5,-.25,0,.25,.5]:Geo.box(self,Vector3(0,.18,z),Vector3(1.4,.07,.15),wood,false)
