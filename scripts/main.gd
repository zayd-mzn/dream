extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wake_up_bar: ProgressBar = $UI/Control/WakeUpBar

func _ready() -> void:
	if player:
		# Connect the signal from player.gd
		player.wake_up_changed.connect(_on_player_wake_up_changed)
		player.player_woke_up.connect(_on_player_woke_up)
		
		# Initialize UI values
		wake_up_bar.max_value = player.max_wake_up
		wake_up_bar.value = player.current_wake_up

func _on_player_wake_up_changed(current_value: float, max_value: float) -> void:
	wake_up_bar.max_value = max_value
	
	# Smooth bar transition using a tween
	var tween = create_tween()
	tween.tween_property(wake_up_bar, "value", current_value, 0.15)

func _on_player_woke_up() -> void:
	wake_up_bar.value = wake_up_bar.max_value
