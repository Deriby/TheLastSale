class_name CheckoutFixture
extends Node3D
## Local +Z is the customer side; the entire desk rotates along the left wall.
const POSITION:=Vector3(-4.25,0,-2.80)
const CUSTOMER_POSITION:=Vector3(-3.10,0,-2.80)
const STAFF_POSITION:=Vector3(-5.12,0,-3.10)
const FOOTPRINT:=Rect2(-4.75,-4.30,1.0,3.0)
var drawer: Node3D
var screen_text: Label3D
var drawer_tween: Tween
var drawer_is_open:=false
func _init() -> void:
	name="Checkout";position=POSITION;rotation.y=PI/2
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	var wood:=SurfaceMaterials.make("wood")
	var dark:=SurfaceMaterials.make("plastic",Color("252925"));var metal:=SurfaceMaterials.make("painted_metal",Color("555952"))
	var batch:=PropBatch.new();batch.name="CheckoutObjects";add_child(batch)
	var body:=Geo.box(self,Vector3(0,.53,0),Vector3(2.80,1.06,.82),wood)
	body.mesh=SurfaceMaterials.wood_box_mesh(Vector3(2.80,1.06,.82))
	SurfaceMaterials.wood_box(batch,Vector3(0,1.09,0),Vector3(2.98,.075,1.00),wood)
	for x in [-1.39,-.10,1.39]:batch.add_box(Vector3(x,.5,-.44),Vector3(.035,.94,.04),metal)
	# Employee-side cash drawer, lower open cubbies and tucked notebook.
	drawer=Node3D.new();drawer.name="CashDrawer";add_child(drawer)
	Geo.box(drawer,Vector3(.52,.83,-.435),Vector3(1.24,.24,.035),dark,false)
	Geo.box(drawer,Vector3(.52,.895,-.459),Vector3(.85,.025,.023),metal,false)
	Geo.box(drawer,Vector3(.52,.72,-.24),Vector3(1.18,.025,.42),dark,false)
	var lock:=Geo.cylinder(drawer,Vector3(1.02,.79,-.46),.022,.012,metal);lock.rotation.x=PI/2
	SurfaceMaterials.wood_box(batch,Vector3(.52,.58,-.455),Vector3(1.25,.08,.055),wood)
	batch.add_box(Vector3(.26,.625,-.465),Vector3(.63,.025,.18),Geo.material(Color("cecfba")))
	for x in range(14):batch.add_box(Vector3(-.035+x*.043,.63,-.566),Vector3(.012,.03,.012),dark)
	for x in [-.97,1.04]:
		batch.add_box(Vector3(x,.27,-.44),Vector3(.54,.38,.025),dark)
	batch.add_box(Vector3(-.93,.13,-.49),Vector3(.40,.14,.21),Geo.material(Color("a6ab9b")))
	# The monitor and keyboard face the employee, on the wall side.
	var monitor:=Node3D.new();monitor.name="RegisterMonitor";add_child(monitor);monitor.position=Vector3(.30,1.48,.045);monitor.rotation.y=PI
	Geo.box(monitor,Vector3.ZERO,Vector3(.55,.36,.055),dark,false)
	for i in 5:Geo.box(monitor,Vector3(0,-.10+i*.022,-.031),Vector3(.28,.007,.008),metal,false)
	Geo.box(monitor,Vector3(0,.005,.029),Vector3(.505,.315,.004),Geo.material(Color("d9e1c5")),false)
	screen_text=Label3D.new();screen_text.name="LiveRegisterScreen";monitor.add_child(screen_text)
	screen_text.position=Vector3(0,.005,.036);screen_text.pixel_size=.00125;screen_text.font_size=22;screen_text.outline_size=0;screen_text.modulate=Color("20362b")
	screen_text.text="JA • FRENTE DE CAIXA\n\nCAIXA DISPONÍVEL";screen_text.no_depth_test=false
	Geo.box(monitor,Vector3(0,-.23,-.005),Vector3(.035,.14,.04),dark,false)
	Geo.box(self,Vector3(.30,1.142,.06),Vector3(.27,.025,.20),dark,false)
	batch.add_box(Vector3(.32,1.148,-.29),Vector3(.48,.026,.19),dark)
	for row in 5:
		for key in 15:
			if row==4 and key>=3 and key<=8:continue
			batch.add_box(Vector3(.10+key*.030,1.165,-.365+row*.033),Vector3(.024,.009,.025),Geo.material(Color("62675d")))
	batch.add_box(Vector3(.265,1.165,-.233),Vector3(.175,.009,.025),Geo.material(Color("62675d")))
	batch.add_box(Vector3(.73,1.151,-.30),Vector3(.065,.034,.10),dark)
	for i in 8:StreetDetail.beam(batch,Vector3(.73-i*.035,1.132,-.22-i*.012),Vector3(.695-i*.035,1.132,-.232-i*.012),.004,dark)
	# Fixed barcode reader and its small red light, receipt printer and paper.
	batch.add_box(Vector3(-.22,1.24,.015),Vector3(.23,.23,.19),dark)
	batch.add_box(Vector3(-.22,1.27,-.087),Vector3(.18,.065,.009),Geo.material(Color("ad251a"),"",1.8))
	Geo.light(self,Vector3(-.22,1.24,-.14),Color("ee3022"),.28,.55)
	batch.add_box(Vector3(-.78,1.23,-.035),Vector3(.23,.20,.25),Geo.material(Color("424942")))
	batch.add_box(Vector3(-.78,1.336,-.04),Vector3(.17,.008,.024),dark)
	StreetDetail.rotated_box(batch,Vector3(-.78,1.336,-.135),Vector3(.11,.003,.16),Vector3(.09,0,.04),Geo.material(Color("e1dfc9")))
	# Yellow customer payment terminal, sloped screen and real keypad geometry.
	var terminal:=Node3D.new();terminal.name="PaymentTerminal";add_child(terminal);terminal.position=Vector3(-.94,1.15,.26);terminal.rotation=Vector3(-.20,PI,0)
	Geo.box(terminal,Vector3(0,.026,0),Vector3(.115,.055,.205),Geo.material(Color("d3ac32")),false)
	var display:=SceneDetail.panel(terminal,Vector3(0,.058,-.035),Vector2(.086,.096),"payment_screen",0,.24);display.rotation.x=-PI/2
	for row in 4:
		for col in 3:Geo.box(terminal,Vector3(-.031+col*.031,.058,.034+row*.018),Vector3(.022,.008,.012),Geo.material(Color("4c6054") if row<3 else [Color("92573b"),Color("a9954b"),Color("4b7d52")][col]),false)
	var notice:=SceneDetail.panel(self,Vector3(.10,1.131,.27),Vector2(.78,.36),"counter_notice");notice.rotation.x=-PI/2
	# Disposable cups, a bag of small goods and the customer's shopping.
	for i in 8:Geo.cylinder(self,Vector3(1.11,1.16+i*.012,.26),.043,.07,Geo.material(Color("d4d5c7")),.052)
	for i in 4:StreetDetail.rotated_box(batch,Vector3(1.14,1.18+i*.008,-.24),Vector3(.27,.008,.20),Vector3(0,.13*i,0),Geo.material(Color("b0b7a0")))
	for i in 2:batch.add_product("snack_"+str(i+1),Vector3(-1.19+i*.18,1.13,.02),.3,Vector3.ONE*.7)
	batch.flush()
func show_sale(sale: ShopSale) -> void:
	var status: String=["REGISTRAR PRODUTOS","RECEBER DINHEIRO","SEPARAR TROCO","ENTREGAR COMPRA","COMPRA CONCLUÍDA"][sale.phase]
	screen_text.text="JA • PEDIDO #%03d\n%s\nTOTAL %s\nRECEBIDO %s\nTROCO %s"%[sale.id,status,ShopSale.money(sale.total()),ShopSale.money(sale.tendered) if sale.phase>=ShopSale.Phase.CHANGE else "—",ShopSale.money(sale.change_due()) if sale.phase>=ShopSale.Phase.CHANGE else "—"]
	var opened:=sale.phase==ShopSale.Phase.CHANGE
	if opened!=drawer_is_open:
		drawer_is_open=opened
		if drawer_tween!=null:drawer_tween.kill()
		drawer_tween=create_tween();drawer_tween.tween_property(drawer,"position:z",-.24 if opened else 0.0,.25)
