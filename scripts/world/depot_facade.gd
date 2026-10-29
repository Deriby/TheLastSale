class_name DepotFacade
extends Node3D
## Stepped annex and two-bay JA frontage from exterior1/2/6/7.
var blockers: Array[Rect2] = []
func _init() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func solid(at: Vector3,size: Vector3,mat: Material) -> void:
	Geo.box(self,at,size,mat)
	if at.y-size.y*.5<1.8:blockers.append(Rect2(Vector2(at.x-size.x*.5,at.z-size.z*.5),Vector2(size.x,size.z)))
func _ready() -> void:
	var render:=StreetDetail.material(Color("aaaead"),"render")
	var dark:=StreetDetail.material(Color("252d2f"))
	var details:=PropBatch.new();details.name="FacadeDetails";add_child(details)
	for x in [-6.0,-2.1]:solid(Vector3(x,2.1,0),Vector3(.28,4.2,.35),render)
	solid(Vector3(-4.05,4.25,0),Vector3(4.16,.45,.38),render)
	# Open the annex during the shift: the left cashier must see the street.
	details.add_box(Vector3(-4.05,4.0,-.025),Vector3(3.65,.35,.36),dark)
	for y in [3.86,3.93,4.0,4.07,4.14]:details.add_box(Vector3(-4.05,y,.17),Vector3(3.65,.018,.025),StreetDetail.material(Color("5b6261")))
	for x in [2.1,6.0]:solid(Vector3(x,1.9,0),Vector3(.3,3.8,.35),render)
	solid(Vector3(2.25,5.15,0),Vector3(8.7,2.7,.35),render)
	solid(Vector3(6.36,1.9,0),Vector3(.64,3.8,.35),render)
	details.add_box(Vector3(2.25,6.53,.025),Vector3(8.78,.075,.46),StreetDetail.material(Color("888d89")))
	details.add_box(Vector3(-4.05,4.49,.025),Vector3(4.2,.07,.46),StreetDetail.material(Color("9b9e99")))
	for x in [-5.87,-2.24,2.24,5.85]:details.add_box(Vector3(x,1.86,.10),Vector3(.07,3.72,.07),StreetDetail.material(Color("4d5453")))
	for x in [0.0,4.05]:
		details.add_box(Vector3(x,3.66,.025),Vector3(3.82,.28,.43),dark)
		for y in [3.55,3.61,3.67,3.73,3.79]:details.add_box(Vector3(x,y,.25),Vector3(3.8,.017,.025),StreetDetail.material(Color("5b6261")))
	var mural:=StreetDetail.panel(self,Vector3(2.0,5.16,.184),Vector2(4.4,2.72),"ja_mural",0,true)
	mural.material_override.emission_enabled=true;mural.material_override.emission=Color.WHITE;mural.material_override.emission_texture=mural.material_override.albedo_texture;mural.material_override.emission_energy_multiplier=.38
	StreetDetail.text(self,"LOJA·2",Vector3(-1.04,4.48,.19),58)
	StreetDetail.text(self,"99124-8730",Vector3(4.78,4.48,.19),50)
	StreetDetail.panel(self,Vector3(3.56,4.48,.193),Vector2(.25,.25),"contact_icon",0,true)
	StreetDetail.text(self,"558",Vector3(2.1,2.96,.19),24)
	StreetDetail.window(details,Vector3(6.36,2.88,.185),Vector2(.29,.95))
	for y in [.35,.86,1.4]:
		details.add_box(Vector3(6.36,y,.205),Vector3(.34,.31,.075),dark)
		details.add_box(Vector3(6.37,y+.035,.249),Vector3(.12,.08,.014),StreetDetail.material(Color("927a47")))
	for at in [Vector3(-1.72,6.12,.6),Vector3(5.87,6.12,.6)]:
		StreetDetail.rotated_box(details,at,Vector3(.23,.29,.08),Vector3(-.35,0,.12),dark)
		var light:=SpotLight3D.new();add_child(light);light.position=at+Vector3(0,-.06,.06);light.look_at_from_position(light.position,Vector3(2,4.9,.20))
		light.light_color=Color("e2dfc9");light.light_energy=1.05;light.spot_range=7;light.spot_angle=65;light.shadow_enabled=false
		light.light_cull_mask=4
	for x in [-3.9,.1]:
		var spill:=SpotLight3D.new();spill.name="EntranceLightSpill";add_child(spill);spill.position=Vector3(x,3.3,-.12);spill.look_at_from_position(spill.position,Vector3(x,0,3.3))
		spill.light_color=Color("dcecf1");spill.light_energy=1.2;spill.spot_range=7.5;spill.spot_angle=62
		spill.light_cull_mask=11
	details.flush()
	add_child(NeonFinish.new())
	for mesh in find_children("*","MeshInstance3D",true,false):mesh.layers=5
