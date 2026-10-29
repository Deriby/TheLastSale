class_name RetailFinish
extends Node3D
func _init() -> void:name="RetailFinish";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	var batch:=PropBatch.new();add_child(batch)
	var dark:=Geo.material(Color("2b3432"));var red:=Geo.material(Color("a83228"));var metal:=Geo.material(Color("83908a"));metal.metallic=.35
	# Wall-mounted extinguisher: cylinder, cap, valve, hose and identification stripe.
	Geo.cylinder(self,Vector3(5.73,.93,-2.65),.105,.45,red,.085)
	Geo.cylinder(self,Vector3(5.73,1.18,-2.65),.04,.06,dark)
	batch.add_box(Vector3(5.73,1.24,-2.65),Vector3(.12,.025,.04),metal)
	batch.add_box(Vector3(5.62,.96,-2.65),Vector3(.008,.19,.12),Geo.material(Color("d1c9a7")))
	var last:=Vector3(5.70,1.19,-2.70)
	for i in 9:
		var p:=Vector3(5.70,.76+i*.047,-2.77-sin(i*.35)*.065);StreetDetail.beam(batch,last,p,.013,dark);last=p
	# Sturdy bags beside the freezer, not in the working aisle.
	var bag:=ProductLibrary.packet(.37,.56,.20);var sack:=SceneDetail.material("finish/charcoal_bag");sack.uv1_triplanar=false
	for i in 4:
		var pos:=Vector3(5.30,.02,-3.38-i*.29)
		batch.add_instance("charcoal_bags",bag,sack,Transform3D(Basis(Vector3.UP,PI/2+.06*(i%2)),pos))
	RetailDetails.collision(self,Vector3(5.30,.30,-3.82),Vector3(.60,.60,1.24))
	# Clip-on printed price card and clear film on a small pack near the entrance.
	var offer:=SceneDetail.panel(self,Vector3(4.34,1.15,-.77),Vector2(.23,.34),"finish/ice_offer")
	batch.add_box(Vector3(4.34,.94,-.79),Vector3(.012,.12,.012),metal)
	batch.add_box(Vector3(4.34,.875,-.79),Vector3(.10,.02,.08),dark)
	var film:=SceneDetail.panel(self,Vector3(4.42,.42,-.70),Vector2(.53,.64),"finish/plastic_film")
	film.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;film.material_override.roughness=.32
	# Roof switch box, wiring and clips give the working perimeter visible structure.
	batch.add_box(Vector3(5.81,2.05,-7.9),Vector3(.09,.44,.34),Geo.material(Color("9ca79a")))
	batch.add_box(Vector3(5.75,2.06,-7.9),Vector3(.02,.18,.16),dark)
	StreetDetail.beam(batch,Vector3(5.81,2.26,-7.9),Vector3(5.81,2.63,-7.9),.025,metal)
	for i in 4:batch.add_box(Vector3(5.74,2.00+i*.047,-7.9),Vector3(.025,.017,.08),Geo.material(Color("c0bba2")))
	batch.flush()
