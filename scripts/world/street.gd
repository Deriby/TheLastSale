class_name Street
extends Node3D
var blockers: Array[Rect2] = []
func _ready() -> void:
	Geo.box(self,Vector3(0,-.38,0),Vector3(64,.28,48),Geo.material(Color("5e6458")))
	var asphalt:=Geo.material(Color.WHITE,"res://assets/textures/asphalt.png")
	Geo.box(self,Vector3(0,-.26,8.4),Vector3(65,.28,9.5),asphalt)
	var concrete:=Geo.material(Color.WHITE,"res://assets/textures/concrete.png")
	for z in [1.85,15.2]:Geo.box(self,Vector3(0,-.12,z),Vector3(65,.24,3.8),concrete)
	for x in range(-30,31,2):
		Geo.box(self,Vector3(x,.005,3.7),Vector3(1.93,.12,.17),Geo.material(Color("bab6a3")))
		Geo.box(self,Vector3(x,-.002,1.9),Vector3(.015,.01,3.3),Geo.material(Color("555955")),false)
	# Slight grade is represented visually beyond the playable storefront, not asserted as measured.
	for x in [-21,-14,14,22]:house(Vector3(x,0,-1),Color("9b9f8a"),false)
	for x in [-23,-15,-7,2,11,20,28]:house(Vector3(x,0,17),Color.from_hsv(.10+float(abs(x)%3)*.035,.13,.49),true)
	for x in [-10,11,25]:pole(Vector3(x,0,3.0))
	for x in [-24,-8,10,25]:
		Geo.cylinder(self,Vector3(x,1.6,16),.15,3.2,Geo.material(Color("474a3c")))
		for j in range(4):
			var leaf:=Geo.box(self,Vector3(x+sin(j*2)*.8,3.4+j*.25,16+cos(j*2)*.7),Vector3(1.6,1.4,1.4),Geo.material(Color("35493a")),false)
			leaf.rotation.y=j*.7
	for x in [-1.9,2.15,5.8]:Geo.cylinder(self,Vector3(x,.5,.7),.055,1,Geo.material(Color("363c3b")))
	car(Vector3(-10,.03,2.5),Color("677e82"))
	car(Vector3(13,.03,14),Color("927d65"))
	# Narrow playable slice, blocked by coherent neighborhood continuation.
	Geo.box(self,Vector3(-28,2,0),Vector3(.3,4,48),Geo.material(Color("414b4b")))
	Geo.box(self,Vector3(28,2,0),Vector3(.3,4,48),Geo.material(Color("414b4b")))
func house(pos: Vector3,color: Color,opposite: bool) -> void:
	var n:=Node3D.new();add_child(n);n.position=pos
	if opposite:n.rotation.y=PI
	var wall:=Geo.material(color,"res://assets/textures/plaster.png")
	Geo.box(n,Vector3(0,1.6,-3),Vector3(7.5,3.2,5),wall)
	Geo.box(n,Vector3(0,1.35,-.45),Vector3(3.0,2.7,.12),Geo.material(Color("4d5855"),"res://assets/textures/metal.png"))
	Geo.box(n,Vector3(2.5,1.8,-.42),Vector3(1.25,.8,.08),Geo.material(Color("9b9871"),"",.12),false)
	for x in [2.0,2.25,2.5,2.75,3.0]:Geo.box(n,Vector3(x,1.8,-.35),Vector3(.035,.85,.06),Geo.material(Color("4d5553")),false)
	var roof:=Geo.box(n,Vector3(0,3.3,-2.8),Vector3(8,.18,5.8),Geo.material(Color("85644c"),"res://assets/textures/metal.png"),false)
	roof.rotation.x=.12
func pole(pos: Vector3) -> void:
	Geo.cylinder(self,pos+Vector3.UP*3.5,.12,7,Geo.material(Color("8d8d7e")))
	Geo.beam(self,pos+Vector3(0,6.6,0),pos+Vector3(0,6.6,1.4),.07,Geo.material(Color("3c4746")))
	Geo.box(self,pos+Vector3(0,6.55,1.4),Vector3(.4,.08,.55),Geo.material(Color("f0c584"),"",1.5),false)
	Geo.light(self,pos+Vector3(0,6.2,1.4),Color("e4bb80"),2.2,12)
	for h in [6.4,6.7,7.0]:
		Geo.beam(self,pos+Vector3(-8,h,0),pos+Vector3(0,h-.25,0),.018,Geo.material(Color("171f24")))
		Geo.beam(self,pos+Vector3(0,h-.25,0),pos+Vector3(8,h,0),.018,Geo.material(Color("171f24")))
func car(pos: Vector3,color: Color) -> void:
	blockers.append(Rect2(Vector2(pos.x-1.9,pos.z-.82),Vector2(3.8,1.64)))
	var n:=Node3D.new();add_child(n);n.position=pos
	Geo.box(n,Vector3(0,.55,0),Vector3(3.7,.65,1.6),Geo.material(color))
	Geo.box(n,Vector3(0,1.12,0),Vector3(1.9,.65,1.45),Geo.material(Color("34494e")))
	Geo.box(n,Vector3(0,1.48,0),Vector3(2,.06,1.5),Geo.material(color),false)
	for x in [-1.15,1.15]:
		for z in [-.8,.8]:
			var wheel:=Geo.cylinder(n,Vector3(x,.34,z),.32,.18,Geo.material(Color("1b2224")))
			wheel.rotation.x=PI/2
	for z in [-.52,.52]:Geo.box(n,Vector3(1.87,.62,z),Vector3(.03,.18,.3),Geo.material(Color("d0c4a0")),false)
