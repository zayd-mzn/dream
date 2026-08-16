class_name CritChanceModifier
extends RefCounted

var id: String = "crit_chance"
var title: String = "Lucky Break"
var description: String = "+8% crit chance"

func apply(player: Node) -> void:
	if player.has_method("apply_crit_chance"):
		player.apply_crit_chance(0.08)
