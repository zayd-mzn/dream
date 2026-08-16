class_name HealOnKillModifier
extends RefCounted

var id: String = "heal_on_kill"
var title: String = "نهم الدم"
var description: String = "اشفي 3 نقاط صحة عند كل قتل"

func apply(player: Node) -> void:
	if player.has_method("apply_heal_on_kill"):
		player.apply_heal_on_kill(3.0)
