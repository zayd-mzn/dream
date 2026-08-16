class_name HealOnKillModifier
extends RefCounted

var id: String = "heal_on_kill"
var title: String = "Bloodthirst"
var description: String = "Heal 3 HP on each kill"

func apply(player: Node) -> void:
	if player.has_method("apply_heal_on_kill"):
		player.apply_heal_on_kill(3.0)
