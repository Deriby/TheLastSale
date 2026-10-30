class_name ServiceYard
extends Node3D
## Fictitious rear maintenance court; independent of the photographed sales floor.
var blockers: Array[Rect2]=[]
var generator: Node3D
var indicator: MeshInstance3D
var status: Label3D
static func contains(at: Vector2) -> bool:
	return Rect2(3.45,-20.8,2.9,5.3).has_point(at)
func solid(at: Vector3,size: Vector3,material: Material,nav := true) -> void:
	Geo.box(self,at,size,material)
	if nav:blockers.append(Rect2(Vector2(at.x-size.x*.5,at.z-size.z*.5),Vector2(size.x,size.z)))
func _ready() -> void:
	var wall:=SurfaceMaterials.make("wall",Color("8f9587"))
	solid(Vector3(4.9,-.12,-18.35),Vector3(2.9,.24,4.7),SurfaceMaterials.make("paving"),false)
	for x in [3.45,6.35]:
		if x==3.45 and int(Session.campaign.night)==2:
			solid(Vector3(x,1.35,-17.35),Vector3(.18,2.7,2.9),wall)
			solid(Vector3(x,1.35,-20.6),Vector3(.18,2.7,.4),wall)
		else:solid(Vector3(x,1.35,-18.4),Vector3(.18,2.7,4.8),wall)
	solid(Vector3(4.9,1.35,-20.8),Vector3(2.9,2.7,.18),wall)
	var steel:=Geo.material(Color("353e39"));var red:=Geo.material(Color("805044"))
	generator=Node3D.new();generator.name="BackupGenerator";add_child(generator);generator.position=Vector3(5.5,0,-19.5)
	Geo.box(generator,Vector3(0,.45,0),Vector3(.95,.65,.73),steel)
	Geo.box(generator,Vector3(0,.83,0),Vector3(.96,.16,.70),red,false)
	Geo.box(generator,Vector3(-.49,.52,0),Vector3(.04,.39,.55),Geo.material(Color("1d2422")),false)
	for i in 9:Geo.box(generator,Vector3(-.518,.36+i*.037,0),Vector3(.018,.014,.5),Geo.material(Color("92988b")),false)
	for x in [-.38,.38]:
		for z in [-.26,.26]:Geo.cylinder(generator,Vector3(x,.1,z),.075,.2,steel)
	Geo.cylinder(generator,Vector3(.3,1.02,.2),.035,.3,steel)
	indicator=Geo.box(generator,Vector3(-.525,.72,.2),Vector3(.015,.06,.06),Geo.material(Color("aa6439"),"",.3),false)
	status=Label3D.new();generator.add_child(status);status.text="GERADOR • RESERVA";status.position=Vector3(-.55,1.2,0);status.rotation.y=-PI/2;status.pixel_size=.0025;status.font_size=30
	blockers.append(Rect2(4.99,-19.89,1.03,.78))
	Geo.beam(self,Vector3(5.96,1,-19.5),Vector3(5.96,1,-16.1),.025,steel)
	Geo.box(self,Vector3(4.8,2.5,-20.68),Vector3(.6,.12,.09),Geo.material(Color("b6c5ac"),"",.45),false)
	var lamp:=Geo.light(self,Vector3(4.8,2.3,-20.4),Color("cfdbc5"),.45,4.2);lamp.name="YardBatteryLight"
	lamp.set_meta("battery_light",true)
