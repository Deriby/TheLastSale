class_name Soundscape
extends Node3D
var hum: AudioStreamPlayer3D
var radio: AudioStreamPlayer3D
var night: AudioStreamPlayer3D
var effect: AudioStreamPlayer3D
var ambience: AudioStreamPlayer3D
var ballast: AudioStreamPlayer3D
var ambient_wait:=18.0
var ambient_index:=0
var store_powered:=true
var radio_powered:=true
func set_store_power(value: bool,radio_on := true) -> void:
	store_powered=value;radio_powered=value and radio_on
	if hum!=null:
		if store_powered and not hum.playing:hum.play()
		elif not store_powered:hum.stop()
	if radio!=null:
		if radio_powered and not radio.playing:radio.play()
		elif not radio_powered:radio.stop()
	refresh()
func _ready() -> void:
	hum=loop_sound("hum",Vector3(-4,1,-6),-17,14)
	radio=loop_sound("radio",Vector3(-5.4,1.7,-2.7),-13,9)
	night=loop_sound("neighborhood_air",Vector3(0,1,7),-11,38)
	ballast=loop_sound("pole_ballast",Vector3(-7.25,6.8,3.4),-18,13)
	effect=AudioStreamPlayer3D.new();add_child(effect);effect.max_distance=20
	ambience=AudioStreamPlayer3D.new();add_child(ambience);ambience.max_distance=48
	Preferences.changed.connect(refresh)
	refresh()
func loop_sound(id: String,at: Vector3,db: float,distance_value: float) -> AudioStreamPlayer3D:
	var p:=AudioStreamPlayer3D.new();add_child(p);p.position=at;p.max_distance=distance_value;p.volume_db=db
	var stream: AudioStreamWAV=load("res://assets/audio/"+id+".wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=stream.data.size()/2
	p.stream=stream;p.play();return p
func refresh() -> void:
	radio.volume_db=-13+linear_to_db(maxf(Preferences.music_volume,.001))
	hum.volume_db=-17+linear_to_db(maxf(Preferences.effects_volume,.001))
	night.volume_db=-15+linear_to_db(maxf(Preferences.effects_volume,.001))
	ballast.volume_db=-18+linear_to_db(maxf(Preferences.effects_volume,.001))
func _process(delta: float) -> void:
	var player:=get_tree().get_first_node_in_group("player") as Node3D
	if player!=null:
		var inside:=smoothstep(-.5,3.0,player.global_position.z)
		night.volume_db=-21+inside*10+linear_to_db(maxf(Preferences.effects_volume,.001))
		night.attenuation_filter_cutoff_hz=lerpf(1800,7500,inside)
	ambient_wait-=delta
	if ambient_wait>0:return
	ambient_index+=1;ambient_wait=22.0+(ambient_index%3)*7.0
	var traffic:=ambient_index%3!=0
	ambience.position=Vector3(-24 if ambient_index%2 else 25,1,7) if traffic else Vector3(-5,1,-8)
	ambience.stream=load("res://assets/audio/"+("distant_traffic" if traffic else "store_settle")+".wav")
	ambience.volume_db=(-11 if traffic else -22)+linear_to_db(maxf(Preferences.effects_volume,.001));ambience.play()
func play_at(id: String,at: Vector3) -> void:
	effect.global_position=at;effect.stream=load("res://assets/audio/"+id+".wav");effect.volume_db=linear_to_db(maxf(Preferences.effects_volume,.001))-5;effect.play()
func unease() -> void:
	create_tween().tween_property(radio,"volume_db",-50.0,4)
func stop_all() -> void:
	for player in [hum,radio,night,effect,ambience,ballast]:
		if is_instance_valid(player):
			player.stop()
			player.stream=null
func _exit_tree() -> void:stop_all()
