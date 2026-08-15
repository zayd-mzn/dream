extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = get_node_or_null("UI/Control/XpBar")

func _ready() -> void:
  if player:
    if player.has_signal("wake_up_changed"):
      player.wake_up_changed.connect(_on_player_wake_up_changed)
    if player.has_signal("player_woke_up"):
      player.player_woke_up.connect(_on_player_woke_up)
    if player.has_signal("player_died"):
      player.player_died.connect(_on_player_died)
    
    if xp_bar:
      xp_bar.max_value = player.max_wake_up
      xp_bar.value = player.current_wake_up

func _on_player_wake_up_changed(current_value: float, max_value: float) -> void:
  if not xp_bar:
    return
  xp_bar.max_value = max_value
  
  var tween = create_tween()
  tween.tween_property(xp_bar, "value", current_value, 0.15)

func _on_player_woke_up() -> void:
  if xp_bar:
    xp_bar.value = xp_bar.max_value

func _on_player_died() -> void:
  print("Game Over: Player Died!")
