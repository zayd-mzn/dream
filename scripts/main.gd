extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = $UI/Control/XpBar

func _ready() -> void:
	if player:
		# Connect player death to handle game over
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		
		# If you have an XP signal on the player, connect it here
		if player.has_signal("xp_changed"):
			player.xp_changed.connect(_on_player_xp_changed)

func _on_player_xp_changed(current_xp: float, max_xp: float) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		var tween = create_tween()
		tween.tween_property(xp_bar, "value", current_xp, 0.15)

func _on_player_died() -> void:
	print("Game Over triggered in Main scene!")
	# Add Game Over UI popup / scene reload here
