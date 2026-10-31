class_name TitleAmbience
extends Node
## Temporary title staging. No circuit flags, materials, transforms or collisions
## change; existing light energies and the ABERTO quad are restored before play.
var active := false
var elapsed := 0.0
var blink_at := 3.2
var stock_at := 9.0
var next_car := 5.5
var next_dog := 10.5
var next_metal := 13.0
var lights: Array[Dictionary] = []
var sign: MeshInstance3D
var sign_visible := true
var hum: AudioStreamPlayer
var car: AudioStreamPlayer
var dog: AudioStreamPlayer
var metal: AudioStreamPlayer
var effects := 1.0
var gain := 1.0
var blink := 1.0
var randomizer := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	randomizer.randomize()
	hum=sound("neon_hum",-23,true);car=sound("street_car",-13);dog=sound("distant_dog",-18);metal=sound("metal_creak",-16)

func sound(id: String,level: float,loop := false) -> AudioStreamPlayer:
	var player:=AudioStreamPlayer.new();add_child(player)
	player.stream=load("res://assets/audio/title/ambient/"+id+".ogg")
	if loop:
		var stream: AudioStreamOggVorbis=player.stream.duplicate();stream.loop=true;player.stream=stream
	player.set_meta("title_level",level);return player

func bind(world: ShiftWorld) -> void:
	restore()
	var facade:=world.depot.get_node("Architecture/Facade")
	var neon:=facade.get_node("NeonFinish")
	for light in facade.find_children("*","Light3D",true,false):
		if light.name in ["NeonRedSpill","NeonWallWash"] or light.get_parent()==facade and light.position.y>5.8:
			lights.append({"node":light,"energy":light.light_energy,"role":"sign"})
	var stock:=world.depot.find_child("StockLight",true,false) as Light3D
	if stock!=null:lights.append({"node":stock,"energy":stock.light_energy,"role":"stock"})
	# Shelving hides the stock-room bulb from the exterior camera. The existing
	# rear aisle pool makes that slow reveal visible through the storefront too.
	for light in world.depot.get_node("Architecture").get_children():
		if light is SpotLight3D and str(light.name).begins_with("CeilingPool") and light.position.x>0 and absf(light.position.z+5.7)<.1:
			lights.append({"node":light,"energy":light.light_energy,"role":"stock"})
	# This is the existing illuminated lettering quad, in front of its dark backing.
	for child in neon.get_children():
		if child is MeshInstance3D and child.mesh is QuadMesh and child.position.distance_to(Vector3(-3.1,2.48,-.18))<.03:
			sign=child;sign_visible=child.visible;break

func start() -> void:
	active=true;elapsed=0;blink_at=3.2;stock_at=9;next_car=5.5;next_dog=10.5;next_metal=13;blink=1
	hum.play();update(0)

func apply_audio(volume: float,mix_gain := 1.0) -> void:
	effects=volume;gain=mix_gain
	for player in [hum,car,dog,metal]:
		if player==null:continue
		var level: float=player.get_meta("title_level")
		var flicker:=.55+.45*blink if player==hum else 1.0
		player.volume_db=-80 if effects<=0 or gain<=0 else level+linear_to_db(maxf(.0001,effects*gain*flicker))

func update(delta: float) -> void:
	if not active:return
	elapsed+=maxf(0,delta)
	var age:=elapsed-blink_at
	blink=.25 if age>=0 and age<.13 or age>=.32 and age<.52 else 1.0
	if age>=.7:blink_at=elapsed+randomizer.randf_range(16,29)
	var stock_age:=elapsed-stock_at
	var stock_level:=.18
	if stock_age>=0 and stock_age<4:
		stock_level+=.82*smoothstep(0,.8,stock_age)*(1.0-smoothstep(2.5,4,stock_age))
	elif stock_age>=4:stock_at=elapsed+randomizer.randf_range(25,39)
	for entry in lights:
		if is_instance_valid(entry.node):entry.node.light_energy=entry.energy*(blink if entry.role=="sign" else stock_level)
	if is_instance_valid(sign):sign.visible=sign_visible and blink>.5
	if elapsed>=next_car:
		car.play();next_car=elapsed+randomizer.randf_range(26,42)
	if elapsed>=next_dog:
		dog.pitch_scale=randomizer.randf_range(.96,1.04);dog.play();next_dog=elapsed+randomizer.randf_range(31,48)
	if elapsed>=next_metal:
		metal.play();next_metal=elapsed+randomizer.randf_range(35,54)
	apply_audio(effects,gain)

func restore() -> void:
	active=false
	for entry in lights:
		if is_instance_valid(entry.node):entry.node.light_energy=entry.energy
	lights.clear()
	if is_instance_valid(sign):sign.visible=sign_visible
	sign=null
	for player in [hum,car,dog,metal]:
		if is_instance_valid(player):player.stop()

func _exit_tree() -> void:restore()
