class_name LivingMotion
extends Node
## Small animation state controller: locomotion, idle variations and interruptible gestures.
signal pose_updated
signal action_finished
var animator: AnimationPlayer
var skeleton: Skeleton3D
var feet: GroundFeet
var attention: HeadAttention
var clips: Dictionary = {}
var action_active:=false
var ambient_active:=false
var idle_time:=0.0
var variation_index:=0
var locomotion_phase:=0.0
var current_clip:=""
var visual_meshes: Array[MeshInstance3D]=[]
var last_view_state:=-1
var strides: Dictionary = {"walk":1.12,"walk_back":.80,"strafe_left":.82,"strafe_right":.82,"run":2.35,"crouch_walk":.62,"carry_walk":.86}
const IDLE_VARIANTS: Array[String]=["idle_shift","idle_look","idle_adjust"]
const LOOP_CLIPS: Array[String] = ["idle","idle_tired","walk","walk_back","strafe_left","strafe_right","run","crouch_idle","crouch_walk","carry","carry_walk","talk","cashier","cashier_idle","look","hold_bottle"]
func setup(visual: Node3D,actor: Node3D) -> void:
	animator=visual.find_child("AnimationPlayer",true,false)
	skeleton=visual.find_child("Skeleton3D",true,false)
	for mesh in skeleton.find_children("*","MeshInstance3D",true,false):visual_meshes.append(mesh)
	for key in animator.get_animation_list():
		var name: String=key.get_slice("/",key.get_slice_count("/")-1)
		clips[name]=key
		animator.get_animation(key).loop_mode=Animation.LOOP_LINEAR if name in LOOP_CLIPS else Animation.LOOP_NONE
	animator.animation_finished.connect(on_finished)
	feet=GroundFeet.new();feet.actor=actor;skeleton.add_child(feet)
	attention=HeadAttention.new();attention.visual=visual;skeleton.add_child(attention)
	feet.clearance=float(visual.get_meta("foot_clearance",.1335))
	attention.eye_height=float(visual.get_meta("height_m",1.78))*.89
	var stride_scale: float=visual.get_meta("stride_scale",1.0)
	for key in strides:strides[key]*=stride_scale
	skeleton.skeleton_updated.connect(func():pose_updated.emit())
	play("idle",0)
func play(clip: String,blend := .22,preserve_phase := false) -> void:
	if not clips.has(clip):return
	# Speech or another explicit pose can interrupt a one-shot idle variation.
	if clip not in IDLE_VARIANTS:ambient_active=false
	if current_clip==clip and animator.is_playing():return
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
	if action_active:return
	if speed>.10:
		idle_time=0;ambient_active=false
		var clip: String="carry_walk" if carrying else ("crouch_walk" if crouch else ("run" if speed>2.55 else direction))
		play(clip,.20,true)
		animator.speed_scale=clampf(speed*animator.get_animation(clips[clip]).length/float(strides.get(clip,1.12)),.25,2.7)
	else:
		animator.speed_scale=1
		idle_time+=delta
		if ambient_active:return
		var clip: String="carry" if carrying else ("crouch_idle" if crouch else ("idle_tired" if tired else "idle"))
		if clip=="idle" and idle_time>8.5:
			var variants: Array[String]=[]
			for candidate in IDLE_VARIANTS:
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
