class_name NightAtmosphere
extends Node
## Local light hierarchy; quality changes and cosmetic motion respect pause.
var environment: Environment
var moon: DirectionalLight3D
var time:=0.0
var unstable: SpotLight3D
var shadow_lights: Array[Light3D]=[]
var detail_lights: Array[Light3D]=[]
static func configure(env: Environment) -> void:
	env.background_mode=Environment.BG_SKY
	var panorama:=PanoramaSkyMaterial.new();panorama.panorama=load("res://assets/textures/mood/night_sky.png")
	var sky:=Sky.new();sky.radiance_size=Sky.RADIANCE_SIZE_32;sky.sky_material=panorama;env.sky=sky
	env.background_color=Color("1b2329")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("a0adbf");env.ambient_light_energy=.080
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.fog_enabled=true;env.fog_mode=Environment.FOG_MODE_DEPTH
	env.fog_light_color=Color("1b2329");env.fog_light_energy=1.0
	env.fog_depth_begin=18;env.fog_depth_end=76;env.fog_depth_curve=1.55
	env.fog_sky_affect=.25;env.fog_sun_scatter=0
func _ready() -> void:
	for light in get_parent().find_children("*","Light3D",true,false):
		if light.get_meta("mood_shadow",false):shadow_lights.append(light)
		if light.get_meta("detail_light",false):detail_lights.append(light)
		if light.get_meta("unstable_lamp",false):unstable=light
	Preferences.changed.connect(apply_quality);apply_quality()
func apply_quality() -> void:
	for light in shadow_lights:light.shadow_enabled=Preferences.pixel_scale<3
	for light in detail_lights:light.visible=Preferences.pixel_scale<3 and light.get_meta("circuit_on",true)
	for probe in get_tree().get_nodes_in_group("detail_reflections"):probe.visible=Preferences.pixel_scale<3 and probe.get_meta("circuit_on",true)
func _process(delta: float) -> void:
	time+=delta
	if unstable!=null:
		var phase:=fposmod(time+8.0,37.0)
		var dip:=.40 if phase>36.4 and phase<36.58 or phase>36.73 and phase<36.81 else 1.0
		unstable.light_energy=float(unstable.get_meta("normal_energy",4.8))*dip
	# The shop stays readable after the warning; only the distant air grows heavier.
	var tension:=1.0 if Session.warning_delivered else 0.0
	environment.fog_depth_end=lerpf(environment.fog_depth_end,76.0-tension*6.0,1-exp(-delta*.16))
