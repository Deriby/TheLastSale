class_name RoofTiles
extends RefCounted
## Small curved clay tiles, baked into the frontage's ordinary material batches.
static func add_to(batch: PropBatch,width: float,depth: float,eaves: float,rise: float) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var u:=i/8.0;var v:=(i+1)/8.0
		var a:=Vector3(0,sin(u*PI)*.035,(u-.5)*.21);var b:=Vector3(.39,sin(u*PI)*.035,(u-.5)*.195)
		var c:=Vector3(.39,sin(v*PI)*.035,(v-.5)*.195);var d:=Vector3(0,sin(v*PI)*.035,(v-.5)*.21)
		for point in [a,c,b,a,d,c]:st.set_normal(Vector3(0,1,.2*cos(u*PI)).normalized());st.add_vertex(point)
	var tile:=st.commit();var length:=sqrt(pow(width*.5,2)+rise*rise);var angle:=atan2(rise,width*.5)
	var colors: Array[Color]=[Color("9e684c"),Color("b37953"),Color("865c48")]
	for side in [-1,1]:
		var basis:=Basis(Vector3(side*cos(angle),-sin(angle),0),Vector3(side*sin(angle),cos(angle),0),Vector3(0,0,side))
		for row in ceili(length/.35):
			for col in ceili((depth+.35)/.20):
				var distance: float=row*.35
				var pos:=Vector3(side*distance*cos(angle),eaves+rise-distance*sin(angle)+.055,-depth-.10+col*.20)
				var index: int=(row*7+col*3+col/4)%3
				var mat:=Geo.material(colors[index]);mat.cull_mode=BaseMaterial3D.CULL_DISABLED
				batch.add_instance("clay_tile_"+str(index),tile,mat,Transform3D(basis,pos))
		batch.add_box(Vector3(side*(width*.5+.035),eaves-.045,-depth*.5),Vector3(.09,.12,depth+.45),Geo.material(Color("725b49")))
		for i in ceili(depth/.75):batch.add_box(Vector3(side*(width*.5-.08),eaves-.13,-depth+i*.75),Vector3(.33,.12,.075),Geo.material(Color("6c5d4d")))
