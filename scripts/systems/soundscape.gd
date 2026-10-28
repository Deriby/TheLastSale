class_name Soundscape
extends Node3D
var hum: AudioStreamPlayer3D
var radio: AudioStreamPlayer3D
var night: AudioStreamPlayer3D
var effect: AudioStreamPlayer3D
func _ready() -> void:
	hum=loop_sound("hum",Vector3(-4,1,-6),-17,14)
	radio=loop_sound("radio",Vector3(4,1.3,-3.7),-9,12)
	night=loop_sound("night",Vector3(0,1,7),-15,30)
	effect=AudioStreamPlayer3D.new();add_child(effect);effect.max_distance=20
	Preferences.changed.connect(refresh)
	refresh()
func loop_sound(id: String,at: Vector3,db: float,distance_value: float) -> AudioStreamPlayer3D:
	var p:=AudioStreamPlayer3D.new();add_child(p);p.position=at;p.max_distance=distance_value;p.volume_db=db
	var stream: AudioStreamWAV=load("res://assets/audio/"+id+".wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=stream.data.size()/2
	p.stream=stream;p.play();return p
func refresh() -> void:
	radio.volume_db=-9+linear_to_db(maxf(Preferences.music_volume,.001))
	hum.volume_db=-17+linear_to_db(maxf(Preferences.effects_volume,.001))
	night.volume_db=-15+linear_to_db(maxf(Preferences.effects_volume,.001))
func play_at(id: String,at: Vector3) -> void:
	effect.global_position=at;effect.stream=load("res://assets/audio/"+id+".wav");effect.volume_db=linear_to_db(maxf(Preferences.effects_volume,.001))-5;effect.play()
func unease() -> void:
	create_tween().tween_property(radio,"volume_db",-50.0,4)
func stop_all() -> void:
	for player in [hum,radio,night,effect]:
		if is_instance_valid(player):
			player.stop()
			player.stream=null
func _exit_tree() -> void:stop_all()
