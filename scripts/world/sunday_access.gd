class_name SundayAccess
extends Node3D
## Small former maintenance bay physically connected to the yard and old stock door.
var blockers: Array[Rect2]=[]
var evidence: Node3D
static func contains(point: Vector2) -> bool:
	return int(Session.campaign.night)==2 and (Rect2(-1.15,-20.8,2.3,5.3).has_point(point) or Rect2(1.0,-20.4,2.5,1.6).has_point(point))
func solid(at: Vector3,size: Vector3,material: Material,nav:=true) -> void:
	Geo.box(self,at,size,material)
	if nav:blockers.append(Rect2(Vector2(at.x-size.x/2,at.z-size.z/2),Vector2(size.x,size.z)))
func _ready() -> void:
	name="FormerMaintenance"
	var wall:=SurfaceMaterials.make("wall",Color("777c70"));var steel:=Geo.material(Color("4b5a50"))
	solid(Vector3(0,-.12,-18.4),Vector3(2.3,.24,4.8),SurfaceMaterials.make("paving"),false)
	solid(Vector3(2.3,-.12,-19.6),Vector3(2.3,.24,1.6),SurfaceMaterials.make("paving"),false)
	solid(Vector3(-1.15,1.4,-18.4),Vector3(.16,2.8,4.8),wall)
	solid(Vector3(0,1.4,-20.8),Vector3(2.3,2.8,.16),wall)
	solid(Vector3(1.15,1.4,-17.35),Vector3(.16,2.8,2.9),wall)
	solid(Vector3(1.15,1.4,-20.6),Vector3(.16,2.8,.4),wall)
	for z in [-18.8,-20.4]:solid(Vector3(2.3,1.4,z),Vector3(2.3,2.8,.16),wall)
	solid(Vector3(.0,2.84,-18.4),Vector3(2.3,.08,4.8),steel,false)
	solid(Vector3(2.3,2.84,-19.6),Vector3(2.3,.08,1.6),steel,false)
	solid(Vector3(-.35,.78,-20.05),Vector3(1.1,.10,.65),SurfaceMaterials.make("wood"))
	for x in [-.8,.1]:solid(Vector3(x,.37,-20.05),Vector3(.07,.74,.55),steel)
	var paper:=Geo.material(Color("bcb79c"))
	Geo.box(self,Vector3(-.3,.838,-20),Vector3(.34,.006,.23),paper,false)
	Geo.sign_text(self,"MANUTENÇÃO • ACESSO ANTIGO",Vector3(0,2.2,-20.69),21).pixel_size=.0025
	Geo.sign_text(self,"CADASTRO / CHAVES / DVR",Vector3(-.3,1.3,-20.65),19).pixel_size=.002
	for i in 4:Geo.box(self,Vector3(-1.03,.3+i*.35,-19.2),Vector3(.12,.035,1.1),steel,false)
	evidence=Node3D.new();evidence.name="DVRMemoryModule";add_child(evidence);evidence.position=Vector3(-.25,0,-19.9)
	Geo.box(evidence,Vector3(0,.87,0),Vector3(.16,.025,.11),Geo.material(Color("658774")),false)
	Geo.box(evidence,Vector3(0,.89,0),Vector3(.08,.016,.07),steel,false)
	var light:=Geo.light(self,Vector3(.0,2.5,-19.8),Color("bdc3a4"),.42,4.2);light.set_meta("battery_light",true)
	Geo.box(self,Vector3(.0,2.65,-19.8),Vector3(.38,.08,.12),paper,false)
