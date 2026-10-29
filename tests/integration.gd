extends Node
## Integration tests use actual physics, original assets and complete customer routes.
var failures: Array[String] = []
var checks:=0
var app: Node
var world: ShiftWorld
var player: DepotPlayer
var served_states: Dictionary = {}
var checkout_positions_valid:=true
func check(condition: bool,description: String) -> void:
	checks+=1
	print("PASS " if condition else "FAIL ",description)
	if not condition:failures.append(description)
func ticks(count: int) -> void:
	for i in count:await get_tree().physics_frame
func find_interaction(parent: Node,kind: String) -> Interaction:
	for node in parent.get_children():
		if node is Interaction and node.kind==kind:return node
	return null
func clear_dialogue() -> void:
	while Dialogue.active:Dialogue.next_line()
func _ready() -> void:call_deferred("run")
func run() -> void:
	app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app)
	await get_tree().process_frame
	check(get_tree().paused,"menu inicial pausa o mundo")
	var loaded_world_id: int=app.world.get_instance_id()
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	world=app.world;player=world.player
	check(world.get_instance_id()==loaded_world_id,"primeiro início aproveita o cenário já carregado no menu")
	check(world.enemy_visual.process_mode==Node.PROCESS_MODE_DISABLED,"assassino oculto não atualiza animações")
	world.enemy_visual.show()
	check(world.enemy_visual.process_mode==Node.PROCESS_MODE_INHERIT,"assassino retoma processamento quando fica visível")
	world.enemy_visual.hide()
	await ticks(12)
	check(world.depot!=null and player.is_on_floor(),"cena principal e chão físico carregam")
	player.position=Vector3(4.2,.01,-2.0);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.reset_physics_interpolation()
	Input.action_press("forward");await ticks(75);Input.action_release("forward");await ticks(10)
	check(player.is_on_floor() and player.position.z< -3.3,"antigo caixa da direita está livre para circulação real")
	check(player.foot_audio.stream==player.tile_step,"passos no salão usam contato seco de piso cerâmico")
	var street_space:=world.get_world_3d().direct_space_state
	var annex_roof:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.7,2.8,-2.75),Vector3(-4.7,7,-2.75),1))
	check(not annex_roof.is_empty() and annex_roof.position.y>4.25 and annex_roof.position.y<4.6,"cobertura baixa fecha o teto sobre o caixa esquerdo")
	var rear_roof:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.7,2.8,-8),Vector3(-4.7,7,-8),1))
	check(not rear_roof.is_empty() and rear_roof.position.y>5.2,"cobertura alta fecha o lado esquerdo dos fundos")
	var side_riser:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-3.8,5.1,-2.2),Vector3(-1.8,5.1,-2.2),1))
	check(not side_riser.is_empty() and absf(side_riser.position.x+2.1)<.2,"encontro lateral entre os dois níveis do telhado não tem vão")
	var rear_riser:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.3,5,-4.5),Vector3(-4.3,5,-7.4),1))
	check(not rear_riser.is_empty() and absf(rear_riser.position.z+6)<.2,"encontro traseiro da cobertura baixa não tem vão")
	var detailed_cars:=0
	for car in world.street.find_children("Parked*","Node3D",true,false):
		if not car.has_meta("vehicle_kind"):continue
		var triangles:=0;var first_bounds:=true;var bounds:=AABB()
		for part in car.find_children("*","MeshInstance3D",true,false):
			var box: AABB=(car.global_transform.affine_inverse()*part.global_transform)*part.get_aabb()
			bounds=box if first_bounds else bounds.merge(box);first_bounds=false
			for index in part.mesh.get_surface_count():triangles+=part.mesh.surface_get_array_index_len(index)/3
		if triangles>25000 and bounds.size.x>3.5 and bounds.size.x<4.8 and bounds.size.y>1.2 and bounds.size.y<1.8:detailed_cars+=1
	check(detailed_cars==2,"sedã e hatch importados têm malhas detalhadas e escala de automóvel")
	var lower:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-20,4,6.5),Vector3(-20,-3,6.5),1))
	var upper:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(20,4,6.5),Vector3(20,-3,6.5),1))
	check(not lower.is_empty() and not upper.is_empty() and upper.position.y-lower.position.y>.8,"rua tem declive físico contínuo entre os lados do quarteirão")
	var post:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(.78,.5,1.3),Vector3(.78,.5,.2),1))
	check(not post.is_empty(),"balizadores da fachada têm colisão física")
	player.position=Vector3(-1.8,.02,1.8);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI;player.reset_physics_interpolation()
	Input.action_press("forward");await ticks(75);Input.action_release("forward");await ticks(10)
	check(player.position.z>3.1 and player.is_on_floor() and player.position.y<-.08,"jogador desce o meio-fio e entra na rua sem cair pelo chão")
	check(player.foot_audio.stream==player.asphalt_step,"passos na rua trocam para contato de asfalto")
	player.position=Vector3(-1.8,-.12,9.8);player.velocity=Vector3.ZERO;player.reset_physics_interpolation()
	Input.action_press("forward");await ticks(75);Input.action_release("forward");await ticks(10)
	check(player.position.z>11.0 and player.is_on_floor() and player.position.y>-.03,"jogador sobe à calçada oposta sem ficar preso no meio-fio")
	var apron:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10.1,2,10.4),Vector3(-10.1,-2,10.4),1))
	check(not apron.is_empty() and absf(apron.position.y-Street.surface_height(-10.1,10.4))<.015,"rampa de garagem tem piso físico coerente com a altura de navegação")
	player.position=Vector3(-10.1,Street.surface_height(-10.1,9.7)+.03,9.7);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI;player.reset_physics_interpolation()
	var ramp_contact:=false;var ramp_error:=0.0
	Input.action_press("forward")
	for i in 70:
		await ticks(1)
		if player.is_on_floor() and player.position.z>10.15 and player.position.z<10.60:
			ramp_contact=true;ramp_error=maxf(ramp_error,absf(player.position.y-Street.surface_height(player.position.x,player.position.z)))
	Input.action_release("forward");await ticks(8)
	check(player.is_on_floor() and player.position.z>11.0 and ramp_contact and ramp_error<.04,"jogador atravessa a nova rampa com contato no piso sem cair ou travar")
	var ramp_save:=world.navigation.nearest_walkable(Vector3(-10.1,-.6,10.4))
	check(absf(ramp_save.y-Street.surface_height(ramp_save.x,ramp_save.z)-.01)<.015,"checkpoint na rampa acompanha o piso inclinado")
	var alley:=street_space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-18,Street.grade(-18)+.8,.8),Vector3(-18,Street.grade(-18)+.8,-.8),1))
	check(not alley.is_empty(),"fechamento físico protege o vão entre as oficinas junto à borda da calçada")
	player.position=Vector3(3.8,.01,1.8);player.velocity=Vector3.ZERO;player.camera_rig.yaw=0;player.reset_physics_interpolation();await ticks(12)
	check(player.visual.find_child("Skeleton3D",true,false).get_bone_count()==72,"Dery mantém os 71 ossos recebidos e um controle adicional de peito superior")
	check(player.animator.get_animation_list().size()>=23,"23 clipes de Dery importados")
	for name in ["Dery","Felps","Enemy","Bryan","Zirico","Garota1","Garota2","Velha1","Customer3"]:
		var model: Node=load("res://assets/models/characters/"+name+".glb").instantiate()
		check(model.find_child("Skeleton3D",true,false)!=null,"rig importado: "+name)
		var meshes:=model.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty() and meshes[0].mesh.surface_get_material(0)!=null,"material presente: "+name)
		if name in ["Dery","Felps","Enemy"]:check(meshes[0].mesh.surface_get_material(0).albedo_texture!=null,"textura original preservada na derivação: "+name)
		model.free()
	var friends:=get_tree().get_nodes_in_group("familiar_npcs")
	check(friends.size()==2,"Bryan e Zirico estão presentes como conhecidos dos protagonistas")
	var child: FamiliarNPC=get_tree().get_first_node_in_group("familiar_npcs")
	check(child.identity=="Bryan" and float(child.visual.get_meta("height_m"))<1.3,"Bryan tem escala infantil própria")
	var stage_before:=Session.stage
	check(child.interaction.activate(player) and Dialogue.sequence=="familiar_Bryan","Bryan tem conversa opcional com Dery e Felps")
	clear_dialogue()
	check(Session.stage==stage_before,"conversa com Bryan preserva o progresso do expediente")
	var imported_normals:=false
	Preferences.pixel_scale=3;CharacterModels.apply_quality()
	for entry in CharacterModels.imported_materials.values():imported_normals=imported_normals or entry.material.normal_enabled
	check(not imported_normals,"modo Econômica desliga os mapas normais dos novos FBX")
	Preferences.pixel_scale=1;CharacterModels.apply_quality()
	for entry in CharacterModels.imported_materials.values():imported_normals=imported_normals or entry.material.normal_enabled
	check(imported_normals,"modo Nítida restaura os mapas normais dos novos FBX")
	var elder: Node3D=CharacterModels.create("Velha1");add_child(elder)
	var elder_motion:=LivingMotion.new();elder.add_child(elder_motion);elder_motion.setup(elder,elder)
	check(absf(elder_motion.feet.clearance-float(elder.get_meta("foot_clearance")))<.001,"contato dos pés usa a medida do modelo recebido")
	elder.queue_free()
	var skeleton: Skeleton3D=player.motion.skeleton
	var chest_index:=skeleton.find_bone("chest")
	var breath_before:=skeleton.get_bone_global_pose(chest_index).basis.get_scale()
	var waist_before:=skeleton.get_bone_pose_rotation(skeleton.find_bone("waist"))
	var upper_before:=skeleton.get_bone_pose_rotation(skeleton.find_bone("upper_chest"))
	await ticks(35)
	check(breath_before.distance_to(skeleton.get_bone_global_pose(chest_index).basis.get_scale())>.0001,"respiração altera a caixa torácica em repouso")
	check(waist_before.angle_to(skeleton.get_bone_pose_rotation(skeleton.find_bone("waist")))>.001 and upper_before.angle_to(skeleton.get_bone_pose_rotation(skeleton.find_bone("upper_chest")))>.001,"cintura e peito superior articulam separadamente em repouso")
	var arms_relaxed:=true
	for side in ["L","R"]:
		var arm: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("arm_"+side)).origin
		var elbow: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("forearm_"+side)).origin
		var wrist: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+side)).origin
		var hip: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("thigh_"+side)).origin
		arms_relaxed=arms_relaxed and wrist.y<hip.y+.15 and elbow.y<arm.y-.18 and absf(wrist.x-hip.x)<.23
	check(arms_relaxed,"cotovelos baixos e punhos abaixo do quadril no repouso")
	var left_ankle:=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("foot_L")).origin
	var right_ankle:=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("foot_R")).origin
	check(absf(left_ankle.x-right_ankle.x)<.33 and absf(left_ankle.y-right_ankle.y)<.02,"repouso tem base estreita e dois pés apoiados")
	check(world.depot.felps.model.find_child("Felps_Head",true,false)!=null,"Felps correto usa malha de cabeça separada")
	player.position=Vector3(3.8,.01,.9);player.camera_rig.yaw=0
	var start:=player.position
	Input.action_press("forward");await ticks(24);Input.action_release("forward");await ticks(10)
	var walked:=start.distance_to(player.position)
	check(walked>.5,"WASD move Dery com colisão real")
	player.position=start;player.velocity=Vector3.ZERO
	Input.action_press("forward");Input.action_press("sprint");await ticks(24);Input.action_release("forward");Input.action_release("sprint");await ticks(2)
	check(start.distance_to(player.position)>walked,"corrida mais rápida que caminhada")
	Input.action_press("crouch");await ticks(3)
	check(player.crouching and player.capsule.height<1.35,"agachamento altera colisão")
	Input.action_release("crouch");await ticks(3)
	# Synthetic absolute coordinates must not be warped by headless mouse capture.
	# Keep the event going through the real viewport and application's input path.
	var previous_mouse_mode:=Input.mouse_mode
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var previous_distance:=player.camera_rig.target_distance
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=Vector2(640,360);wheel.global_position=wheel.position;Input.parse_input_event(wheel);await ticks(3)
	check(player.camera_rig.target_distance<previous_distance,"roda do mouse chega à câmera pela viewport")
	var previous_yaw:=player.camera_rig.yaw
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(50,0);motion.position=Vector2(640,360);motion.global_position=motion.position;Input.parse_input_event(motion);await ticks(3)
	check(player.camera_rig.yaw!=previous_yaw,"movimento do mouse gira a câmera pela viewport")
	Input.mouse_mode=previous_mouse_mode
	player.position=Vector3(5.45,0,-9.6);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI/2;player.camera_rig.target_distance=2.5
	await ticks(30)
	check(player.camera_rig.arm.get_hit_length()<1.0,"SpringArm encurta ao encostar na parede")
	check(player.camera_rig.camera.global_position.x<5.9,"câmera permanece do lado interno da parede")
	player.position=Vector3(5.55,0,-9.6);player.camera_rig.yaw=0;await ticks(20)
	check(player.camera_rig.arm.position.x<.25,"ombro recolhe lateralmente perto da parede")
	var camera_probe:=PhysicsShapeQueryParameters3D.new();var camera_sphere:=SphereShape3D.new();camera_sphere.radius=.045;camera_probe.shape=camera_sphere;camera_probe.transform=Transform3D(Basis.IDENTITY,player.camera_rig.camera.global_position);camera_probe.collision_mask=1
	check(world.get_world_3d().direct_space_state.intersect_shape(camera_probe).is_empty(),"volume próximo da lente fica fora da parede")
	player.camera_rig.target_distance=0;await ticks(40)
	check(player.camera_rig.first_person and player.visual.find_child("Dery_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and player.visual.find_child("Dery_Body",true,false).visible,"aproximação entra em primeira pessoa com corpo visível e cabeça apenas na sombra")
	player.position=Vector3(3.4,0,-7.8);player.reset_physics_interpolation()
	player.camera_rig.target_distance=2.5;await ticks(40)
	check(not player.camera_rig.first_person and player.visual.find_child("Dery_Head",true,false).visible and player.visual.find_child("Dery_Head",true,false).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"afastamento retorna à terceira pessoa")
	player.position=CheckoutFixture.CUSTOMER_POSITION;player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI/2;player.camera_rig.pitch=-.13;player.reset_physics_interpolation();await ticks(30)
	check(player.target!=null and player.target.kind=="talk","Felps é alcançável pela interação sobre o balcão")
	var interact_key:=InputEventKey.new();interact_key.physical_keycode=KEY_E;interact_key.keycode=KEY_E;interact_key.pressed=true;Input.parse_input_event(interact_key);await ticks(2)
	check(Session.stage==1,"tecla E conversa com Felps e libera tarefas")
	check(Dialogue.active,"diálogo exibe falas reais")
	check(world.depot.felps.motion.current_clip=="talk","Felps gesticula enquanto fala")
	clear_dialogue()
	check(not Session.deliver("loose"),"caixa errada não avança reposição")
	var door:=find_interaction(world.depot.stock_door,"door")
	var a:=Vector3(4.9,1,-10.3);var b:=Vector3(4.9,1,-11.8)
	var space:=world.get_world_3d().direct_space_state
	check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty(),"porta fechada bloqueia passagem")
	door.activate(player);await ticks(40)
	check(space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty(),"porta aberta libera passagem física")
	var fridge:=find_interaction(world.depot.fridge_target,"fridge")
	var initial_bottles: int=world.depot.fridge_target.products.groups["beer_0"].baked_count
	check(not find_interaction(world.depot.crates.stock_1,"crate").activate(player),"caixa distante exige aproximação antes de alcançar")
	for id in ["stock_1","stock_2"]:
		var item: Node3D=world.depot.crates[id]
		player.position=item.position+Vector3(0,0,.7)
		check(find_interaction(item,"crate").activate(player),"pegar "+id)
		check(player.motion.action_active and item.get_parent()!=player.socket,"pegar caixa começa com alcance antes da fixação")
		await ticks(85)
		check(player.carried==item and item.get_parent()==player.socket,"caixa presa ao transporte visível")
		var palm: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand_L")).origin
		check(palm.distance_to(item.to_global(Vector3(.325,.275,-.09)))<.10,"mão permanece junto à pega lateral da caixa")
		player.position=world.depot.fridge_target.global_position+Vector3(1.35,0,0)
		if not fridge.open:fridge.activate(player)
		check(fridge.activate(player),"repor "+id)
		await ticks(75)
		check(player.carried==null,"mãos livres após reposição")
		check(world.depot.fridge_target.products.groups["beer_0"].baked_count==initial_bottles+2*Session.stocked.size(),"malha visível recebe novos produtos após reposição")
	check(Session.stage==3 and Session.stocked.size()==2,"duas reposições completam objetivo na ordem")
	var loose: Node3D=world.depot.crates.loose
	player.position=loose.global_position+Vector3(0,0,.7)
	find_interaction(loose,"crate").activate(player);await ticks(85)
	player.position=Vector3(-3.8,0,-12.8)
	var pallet: Interaction
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="pallet":pallet=node
	check(pallet.activate(player) and Session.organized,"organização move caixa para palete")
	await ticks(85)
	check(loose.global_position.distance_to(Vector3(-3.8,.23,-13.8))<.1,"caixa permanece materialmente no palete")
	clear_dialogue()
	check(not Session.can_warn(),"aviso exige clientes atendidos além das tarefas")
	player.position=Vector3(4.7,0,-8.5);player.velocity=Vector3.ZERO
	# Simulate the actual complete routes. No waypoint skipping or teleporting customers.
	Engine.time_scale=12
	for i in 3000:
		await get_tree().physics_frame
		if world.customer!=null:
			served_states[world.customer.state]=true
			if world.customer.state in [Customer.State.WAITING,Customer.State.PAYING] and world.customer.global_position.distance_to(CheckoutFixture.CUSTOMER_POSITION)>.4:checkout_positions_valid=false
		if Dialogue.active and world.customer!=null and world.customer.state==Customer.State.WAITING:
			clear_dialogue()
		if Session.warning_delivered:break
	Engine.time_scale=1
	check(Session.customers_served>=3,"clientes atravessam loja, compram e saem")
	var ambient_finished:=true
	for friend in get_tree().get_nodes_in_group("familiar_npcs"):
		if friend.motion.ambient_active:
			var clip: String=friend.motion.clips.get(friend.motion.current_clip,"")
			ambient_finished=ambient_finished and not clip.is_empty() and friend.motion.animator.get_animation(clip).loop_mode==Animation.LOOP_NONE
	check(ambient_finished,"conhecidos mantêm variações de repouso que terminam durante o expediente longo")
	check(served_states.size()>=7,"máquina de estados dos clientes executa o ciclo completo")
	check(checkout_positions_valid,"todos os clientes são atendidos junto ao novo balcão esquerdo")
	check(Session.warning_delivered and Session.stage==6,"aviso ocorre somente depois da rotina e da visita")
	clear_dialogue()
	player.position=Vector3(4,0,-6);await ticks(3)
	check(Dialogue.active,"ruído posterior tem reação narrativa")
	clear_dialogue()
	check(find_interaction(world.depot.old_door,"note").activate(player) and Session.finale_seen,"inspeção do ruído conclui a demonstração")
	check(Session.save_shift(Vector3(0,0,-4))==OK,"salvamento grava checkpoint")
	Session.new_shift();check(Session.load_shift() and Session.stage==7 and Session.stocked.size()==2,"checkpoint restaura progressão e tarefas")
	clear_dialogue()
	await get_tree().process_frame
	app.start_saved();world=app.world;player=world.player;await ticks(5)
	check(player.position.distance_to(Vector3(0,0,-4))<.3,"continuar restaura posição no mundo")
	check(not is_instance_valid(world.depot.crates.stock_1),"continuar não duplica caixas já repostas")
	check(world.depot.fridge_target.products.groups["beer_0"].baked_count==initial_bottles+4,"continuar restaura produtos na malha da geladeira")
	var migrated:=world.navigation.nearest_walkable(Vector3(1,0,-4))
	check(migrated.distance_to(Vector3(1,0,-4))>.3 and migrated.distance_to(Vector3(1,0,-4))<2,"checkpoint antigo dentro da gôndola migra para corredor próximo")
	Session.save_shift(Vector3(20,0,1.8))
	await get_tree().process_frame
	app.start_saved();world=app.world;player=world.player;await ticks(15)
	check(player.is_on_floor() and player.position.y>.4,"checkpoint antigo na rua acompanha a nova cota do terreno")
	Session.save_shift(Vector3(-4.25,0,-2.8))
	await get_tree().process_frame
	app.start_saved();world=app.world;player=world.player;await ticks(15)
	var restored_probe:=PhysicsShapeQueryParameters3D.new();var restored_capsule:=CapsuleShape3D.new();restored_capsule.radius=.24;restored_capsule.height=1.68
	restored_probe.shape=restored_capsule;restored_probe.transform=Transform3D(Basis.IDENTITY,player.global_position+Vector3.UP*.87);restored_probe.collision_mask=1
	check(player.is_on_floor() and world.get_world_3d().direct_space_state.intersect_shape(restored_probe).is_empty(),"checkpoint antigo no novo balcão restaura personagem fora dos móveis")
	app.interface.set_paused(true);var frozen:=Session.world_seconds;await ticks(3)
	check(Session.world_seconds==frozen,"pausa congela o relógio narrativo")
	app.interface.set_paused(false)
	print("RESULT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	app.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.2).timeout
	Geo.materials.clear()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
