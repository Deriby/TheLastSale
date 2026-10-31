extends Node3D
var checks := 0
var failures: Array[String]=[]
var metrics: Dictionary={}
func check(value: bool,message: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",message)
	if not value:failures.append(message)
func ticks(count: int) -> void:
	for frame in count:await get_tree().physics_frame
	await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func sample(identity: String) -> Dictionary:
	var actor:=Node3D.new();add_child(actor);actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var visual:=CharacterModels.create(identity);actor.add_child(visual)
	var motion:=LivingMotion.new();actor.add_child(motion);motion.setup(visual,actor)
	motion.feet.active=false;motion.detail.active=false;motion.attention.active=false
	var sk:=motion.skeleton;var valid:=true;var seam:=0.0;var results:={}
	for clip in ["idle","walk","run"]:
		motion.play(clip,0);var wrist_min:=Vector3(INF,INF,INF);var wrist_max:=-wrist_min;var roll_min:=INF;var roll_max:=-INF
		var first: Array[Transform3D]=[]
		for frame in 41:
			motion.animator.seek(float(frame)/40*motion.animator.current_animation_length,true);motion.animator.advance(0)
			var head:=sk.get_bone_global_pose(sk.find_bone("head")).origin
			var pelvis:=sk.get_bone_global_pose(sk.find_bone("pelvis")).origin
			var wrist:=sk.get_bone_global_pose(sk.find_bone("hand_R")).origin
			wrist_min=wrist_min.min(wrist);wrist_max=wrist_max.max(wrist)
			var roll:=atan2(head.x-pelvis.x,head.y-pelvis.y);roll_min=minf(roll_min,roll);roll_max=maxf(roll_max,roll)
			for bone in sk.get_bone_count():
				var pose:=sk.get_bone_global_pose(bone);valid=valid and pose.is_finite()
				if frame==0:first.append(pose)
				elif frame==40:seam=maxf(seam,pose.origin.distance_to(first[bone].origin))
		results[clip]={"hand_range":(wrist_max-wrist_min).length()*sk.global_basis.get_scale().x,"body_roll_range":roll_max-roll_min}
	check(valid and seam<.003,identity+" mantém corpo finito e ciclo sem salto de posição (%.4f m)"%seam)
	results["cadence_at_1_15_mps"]=1.15/float(motion.strides.walk)
	actor.free();return results
func run() -> void:
	Engine.max_fps=60
	for identity in ["Dery","Felps","Garota1","Garota2","Customer1","Customer2","Customer3","Zirico","Bryan","Velha1","Enemy"]:metrics[identity]=sample(identity)
	check(float(metrics.Zirico.idle.body_roll_range)>float(metrics.Dery.idle.body_roll_range)*2.5,"Zirico oscila o tronco de forma própria em vez de usar repouso genérico")
	check(float(metrics.Bryan.idle.hand_range)>float(metrics.Dery.idle.hand_range)*2.0 and float(metrics.Bryan.idle.hand_range)>.04,"Bryan tem gestos inquietos reais no repouso, proporcionais ao corpo infantil")
	check(absf(float(metrics.Dery.cadence_at_1_15_mps)-float(metrics.Felps.cadence_at_1_15_mps))>.03,"Deryk e Felps não compartilham a mesma cadência de caminhada")
	Geo.box(self,Vector3(0,-.1,0),Vector3(24,.2,24),Geo.material(Color("777777")))
	var wall:=Geo.box(self,Vector3(0,1,0),Vector3(14,2,.2),Geo.material(Color("555555")))
	var nav:=AisleNavigation.new();nav.configure([])
	var customers: Array[Customer]=[]
	var ids: Array[String]=["ClienteBone","ClienteTrabalho","ClienteVinho","ClienteMostarda","ClienteCinza","ClienteVerde"]
	for index in ids.size():
		var customer:=Customer.new();customer.identity=ids[index];customer.navigation=nav;customer.position=Vector3(-5+index*2,.01,.55);add_child(customer)
		customer.waypoints=PackedVector3Array([Vector3(customer.position.x,0,-2)]);customers.append(customer)
		check(customer.motion!=null and str(customer.motion.clips.walk).begins_with("natural/"),ids[index]+" usa o mesmo controlador medido das personagens importadas")
	var visitor:=Customer.new();visitor.warned=true;visitor.navigation=nav;visitor.position=Vector3(6,.01,.55);add_child(visitor)
	visitor.waypoints=PackedVector3Array([Vector3(6,0,-2)]);customers.append(visitor)
	check(visitor.motion!=null and str(visitor.motion.clips.walk).begins_with("natural/"),"cliente do aviso também usa caminhada medida sem alterar seu evento narrativo")
	var friends: Array[FamiliarNPC]=[]
	for index in 2:
		var friend:=FamiliarNPC.new();friend.identity="Bryan" if index==0 else "Zirico";friend.position=Vector3(-2+index*4,.01,1.35);add_child(friend)
		friend.depart(PackedVector3Array([Vector3(friend.position.x,0,-2)]));friends.append(friend)
	await ticks(90)
	var bounded:=true
	for customer in customers:
		var sk:=customer.motion.skeleton
		for bone in sk.get_bone_count():
			var pose:=sk.get_bone_global_pose(bone);bounded=bounded and pose.is_finite() and pose.basis.get_scale().length()<2.0
	check(bounded,"modificadores em execução não acumulam escala nem deformam os corpos")
	for customer in customers:check(customer.actual_speed<.03 and not customer.motion.strides.has(customer.motion.current_clip),customer.identity+" para a passada ao ser bloqueado por uma parede")
	for friend in friends:check(friend.actual_speed<.03 and not friend.motion.strides.has(friend.motion.current_clip),friend.identity+" também não caminha no lugar quando bloqueado")
	wall.queue_free();await ticks(15)
	for customer in customers:check(customer.actual_speed>.6 and customer.motion.current_clip=="walk",customer.identity+" retoma a passada quando o caminho volta a abrir")
	for friend in friends:check(friend.actual_speed>.6 and friend.motion.current_clip=="walk",friend.identity+" retoma seu estilo ao voltar a se deslocar")
	var resting:=customers[0];resting.set_physics_process(false)
	resting.motion.locomotion(.1,0,false,false,false);resting.motion.idle_time=12;resting.motion.locomotion(.1,0,false,false,false)
	resting.motion.animator.seek(resting.motion.animator.current_animation_length-.01,true);resting.motion.animator.advance(.05)
	await get_tree().process_frame
	resting.motion.locomotion(.1,0,false,false,false)
	check(not resting.motion.ambient_active and resting.motion.current_clip=="idle","gesto de repouso de cliente termina e retorna ao normal sem ficar preso em loop")
	for customer in customers:customer.queue_free()
	for friend in friends:friend.queue_free()
	await ticks(5)
	var path:=OS.get_environment("LOCOMOTION_REPORT_PATH")
	if not path.is_empty():FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(metrics,"  "))
	Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear()
	print("LOCOMOTION RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
