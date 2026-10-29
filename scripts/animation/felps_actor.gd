class_name FelpsActor
extends DepotPlayer
## The cashier is the same physical actor before and after taking control.
var model: Node3D:
	get:return visual
func _init() -> void:
	identity="Felps";controlled=false
