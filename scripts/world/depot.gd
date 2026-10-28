class_name Depot
extends Node3D
var blockers: Array[Rect2] = []
var crates: Dictionary = {}
var stock_door: Node3D
var old_door: Node3D
var fridge_target: Node3D
var fluorescent: OmniLight3D
var felps: Node3D
var counter: MeshInstance3D
func _ready() -> void:
	build_shell()
	build_furniture()
	build_stock()
	build_staff()
func solid(pos: Vector3,size: Vector3,mat: Material,nav := true) -> MeshInstance3D:
	if nav and pos.y-size.y/2<1.8:blockers.append(Rect2(Vector2(pos.x-size.x/2,pos.z-size.z/2),Vector2(size.x,size.z)))
	return Geo.box(self,pos,size,mat)
func prop(kind: String,pos: Vector3,angle := 0.0) -> DepotProp:
	var p: DepotProp=load("res://scenes/world/props/"+kind+".tscn").instantiate()
	add_child(p);p.position=pos;p.rotation.y=angle
	return p
func interact(parent: Node3D,kind: String,id := "") -> Interaction:
	var i:=Interaction.new();i.kind=kind;i.identity=id;parent.add_child(i)
	return i
func build_shell() -> void:
	var wall:=Geo.material(Color("c3bd9f"),"res://assets/textures/plaster.png")
	var steel:=Geo.material(Color("545e60"))
	solid(Vector3(0,-.14,-7.8),Vector3(12.2,.28,16.4),Geo.material(Color.WHITE,"res://assets/textures/tile.png"),false)
	solid(Vector3(-6,3,-8),Vector3(.24,6,16),wall)
	solid(Vector3(6,3,-8),Vector3(.24,6,16),wall)
	solid(Vector3(0,3,-16),Vector3(12,6,.24),wall)
	for x in [-6,-2.1,2.1,6]:solid(Vector3(x,2,0),Vector3(.28,4,.35),wall)
	solid(Vector3(0,5.15,0),Vector3(12.3,2.7,.35),Geo.material(Color("727977"),"res://assets/textures/plaster.png"))
	# Left shutter closed; two selling bays rolled up.
	solid(Vector3(-4.05,1.9,0),Vector3(3.65,3.8,.12),Geo.material(Color("454e50"),"res://assets/textures/metal.png"))
	for x in [0,4.05]:Geo.box(self,Vector3(x,3.6,0),Vector3(3.8,.45,.42),steel,false)
	Geo.sign_text(self,"DEPÓSITO DE BEBIDAS",Vector3(0,5.65,.23),74)
	Geo.sign_text(self,"JA",Vector3(0,4.6,.25),160,Color("c99776"))
	Geo.sign_text(self,"LOJA 2",Vector3(-4.2,4.4,.24),39)
	Geo.sign_text(self,"BEBIDAS • GELO • CONVENIÊNCIA",Vector3(4,4.5,.23),21)
	# Roof beams, corrugated metal and pendant lamps follow interior photographs.
	var roof:=Geo.box(self,Vector3(0,6.25,-8),Vector3(12.4,.18,16.6),Geo.material(Color("888e87"),"res://assets/textures/metal.png"),false)
	roof.rotation.z=.025
	for z in [-1.0,-4.3,-7.6,-10.9,-14.3]:
		Geo.beam(self,Vector3(-6,5.5,z),Vector3(0,6.1,z),.08,steel)
		Geo.beam(self,Vector3(0,6.1,z),Vector3(6,5.5,z),.08,steel)
		Geo.beam(self,Vector3(-6,5.5,z),Vector3(6,5.5,z),.07,steel)
		for x in [-5,-3,-1,1,3,5]:Geo.beam(self,Vector3(x,5.5,z),Vector3(x+1,5.9,z),.045,steel)
	for x in [-3,2.8]:
		for z in [-2.2,-6,-9.3]:
			Geo.cylinder(self,Vector3(x,4.7,z),.3,.18,Geo.material(Color("bcbca6")),.09)
			Geo.cylinder(self,Vector3(x,4.59,z),.2,.025,Geo.material(Color("ffedc5"),"",1.2))
			var l:=Geo.light(self,Vector3(x,4.25,z),Color("f0e6c7"),1.8,7.0)
			if x<0 and z==-9.3:fluorescent=l
	Geo.sign_text(self,"OFERTAS DA SEMANA",Vector3(0,2.65,-10.6),42,Color("e1ba70"))
	# Fictitious stock partition; clear door is on the right, away from customer aisles.
	solid(Vector3(-1.1,2,-11.1),Vector3(9.8,4,.18),wall)
	solid(Vector3(5.85,2,-11.1),Vector3(.3,4,.18),wall)
	solid(Vector3(4.8,3.3,-11.1),Vector3(1.8,1.4,.18),wall)
	stock_door=Node3D.new();stock_door.name="StockDoor";add_child(stock_door);stock_door.position=Vector3(3.85,0,-11.05)
	Geo.box(stock_door,Vector3(.87,1.3,0),Vector3(1.7,2.6,.08),Geo.material(Color("677369"),"res://assets/textures/metal.png"))
	Geo.cylinder(stock_door,Vector3(1.55,1.2,.09),.05,.05,Geo.material(Color("c6b88c")))
	Geo.sign_text(stock_door,"ESTOQUE",Vector3(.87,1.9,.06),27)
	interact(stock_door,"door")
func build_furniture() -> void:
	for x in [-1.9,1.35]:
		for z in [-5.1,-8.25]:
			prop("shelf",Vector3(x,0,z))
			blockers.append(Rect2(Vector2(x-.62,z-1.5),Vector2(1.24,3)))
	for z in [-3.4,-5.1,-6.8,-8.5]:
		var p:=prop("fridge",Vector3(-5.45,0,z),PI/2)
		blockers.append(Rect2(Vector2(-6,z-.6),Vector2(1.15,1.2)))
		if z==-3.4:fridge_target=p;interact(p,"fridge")
	for x in [-3.6,-2.3,-1.0,.3,1.6]:
		var p:=prop("fridge",Vector3(x,0,-10.5));p.tint=Color("9b4c36")
		blockers.append(Rect2(Vector2(x-.57,-10.9),Vector2(1.14,.95)))
	# Checkout near right-hand entrance; its exact position is an approximation.
	var dark:=Geo.material(Color("403d32"))
	counter=solid(Vector3(4.35,.53,-2.8),Vector3(2.55,1.06,.75),dark)
	Geo.box(self,Vector3(4.35,1.1,-2.8),Vector3(2.65,.12,.85),Geo.material(Color("929184")),false)
	Geo.box(self,Vector3(4.5,1.35,-2.75),Vector3(.52,.34,.08),Geo.material(Color("282e2d")),false)
	Geo.box(self,Vector3(4.5,1.36,-2.69),Vector3(.45,.27,.018),Geo.material(Color("577a65"),"",.4),false)
	Geo.box(self,Vector3(4.5,1.16,-2.4),Vector3(.45,.05,.18),dark,false)
	Geo.sign_text(self,"CAIXA",Vector3(4.2,2.3,-2.78),38)
	Geo.box(self,Vector3(-5.85,3.4,-6),Vector3(.08,.65,1.1),Geo.material(Color("101c20")),false)
	var poster:=Geo.box(self,Vector3(5.86,2.4,-6),Vector3(.02,1.2,.9),Geo.material(Color("a68e44")),false)
	poster.rotation.y=0
	Geo.sign_text(self,"ÁGUA\nGELO\nCARVÃO",Vector3(5.8,2.4,-6),35).rotation.y=-PI/2
func add_crate(id: String,pos: Vector3) -> void:
	var c:=prop("crate",pos);c.name=id
	crates[id]=c
	interact(c,"crate",id)
func build_stock() -> void:
	Geo.light(self,Vector3(0,3.3,-13.4),Color("c3d0ac"),1.0,6)
	var p:=prop("pallet",Vector3(-3.8,0,-13.8));interact(p,"pallet")
	Geo.sign_text(self,"DEVOLUÇÕES",Vector3(-3.8,1.9,-14.5),26)
	add_crate("stock_1",Vector3(.5,0,-13.5))
	add_crate("stock_2",Vector3(1.5,0,-13.5))
	add_crate("loose",Vector3(3.4,0,-13.3))
	for x in [-4.2,-3.5,-2.8]:
		for y in [.0,.48,.96]:prop("crate",Vector3(x,y,-15.0))
	blockers.append(Rect2(Vector2(-4.7,-15.6),Vector2(2.4,1.2)))
	old_door=Node3D.new();add_child(old_door);old_door.position=Vector3(0,0,-15.82)
	Geo.box(old_door,Vector3(0,1.2,0),Vector3(1.3,2.4,.12),Geo.material(Color("3b443d"),"res://assets/textures/metal.png"))
	Geo.sign_text(old_door,"SEM ACESSO",Vector3(0,1.65,.08),22)
	interact(old_door,"note")
func build_staff() -> void:
	felps=Node3D.new();felps.name="Felps";add_child(felps);felps.position=Vector3(4.4,0,-3.9)
	var model: Node3D=load("res://assets/models/characters/Felps.glb").instantiate();felps.add_child(model)
	var ap: AnimationPlayer=model.find_child("AnimationPlayer",true,false)
	if ap:
		for key in ap.get_animation_list():
			if key.contains("cashier"):
				ap.get_animation(key).loop_mode=Animation.LOOP_LINEAR;ap.play(key)
	var body:=StaticBody3D.new();felps.add_child(body)
	var col:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.height=1.75;shape.radius=.25;col.shape=shape;col.position.y=.87;body.add_child(col)
	var talk:=interact(felps,"talk")
	for collider in counter.find_children("*","CollisionObject3D",true,false):collider.set_meta("interaction",talk)
func restore_state(player: DepotPlayer) -> void:
	for id in crates:
		if id in Session.stocked:
			crates[id].queue_free()
		elif id=="loose" and Session.organized:
			crates[id].position=Vector3(-3.8,.23,-13.8)
		elif id==Session.carried_id:player.pick_up(crates[id],id)
	for i in Session.stocked.size():fridge_target.bottle(Vector3(i*.2-.1,1.4,.48),Color("b69b37"))
