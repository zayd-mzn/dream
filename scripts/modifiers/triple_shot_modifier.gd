class_name TripleShotModifier
extends RefCounted

var id: String = "triple_shot"
var title: String = "Triple Threat"
var description: String = "Fire 3 sandals at once"

func apply(player: Node) -> void:
	if player.has_method("apply_triple_shot"):
		player.apply_triple_shot()
