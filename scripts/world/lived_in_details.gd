class_name LivedInDetails
extends Node3D
## Static, grouped working-life details. Doorways and the cooperative route stay clear.
var exterior:=false
var batch: PropBatch
var hour_hand: Node3D
var minute_hand: Node3D
var clock_wait:=0.0
func _ready() -> void:
	name="StreetLivedIn" if exterior else "DepotLivedIn"
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	batch=PropBatch.new();batch.name="LivedInBatch";add_child(batch)
	if exterior:street_details()
	else:depot_details()
	batch.flush()
	for piece in find_children("*","GeometryInstance3D",true,false):piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func paper(parent: Node3D,at: Vector3,size: Vector2,words: String,angle:=0.0) -> void:
	var root:=Node3D.new();parent.add_child(root);root.position=at;root.rotation.y=angle
	Geo.box(root,Vector3.ZERO,Vector3(size.x,size.y,.008),Geo.material(Color("c8c4aa")),false)
	for x in [-size.x*.38,size.x*.38]:Geo.box(root,Vector3(x,size.y*.48,.008),Vector3(.045,.035,.008),Geo.material(Color("a8a179")),false)
	var label:=Geo.sign_text(root,words,Vector3(0,0,.009),22,Color("3d4940"));label.pixel_size=.0023
func depot_details() -> void:
	var iron:=SurfaceMaterials.make("painted_metal",Color("69746b"));var dark:=Geo.material(Color("29362f"));var steel:=Geo.material(Color("a4afa4"));var rubber:=SurfaceMaterials.make("rubber",Color("3a433b"))
	# Tool board mounted to the left stock wall, within the existing perimeter.
	var root:=Node3D.new();root.name="StockToolBoard";add_child(root);root.position=Vector3(2.2,1.75,-15.85)
	var tools:=PropBatch.new();root.add_child(tools)
	tools.add_box(Vector3.ZERO,Vector3(1.22,.73,.035),Geo.material(Color("9a9c80")))
	for row in 6:
		for column in 12:tools.add_box(Vector3(-.55+column*.10,-.30+row*.12,.022),Vector3(.014,.014,.004),dark)
	for i in 3:
		var x: float=-.43+i*.26;var length: float=.23+i*.035
		NeighborhoodProps.tube(tools,Vector3(x,.24,.055),Vector3(x,-.02,.055),.009,steel)
		tools.add_box(Vector3(x,-.13,.055),Vector3(.035,.20,.024),rubber)
		tools.add_box(Vector3(x,.22,.055),Vector3(.07,.025,.025),steel)
		tools.add_box(Vector3(x-.025,.25,.055),Vector3(.018,.05,.025),steel)
		tools.add_box(Vector3(x+.025,.25,.055),Vector3(.018,.05,.025),steel)
	tools.add_box(Vector3(.40,-.06,.07),Vector3(.04,.36,.04),Geo.material(Color("9e815b")))
	tools.add_box(Vector3(.40,.15,.07),Vector3(.20,.07,.07),iron)
	tools.flush()
	paper(self,Vector3(2.66,2.11,-11.145),Vector2(.66,.48),"ENTREGAS\nCONFERIR VASILHAMES\nCORREDOR LIVRE",PI)
	# Tape roll and a delivery docket on the already blocked rear stack.
	var roll:=Geo.cylinder(self,Vector3(-3.5,1.465,-15.0),.065,.035,Geo.material(Color("a29468")));roll.mesh.radial_segments=16
	var core:=Geo.cylinder(self,Vector3(-3.5,1.485,-15.0),.035,.005,Geo.material(Color("635f4c")));core.mesh.radial_segments=16
	for i in 4:
		StreetDetail.rotated_box(batch,Vector3(-4.12+i*.012,1.426+i*.003,-14.97),Vector3(.23,.002,.31),Vector3(0,.08*i,0),Geo.material(Color("bdbda7")))
	for x in [-4.34,-3.66,-2.96]:
		batch.add_box(Vector3(x,1.13,-14.767),Vector3(.16,.055,.006),Geo.material(Color("c5bea2")))
		for line in 3:batch.add_box(Vector3(x-.03+line*.03,1.13,-14.762),Vector3(.006,.032,.003),dark)
	# Shallow entrance mat and shoe wear: cosmetic surfaces, no raised obstacle.
	batch.add_box(Vector3(3.1,.006,.35),Vector3(1.28,.009,.48),rubber)
	for i in 18:batch.add_box(Vector3(2.51+i*.068,.012,.35),Vector3(.016,.003,.43),dark)
	var desk: Node3D=get_parent().counter
	for i in 3:
		var slip:=Geo.box(desk,Vector3(.98+i*.013,1.134+i*.002,-.07),Vector3(.17,.002,.12),Geo.material(Color("cfc8ae")),false);slip.rotation.y=.12*i
	# Wall clock, scale markings and a worn housing above the front working area.
	var clock:=Node3D.new();add_child(clock);clock.position=Vector3(5.86,2.45,-9.15);clock.rotation.y=-PI/2
	var rim:=Geo.cylinder(clock,Vector3.ZERO,.17,.025,iron);rim.rotation.x=PI/2;rim.mesh.radial_segments=24
	var face:=Geo.cylinder(clock,Vector3(0,0,.018),.145,.008,Geo.material(Color("c4c6b1")));face.rotation.x=PI/2;face.mesh.radial_segments=24
	for i in 12:
		var mark:=Geo.box(clock,Vector3(sin(i*TAU/12)*.124,cos(i*TAU/12)*.124,.025),Vector3(.008,.022,.004),dark,false);mark.rotation.z=-i*TAU/12
	hour_hand=Node3D.new();clock.add_child(hour_hand);hour_hand.position.z=.03
	Geo.box(hour_hand,Vector3(0,.038,0),Vector3(.009,.085,.004),dark,false)
	minute_hand=Node3D.new();clock.add_child(minute_hand);minute_hand.position.z=.034
	Geo.box(minute_hand,Vector3(0,.058,0),Vector3(.006,.13,.004),dark,false)
func street_details() -> void:
	var dark:=SurfaceMaterials.make("rubber",Color("242d2a"));var green:=SurfaceMaterials.make("plastic",Color("526b58"));var iron:=SurfaceMaterials.make("painted_metal",Color("77827a"))
	var root:=Node3D.new();root.name="ClosedStreetBin";add_child(root);root.position=Vector3(-7.8,Street.surface_height(-7.8,.48),.48)
	var bin:=PropBatch.new();root.add_child(bin)
	# Tapered shell with molded rim, separate hinged lid, axle and wheels.
	var vertices:=PackedVector3Array([Vector3(-.23,.08,-.22),Vector3(.23,.08,-.22),Vector3(.23,.08,.22),Vector3(-.23,.08,.22),Vector3(-.29,.88,-.27),Vector3(.29,.88,-.27),Vector3(.29,.88,.27),Vector3(-.29,.88,.27)])
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for quad in [[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7],[0,3,2,1]]:
		for i in [0,2,1,0,3,2]:st.add_vertex(vertices[quad[i]])
	st.generate_normals();bin.add_instance("molded_bin",st.commit(),green,Transform3D.IDENTITY)
	bin.add_box(Vector3(0,.89,0),Vector3(.64,.055,.60),green)
	bin.add_box(Vector3(0,.929,0),Vector3(.66,.032,.62),green)
	for x in [-.23,.23]:
		NeighborhoodProps.tube(bin,Vector3(x,.91,-.29),Vector3(x,.91,-.36),.014,dark)
		var wheel:=Geo.cylinder(root,Vector3(x,.09,-.21),.09,.045,dark);wheel.rotation.z=PI/2;wheel.mesh.radial_segments=16
	NeighborhoodProps.tube(bin,Vector3(-.24,.09,-.21),Vector3(.24,.09,-.21),.014,iron)
	NeighborhoodProps.tube(bin,Vector3(-.17,.94,-.36),Vector3(.17,.94,-.36),.018,green)
	for x in [-.20,.20]:bin.add_box(Vector3(x,.45,.251),Vector3(.026,.55,.018),green)
	bin.flush();NeighborhoodProps.obstacle(root,Vector3(0,.48,0),Vector3(.68,.96,.64))
	RetailDetails.shadow(root,Vector3(0,.008,0),Vector2(.84,.74))
	paper(root,Vector3(0,.64,.285),Vector2(.34,.21),"COLETA\nSACOS FECHADOS")
	# Flush storm drain fitted to the sloping curb; no new step or collision.
	var drain:=Node3D.new();add_child(drain);drain.name="CurbStormDrain";drain.position=Vector3(-1.3,Street.surface_height(-1.3,2.55)+.003,2.55);drain.rotation.x=atan(.7)
	var grate:=PropBatch.new();drain.add_child(grate);grate.add_box(Vector3.ZERO,Vector3(.72,.008,.16),dark)
	for i in 12:grate.add_box(Vector3(-.33+i*.06,.006,0),Vector3(.014,.006,.155),iron)
	grate.flush()
	# Local rain marks below opposite wall services and a few curb-side leaves.
	var stain:=Geo.material(Color("7d897c"));var leaf:=Geo.material(Color("7b7153"))
	for x in [-5.9,5.75,11.22]:
		for i in 5:
			var height: float=.15+.035*(i%3)
			batch.add_box(Vector3(x+i*.024,Street.grade(x)+height*.5,12.292),Vector3(.014,height,.004),stain)
	for i in 9:
		var x: float=-7.4+i*.035;var z: float=2.27+sin(i*2.399)*.065
		StreetDetail.rotated_box(batch,Vector3(x,Street.surface_height(x,z)+.007,z),Vector3(.035,.003,.07),Vector3(0,i*2.399,0),leaf)

func _process(delta: float) -> void:
	if minute_hand==null:return
	clock_wait-=delta
	if clock_wait>0:return
	clock_wait=.5
	var minutes:=Session.clock_minutes()
	hour_hand.rotation.z=-TAU*fmod(float(minutes)/60,12)/12
	minute_hand.rotation.z=-TAU*(minutes%60)/60.0
