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
			for i in 4:
				var p:=Vector3(x+i*.035,Street.surface_height(x,z)+.07,z)
				StreetDetail.rotated_box(batch,p,Vector3(.013,.15,.012),Vector3(.18*i,0,.14*(i-2)),StreetDetail.material(Color("68775a")))
	# Meter boxes, service pipes, mail slots and doorstep patches on photographed fronts.
	for frontage in get_parent().get_children():
		if not frontage is Node3D or not (str(frontage.name).begins_with("Opposite") or frontage.name=="CassianoGasShop" or frontage.name=="UphillTwoStoreyHouse"):continue
		var local:=PropBatch.new();local.name="FrontageServices";frontage.add_child(local)
		var width:=5.4
		var at_x:=width*.44
		local.add_box(Vector3(at_x,1.47,.11),Vector3(.20,.28,.08),cement)
		local.add_box(Vector3(at_x,1.5,.157),Vector3(.12,.09,.012),iron)
		StreetDetail.beam(local,Vector3(at_x,1.62,.09),Vector3(at_x,3.1,.09),.018,iron)
		local.add_box(Vector3(-at_x,.78,.09),Vector3(.23,.04,.02),iron)
		StreetDetail.beam(local,Vector3(-at_x,2.72,.10),Vector3(-at_x,.12,.10),.045,StreetDetail.material(Color("a9af9d")))
		local.add_box(Vector3(-at_x,.12,.17),Vector3(.065,.07,.18),StreetDetail.material(Color("9a9f8c")))
		local.flush()
	batch.flush()
