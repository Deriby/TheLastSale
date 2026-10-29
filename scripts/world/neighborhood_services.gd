class_name NeighborhoodServices
extends RefCounted
## Different service layouts fitted to each lot, with no extra street lights.
static func add_to(root: Node3D) -> void:
	var kind: String=root.get_meta("frontage_kind","");var width: float=root.get_meta("frontage_width",5.4)
	var batch:=PropBatch.new();batch.name="FrontageServices";root.add_child(batch)
	var seed_value:=posmod(str(root.name).hash(),997);var x: float=width*.42*(1 if seed_value%2 else -1);var height:=1.47
	match kind:
		"gray":x=-2.38
		"peach":x=-.28
		"yellow":x=-2.30
		"cassiano":x=-3.02
		"two_storey":x=width*.43
		"brick_garage":x=-2.53
		"garden_house":x=-2.34;height=.78
		"courtyard_house":x=2.50;height=.82
		"tile_house":x=.91
		"corner_shop":x=2.48
		"workshop_annex":x=-2.60
	var case_mat:=SurfaceMaterials.make("painted_metal",Color("acb5a9") if seed_value%2 else Color("999f91"));var dark:=SurfaceMaterials.make("plastic",Color("354741"));var pipe:=SurfaceMaterials.make("plastic",Color("adb9aa"))
	batch.add_box(Vector3(x,height,.12),Vector3(.22,.29,.10),case_mat)
	batch.add_box(Vector3(x,height+.025,.176),Vector3(.14,.15,.018),dark)
	var dial:=Geo.cylinder(root,Vector3(x,height+.042,.190),.044,.008,Geo.material(Color("dedac4")));dial.rotation.x=PI/2;dial.mesh.radial_segments=20
	NeighborhoodProps.label(root,"kWh",Vector3(x,height-.07,.191),12,.0013,Color("b4c4b4"))
	var mast: float=5.65 if kind=="two_storey" else 3.70+float(seed_value%3)*.13
	NeighborhoodProps.tube(batch,Vector3(x,height+.15,.10),Vector3(x,mast,.10),.018,pipe)
	NeighborhoodProps.tube(batch,Vector3(x,mast,.10),Vector3(x+.09,mast+.09,.10),.018,pipe)
	for y in [height+.23,height+.73]:batch.add_box(Vector3(x,y,.09),Vector3(.065,.023,.026),case_mat)
	var mail_x: float=-x if absf(x)>.8 else 2.45
	if kind=="garden_house":mail_x=1.75
	if kind=="courtyard_house":mail_x=-2.45
	batch.add_box(Vector3(mail_x,.72,.108),Vector3(.24,.065,.035),case_mat);batch.add_box(Vector3(mail_x,.723,.13),Vector3(.18,.012,.010),dark)
	var doorbell_x: float=x-.21 if x>0 else x+.21
	batch.add_box(Vector3(doorbell_x,minf(height+.03,1.42),.13),Vector3(.055,.12,.025),dark)
	batch.add_box(Vector3(doorbell_x,minf(height+.045,1.435),.147),Vector3(.025,.025,.007),case_mat)
	var top: float={"gray":2.76,"peach":3.0,"yellow":2.72,"cassiano":3.24,"two_storey":5.3,"brick_garage":3.15,"garden_house":2.9,"corner_shop":3.55,"tile_house":3.05,"courtyard_house":3.1,"workshop_annex":4.05}.get(kind,3.1)
	var gutter_z: float=-.68 if kind=="garden_house" else (-.5 if kind=="courtyard_house" else .10)
	var drain_x: float=width*.5-.14
	NeighborhoodProps.tube(batch,Vector3(drain_x,.15,gutter_z),Vector3(drain_x,top,gutter_z),.025,pipe)
	NeighborhoodProps.tube(batch,Vector3(drain_x,.15,gutter_z),Vector3(drain_x,.10,gutter_z+.16),.025,pipe)
	for y in [.40,1.45,2.40]:batch.add_box(Vector3(drain_x,minf(y,top-.10),gutter_z-.015),Vector3(.075,.025,.035),case_mat)
	if kind in ["gray","cassiano","brick_garage","corner_shop","tile_house","workshop_annex"]:batch.add_box(Vector3(0,top-.025,.12),Vector3(width+.07,.075,.13),case_mat)
	if kind in ["corner_shop","workshop_annex"]:
		batch.add_box(Vector3(width*.39,top-.50,.16),Vector3(.50,.31,.24),case_mat)
		for i in 6:batch.add_box(Vector3(width*.39,top-.61+i*.041,.29),Vector3(.40,.012,.018),dark)
		NeighborhoodProps.tube(batch,Vector3(width*.39+.2,top-.64,.11),Vector3(width*.39+.2,.33,.11),.012,pipe)
	if kind=="cassiano":NeighborhoodProps.gas_cage(root,Vector3(1.40,.015,.48))
	if kind=="two_storey" and str(root.name)=="UphillTwoStoreyHouse":NeighborhoodProps.aerial(root,Vector3(-2.0,5.42,-2.2),.35)
	batch.flush()
