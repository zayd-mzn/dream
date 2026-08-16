class_name TripleShotModifier
extends RefCounted

var id: String = "triple_shot"
var title: String = "ثلاثي التهديد"
var description: String = "اطلق 3 صنادل دفعة واحدة"

func apply(player: Node) -> void:
	if player.has_method("apply_triple_shot"):
		player.apply_triple_shot()
