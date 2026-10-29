extends Node
## Structural memory/startup audit. Decoded array sizes are not total RAM or VRAM.
var app: Node
var report: Dictionary = {}
var prefix:="performance"
func _ready() -> void:call_deferred("review")
func frames(count: int) -> void:
	for i in count:await get_tree().process_frame
func structure() -> Dictionary:
	var totals:={"mesh_instances":0,"mesh_resources":0,"vertices":0,"indices":0,"triangles":0,"mesh_buffer_bytes":0,"nodes":0,"shadow_lights":0}
	var meshes:={}
	for node in app.world.find_children("*","Node",true,false):
		totals.nodes+=1
		if node is Light3D and node.shadow_enabled:totals.shadow_lights+=1
		if not node is MeshInstance3D or node.mesh==null:continue
		totals.mesh_instances+=1
		var mesh: Mesh=node.mesh
		if meshes.has(mesh.get_instance_id()):continue
		meshes[mesh.get_instance_id()]=true;totals.mesh_resources+=1
		for surface in mesh.get_surface_count():
			var arrays:=mesh.surface_get_arrays(surface)
			var vertices: int=arrays[Mesh.ARRAY_VERTEX].size()
			var indices: int=arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else 0
			totals.vertices+=vertices;totals.indices+=indices
			totals.triangles+=(indices if indices>0 else vertices)/3
			for data in arrays:
				if data==null:continue
				if data is PackedVector3Array:totals.mesh_buffer_bytes+=data.size()*12
				elif data is PackedVector2Array:totals.mesh_buffer_bytes+=data.size()*8
				elif data is PackedColorArray:totals.mesh_buffer_bytes+=data.size()*16
				elif data is PackedFloat32Array or data is PackedInt32Array:totals.mesh_buffer_bytes+=data.size()*4
	return totals
func review() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	Engine.max_fps=0
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():prefix=args[0]
	Preferences.pixel_scale=3 if prefix.contains("eco") else 1;Preferences.grain=0
	await get_tree().physics_frame
	var before:=Time.get_ticks_usec()
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	report["menu_build_ms"]=(Time.get_ticks_usec()-before)/1000.0
	before=Time.get_ticks_usec();app.start_new();report["start_shift_ms"]=(Time.get_ticks_usec()-before)/1000.0
	app.interface.has_started=true;app.interface.set_paused(true);app.interface.root.hide()
	report["structure"]=structure();report["pixel_scale"]=Preferences.pixel_scale
	report["measurement"]="decoded mesh arrays and startup work; not a hardware FPS benchmark"
	print("PROFILE_STRUCTURE ",JSON.stringify(report.structure))
	FileAccess.open("/tmp/"+prefix+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	app.queue_free();await frames(4)
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();await frames(4);get_tree().quit()
