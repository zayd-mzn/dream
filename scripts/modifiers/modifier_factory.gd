class_name ModifierFactory
extends RefCounted

static func _load_modifier(script_path: String) -> RefCounted:
	var script = load(script_path)
	return script.new()

static func get_random_modifiers(count: int = 3) -> Array:
	var all_modifiers: Array = [
		_load_modifier("res://scripts/modifiers/speed_modifier.gd"),
		_load_modifier("res://scripts/modifiers/max_health_modifier.gd"),
		_load_modifier("res://scripts/modifiers/damage_modifier.gd"),
	]
	all_modifiers.shuffle()

	var chosen: Array = []
	for i in range(min(count, all_modifiers.size())):
		chosen.append(all_modifiers[i])
	return chosen
