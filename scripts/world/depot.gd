class_name Depot
extends Node3D
var blockers: Array[Rect2] = []
var crates: Dictionary = {}
var stock_door: Node3D
var old_door: Node3D
var fridge_target: Node3D
var fluorescent: OmniLight3D
var felps: Node3D
var counter: Node3D
func _ready() -> void:
	build_shell()
	build_furniture()
	build_stock()
	build_staff()
func solid(pos: Vector3,size: Vector3,mat: Material,nav := true) -> MeshInstance3D:
	if nav and pos.y-size.y/2<1.8:blockers.append(Rect2(Vector2(pos.x-size.x/2,pos.z-size.z/2),Vector2(size.x,size.z)))
	return Geo.box(self,pos,size,mat)
func prop(kind: String,pos: Vector3,angle := 0.0,options: Dictionary = {}) -> DepotProp:
	var p: DepotProp=load("res://scenes/world/props/"+kind+".tscn").instantiate()
	for key in options:p.set(key,options[key])
	add_child(p);p.position=pos;p.rotation.y=angle
	return p
func interact(parent: Node3D,kind: String,id := "") -> Interaction:
	var i:=Interaction.new();i.kind=kind;i.identity=id;parent.add_child(i)
	return i
func build_shell() -> void:
	var shell:=DepotShell.new();shell.name="Architecture";add_child(shell)
	blockers.append_array(shell.blockers)
	stock_door=shell.stock_door;fluorescent=shell.fluorescent
	interact(stock_door,"door")
func build_furniture() -> void:
	# Continuous central gondolas, with grouped products instead of repeated colored pegs.
	for x in [-1.9,1.35]:
		for z in [-5.1,-8.25]:
			var style: String="snacks" if z==-5.1 else "beverages"
			if x>0 and z==-8.25:style="mixed"
			prop("shelf",Vector3(x,0,z),0,{"shelf_style":style,"brand_index":1 if x>0 else 0})
			blockers.append(Rect2(Vector2(x-.57,z-1.44),Vector2(1.14,2.88)))
		if x<0:
			prop("endcap",Vector3(x,0,-3.5),0,{"brand_index":0})
			blockers.append(Rect2(Vector2(x-.35,-3.62),Vector2(.7,.24)))
		else:
			ShopDetails.cup_display(self,Vector3(x,0,-3.0))
			blockers.append(Rect2(1.12,-3.52,.46,1.04))
	# Close-set equipment follows the unbroken refrigerated perimeter in the photos.
	for i in 5:
		var z: float=-4.8-i*1.12
		var cabinet:=prop("fridge",Vector3(-5.45,0,z),PI/2,{"brand_index":i%3,"needs_restock":i==0})
		blockers.append(Rect2(Vector2(-5.86,z-.53),Vector2(.82,1.06)))
		if i==0:fridge_target=cabinet;interact(cabinet,"fridge")
	for i in 7:
		var x: float=-4.8+i*1.10
		prop("fridge",Vector3(x,0,-10.5),0,{"brand_index":(i+1)%3})
		blockers.append(Rect2(Vector2(x-.52,-10.90),Vector2(1.04,.79)))
	counter=CheckoutFixture.new();add_child(counter)
	blockers.append(CheckoutFixture.FOOTPRINT)
	blockers.append(Rect2(-5.90,-3.70,.40,1.92))
	blockers.append(Rect2(-5.81,-1.10,.73,.90))
	blockers.append(Rect2(-5.38,-3.36,.52,.52))
	var detail:=ShopDetails.new();add_child(detail)
	blockers.append(Rect2(1.50,-.64,1.14,.54))
	prop("freezer",Vector3(5.28,0,-6.5),-PI/2)
	blockers.append(Rect2(Vector2(4.895,-7.35),Vector2(.77,1.70)))
	# Entrance display and blue returnable crates seen in interno7.
	RetailDetails.display_pallet(self,Vector3(4.60,0,-1.25))
	blockers.append(Rect2(Vector2(3.95,-1.75),Vector2(1.3,1.0)))
	for x in [-1.65,-1.0]:RetailDetails.plastic_crate(self,Vector3(x,0,-.85),Color("28527e"),3)
	blockers.append(Rect2(Vector2(-1.96,-1.06),Vector2(1.27,.42)))
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
	felps=FelpsActor.new();felps.name="Felps";felps.position=CheckoutFixture.STAFF_POSITION;felps.rotation.y=PI/2;add_child(felps)
	var talk:=interact(felps,"talk")
	for collider in counter.find_children("*","CollisionObject3D",true,false):collider.set_meta("interaction",talk)
func restore_state(player: DepotPlayer) -> void:
	for id in crates:
		if id in Session.stocked:
			crates[id].queue_free()
		elif id=="loose" and Session.organized:
			crates[id].position=Vector3(-3.8,.23,-13.8)
		elif id==Session.carried_id:player.pick_up(crates[id],id,true)
	for i in Session.stocked.size():fridge_target.replenish(i)
