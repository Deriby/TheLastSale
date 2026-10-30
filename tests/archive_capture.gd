extends Node
## Offline source for the fictional DVR clip. Never creates a second world at runtime.
var world: ShiftWorld
var view: SubViewport
var camera: Camera3D
var figures: Array[Node3D]=[]
var animations: Array[AnimationPlayer]=[]
const TRACK: Array[Vector3]=[Vector3(4.8,0,-16.5),Vector3(4.8,0,-19.55),Vector3(2.0,0,-19.6),Vector3(0,0,-19.6)]
func _ready() -> void:call_deferred("capture")
func along(distance: float) -> Transform3D:
	for i in TRACK.size()-1:
		var length:=TRACK[i].distance_to(TRACK[i+1])
		if distance<length:
			var direction: Vector3=(TRACK[i+1]-TRACK[i]).normalized()
			return Transform3D(Basis(Vector3.UP,atan2(direction.x,direction.z)),TRACK[i].lerp(TRACK[i+1],distance/length))
		distance-=length
	return Transform3D(Basis.IDENTITY,TRACK[-1])
func capture() -> void:
	Session.new_shift();Session.advance_to_sunday();Session.campaign.phase="sunday_investigation"
	view=SubViewport.new();view.size=Vector2i(384,216);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	world=ShiftWorld.new();view.add_child(world);world.active=false;world.sunday.change_door("service",true);world.sunday.change_door("old",true)
	for actor in world.characters.values():actor.hide();actor.process_mode=Node.PROCESS_MODE_DISABLED
	world.depot.yard.get_node("YardBatteryLight").omni_range=6.5;world.depot.yard.get_node("YardBatteryLight").light_energy=.9
	camera=Camera3D.new();world.add_child(camera);camera.position=Vector3(6,2.6,-20.3);camera.look_at(Vector3(4.5,1,-17.6));camera.fov=74;camera.current=true
	for id in ["Customer2","ClienteBone"]:
		var visual:=CharacterModels.create(id);world.add_child(visual);figures.append(visual)
		var animation: AnimationPlayer=visual.find_child("AnimationPlayer",true,false)
		for clip in animation.get_animation_list():
			if clip.ends_with("walk"):animation.play(clip);break
		animations.append(animation)
	var folder:=OS.get_environment("DVR_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	for i in 12:await get_tree().process_frame
	for frame in 80:
		var time:=frame/10.0
		figures[0].transform=along(time*1.05+1.3);figures[1].transform=along(time*1.05)
		for animation in animations:animation.seek(fmod(time,animation.current_animation_length),true)
		await get_tree().process_frame;await RenderingServer.frame_post_draw
		view.get_texture().get_image().save_png(folder.path_join("%04d.png"%frame))
	print("DVR_FRAMES 80")
	world.queue_free();await get_tree().process_frame;Geo.materials.clear();CharacterModels.costume_materials.clear();CharacterModels.imported_materials.clear();get_tree().quit()
