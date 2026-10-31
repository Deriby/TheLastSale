class_name TitleSavePreview
extends RefCounted
## Read-only metadata: do not load a shift just to label its menu button.
static func read(path := "user://shift.json") -> Dictionary:
	var unavailable:={"valid":false,"label":"CONTINUAR TURNO SALVO"}
	if not FileAccess.file_exists(path):return unavailable
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return unavailable
	var data: Variant=parser.data
	if not data is Dictionary:return unavailable
	var version: Variant=data.get("version",0)
	if not (version is int or version is float) or not is_finite(float(version)) or int(version) not in [1,2,3,4,5]:return unavailable
	var position: Variant=data.get("position")
	if not position is Array or position.size()!=3:return unavailable
	for value in position:
		if not (value is int or value is float) or not is_finite(float(value)):return unavailable
	var campaign: Dictionary=data.get("campaign",{}) if int(version)>=4 and data.get("campaign") is Dictionary else {}
	var night_value: Variant=campaign.get("night",0)
	var night:=clampi(int(night_value),0,2) if int(version)>=4 and (night_value is int or night_value is float) and is_finite(float(night_value)) else 0
	var seconds_value: Variant=data.get("seconds",0)
	var seconds:=clampf(float(seconds_value),0,86400) if (seconds_value is int or seconds_value is float) and is_finite(float(seconds_value)) else 0.0
	var stage_value: Variant=data.get("stage",0)
	var stage:=clampi(int(stage_value),0,7) if (stage_value is int or stage_value is float) and is_finite(float(stage_value)) else 0
	var minutes:=21*60+40+int(seconds/8)
	if night==0 and stage>=5:minutes=maxi(minutes,22*60+35)
	if str(campaign.get("phase","")) in ["restored","closing","complete"]:minutes=maxi(minutes,23*60+40)
	minutes=mini(minutes,23*60+59)
	var night_name: String=["SEXTA-FEIRA","SÁBADO","DOMINGO"][night]
	var clock:="%02d:%02d"%[minutes/60,minutes%60]
	return {"valid":true,"night":night,"clock":clock,"label":"CONTINUAR — %s, %s"%[night_name,clock]}
