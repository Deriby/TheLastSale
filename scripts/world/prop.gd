class_name DepotProp
extends Node3D
@export_enum("shelf", "fridge", "crate", "pallet", "endcap", "freezer") var kind := "shelf"
@export_enum("snacks", "beverages", "mixed") var shelf_style := "snacks"
@export var brand_index := 0
@export var needs_restock := false
@export var tint := Color("465347")
var hinge: Node3D
var opened := false
var products: PropBatch
var restock_count := 0
func _ready() -> void:
	products=PropBatch.new();products.name="Products";add_child(products)
	match kind:
		"shelf":make_shelf()
		"fridge":make_fridge()
		"crate":make_crate()
		"pallet":make_pallet()
		"endcap":make_endcap()
		"freezer":make_freezer()
	products.flush()
func make_shelf() -> void:
	var metal:=SurfaceMaterials.make("painted_metal",Color("242b27"))
	var edge:=SurfaceMaterials.make("painted_metal",Color("51574a"))
	for x in [-.55,.55]:
		for z in [-1.39,1.39]:
			products.add_box(Vector3(x,.8,z),Vector3(.045,1.60,.045),metal)
			products.add_box(Vector3(x,.035,z),Vector3(.085,.07,.085),edge)
	products.add_box(Vector3(0,.81,0),Vector3(.035,1.43,2.76),metal)
	for row in 5:
		var y:=.18+row*.34
		products.add_box(Vector3(0,y,0),Vector3(1.14,.035,2.88),metal)
		for side in [-1,1]:
			products.add_box(Vector3(side*.57,y-.025,0),Vector3(.025,.08,2.88),edge)
			RetailDetails.price_strip(self,Vector3(side*.586,y,0),2.76,side*PI/2)
			for index in 10:
				var z: float=-1.22+index*.27
				var sku: String
				if shelf_style=="snacks" and row<4:sku="snack_"+str((row*2+index/4+brand_index)%6)
				elif shelf_style=="mixed" and row<3:sku="snack_"+str((row+index/3+brand_index)%6)
				elif row==4:sku="soda_"+str((index/4+brand_index)%3) if shelf_style!="snacks" else "can_"+str((index/4)%3)
				elif row==3:sku="water" if index<5 else "spirits"
				else:sku="beer_"+str(index/5%2)
				products.add_product(sku,Vector3(side*.405,y+.022,z),side*PI/2)
				if not sku.begins_with("snack"):
					products.add_product(sku,Vector3(side*.245,y+.022,z),side*PI/2)
					if sku.begins_with("can"):products.add_product(sku,Vector3(side*.405,y+.15,z),side*PI/2)
	RetailDetails.collision(self,Vector3(0,.77,0),Vector3(1.14,1.54,2.88))
	RetailDetails.shadow(self,Vector3(0,.008,0),Vector2(1.45,3.15))
func make_fridge() -> void:
	var shell:=SurfaceMaterials.make("painted_metal",Color("c5cbc0"))
	var dark:=Geo.material(Color("293a34"))
	var brand_color: Color=[Color("a0893d"),Color("a93b34"),Color("396c85")][brand_index%3]
	products.add_box(Vector3(0,.08,0),Vector3(1.04,.16,.76),shell)
	products.add_box(Vector3(0,1.04,-.34),Vector3(1.04,1.94,.08),shell)
	for x in [-.49,.49]:products.add_box(Vector3(x,1.02,0),Vector3(.065,1.9,.76),shell)
	products.add_box(Vector3(0,2.04,0),Vector3(1.04,.18,.76),SurfaceMaterials.make("painted_metal",brand_color))
	products.add_box(Vector3(0,1.08,-.29),Vector3(.92,1.72,.025),dark)
	# Products are recessed behind the door, with a deliberately empty restock slot.
	for row in 5:
		var y:=.19+row*.35
		products.add_box(Vector3(0,y,.015),Vector3(.89,.025,.56),Geo.material(Color("9baca1")))
		for col in 6:
			if needs_restock and row==2 and col>=3:continue
			var sku: String
			if brand_index%3==0:sku="beer_"+str(col/3%2)
			elif brand_index%3==1:sku="soda_"+str(col/2%3)
			else:sku="water" if row>1 else "can_"+str(col/2%3)
			var scale_value:=Vector3.ONE*(.88 if sku.begins_with("soda") else .95)
			for depth in [-.16,.08]:products.add_product(sku,Vector3(-.365+col*.145,y+.015,depth),0,scale_value)
		RetailDetails.price_strip(self,Vector3(0,y,.31),.85,0)
	# Light strips, ventilation grille and manufacturer rail replace the plain block.
	var led:=Geo.material(Color("d8ece2"),"",1.2)
	for x in [-.445,.445]:products.add_box(Vector3(x,1.04,.27),Vector3(.016,1.73,.016),led)
	for y in [.04,.067,.094]:products.add_box(Vector3(0,y,.389),Vector3(.8,.008,.012),dark)
	RetailDetails.panel(self,Vector3(0,2.055,.389),Vector2(.96,.14),["beer_banner","soda_banner","water_banner"][brand_index%3],0,.12)
	hinge=Node3D.new();hinge.name="DoorHinge";add_child(hinge);hinge.position=Vector3(-.49,0,.40)
	var frame:=SurfaceMaterials.make("painted_metal",brand_color.darkened(.12))
	for x in [0,.98]:Geo.box(hinge,Vector3(x,1.065,0),Vector3(.032,1.82,.045),frame,false)
	for y in [.155,1.975]:Geo.box(hinge,Vector3(.49,y,0),Vector3(1,.032,.045),frame,false)
	var glass:=SurfaceMaterials.make("glass",Color(.53,.74,.68,.10));glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var pane:=Geo.box(hinge,Vector3(.49,1.065,0),Vector3(.935,1.77,.008),glass,false);pane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.box(hinge,Vector3(.87,1.08,.045),Vector3(.03,.40,.04),Geo.material(Color("a1aca0")),false)
	# Small diagonal glints suggest old glass without a screen-space reflection dependency.
	var glint:=Geo.material(Color(.69,.84,.81,.18));glint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var streak:=Geo.box(hinge,Vector3(.25,1.60,.015),Vector3(.022,.32,.003),glint,false);streak.rotation.z=-.35
	RetailDetails.collision(self,Vector3(0,1.05,-.02),Vector3(1.04,2.10,.76))
	RetailDetails.shadow(self,Vector3(0,.009,.02),Vector2(1.25,1.0))
func replenish(slot := -1) -> void:
	var index:=restock_count if slot<0 else slot
	products.add_product("beer_0",Vector3(.07+index*.14,.905,.08))
	products.add_product("beer_0",Vector3(.07+index*.14,.905,-.16))
	restock_count+=1;products.flush()
func bottle(pos: Vector3,_color: Color) -> void:
	# Legacy callers can add visible products without putting them outside the cabinet.
	products.add_product("beer_0",Vector3(pos.x,pos.y,minf(pos.z,.12)));products.flush()
func toggle() -> void:
	if hinge==null:return
	opened=not opened
	create_tween().tween_property(hinge,"rotation:y",-1.35 if opened else 0.0,.4)
func make_crate() -> void:
	var cardboard:=Geo.material(Color.WHITE,"res://assets/textures/depot/carton.png")
	Geo.box(self,Vector3(0,.23,0),Vector3(.65,.46,.44),cardboard)
	RetailDetails.panel(self,Vector3(0,.23,.223),Vector2(.59,.39),"carton")
	for x in [-.31,.31]:Geo.box(self,Vector3(x,.455,0),Vector3(.005,.009,.42),Geo.material(Color("7b633c")),false)
func make_pallet() -> void:
	var wood:=Geo.material(Color.WHITE,"res://assets/textures/depot/wood.png")
	for x in [-.6,0,.6]:products.add_box(Vector3(x,.08,0),Vector3(.12,.16,1.1),wood)
	for z in [-.5,-.25,0,.25,.5]:products.add_box(Vector3(0,.18,z),Vector3(1.4,.07,.15),wood)
	RetailDetails.shadow(self,Vector3(0,.006,0),Vector2(1.6,1.3))
func make_endcap() -> void:
	var steel:=Geo.material(Color("313e36"))
	for x in [-.33,.33]:products.add_box(Vector3(x,.87,0),Vector3(.025,1.73,.025),steel)
	for y in [.22,.52,.82,1.12,1.42,1.7]:products.add_box(Vector3(0,y,0),Vector3(.70,.02,.025),steel)
	for x in [-.15,.15]:
		for row in 5:
			products.add_product("toy_"+str((row+brand_index)%3),Vector3(x,.20+row*.29,.04))
	products.add_box(Vector3(0,.03,0),Vector3(.77,.04,.32),steel)
	RetailDetails.collision(self,Vector3(0,.8,0),Vector3(.7,1.6,.24))
func make_freezer() -> void:
	var white:=Geo.material(Color("cbd2c7"))
	var trim:=Geo.material(Color("82998e"))
	products.add_box(Vector3(0,.49,0),Vector3(1.64,.94,.72),white)
	products.add_box(Vector3(0,.985,0),Vector3(1.70,.055,.77),trim)
	for x in [-.41,.41]:
		products.add_box(Vector3(x,1.02,0),Vector3(.78,.035,.65),Geo.material(Color("9aada2")))
		products.add_box(Vector3(x,1.045,.28),Vector3(.22,.035,.035),white)
	for x in [-.72,.72]:products.add_box(Vector3(x,.025,0),Vector3(.10,.05,.50),Geo.material(Color("343d34")))
	RetailDetails.panel(self,Vector3(0,.55,.365),Vector2(1.30,.35),"water_banner")
	RetailDetails.collision(self,Vector3(0,.52,0),Vector3(1.7,1.04,.77))
	RetailDetails.shadow(self,Vector3(0,.008,0),Vector2(1.9,1.0))
