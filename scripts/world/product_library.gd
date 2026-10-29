class_name ProductLibrary
extends RefCounted
## Shared original product meshes: shaped bottles, cans and puffed packets.
## Dimensions are in meters; origin is at the bottom of each product.
static var meshes: Dictionary = {}
static var materials: Dictionary = {}
const ART := "res://assets/textures/depot/"
static func material(id: String, emission := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var key:=id+str(emission)+str(alpha)
	if materials.has(key):return materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_texture=load((SceneDetail.ART if id.begins_with("cup_") or id.begins_with("spirits_") else ART)+id+".png")
	m.albedo_color=Color(1,1,1,alpha)
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness=.83
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	if emission>0:
		m.emission_enabled=true;m.emission=Color.WHITE;m.emission_texture=m.albedo_texture;m.emission_energy_multiplier=emission
	if alpha<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	materials[key]=m
	return m
static func mesh(id: String) -> ArrayMesh:
	if meshes.has(id):return meshes[id]
	var result: ArrayMesh
	if id.begins_with("cup_"):
		result=lathe([Vector2(.032,0),Vector2(.035,.008),Vector2(.045,.18),Vector2(.046,.19),Vector2(.042,.197)],16)
	elif id.begins_with("snack") or id.begins_with("toy"):
		result=packet(.24 if id.begins_with("snack") else .15,.255 if id.begins_with("snack") else .24,.055)
	elif id.begins_with("can"):
		result=lathe([Vector2(.030,0),Vector2(.034,.008),Vector2(.034,.118),Vector2(.030,.126)],16)
	elif id.begins_with("soda"):
		result=lathe([Vector2(.044,0),Vector2(.052,.018),Vector2(.053,.06),Vector2(.050,.22),Vector2(.045,.26),Vector2(.019,.30),Vector2(.018,.33),Vector2(.020,.335)],16)
	elif id=="water":
		result=lathe([Vector2(.032,0),Vector2(.037,.018),Vector2(.036,.19),Vector2(.017,.22),Vector2(.015,.25)],14)
	elif id.begins_with("spirits"):
		result=lathe([Vector2(.032,0),Vector2(.038,.02),Vector2(.038,.19),Vector2(.017,.23),Vector2(.014,.30)],14)
	else:
		result=lathe([Vector2(.031,0),Vector2(.037,.012),Vector2(.037,.18),Vector2(.033,.22),Vector2(.015,.26),Vector2(.013,.30),Vector2(.015,.306)],16)
	meshes[id]=result
	return result
static func vertex(st: SurfaceTool,p: Vector3,uv: Vector2,n: Vector3) -> void:
	st.set_normal(n);st.set_uv(uv);st.add_vertex(p)
static func lathe(profile: Array,segments: int) -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height: float=profile[-1].y
	for row in range(profile.size()-1):
		var low: Vector2=profile[row];var high: Vector2=profile[row+1]
		for i in segments:
			var a:=TAU*i/segments;var b:=TAU*(i+1)/segments
			var n1:=Vector3(sin(a)*(high.y-low.y),low.x-high.x,cos(a)*(high.y-low.y)).normalized()
			var n2:=Vector3(sin(b)*(high.y-low.y),low.x-high.x,cos(b)*(high.y-low.y)).normalized()
			var p0:=Vector3(sin(a)*low.x,low.y,cos(a)*low.x)
			var p1:=Vector3(sin(b)*low.x,low.y,cos(b)*low.x)
			var p2:=Vector3(sin(a)*high.x,high.y,cos(a)*high.x)
			var p3:=Vector3(sin(b)*high.x,high.y,cos(b)*high.x)
			var u0:=.5+float(i)/segments;var u1:=.5+float(i+1)/segments
			vertex(st,p0,Vector2(u0,1-low.y/height),n1);vertex(st,p2,Vector2(u0,1-high.y/height),n1);vertex(st,p1,Vector2(u1,1-low.y/height),n2)
			vertex(st,p1,Vector2(u1,1-low.y/height),n2);vertex(st,p2,Vector2(u0,1-high.y/height),n1);vertex(st,p3,Vector2(u1,1-high.y/height),n2)
	for end in [0,profile.size()-1]:
		var r: float=profile[end].x;var y: float=profile[end].y
		for i in segments:
			vertex(st,Vector3(0,y,0),Vector2(.5,1-y/height),Vector3.DOWN if end==0 else Vector3.UP)
			for j in [i,i+1]:
				var angle: float=TAU*j/segments
				vertex(st,Vector3(sin(angle)*r,y,cos(angle)*r),Vector2(.5,1-y/height),Vector3.DOWN if end==0 else Vector3.UP)
	st.index()
	return st.commit()
static func packet(width: float,height: float,depth: float) -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3]=[Vector3(-width*.42,0,0),Vector3(width*.42,0,0),Vector3(width*.5,height*.5,depth*.25),Vector3(width*.42,height,0),Vector3(-width*.42,height,0),Vector3(-width*.5,height*.5,depth*.25)]
	var uvs: Array[Vector2]=[Vector2(.08,1),Vector2(.92,1),Vector2(1,.5),Vector2(.92,0),Vector2(.08,0),Vector2(0,.5)]
	for side in [-1,1]:
		var center:=Vector3(0,height*.5,side*depth*.5)
		for i in corners.size():
			var next: int=(i+1)%corners.size()
			var a:=corners[i];var b:=corners[next];a.z*=side;b.z*=side
			var n:=Vector3(0,.1,side).normalized()
			vertex(st,center,Vector2(.5,.5),n);vertex(st,a,uvs[i],n);vertex(st,b,uvs[next],n)
	st.index()
	return st.commit()
