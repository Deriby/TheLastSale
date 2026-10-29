extends Node
signal changed
var sensitivity := 0.0024
var fov := 68.0
var volume := 0.7
var effects_volume := 0.8
var music_volume := 0.35
var pixel_scale := 1
var ps1_mode := false
var grain := 0.018
var vhs := 0.0
var camera_distance := 2.2
var fullscreen := false
var frame_limit := 30
func _ready() -> void:
	var c := ConfigFile.new()
	if c.load("user://settings.cfg") == OK:
		for key in ["sensitivity","fov","volume","effects_volume","music_volume","pixel_scale","ps1_mode","grain","vhs","camera_distance","fullscreen","frame_limit"]:
			set(key,c.get_value("settings",key,get(key)))
	apply()
func apply() -> void:
	Engine.max_fps=frame_limit
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.001)))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()
func save() -> void:
	var c := ConfigFile.new()
	for key in ["sensitivity","fov","volume","effects_volume","music_volume","pixel_scale","ps1_mode","grain","vhs","camera_distance","fullscreen","frame_limit"]: c.set_value("settings",key,get(key))
	c.save("user://settings.cfg")
	apply()
