class_name MaxHealthModifier
extends RefCounted

var id: String = "max_health"
var title: String = "Vitality"
var description: String = "+20 max health and heal 20"

func apply(player: Node) -> void:
	if player.has_method("apply_max_health_modifier"):
		player.apply_max_health_modifier(20)
	elif "max_hp" in player:
		player.max_hp += 20.0
		player.current_hp = min(player.max_hp, player.current_hp + 20.0)
		if player.has_method("update_health_ui"):
			player.update_health_ui()
