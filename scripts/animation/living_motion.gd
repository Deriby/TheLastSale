class_name LivingMotion
extends Node
## Small animation state controller: locomotion, idle variations and interruptible gestures.
signal pose_updated
signal action_finished
var animator: AnimationPlayer
var skeleton: Skeleton3D
var feet: GroundFeet
var attention: HeadAttention
var detail: MotionDetail
var filtered_speed:=0.0
var clips: Dictionary = {}
var action_active:=false
var ambient_active:=false
var idle_time:=0.0
var variation_index:=0
var locomotion_phase:=0.0
var current_clip:=""
var visual_meshes: Array[MeshInstance3D]=[]
var last_view_state:=-1
var profile: Dictionary={}
var contacts: Dictionary={}
var strides: Dictionary = {"walk":1.12,"walk_back":.80,"strafe_left":.82,"strafe_right":.82,"run":2.35,"crouch_walk":.62,"carry_walk":.86}
const IDLE_VARIANTS: Array[String]=["idle_shift","idle_look","idle_adjust"]
const LOOP_CLIPS: Array[String] = ["idle","idle_tired","walk","walk_back","strafe_left","strafe_right","run","crouch_idle","crouch_walk","carry","carry_walk","talk","cashier","cashier_idle","look","hold_bottle"]
func setup(visual: Node3D,actor: Node3D) -> void:
	profile=MotionProfiles.for_actor(str(visual.get_meta("character_identity",visual.scene_file_path.get_file().get_basename())),visual.scene_file_path)
	animator=visual.find_child("AnimationPlayer",true,false)
	skeleton=visual.find_child("Skeleton3D",true,false)
	for mesh in skeleton.find_children("*","MeshInstance3D",true,false):visual_meshes.append(mesh)
	for key in animator.get_animation_list():
		var name: String=key.get_slice("/",key.get_slice_count("/")-1)
		clips[name]=key
		animator.get_animation(key).loop_mode=Animation.LOOP_LINEAR if name in LOOP_CLIPS else Animation.LOOP_NONE
	animator.animation_finished.connect(on_finished)
	feet=GroundFeet.new();feet.actor=actor;skeleton.add_child(feet)
	detail=MotionDetail.new();detail.visual=visual;skeleton.add_child(detail)
	attention=HeadAttention.new();attention.visual=visual;skeleton.add_child(attention)
	feet.motion=self
	feet.clearance=float(visual.get_meta("foot_clearance",.1335))
	feet.anchor_limit=.025*float(visual.get_meta("stride_scale",1.0))
	attention.eye_height=float(visual.get_meta("height_m",1.78))*.89
	var stride_scale: float=visual.get_meta("stride_scale",1.0)
	for key in strides:strides[key]*=stride_scale
	var path: String="res://resources/motion/"+visual.scene_file_path.get_file().get_basename()+".res"
	if ResourceLoader.exists(path):
		var library: AnimationLibrary=load(path)
		if not animator.has_animation_library("natural"):animator.add_animation_library("natural",library)
		for clip in library.get_animation_list():clips[str(clip)]="natural/"+str(clip)
		for key in library.get_meta("strides",{}):strides[key]=library.get_meta("strides")[key]
		contacts=library.get_meta("contacts",{})
	skeleton.skeleton_updated.connect(func():pose_updated.emit())
	play("idle",0)
func foot_contact(side: String) -> float:
	if not contacts.has(current_clip):return 0.0
	var samples: Array=contacts[current_clip]
	var at:=fposmod(animator.current_animation_position/maxf(.001,animator.current_animation_length),1.0)*(samples.size()-1)
	var low:=int(at);var high:=mini(low+1,samples.size()-1);var k:=0 if side=="L" else 1
	return lerpf(samples[low][k],samples[high][k],at-low)
func play(clip: String,blend := .22,preserve_phase := false) -> void:
	if not clips.has(clip):return
	# Speech or another explicit pose can interrupt a one-shot idle variation.
	if clip not in IDLE_VARIANTS:ambient_active=false
	if current_clip==clip and animator.is_playing():return
	if feet!=null:feet.reset_contacts()
	var phase:=0.0
	if preserve_phase and strides.has(current_clip) and animator.current_animation_length>0:phase=fmod(animator.current_animation_position/animator.current_animation_length,1)
	current_clip=clip
	animator.play(clips[clip],blend)
	if preserve_phase:animator.seek(phase*animator.get_animation(clips[clip]).length,true)
	animator.advance(0)
func action(clip: String) -> void:
	action_active=true;ambient_active=false;animator.speed_scale=1
	play(clip,.18)
func on_finished(_name: StringName) -> void:
	if action_active:action_active=false;action_finished.emit()
	ambient_active=false;current_clip=""
func locomotion(delta: float,speed: float,crouch: bool,carrying: bool,tired: bool,direction := "walk") -> void:
	if detail!=null:detail.speed=speed;detail.carrying=carrying
	if action_active:return
	filtered_speed=lerpf(filtered_speed,speed,1-exp(-delta*14))
	var moving:=speed>(.075 if strides.has(current_clip) else .14)
	if moving:
		idle_time=0;ambient_active=false
		var clip: String="carry_walk" if carrying else ("crouch_walk" if crouch else ("run" if speed>2.55 else direction))
		if not clips.has(clip):clip="walk" if clips.has("walk") else "idle"
		play(clip,.20,true)
		animator.speed_scale=clampf(filtered_speed*animator.get_animation(clips[clip]).length/float(strides.get(clip,1.12)),.25,2.7)
	else:
		animator.speed_scale=1
		idle_time+=delta
		if ambient_active:return
		var clip: String="carry" if carrying else ("crouch_idle" if crouch else ("idle_tired" if tired else "idle"))
		if clip=="idle" and idle_time>float(profile.get("idle_after",8.5)):
			var variants: Array[String]=[]
			var choices: Array=["idle_adjust","idle_shift","idle_look"] if profile.get("style")=="restless_child" else IDLE_VARIANTS
			for candidate in choices:
				if clips.has(candidate):variants.append(candidate)
			if not variants.is_empty():
				clip=variants[variation_index%variants.size()];variation_index+=1;ambient_active=true
			idle_time=0
		play(clip,.35)
func look_at_position(at: Vector3,enabled := true) -> void:
	attention.target_global=at;attention.following=enabled
func set_first_person(value: bool,hide_body := false) -> void:
	# Keep a complete shadow while hiding geometry from the camera's own view.
	var state: int=(1 if value else 0)|(2 if hide_body else 0)
	if state==last_view_state:return
	last_view_state=state
	for mesh in visual_meshes:
		mesh.visible=true
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if hide_body or value and mesh.name.contains("Head") else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
