extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wake_up_bar: ProgressBar = get_node_or_null("UI/Control/WakeUpBar")

func _ready() -> void:
  if player:
    if player.has_signal("wake_up_changed"):
      player.wake_up_changed.connect(_on_player_wake_up_changed)
    if player.has_signal("player_woke_up"):
      player.player_woke_up.connect(_on_player_woke_up)
    if player.has_signal("player_died"):
      player.player_died.connect(_on_player_died)
    
    if wake_up_bar:
      wake_up_bar.max_value = player.max_wake_up
      wake_up_bar.value = player.current_wake_up

func _on_player_wake_up_changed(current_value: float, max_value: float) -> void:
  if not wake_up_bar:
    return
  wake_up_bar.max_value = max_value
  
  # Smooth bar transition using a tween
  var tween = create_tween()
  tween.tween_property(wake_up_bar, "value", current_value, 0.15)

func _on_player_woke_up() -> void:
  if wake_up_bar:
    wake_up_bar.value = wake_up_bar.max_value

func _on_player_died() -> void:
  print("Game Over: Player Died!")
