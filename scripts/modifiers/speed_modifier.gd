class_name SpeedModifier
extends RefCounted

var id: String = "speed"
var title: String = "Swift Steps"
var description: String = "+15% move speed"

func apply(player: Node) -> void:
	if player.has_method("apply_speed_modifier"):
		player.apply_speed_modifier(1.15)
	elif "speed" in player:
		player.speed *= 1.15
