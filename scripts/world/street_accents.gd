class_name StreetAccents
extends Node3D
## Small local wear/service details; exact placement is an artistic approximation.
func _init() -> void:
	name="StreetAccents";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
func _ready() -> void:
	var batch:=PropBatch.new();add_child(batch)
	var iron:=StreetDetail.material(Color("414a46"));var cement:=StreetDetail.material(Color("9e9d89"),"render")
	for x in [-15.0,-4.5,8.8,20.2]:
		for z in [2.58,10.52]:
			var y:=Street.surface_height(x,z)+.008
			batch.add_box(Vector3(x,y-.025,z),Vector3(.72,.045,.22),iron)
			for i in 8:batch.add_box(Vector3(x-.30+i*.085,y+.004,z),Vector3(.026,.012,.22),cement)
	for x in [-11.2,-4.8,7.2,18.4]:
		for z in [1.05,11.5]:SceneDetail.decal(self,Vector3(x,Street.surface_height(x,z)+.009,z),Vector2(.80,.55),"cracks",x*.3)
	for x in [-10.0,-3.0,6.2,15.0]:
		for z in [2.38,10.73]:
			NeighborhoodProps.grass(batch,Vector3(x,Street.surface_height(x,z)+.005,z),x*.3)
	# Meter boxes, service pipes, mail slots and doorstep patches on photographed fronts.
	for frontage in get_parent().get_children():
		if frontage is Node3D and frontage.has_meta("frontage_kind"):NeighborhoodServices.add_to(frontage)
	batch.flush()
