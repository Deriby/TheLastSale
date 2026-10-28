class_name FoliageWind
extends Node
var materials: Array[ShaderMaterial]=[]
var time:=0.0
func _process(delta: float) -> void:
	time+=delta
	for material in materials:material.set_shader_parameter("wind_time",time)
