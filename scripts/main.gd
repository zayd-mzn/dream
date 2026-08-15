extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = get_node_or_null("UI/Control/XpBar")
@onready var clock_label: Label = get_node_or_null("UI/Control/ClockLabel")

var elapsed_time: float = 0.0
var spawn_interval: float = 2.5
var spawn_timer: Timer
var enemy_scenes: Array[PackedScene] = [
  preload("res://scenes/enemies/cockroach_normal.tscn"),
  preload("res://scenes/enemies/cockroach_fast.tscn"),
  preload("res://scenes/enemies/cockroach_big.tscn")
]

func _ready() -> void:
  _setup_spawn_timer()

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

  if clock_label:
    clock_label.text = "00:00"

func _process(delta: float) -> void:
  elapsed_time += delta
  if clock_label:
    clock_label.text = _format_time(elapsed_time)

  var difficulty_scale: float = min(0.9, elapsed_time * 0.03)
  var next_spawn_delay: float = max(0.5, spawn_interval - difficulty_scale)
  if spawn_timer and not is_equal_approx(spawn_timer.wait_time, next_spawn_delay):
    spawn_timer.wait_time = next_spawn_delay

func _setup_spawn_timer() -> void:
  spawn_timer = Timer.new()
  spawn_timer.name = "EnemySpawnTimer"
  spawn_timer.wait_time = spawn_interval
  spawn_timer.autostart = true
  spawn_timer.timeout.connect(_on_spawn_timer_timeout)
  add_child(spawn_timer)
  spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
  _spawn_enemy()
  spawn_timer.start()

func _spawn_enemy() -> void:
  if not player:
    return

  var enemy_scene: PackedScene = _choose_enemy_scene()
  var enemy = enemy_scene.instantiate()
  if enemy is CharacterBody2D:
    enemy.target = player
    enemy.global_position = _get_spawn_position()
    get_tree().current_scene.add_child(enemy)

func _choose_enemy_scene() -> PackedScene:
  var time_based_roll: float = elapsed_time
  if time_based_roll >= 45.0:
    return enemy_scenes.pick_random()
  if time_based_roll >= 25.0:
    return enemy_scenes[randi_range(1, enemy_scenes.size() - 1)]
  if time_based_roll >= 12.0:
    return enemy_scenes[randi_range(0, 1)]
  return enemy_scenes[0]

func _get_spawn_position() -> Vector2:
  var view_size: Vector2 = get_viewport().get_visible_rect().size
  var player_pos: Vector2 = player.global_position
  var margin: float = 100.0
  var side: int = randi() % 4
  var spawn_pos: Vector2 = player_pos

  match side:
    0:
      spawn_pos.x = player_pos.x - view_size.x * 0.7 - margin
      spawn_pos.y = randf_range(player_pos.y - view_size.y * 0.7, player_pos.y + view_size.y * 0.7)
    1:
      spawn_pos.x = player_pos.x + view_size.x * 0.7 + margin
      spawn_pos.y = randf_range(player_pos.y - view_size.y * 0.7, player_pos.y + view_size.y * 0.7)
    2:
      spawn_pos.x = randf_range(player_pos.x - view_size.x * 0.7, player_pos.x + view_size.x * 0.7)
      spawn_pos.y = player_pos.y - view_size.y * 0.7 - margin
    3:
      spawn_pos.x = randf_range(player_pos.x - view_size.x * 0.7, player_pos.x + view_size.x * 0.7)
      spawn_pos.y = player_pos.y + view_size.y * 0.7 + margin

  return spawn_pos

func _format_time(total_seconds: float) -> String:
  var total_int: int = int(total_seconds)
  var minutes: int = int(total_int / 60.0)
  var seconds: int = total_int % 60
  return "%02d:%02d" % [minutes, seconds]

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
