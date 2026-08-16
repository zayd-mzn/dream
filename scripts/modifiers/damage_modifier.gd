class_name DamageModifier
extends RefCounted

var id: String = "damage"
var title: String = "ضربات قوية"
var description: String = "+20% ضرر"

func apply(player: Node) -> void:
	if player.has_method("apply_damage_modifier"):
		player.apply_damage_modifier(1.2)
	elif "damage_bonus" in player:
		player.damage_bonus *= 1.2
