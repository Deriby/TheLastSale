class_name RetailDetails
extends RefCounted
static func panel(parent: Node3D,at: Vector3,size: Vector2,art: String,angle := 0.0,emission := 0.0) -> MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=size;node.mesh=mesh;node.material_override=ProductLibrary.material(art,emission);parent.add_child(node);node.position=at;node.rotation.y=angle;return node
static func collision(parent: Node3D,at: Vector3,size: Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();parent.add_child(body)
	var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;col.position=at;body.add_child(col);return body
static func shadow(parent: Node3D,at: Vector3,size: Vector2) -> void:
	var node:=panel(parent,at,size,"contact",0,0)
	node.rotation.x=-PI/2
	node.material_override=ProductLibrary.material("contact",0,.75)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func price_strip(parent: Node3D,at: Vector3,width: float,angle: float) -> void:
	panel(parent,at,Vector2(width,.055),"price",angle)
static func plastic_crate(parent: Node3D,at: Vector3,color: Color,stack_count := 1) -> void:
	var batch:=PropBatch.new();parent.add_child(batch);batch.position=at
	var plastic:=Geo.material(color)
	for level in stack_count:
		var y:=level*.31
		batch.add_box(Vector3(0,y+.03,0),Vector3(.59,.06,.39),plastic)
		for x in [-.28,.28]:
			for z in [-.18,.18]:batch.add_box(Vector3(x,y+.17,z),Vector3(.04,.29,.04),plastic)
		for z in [-.18,.18]:
			for h in [.11,.22,.30]:batch.add_box(Vector3(0,y+h,z),Vector3(.60,.045,.035),plastic)
			for x in [-.21,-.07,.07,.21]:batch.add_box(Vector3(x,y+.17,z),Vector3(.025,.28,.025),plastic)
		for x in [-.28,.28]:
			for h in [.11,.22,.30]:batch.add_box(Vector3(x,y+h,0),Vector3(.04,.045,.39),plastic)
		for x in [-.18,0,.18]:
			for z in [-.09,.09]:batch.add_product("beer_0",Vector3(x,y+.06,z),0,Vector3.ONE*.85)
	batch.flush()
	collision(parent,at+Vector3(0,.155*stack_count,0),Vector3(.60,.31*stack_count,.40))
static func display_pallet(parent: Node3D,at: Vector3) -> void:
	var pallet: Node3D=load("res://scenes/world/props/pallet.tscn").instantiate();parent.add_child(pallet);pallet.position=at
	var batch:=PropBatch.new();parent.add_child(batch)
	for y in range(2):
		for x in range(5):
			for z in range(3):batch.add_product("soda_1" if x<2 else "soda_0",at+Vector3(-.5+x*.24,.23+y*.36,-.32+z*.25),0)
	batch.flush();collision(parent,at+Vector3(0,.45,0),Vector3(1.3,.9,1.0))
static func checkout(parent: Node3D) -> MeshInstance3D:
	var black:=Geo.material(Color.WHITE,"res://assets/textures/depot/counter.png")
	var main:=Geo.box(parent,Vector3(4.35,.53,-2.8),Vector3(2.55,1.06,.75),black)
	var wood:=Geo.material(Color("b4a68a"))
	Geo.box(parent,Vector3(4.35,1.1,-2.8),Vector3(2.68,.08,.9),wood,false)
	Geo.box(parent,Vector3(4.35,.09,-2.40),Vector3(2.5,.15,.045),Geo.material(Color("6a7065")),false)
	for x in [3.12,3.95,4.79,5.61]:Geo.box(parent,Vector3(x,.55,-2.415),Vector3(.018,.87,.02),Geo.material(Color("73786b")),false)
	# Monitor faces the cashier; customer-facing back remains plausible.
	var monitor:=Node3D.new();parent.add_child(monitor);monitor.position=Vector3(4.5,1.38,-2.8);monitor.rotation.y=PI
	Geo.box(monitor,Vector3.ZERO,Vector3(.47,.30,.06),Geo.material(Color("252c29")),false)
	panel(monitor,Vector3(0,0,.035),Vector2(.42,.255),"register_screen",0,.20)
	Geo.box(monitor,Vector3(0,-.20,0),Vector3(.035,.16,.04),Geo.material(Color("333c36")),false)
	Geo.box(parent,Vector3(4.5,1.165,-3.05),Vector3(.44,.025,.16),Geo.material(Color("373f38")),false)
	var keys:=PropBatch.new();parent.add_child(keys)
	for x in 12:
		for z in 4:keys.add_box(Vector3(4.3+x*.034,1.182,-3.11+z*.032),Vector3(.026,.005,.022),Geo.material(Color("7d8273")))
	keys.flush()
	Geo.box(parent,Vector3(3.85,1.23,-2.92),Vector3(.20,.18,.24),Geo.material(Color("a8ac9b")),false)
	Geo.box(parent,Vector3(3.85,1.327,-2.92),Vector3(.13,.005,.04),Geo.material(Color("292f28")),false)
	var receipt:=Geo.box(parent,Vector3(3.85,1.33,-2.84),Vector3(.11,.004,.19),Geo.material(Color("e0dfc5")),false);receipt.rotation.x=.13
	panel(parent,Vector3(5.12,1.32,-2.40),Vector2(.17,.22),"pix_sign")
	Geo.box(parent,Vector3(5.12,1.16,-2.44),Vector3(.19,.025,.13),Geo.material(Color("526354")),false)
	var goods:=PropBatch.new();parent.add_child(goods)
	for x in range(4):goods.add_product("can_"+str(x%3),Vector3(3.30+x*.12,1.15,-2.60))
	for x in range(2):goods.add_product("snack_3",Vector3(5.3+x*.17,1.15,-2.85))
	goods.flush()
	Geo.sign_text(parent,"CAIXA",Vector3(4.2,2.3,-2.78),28,Color("b0b4a0"))
	return main
