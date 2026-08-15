extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wake_up_bar: ProgressBar = $UI/Control/WakeUpBar

const XP_ORB_SCENE_PATH := "res://scenes/xp_orb.tscn"

func _ready() -> void:
	if player:
		# Connect the signal from player.gd
		player.wake_up_changed.connect(_on_player_wake_up_changed)
		player.player_woke_up.connect(_on_player_woke_up)
		
		# Initialize UI values
		wake_up_bar.max_value = player.max_wake_up
		wake_up_bar.value = player.current_wake_up

	for enemy_node: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is Enemy:
			var enemy := enemy_node as Enemy
			if not enemy.died.is_connected(_on_enemy_died):
				enemy.died.connect(_on_enemy_died)

func _on_player_wake_up_changed(current_value: float, max_value: float) -> void:
	wake_up_bar.max_value = max_value
	
	# Smooth bar transition using a tween
	var tween = create_tween()
	tween.tween_property(wake_up_bar, "value", current_value, 0.15)

func _on_player_woke_up() -> void:
	wake_up_bar.value = wake_up_bar.max_value

func _on_enemy_died(enemy: Enemy) -> void:
	var xp_orb_scene: PackedScene = load(XP_ORB_SCENE_PATH)
	if xp_orb_scene == null:
		return

	var xp_orb = xp_orb_scene.instantiate()
	if xp_orb == null:
		return

	xp_orb.global_position = enemy.global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	xp_orb.xp_amount = max(1, enemy.xp_value)
	add_child(xp_orb)
