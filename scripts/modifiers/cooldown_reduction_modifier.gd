class_name CooldownReductionModifier
extends RefCounted

var id: String = "cooldown_reduction"
var title: String = "رمي سريع"
var description: String = ""

func _init() -> void:
	var current_cooldown: float = 0.2
	var reduced: float = max(0.05, current_cooldown - 0.01)
	var percent: int = int((1.0 - reduced / current_cooldown) * 100.0)
	description = "-" + str(percent) + "% وقت إعادة الرمي"

func apply(player: Node) -> void:
	if player.has_method("apply_cooldown_modifier"):
		player.apply_cooldown_modifier(-0.01)
