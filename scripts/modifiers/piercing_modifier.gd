class_name PiercingModifier
extends RefCounted

var id: String = "piercing"
var title: String = "صندل الاختراق"
var description: String = "تخترق الصندل عدوا واحدا وتكمل مسارها"

func apply(player: Node) -> void:
	if player.has_method("apply_piercing"):
		player.apply_piercing()
