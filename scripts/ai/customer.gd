class_name Customer
extends CharacterBody3D
signal checked_out(customer: Customer)
signal departed(customer: Customer)
signal impatient(text: String)
enum State {ENTERING,BROWSING,SELECTING_PRODUCT,GOING_TO_CHECKOUT,WAITING,PAYING,EXITING}
var state: State = State.ENTERING
var navigation: AisleNavigation
var waypoints:=PackedVector3Array()
var wait:=0.0
var warned := false
var appearance:=0
var visual: Node3D
var animation: AnimationPlayer
var motion: LivingMotion
var identity:=""
var product: MeshInstance3D
var destination:=Vector3.ZERO
var blocked_time:=0.0
var service_started:=false
var purchase_complete:=false
var basket_sku:="water"
var empty_handed:=false
var waited_seconds:=0.0
var wait_comment:=0
var bag: MeshInstance3D
var reroutes:=0
var actual_speed:=0.0
var talking:=false
var gaze_time:=0.0
var quiet_pause:=false
var entry_chimed:=false
var walked_distance:=0.0
var foot_audio: AudioStreamPlayer3D
func _ready() -> void:
	add_to_group("customers")
	collision_layer=2;collision_mask=1|2
	var col:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7;col.shape=shape;col.position.y=.85;add_child(col)
	identity="Customer3" if warned else NPCCast.customer_identity(appearance,identity)
	visual=CharacterModels.create(identity);add_child(visual)
	animation=visual.find_child("AnimationPlayer",true,false)
	motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	foot_audio=AudioStreamPlayer3D.new();add_child(foot_audio);foot_audio.stream=load("res://assets/audio/step_tile.wav");foot_audio.max_distance=11
	Dialogue.spoken.connect(func(who: String,_text: String):talking=who.begins_with("Cliente"))
	product=MeshInstance3D.new();visual.add_child(product);product.mesh=ProductLibrary.mesh(basket_sku);product.material_override=ProductLibrary.material(basket_sku);product.position=Vector3(.23,.95,.3);product.visible=false
	bag=Geo.box(visual,Vector3(.23,.73,.28),Vector3(.23,.32,.15),ProductLibrary.material("carton"),false);bag.visible=false
	if motion:motion.pose_updated.connect(sync_product)
	go_to(Vector3(0,0,-1.5))
func sync_product() -> void:
	if not product.visible and not bag.visible:return
	var sk:=motion.skeleton
	var hand:=sk.get_bone_global_pose(sk.find_bone("hand_R"))
	product.global_transform=Transform3D(Basis.IDENTITY,sk.global_transform*hand.origin+visual.global_basis.z*.05)
	bag.global_transform=Transform3D(Basis.IDENTITY,sk.global_transform*hand.origin-Vector3.UP*.14+visual.global_basis.z*.05)
func play(clip: String) -> void:
	if motion:
		motion.play(clip,.24);return
	if animation==null:return
	for key in animation.get_animation_list():
		if key==clip or key.ends_with("/"+clip):
			if animation.current_animation!=key:animation.play(key,.2)
			return
func go_to(at: Vector3) -> void:
	destination=at
	waypoints=navigation.path(global_position,at)
func _physics_process(delta: float) -> void:
	gaze_time+=delta
	if not waypoints.is_empty():
		var diff:=waypoints[0]-global_position;diff.y=0
		if diff.length()<.14:waypoints.remove_at(0)
		else:
			var dir:=diff.normalized();velocity.x=dir.x*1.15;velocity.z=dir.z*1.15;velocity.y=-2
			var before:=global_position;move_and_slide()
			actual_speed=Vector2(global_position.x-before.x,global_position.z-before.z).length()/maxf(delta,.001)
			walked_distance+=actual_speed*delta
			if walked_distance>.54:
				walked_distance=0;foot_audio.volume_db=-20+linear_to_db(maxf(.001,Preferences.effects_volume));foot_audio.play()
			if not entry_chimed and global_position.z<0:
				entry_chimed=true
				var world:=get_tree().get_first_node_in_group("shift_world") as ShiftWorld
				if world!=null:world.sound.play_spatial("res://assets/audio/everyday/entry_chime.ogg",Vector3(.7,2.1,.1),-14)
			visual.rotation.y=lerp_angle(visual.rotation.y,atan2(dir.x,dir.z),delta*9)
			if motion:motion.locomotion(delta,actual_speed,false,false,false)
			else:play("walk")
			blocked_time=blocked_time+delta if (global_position-before).dot(dir)<delta*.2 else 0
			if blocked_time>2.5:
				var people: Array[Vector3]=[]
				for group in ["protagonists","familiar_npcs"]:
					for person in get_tree().get_nodes_in_group(group):
						if person.global_position.distance_to(global_position)<4:people.append(person.global_position)
				var detour:=navigation.path_around(global_position,destination,people)
				if not detour.is_empty():waypoints=detour;reroutes+=1
				else:go_to(destination)
				blocked_time=0
		return
	velocity=Vector3.ZERO
	if motion:
		if Dialogue.active and talking:motion.play("talk",.3)
		elif state==State.SELECTING_PRODUCT:motion.play("browse",.3)
		elif state==State.PAYING and not quiet_pause:motion.play("pay",.3)
		elif product.visible or bag.visible:motion.play("hold_bottle",.3)
		else:motion.locomotion(delta,0,false,false,false)
		var player:=get_tree().get_first_node_in_group("player") as Node3D
		if player!=null:motion.look_at_position(player.global_position+Vector3.UP*1.6,state==State.PAYING or state==State.WAITING and fposmod(gaze_time,9.0)<4.2)
	else:play("carry" if product.visible else "idle")
	if state==State.WAITING and not purchase_complete and not Dialogue.active:
		waited_seconds+=delta
		if waited_seconds>45 and wait_comment==0:
			wait_comment=1;impatient.emit("Cliente: vocês conseguem me atender? Ainda tô esperando aqui.")
		elif waited_seconds>100 and wait_comment==1:
			wait_comment=2;impatient.emit("Cliente: tá corrido hoje, hein? Confere meu pedido quando puder.")
	wait-=delta
	if wait>0:return
	match state:
		State.ENTERING:state=State.BROWSING;go_to(Vector3(0,0,-5.2))
		State.BROWSING:visual.rotation.y=PI/2;state=State.SELECTING_PRODUCT;wait=3.5
		State.SELECTING_PRODUCT:product.visible=not empty_handed;state=State.GOING_TO_CHECKOUT;go_to(CheckoutFixture.CUSTOMER_POSITION)
		State.GOING_TO_CHECKOUT:visual.rotation.y=-PI/2;state=State.WAITING;checked_out.emit(self);wait=1.5
		State.WAITING:
			if not purchase_complete or Dialogue.active:wait=.5
			else:
				state=State.PAYING;quiet_pause=identity=="ClienteBone" and int(Session.campaign.night)==1
				wait=6.5 if quiet_pause else 2.0
		State.PAYING:state=State.EXITING;go_to(Vector3(19,0,1.9))
		State.EXITING:departed.emit(self);queue_free()
func snapshot() -> Dictionary:
	var at:=global_position
	return {"position":[at.x,at.y,at.z],"state":int(state),"wait":wait,"warned":warned,"identity":identity,"appearance":appearance,"service_started":service_started,"purchase_complete":purchase_complete,"waited_seconds":waited_seconds,"wait_comment":wait_comment,"quiet_pause":quiet_pause,"entry_chimed":entry_chimed}
func restore(data: Dictionary) -> void:
	global_position=navigation.restore_position(Session.read_position(data.get("position"),global_position))
	state=clampi(int(data.get("state",0)),0,6) as State;wait=maxf(0,float(data.get("wait",0)))
	service_started=bool(data.get("service_started",false));purchase_complete=bool(data.get("purchase_complete",false))
	waited_seconds=maxf(0,float(data.get("waited_seconds",0)));wait_comment=clampi(int(data.get("wait_comment",0)),0,2)
	quiet_pause=bool(data.get("quiet_pause",false));entry_chimed=bool(data.get("entry_chimed",global_position.z<0 or state!=State.ENTERING))
	waypoints.clear();product.visible=state>=State.GOING_TO_CHECKOUT and not purchase_complete and not empty_handed;bag.visible=purchase_complete
	match state:
		State.ENTERING:go_to(Vector3(0,0,-1.5))
		State.BROWSING:go_to(Vector3(0,0,-5.2))
		State.GOING_TO_CHECKOUT:go_to(CheckoutFixture.CUSTOMER_POSITION)
		State.WAITING,State.PAYING:visual.rotation.y=-PI/2
		State.EXITING:go_to(Vector3(19,0,1.9))
	reset_physics_interpolation()
