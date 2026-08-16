class_name ModifierFactory
extends RefCounted

static var last_chosen_ids: Array[String] = []
static var acquired_ids: Array[String] = []

# IDs that can only be picked once ever
static var one_time_ids: Array[String] = ["triple_shot", "piercing", "heal_on_kill"]

static func _load_modifier(script_path: String) -> RefCounted:
	var script = load(script_path)
	return script.new()

static func get_random_modifiers(count: int = 3, elapsed_time: float = 0.0) -> Array:
	var all_modifiers: Array = [
		_load_modifier("res://scripts/modifiers/speed_modifier.gd"),
		_load_modifier("res://scripts/modifiers/max_health_modifier.gd"),
		_load_modifier("res://scripts/modifiers/damage_modifier.gd"),
		_load_modifier("res://scripts/modifiers/cooldown_reduction_modifier.gd"),
		_load_modifier("res://scripts/modifiers/crit_chance_modifier.gd"),
		_load_modifier("res://scripts/modifiers/heal_on_kill_modifier.gd"),
		_load_modifier("res://scripts/modifiers/piercing_modifier.gd"),
	]

	# Unlock triple shot after 60 seconds
	if elapsed_time >= 60.0:
		all_modifiers.append(_load_modifier("res://scripts/modifiers/triple_shot_modifier.gd"))

	# Remove one-time upgrades already acquired
	all_modifiers = all_modifiers.filter(func(m): return not acquired_ids.has(m.id))

	# Filter out modifiers chosen last time
	var available: Array = all_modifiers.filter(func(m): return not last_chosen_ids.has(m.id))

	# If filtering leaves too few, fall back to full (minus already acquired)
	if available.size() < count:
		available = all_modifiers

	available.shuffle()

	var chosen: Array = []
	var chosen_ids: Array[String] = []
	for i in range(min(count, available.size())):
		chosen.append(available[i])
		chosen_ids.append(available[i].id)

	last_chosen_ids = chosen_ids
	return chosen

static func on_modifier_acquired(id: String) -> void:
	if one_time_ids.has(id) and not acquired_ids.has(id):
		acquired_ids.append(id)
