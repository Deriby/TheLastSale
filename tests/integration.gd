extends Node
## Integration tests use actual physics, original assets and complete customer routes.
var failures: Array[String] = []
var checks:=0
var app: Node
var world: ShiftWorld
var player: DepotPlayer
var served_states: Dictionary = {}
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
	app.start_new();app.interface.has_started=true;app.interface.set_paused(false)
	world=app.world;player=world.player
	await ticks(12)
	check(world.depot!=null and player.is_on_floor(),"cena principal e chão físico carregam")
	check(player.visual.find_child("Skeleton3D",true,false).get_bone_count()==19,"Dery usa esqueleto humanoide de 19 ossos")
	check(player.animator.get_animation_list().size()>=14,"clipes de Dery importados")
	for name in ["Dery","Felps","Enemy","Customer1","Customer2","Customer3"]:
		var model: Node=load("res://assets/models/characters/"+name+".glb").instantiate()
		check(model.find_child("Skeleton3D",true,false)!=null,"rig importado: "+name)
		var meshes:=model.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty() and meshes[0].mesh.surface_get_material(0)!=null,"material presente: "+name)
		if name in ["Dery","Felps","Enemy"]:check(meshes[0].mesh.surface_get_material(0).albedo_texture!=null,"textura original preservada na derivação: "+name)
		model.free()
	player.position=Vector3(3.8,.01,.9);player.camera_rig.yaw=0
	var start:=player.position
	Input.action_press("forward");await ticks(24);Input.action_release("forward");await ticks(10)
	var walked:=start.distance_to(player.position)
	check(walked>.5,"WASD move Dery com colisão real")
	player.position=start;player.velocity=Vector3.ZERO
	Input.action_press("forward");Input.action_press("sprint");await ticks(24);Input.action_release("forward");Input.action_release("sprint");await ticks(2)
	check(start.distance_to(player.position)>walked,"corrida mais rápida que caminhada")
	Input.action_press("crouch");await ticks(3)
	check(player.crouching and player.capsule.height<1.2,"agachamento altera colisão")
	Input.action_release("crouch");await ticks(3)
	var previous_distance:=player.camera_rig.target_distance
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=Vector2(640,360);Input.parse_input_event(wheel);await ticks(3)
	check(player.camera_rig.target_distance<previous_distance,"roda do mouse chega à câmera pela viewport")
	var previous_yaw:=player.camera_rig.yaw
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(50,0);motion.position=Vector2(640,360);Input.parse_input_event(motion);await ticks(3)
	check(player.camera_rig.yaw!=previous_yaw,"movimento do mouse gira a câmera pela viewport")
	player.position=Vector3(5.45,0,-6.5);player.velocity=Vector3.ZERO;player.camera_rig.yaw=PI/2;player.camera_rig.target_distance=2.5
	await ticks(30)
	check(player.camera_rig.arm.get_hit_length()<1.0,"SpringArm encurta ao encostar na parede")
	check(player.camera_rig.camera.global_position.x<5.9,"câmera permanece do lado interno da parede")
	player.camera_rig.target_distance=0;await ticks(40)
	check(player.camera_rig.first_person and not player.visual.visible,"aproximação entra em primeira pessoa sem interior da cabeça")
	player.camera_rig.target_distance=2.5;await ticks(40)
	check(not player.camera_rig.first_person and player.visual.visible,"afastamento retorna à terceira pessoa")
	player.position=Vector3(4.4,0,-1.65);player.camera_rig.yaw=0;player.camera_rig.pitch=-.13;await ticks(20)
	check(player.target!=null and player.target.kind=="talk","Felps é alcançável pela interação sobre o balcão")
	var interact_key:=InputEventKey.new();interact_key.physical_keycode=KEY_E;interact_key.keycode=KEY_E;interact_key.pressed=true;Input.parse_input_event(interact_key);await ticks(2)
	check(Session.stage==1,"tecla E conversa com Felps e libera tarefas")
	check(Dialogue.active,"diálogo exibe falas reais")
	clear_dialogue()
	check(not Session.deliver("loose"),"caixa errada não avança reposição")
	var door:=find_interaction(world.depot.stock_door,"door")
	var a:=Vector3(4.9,1,-10.3);var b:=Vector3(4.9,1,-11.8)
	var space:=world.get_world_3d().direct_space_state
	check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty(),"porta fechada bloqueia passagem")
	door.activate(player);await ticks(40)
	check(space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty(),"porta aberta libera passagem física")
	var fridge:=find_interaction(world.depot.fridge_target,"fridge")
	for id in ["stock_1","stock_2"]:
		var item: Node3D=world.depot.crates[id]
		player.position=item.position+Vector3(0,0,.7)
		check(find_interaction(item,"crate").activate(player),"pegar "+id)
		await ticks(2)
		check(player.carried==item and item.get_parent()==player.socket,"caixa presa ao transporte visível")
		player.position=Vector3(-4.1,0,-3.4)
		if not fridge.open:fridge.activate(player)
		check(fridge.activate(player),"repor "+id)
		await ticks(2)
		check(player.carried==null,"mãos livres após reposição")
	check(Session.stage==3 and Session.stocked.size()==2,"duas reposições completam objetivo na ordem")
	var loose: Node3D=world.depot.crates.loose
	find_interaction(loose,"crate").activate(player);await ticks(2)
	var pallet: Interaction
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="pallet":pallet=node
	check(pallet.activate(player) and Session.organized,"organização move caixa para palete")
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
		if Dialogue.active and world.customer!=null and world.customer.state==Customer.State.WAITING:
			clear_dialogue()
		if Session.warning_delivered:break
	Engine.time_scale=1
	check(Session.customers_served>=3,"clientes atravessam loja, compram e saem")
	check(served_states.size()>=7,"máquina de estados dos clientes executa o ciclo completo")
	check(Session.warning_delivered and Session.stage==6,"aviso ocorre somente depois da rotina e da visita")
	clear_dialogue()
	player.position=Vector3(4,0,-6);await ticks(3)
	check(Dialogue.active,"ruído posterior tem reação narrativa")
	clear_dialogue()
	check(find_interaction(world.depot.old_door,"note").activate(player) and Session.finale_seen,"inspeção do ruído conclui a demonstração")
	check(Session.save_shift(Vector3(1,0,-4))==OK,"salvamento grava checkpoint")
	Session.new_shift();check(Session.load_shift() and Session.stage==7 and Session.stocked.size()==2,"checkpoint restaura progressão e tarefas")
	clear_dialogue()
	app.start_saved();world=app.world;player=world.player;await ticks(5)
	check(player.position.distance_to(Vector3(1,0,-4))<.3,"continuar restaura posição no mundo")
	check(not is_instance_valid(world.depot.crates.stock_1),"continuar não duplica caixas já repostas")
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
