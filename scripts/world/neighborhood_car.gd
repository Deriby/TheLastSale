class_name NeighborhoodCar
extends RefCounted
## Original Blender assets: curved panels, glazing, interior and detailed wheels.
static func create(parent: Node3D,at: Vector3,kind: String,angle: float) -> Node3D:
	var root: Node3D=load("res://assets/models/environment/"+kind+".glb").instantiate()
	root.name="ParkedSedan" if kind=="sedan" else "ParkedHatchback";root.set_meta("vehicle_kind",kind)
	parent.add_child(root);root.position=at
	var slope:=.045 if absf(at.x)>6 else 0.0
	var forward:=Vector3(cos(angle),slope*cos(angle),-sin(angle)).normalized();var side:=Vector3(sin(angle),0,cos(angle))
	root.basis=Basis(forward,side.cross(forward).normalized(),side)
	for node in root.find_children("*","MeshInstance3D",true,false):
		node.add_to_group("vehicle_render");node.layers=8
		var profile:=""
		if str(node.name).begins_with("Paint_"):profile="carpaint"
		elif str(node.name).contains("Rubber_Tires"):profile="rubber"
		elif str(node.name).contains("Alloy_and_Chrome"):profile="steel"
		elif str(node.name).contains("Glass"):profile="glass"
		if not profile.is_empty():
			for index in node.mesh.get_surface_count():
				var key:="vehicle-surface:"+kind+str(node.name)+str(index)
				if not Geo.materials.has(key):
					var coating: StandardMaterial3D=node.mesh.surface_get_material(index).duplicate()
					SurfaceMaterials.configure(coating,profile)
					if profile=="carpaint":coating.clearcoat_enabled=true;coating.clearcoat=.55;coating.clearcoat_roughness=.25
					Geo.materials[key]=coating
				node.set_surface_override_material(index,Geo.materials[key])
		if str(node.name).contains("Glass"):
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for index in node.mesh.get_surface_count():
				var mat: StandardMaterial3D=node.get_surface_override_material(index)
				mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color.a=.62;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
				node.set_surface_override_material(index,mat)
	RetailDetails.collision(root,Vector3(0,.77,0),Vector3(4.40 if kind=="sedan" else 4.0,1.54,1.88))
	return root
