class_name Customer
extends CharacterBody3D
signal checked_out(customer: Customer)
signal departed(customer: Customer)
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
func _ready() -> void:
	add_to_group("customers")
	collision_layer=2;collision_mask=1|2
	var col:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7;col.shape=shape;col.position.y=.85;add_child(col)
	var cast: Array[String]=["Garota1","Garota2","Velha1"]
	identity="Customer3" if warned else cast[posmod(appearance,cast.size())]
	visual=CharacterModels.create(identity);add_child(visual)
	animation=visual.find_child("AnimationPlayer",true,false)
	if not warned:
		motion=LivingMotion.new();add_child(motion);motion.setup(visual,self)
	if animation:
		for key in animation.get_animation_list():
			if key.contains("idle") or key.contains("walk") or key.contains("carry"):animation.get_animation(key).loop_mode=Animation.LOOP_LINEAR
	product=Geo.cylinder(visual,Vector3(.23,.95,.3),.06,.28,Geo.material(Color("8c9a65")));product.visible=false
	if motion:motion.pose_updated.connect(sync_product)
	go_to(Vector3(0,0,-1.5))
func sync_product() -> void:
	if not product.visible:return
	var sk:=motion.skeleton
	var hand:=sk.get_bone_global_pose(sk.find_bone("hand_R"))
	product.global_transform=Transform3D(Basis.IDENTITY,sk.global_transform*hand.origin+visual.global_basis.z*.05)
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
	if not waypoints.is_empty():
		var diff:=waypoints[0]-global_position;diff.y=0
		if diff.length()<.14:waypoints.remove_at(0)
		else:
			var dir:=diff.normalized();velocity.x=dir.x*1.15;velocity.z=dir.z*1.15;velocity.y=-2
			var before:=global_position;move_and_slide()
			visual.rotation.y=lerp_angle(visual.rotation.y,atan2(dir.x,dir.z),delta*9)
			if motion:motion.locomotion(delta,Vector2(velocity.x,velocity.z).length(),false,false,false)
			else:play("walk")
			blocked_time=blocked_time+delta if before.distance_to(global_position)<.003 else 0
			if blocked_time>2.5:go_to(destination);blocked_time=0
		return
	velocity=Vector3.ZERO
	if motion:
		if state==State.SELECTING_PRODUCT:motion.play("browse",.3)
		elif state==State.PAYING:motion.play("pay",.3)
		elif product.visible:motion.play("hold_bottle",.3)
		else:motion.locomotion(delta,0,false,false,false)
		var player:=get_tree().get_first_node_in_group("player") as Node3D
		if player!=null:motion.look_at_position(player.global_position+Vector3.UP*1.6,state in [State.WAITING,State.PAYING])
	else:play("carry" if product.visible else "idle")
	wait-=delta
	if wait>0:return
	match state:
		State.ENTERING:state=State.BROWSING;go_to(Vector3(0,0,-5.2))
		State.BROWSING:visual.rotation.y=PI/2;state=State.SELECTING_PRODUCT;wait=3.5
		State.SELECTING_PRODUCT:product.visible=true;state=State.GOING_TO_CHECKOUT;go_to(CheckoutFixture.CUSTOMER_POSITION)
		State.GOING_TO_CHECKOUT:visual.rotation.y=-PI/2;state=State.WAITING;checked_out.emit(self);wait=1.5
		State.WAITING:
			if warned and Dialogue.active:wait=.5
			else:state=State.PAYING;wait=2.0
		State.PAYING:state=State.EXITING;go_to(Vector3(19,0,1.9));Session.serve_customer()
		State.EXITING:departed.emit(self);queue_free()
