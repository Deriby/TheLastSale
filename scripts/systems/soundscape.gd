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
var compressors: Array[AudioStreamPlayer3D]=[]
var engine: AudioStreamPlayer3D
var voices: Array[AudioStreamPlayer3D]=[]
var voice_index:=0
var unease_amount:=0.0
var loop_players: Array[AudioStreamPlayer3D]=[]
func set_store_power(value: bool,radio_on := true) -> void:
	store_powered=value;radio_powered=value and radio_on
	if hum!=null:
		if store_powered and not hum.playing:hum.play()
		elif not store_powered:hum.stop()
	if radio!=null:
		if radio_powered and not radio.playing:radio.play()
		elif not radio_powered:radio.stop()
	for player in compressors:
		if store_powered and not player.playing:player.play()
		elif not store_powered:player.stop()
	refresh()
func _ready() -> void:
	hum=loop_sound("hum",Vector3(-4,1,-6),-17,14)
	radio=loop_sound("radio",Vector3(-5.4,1.7,-2.7),-19,22);radio.unit_size=2.5
	night=loop_sound("neighborhood_air",Vector3(0,1,7),-11,38)
	ballast=loop_sound("pole_ballast",Vector3(-7.25,6.8,3.4),-18,13)
	effect=AudioStreamPlayer3D.new();add_child(effect);effect.max_distance=20
	ambience=AudioStreamPlayer3D.new();add_child(ambience);ambience.max_distance=48
	for at in [Vector3(-5.25,.8,-5.6),Vector3(-.5,.9,-10.3),Vector3(5.15,.8,-6.5)]:
		var player:=spatial_loop("res://assets/audio/everyday/compressor.ogg",at,7.5)
		player.unit_size=2.5;player.pitch_scale=[.93,1.0,1.06][compressors.size()];compressors.append(player)
	engine=spatial_loop("res://assets/audio/everyday/car_idle.ogg",Vector3(3,.8,9.55),28);engine.unit_size=4;engine.stop()
	voices.append(effect)
	for index in 3:
		var player:=AudioStreamPlayer3D.new();add_child(player);player.max_distance=22;voices.append(player)
	unease_amount=1.0 if Session.warning_delivered else 0.0
	Preferences.changed.connect(refresh)
	refresh()
func spatial_loop(path: String,at: Vector3,reach: float) -> AudioStreamPlayer3D:
	var player:=AudioStreamPlayer3D.new();add_child(player);player.position=at;player.max_distance=reach
	var stream: AudioStreamOggVorbis=load(path).duplicate();stream.loop=true;player.stream=stream;player.play();return player
func set_engine_active(value: bool) -> void:
	if value and not engine.playing:engine.play()
	elif not value:engine.stop()
func play_spatial(path: String,at: Vector3,db: float=-12.0,muffled:=false) -> void:
	var player:=voices[voice_index%voices.size()];voice_index+=1
	player.global_position=at;player.stream=load(path);player.set_meta("base_db",db)
	player.volume_db=db+linear_to_db(maxf(Preferences.effects_volume,.001))
	player.attenuation_filter_cutoff_hz=1800 if muffled else 10000;player.play()
func loop_sound(id: String,at: Vector3,db: float,distance_value: float) -> AudioStreamPlayer3D:
	var p:=AudioStreamPlayer3D.new();add_child(p);p.position=at;p.max_distance=distance_value;p.volume_db=db
	p.set_meta("loop_base_db",db);p.set_meta("music_loop",id=="radio");loop_players.append(p)
	p.volume_db=db+linear_to_db(maxf(.001,Preferences.music_volume if id=="radio" else Preferences.effects_volume))
	var stream: AudioStreamWAV=load("res://assets/audio/"+id+".wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=stream.data.size()/2
	p.stream=stream;p.play();return p
func refresh() -> void:
	for player in loop_players:player.volume_db=float(player.get_meta("loop_base_db"))+linear_to_db(maxf(.001,Preferences.music_volume if player.get_meta("music_loop",false) else Preferences.effects_volume))
	radio.volume_db=-19-unease_amount*15+linear_to_db(maxf(Preferences.music_volume,.001))
	hum.volume_db=-17+linear_to_db(maxf(Preferences.effects_volume,.001))
	night.volume_db=-15+linear_to_db(maxf(Preferences.effects_volume,.001))
	ballast.volume_db=-18+linear_to_db(maxf(Preferences.effects_volume,.001))
	for player in compressors:player.volume_db=-25+linear_to_db(maxf(Preferences.effects_volume,.001))
	if engine!=null:engine.volume_db=-19+linear_to_db(maxf(Preferences.effects_volume,.001))
	for player in voices:player.volume_db=float(player.get_meta("base_db",-5))+linear_to_db(maxf(Preferences.effects_volume,.001))
func _process(delta: float) -> void:
	var player:=get_tree().get_first_node_in_group("player") as Node3D
	if player!=null:
		var inside:=smoothstep(-.5,3.0,player.global_position.z)
		night.volume_db=-21+inside*10+linear_to_db(maxf(Preferences.effects_volume,.001))
		night.attenuation_filter_cutoff_hz=lerpf(1800,7500,inside)
		var stock:=1.0-smoothstep(-12.5,-10.8,player.global_position.z)
		radio.volume_db=-19-unease_amount*15-stock*6+linear_to_db(maxf(Preferences.music_volume,.001))
		radio.attenuation_filter_cutoff_hz=lerpf(8500,1600,stock)
	ambient_wait-=delta
	if ambient_wait>0:return
	ambient_index+=1;ambient_wait=[38.0,55.0,47.0,66.0][ambient_index%4]
	var paths: Array[String]=["res://assets/audio/distant_traffic.wav","res://assets/audio/title/ambient/distant_dog.ogg","res://assets/audio/store_settle.wav","res://assets/audio/title/ambient/metal_creak.ogg"]
	ambience.position=[Vector3(-25,1,7),Vector3(24,1,14),Vector3(-2,1,-14),Vector3(15,1,11)][ambient_index%4]
	ambience.stream=load(paths[ambient_index%4]);ambience.volume_db=(-15 if ambient_index%4<2 else -24)+linear_to_db(maxf(Preferences.effects_volume,.001));ambience.play()
func play_at(id: String,at: Vector3) -> void:
	play_spatial("res://assets/audio/"+id+".wav",at,-5)
func unease() -> void:
	create_tween().tween_property(self,"unease_amount",1.0,4)
func stop_all() -> void:
	for player in [hum,radio,night,effect,ambience,ballast,engine]+compressors+voices+loop_players:
		if is_instance_valid(player):
			player.stop()
			player.stream=null
func _exit_tree() -> void:stop_all()
