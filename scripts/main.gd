extends Node2D

const MODIFIER_FACTORY = preload("res://scripts/modifiers/modifier_factory.gd")

@onready var player: CharacterBody2D = $Player
@onready var xp_bar: ProgressBar = get_node_or_null("UI/Control/XpBar")
@onready var clock_label: Label = get_node_or_null("UI/Control/ClockLabel")
@onready var shoot_bar: ProgressBar = get_node_or_null("UI/Control/ShootCooldown")
@onready var shoot_label: Label = get_node_or_null("UI/Control/ShootLabel")
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var elapsed_time: float = 0.0
var spawn_interval: float = 2.1
var spawn_timer: Timer
var shoot_cooldown_duration: float = 0.2
var shoot_cooldown_elapsed: float = 0.5
var enemy_scenes: Array[PackedScene] = [
  preload("res://scenes/enemies/cockroach_normal.tscn"),
  preload("res://scenes/enemies/cockroach_fast.tscn"),
  preload("res://scenes/enemies/cockroach_big.tscn")
]
var rare_enemy_scenes: Array[PackedScene] = [
  preload("res://scenes/enemies/jinn.tscn")
]
var modifier_menu: Control
var modifier_buttons: Array[Button] = []
var game_over_overlay: Control
var restart_button: Button

func _ready() -> void:
  _setup_spawn_timer()
  _build_modifier_menu()
  _build_game_over_overlay()

  if music_player:
    music_player.stream = load("res://assets/uhhhhhhhhh.mp3")
    music_player.finished.connect(_on_music_finished)
    music_player.volume_db = -4.0
    music_player.play()

  if player:
    if player.has_signal("xp_changed"):
      player.xp_changed.connect(_on_player_xp_changed)
    if player.has_signal("wake_up_changed"):
      player.wake_up_changed.connect(_on_player_wake_up_changed)
    if player.has_signal("player_woke_up"):
      player.player_woke_up.connect(_on_player_woke_up)
    if player.has_signal("player_died"):
      player.player_died.connect(_on_player_died)
    if player.has_signal("shot_fired"):
      player.shot_fired.connect(_on_player_shot_fired)

    if xp_bar:
      xp_bar.max_value = player.xp_to_next_level
      xp_bar.value = player.current_xp

  if clock_label:
    clock_label.text = "00:00"

  if shoot_bar:
    shoot_bar.max_value = 1.0
    shoot_bar.value = 1.0
  if shoot_label:
    shoot_label.modulate.a = 1.0

func _build_modifier_menu() -> void:
  if not is_instance_valid(get_node_or_null("UI")):
    return

  modifier_menu = Control.new()
  modifier_menu.name = "ModifierMenu"
  modifier_menu.visible = false
  modifier_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
  modifier_menu.set_anchors_preset(Control.PRESET_FULL_RECT)

  var dim = ColorRect.new()
  dim.color = Color(0.0, 0.0, 0.0, 0.7)
  dim.set_anchors_preset(Control.PRESET_FULL_RECT)
  dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
  modifier_menu.add_child(dim)

  var panel = PanelContainer.new()
  panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
  panel.anchor_left = 0.5
  panel.anchor_top = 0.5
  panel.anchor_right = 0.5
  panel.anchor_bottom = 0.5
  panel.offset_left = -400
  panel.offset_top = -300
  panel.offset_right = 400
  panel.offset_bottom = 450
  panel.custom_minimum_size = Vector2(800, 750)
  modifier_menu.add_child(panel)

  var vbox = VBoxContainer.new()
  vbox.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
  vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
  panel.add_child(vbox)

  var title = Label.new()
  title.text = "Choose a modifier"
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.add_theme_font_size_override("font_size", 64)
  vbox.add_child(title)

  for i in range(3):
    var button = Button.new()
    button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    button.focus_mode = Control.FOCUS_ALL
    button.text = "Modifier"
    button.custom_minimum_size = Vector2(0, 120)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 48)
    var index: int = i
    button.pressed.connect(_on_modifier_pressed.bind(index))
    modifier_buttons.append(button)
    vbox.add_child(button)

  $UI.add_child(modifier_menu)

func request_modifier_menu() -> void:
  var modifiers = MODIFIER_FACTORY.get_random_modifiers(3, elapsed_time)
  open_modifier_menu(modifiers)

func open_modifier_menu(modifiers: Array) -> void:
  if not modifier_menu:
    return

  for i in range(3):
    var button = modifier_buttons[i]
    var modifier = modifiers[i] if i < modifiers.size() else null
    if modifier:
      button.set_meta("modifier", modifier)
      button.text = modifier.title + "\n" + modifier.description
      button.disabled = false
    else:
      button.set_meta("modifier", null)
      button.text = ""
      button.disabled = true

  modifier_menu.visible = true
  get_tree().paused = true

func _on_modifier_pressed(index: int) -> void:
  if index >= modifier_buttons.size():
    return

  var button = modifier_buttons[index]
  var modifier = button.get_meta("modifier", null)
  if modifier and modifier.has_method("apply"):
    modifier.apply(player)
    MODIFIER_FACTORY.on_modifier_acquired(modifier.id)

  modifier_menu.visible = false
  get_tree().paused = false

func _process(delta: float) -> void:
  if get_tree().paused:
    return

  elapsed_time += delta
  if clock_label:
    clock_label.text = _format_time(elapsed_time)

  if shoot_bar:
    shoot_cooldown_elapsed = min(shoot_cooldown_elapsed + delta, shoot_cooldown_duration)
    var fill: float = shoot_cooldown_elapsed / shoot_cooldown_duration
    shoot_bar.value = fill
    if shoot_label:
      shoot_label.modulate.a = fill

  var difficulty_scale: float = min(1.2, elapsed_time * 0.05)
  var next_spawn_delay: float = max(0.65, spawn_interval - difficulty_scale)
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
  if not player or get_tree().paused:
    return

  var enemy_scene: PackedScene = _choose_enemy_scene()
  var enemy = enemy_scene.instantiate()
  if enemy is CharacterBody2D:
    enemy.target = player
    enemy.global_position = _get_spawn_position()
    get_tree().current_scene.add_child(enemy)

func _choose_enemy_scene() -> PackedScene:
  var time_based_roll: float = elapsed_time
  var player_level: int = 1
  if player:
    player_level = int(player.level)

  if player_level >= 3:
    if randf() < 0.14:
      return rare_enemy_scenes.pick_random()

  if time_based_roll >= 45.0:
    return enemy_scenes.pick_random()
  if time_based_roll >= 25.0:
    return enemy_scenes[randi_range(1, enemy_scenes.size() - 1)]
  if time_based_roll >= 12.0:
    return enemy_scenes[randi_range(0, 1)]
  return enemy_scenes[0]

func _get_spawn_position() -> Vector2:
  var viewport_size: Vector2 = get_viewport().get_visible_rect().size
  var active_camera: Camera2D = get_viewport().get_camera_2d()
  var zoom: Vector2 = Vector2.ONE
  if active_camera:
    zoom = active_camera.zoom

  var world_view_size: Vector2 = Vector2(
    viewport_size.x / max(zoom.x, 0.001),
    viewport_size.y / max(zoom.y, 0.001)
  )
  var player_pos: Vector2 = player.global_position
  var margin: float = 100.0
  var side: int = randi() % 4
  var spawn_pos: Vector2 = player_pos

  match side:
    0:
      spawn_pos.x = player_pos.x - world_view_size.x * 0.7 - margin
      spawn_pos.y = randf_range(player_pos.y - world_view_size.y * 0.7, player_pos.y + world_view_size.y * 0.7)
    1:
      spawn_pos.x = player_pos.x + world_view_size.x * 0.7 + margin
      spawn_pos.y = randf_range(player_pos.y - world_view_size.y * 0.7, player_pos.y + world_view_size.y * 0.7)
    2:
      spawn_pos.x = randf_range(player_pos.x - world_view_size.x * 0.7, player_pos.x + world_view_size.x * 0.7)
      spawn_pos.y = player_pos.y - world_view_size.y * 0.7 - margin
    3:
      spawn_pos.x = randf_range(player_pos.x - world_view_size.x * 0.7, player_pos.x + world_view_size.x * 0.7)
      spawn_pos.y = player_pos.y + world_view_size.y * 0.7 + margin

  return spawn_pos

func _format_time(total_seconds: float) -> String:
  var total_int: int = int(total_seconds)
  var minutes: int = int(total_int / 60.0)
  var seconds: int = total_int % 60
  return "%02d:%02d" % [minutes, seconds]

func _on_player_xp_changed(current_xp: int) -> void:
  if not xp_bar:
    return
  if player:
    xp_bar.max_value = player.xp_to_next_level
  xp_bar.value = current_xp

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
  if not game_over_overlay:
    _build_game_over_overlay()

  if game_over_overlay:
    game_over_overlay.visible = true

  get_tree().paused = true
  print("Game Over: Player Died!")

func _restart_game() -> void:
  get_tree().paused = false
  get_tree().reload_current_scene()

func _build_game_over_overlay() -> void:
  if not is_instance_valid(get_node_or_null("UI")):
    return

  game_over_overlay = Control.new()
  game_over_overlay.name = "GameOverOverlay"
  game_over_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
  game_over_overlay.visible = false
  game_over_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
  $UI.add_child(game_over_overlay)

  var darken = ColorRect.new()
  darken.color = Color(0.0, 0.0, 0.0, 0.72)
  darken.set_anchors_preset(Control.PRESET_FULL_RECT)
  darken.mouse_filter = Control.MOUSE_FILTER_IGNORE
  game_over_overlay.add_child(darken)

  var panel = PanelContainer.new()
  panel.anchor_left = 0.5
  panel.anchor_top = 0.5
  panel.anchor_right = 0.5
  panel.anchor_bottom = 0.5
  panel.offset_left = -200
  panel.offset_top = -110
  panel.offset_right = 200
  panel.offset_bottom = 110
  game_over_overlay.add_child(panel)

  var vbox = VBoxContainer.new()
  vbox.alignment = BoxContainer.ALIGNMENT_CENTER
  vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  panel.add_child(vbox)

  var title = Label.new()
  title.text = "You Died"
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.add_theme_font_size_override("font_size", 32)
  vbox.add_child(title)

  var subtitle = Label.new()
  subtitle.text = "The jinns took the night."
  subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(subtitle)

  restart_button = Button.new()
  restart_button.text = "Restart Run"
  restart_button.custom_minimum_size = Vector2(180, 48)
  restart_button.pressed.connect(_restart_game)
  vbox.add_child(restart_button)

func _on_music_finished() -> void:
  if music_player:
    music_player.play()

func _on_player_shot_fired() -> void:
  shoot_cooldown_elapsed = 0.0
  if shoot_bar:
    shoot_bar.value = 0.0
  if shoot_label:
    shoot_label.modulate.a = 0.0

func show_damage_number(world_position: Vector2, amount: float, color: Color = Color(1.0, 0.35, 0.35, 1.0)) -> void:
  if not is_instance_valid($UI):
    return

  var label = Label.new()
  label.text = str(int(amount))
  label.modulate = color
  label.z_index = 1000
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", 18)
  $UI.add_child(label)

  var viewport = get_viewport()
  var camera = viewport.get_camera_2d()
  var screen_position: Vector2 = world_position

  if camera:
    var camera_offset: Vector2 = world_position - camera.global_position
    var view_size: Vector2 = viewport.get_visible_rect().size
    screen_position = (camera_offset / camera.zoom) + (view_size * 0.5)

  label.position = screen_position
  label.position -= Vector2(20, 10)

  var tween = create_tween()
  tween.set_parallel(true)
  tween.tween_property(label, "position:y", label.position.y - 28.0, 0.45)
  tween.tween_property(label, "modulate:a", 0.0, 0.45)
  tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.12)
  tween.tween_property(label, "scale", Vector2.ONE, 0.33).set_delay(0.12)
  tween.finished.connect(label.queue_free)
