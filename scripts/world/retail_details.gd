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
	var plastic:=SurfaceMaterials.make("plastic",color)
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
static func display_pallet(parent: Node3D,at: Vector3) -> Node3D:
	var root:=Node3D.new();root.name="BeverageDisplay";parent.add_child(root);root.position=at;root.add_to_group("beverage_displays")
	var batch:=PropBatch.new();batch.name="CratesAndPallet";root.add_child(batch)
	var wood:=SurfaceMaterials.make("pallet_wood");var plastic:=SurfaceMaterials.make("plastic",Color("28527e"))
	# Skids, nine support blocks, rails and deck meet physically at each layer.
	for x in [-.51,0,.51]:
		SurfaceMaterials.wood_box(batch,Vector3(x,.018,0),Vector3(.14,.036,.86),wood)
		for z in [-.31,0,.31]:SurfaceMaterials.wood_box(batch,Vector3(x,.069,z),Vector3(.14,.066,.14),wood)
		SurfaceMaterials.wood_box(batch,Vector3(x,.116,0),Vector3(.14,.028,.84),wood)
	for z in [-.35,-.175,0,.175,.35]:SurfaceMaterials.wood_box(batch,Vector3(0,.146,z),Vector3(1.30,.032,.14),wood)
	for level in 2:
		for x in [-.315,.315]:
			for z in [-.215,.215]:display_crate(batch,Vector3(x,.165+level*.410,z),plastic,"soda_0" if x<0 else "soda_1")
	batch.flush();collision(root,Vector3(0,.4925,0),Vector3(1.30,.985,.88))
	return root
static func display_crate(batch: PropBatch,at: Vector3,plastic: Material,sku: String) -> void:
	batch.add_box(at+Vector3(0,.02,0),Vector3(.58,.04,.40),plastic)
	for x in [-.2735,.2735]:
		for z in [-.1835,.1835]:batch.add_box(at+Vector3(x,.215,z),Vector3(.033,.39,.033),plastic)
	for z in [-.19,.19]:
		for y in [.12,.26,.38]:batch.add_box(at+Vector3(0,y,z),Vector3(.58,.04,.025),plastic)
		for x in [-.20,-.07,.07,.20]:batch.add_box(at+Vector3(x,.18,z),Vector3(.022,.20,.025),plastic)
		for x in [-.20,.20]:batch.add_box(at+Vector3(x,.315,z),Vector3(.16,.07,.025),plastic)
	for x in [-.277,.277]:
		for y in [.12,.26,.38]:batch.add_box(at+Vector3(x,y,0),Vector3(.025,.04,.40),plastic)
		for z in [-.13,.13]:batch.add_box(at+Vector3(x,.315,z),Vector3(.025,.07,.10),plastic)
	for x in [-.085,.085]:batch.add_box(at+Vector3(x,.145,0),Vector3(.010,.21,.34),plastic)
	batch.add_box(at+Vector3(0,.145,0),Vector3(.50,.21,.010),plastic)
	for x in [-.17,0,.17]:
		for z in [-.095,.095]:batch.add_product(sku,at+Vector3(x,.041,z),0,Vector3.ONE*.95)
