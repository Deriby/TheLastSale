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
