extends Node
var checks:=0
var failures: Array[String]=[]
var report: Dictionary={}
func check(value: bool,message: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",message)
	if not value:failures.append(message)
func _ready() -> void:call_deferred("run")
func pose_at(motion: LivingMotion,phase: float) -> Dictionary:
	motion.animator.seek(phase*motion.animator.current_animation_length,true);motion.animator.advance(0)
	var sk:=motion.skeleton;var result: Dictionary={}
	for bone in ["root","pelvis","thigh_L","thigh_R","shin_L","shin_R","foot_L","foot_R"]:
		result[bone]=sk.get_bone_global_pose(sk.find_bone(bone))
	return result
func run() -> void:
	for identity in ["Dery","Felps"]:
		var actor:=Node3D.new();add_child(actor);var visual:=CharacterModels.create(identity);actor.add_child(visual)
		var motion:=LivingMotion.new();actor.add_child(motion);motion.setup(visual,actor)
		motion.feet.active=false;motion.detail.active=false;motion.attention.active=false
		var sk:=motion.skeleton;var scale:=sk.global_basis.get_scale().x;var data: Dictionary={}
		for clip in ["walk","run"]:
			motion.play(clip,0);var speed:=3.9 if clip=="run" else 1.55
			var period: float=motion.strides[clip]/speed
			var low:=INF;var high:=-INF;var root_low:=INF;var root_high:=-INF
			var foot_turn:=0.0;var knee_turn:=0.0;var pitch_max:=0.0
			for frame in 241:
				var t:=float(frame)/240;var pose:=pose_at(motion,t);var next:=pose_at(motion,fposmod(t+1.0/(30*period),1.0))
				low=minf(low,pose.pelvis.origin.y);high=maxf(high,pose.pelvis.origin.y)
				root_low=minf(root_low,pose.root.origin.y);root_high=maxf(root_high,pose.root.origin.y)
				for side in ["L","R"]:
					for name in ["foot_"+side,"shin_"+side]:
						var angle: float=pose[name].basis.orthonormalized().get_rotation_quaternion().angle_to(next[name].basis.orthonormalized().get_rotation_quaternion())
						if name.begins_with("foot"):foot_turn=maxf(foot_turn,angle)
						else:knee_turn=maxf(knee_turn,angle)
					var delta: Basis=pose["foot_"+side].basis*sk.get_bone_global_rest(sk.find_bone("foot_"+side)).basis.inverse()
					var forward:=delta*Vector3.BACK;pitch_max=maxf(pitch_max,absf(atan2(-forward.y,forward.z)))
			var bob: float=(high-low)*scale
			check(bob<(.045 if clip=="run" else .060),identity+" "+clip+" mantém arco vertical contido (%.3f m)"%bob)
			check((root_high-root_low)*scale<.003,identity+" "+clip+" não anima saltos de correção no osso raiz")
			check(foot_turn<.42,identity+" "+clip+" limita giro do pé entre quadros a 30 FPS (%.1f°)"%rad_to_deg(foot_turn))
			check(knee_turn<.60,identity+" "+clip+" dobra os joelhos sem os trancos anteriores (%.1f°/quadro)"%rad_to_deg(knee_turn))
			check(pitch_max<.50,identity+" "+clip+" mantém os sapatos em ângulos legíveis (%.1f°)"%rad_to_deg(pitch_max))
			var first:=pose_at(motion,.06);var last:=pose_at(motion,.18)
			var slip: float=absf((last.foot_L.origin.z-first.foot_L.origin.z)*scale+motion.strides[clip]*.12)
			check(slip<.015,identity+" "+clip+" combina a velocidade do pé apoiado com a do corpo (erro %.3f m)"%slip)
			data[clip]={"pelvis_range_m":bob,"root_correction_range_m":(root_high-root_low)*scale,"max_foot_turn_degrees_at_30fps":rad_to_deg(foot_turn),"max_knee_turn_degrees_at_30fps":rad_to_deg(knee_turn),"max_foot_pitch_degrees":rad_to_deg(pitch_max),"support_velocity_error_m":slip,"cycle_seconds_at_game_speed":period}
		motion.filtered_speed=0;motion.locomotion(1,3.9,false,false,false)
		var stable:=motion.current_clip=="run"
		for frame in 120:
			motion.locomotion(1.0/60,2.48 if frame%2==0 else 2.62,false,false,false);stable=stable and motion.current_clip=="run"
		check(stable,identity+" não alterna caminhada/corrida a cada oscilação em torno de 2,55 m/s")
		for frame in 60:motion.locomotion(1.0/60,1.55,false,false,false)
		check(motion.current_clip=="walk",identity+" volta a caminhar quando desacelera")
		motion.filtered_speed=3.9;motion.play("run",0);pose_at(motion,.10)
		var foot:=sk.find_bone("foot_L");var before:=sk.get_bone_global_pose(foot)
		motion.feet.was_support.L=true;motion.feet.anchors.L=sk.global_transform*before.origin+Vector3(0,0,.025)
		motion.feet._process_modification()
		check(sk.get_bone_global_pose(foot).origin.distance_to(before.origin)<.00003,identity+" não prende a perna da corrida em uma âncora de caminhada")
		report[identity]=data;actor.free()
	var path:=OS.get_environment("SPRINT_REPORT_PATH")
	if not path.is_empty():FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	print("SPRINT RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
