extends CharacterBody2D

# Signals
signal wake_up_changed(current_value: float, max_value: float)
signal player_woke_up
signal xp_changed(current_xp: int)

# Movement & Combat parameters
@export var speed: float = 220.0
@export var sndala_scene: PackedScene

# Wake-up Bar Settings (Replaces HP)
@export var max_wake_up: float = 100.0
var current_xp: int = 0
var current_wake_up: float = 0.0
var is_invulnerable: bool = false
var is_dead: bool = false

# Camera Shake Settings
@export var max_shake_offset: float = 8.0
var trauma: float = 0.0
var trauma_decay: float = 1.8

# Node References
@onready var sprite: CanvasItem = $Sprite2D # Works for both Sprite2D and AnimatedSprite2D
@onready var shoot_pivot: Node2D = $ShootPivot
@onready var spawn_point: Marker2D = $ShootPivot/SndalaSpawnPoint
@onready var special_timer: Timer = $SpecialCooldown
@onready var camera: Camera2D = $Camera2D

# Optional nodes (checks before accessing)
@onready var invuln_timer: Timer = get_node_or_null("InvincibilityTimer")
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")

func _ready() -> void:
	add_to_group("Player")
	current_wake_up = 0.0
	wake_up_changed.emit(current_wake_up, max_wake_up)
	
	if camera:
		camera.ignore_rotation = true
		
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if invuln_timer:
		invuln_timer.timeout.connect(_on_invincibility_timeout)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	handle_movement()
	handle_aim()
	handle_camera_shake(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
		
	if event.is_action_pressed("shoot"):
		shoot_sndala()

	if event.is_action_pressed("special") and special_timer and special_timer.is_stopped():
		use_special_ability()
		special_timer.start()

func handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()

func handle_aim() -> void:
	if shoot_pivot:
		shoot_pivot.look_at(get_global_mouse_position())

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func handle_camera_shake(delta: float) -> void:
	if not camera:
		return
		
	var wake_ratio: float = current_wake_up / max_wake_up
	var ambient_shake: float = 0.0
	if wake_ratio > 0.6:
		ambient_shake = (wake_ratio - 0.6) * 0.4
	
	var effective_trauma: float = clamp(trauma + ambient_shake, 0.0, 1.0)
	
	if effective_trauma > 0.0:
		var shake_amount: float = effective_trauma * effective_trauma
		camera.offset = Vector2(
			randf_range(-max_shake_offset, max_shake_offset) * shake_amount,
			randf_range(-max_shake_offset, max_shake_offset) * shake_amount
		)
		trauma = max(0.0, trauma - trauma_decay * delta)
	else:
		camera.offset = Vector2.ZERO

# --- Combat Actions ---
func shoot_sndala() -> void:
	var sndala = sndala_scene.instantiate()
	sndala.global_position = spawn_point.global_position
	sndala.rotation = shoot_pivot.global_rotation
	get_tree().current_scene.add_child(sndala)
	
func use_special_ability() -> void:
	increase_wake_up(25.0)
	add_trauma(0.7)

# --- Damage & Health System ---
func take_damage(amount: float = 15.0) -> void:
	if is_invulnerable or is_dead:
		return

	increase_wake_up(amount)
	add_trauma(0.4)
	start_invulnerability(1.0)

func start_invulnerability(duration: float = 1.0) -> void:
	is_invulnerable = true
	if invuln_timer:
		invuln_timer.start(duration)
	
	if sprite:
		var tween = create_tween().set_loops(int(duration / 0.1))
		tween.tween_property(sprite, "modulate:a", 0.3, 0.05)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.05)

func _on_invincibility_timeout() -> void:
	is_invulnerable = false
	if sprite:
		sprite.modulate.a = 1.0

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox") and not is_invulnerable and not is_dead:
		var dmg: float = 15.0
		if "damage" in area:
			dmg = area.damage
		take_damage(dmg)
		
func calm_down(amount: float = 10.0) -> void:
	current_wake_up = max(0.0, current_wake_up - amount)
	wake_up_changed.emit(current_wake_up, max_wake_up)

func increase_wake_up(amount: float) -> void:
	current_wake_up = min(max_wake_up, current_wake_up + amount)
	wake_up_changed.emit(current_wake_up, max_wake_up)
	
	if current_wake_up >= max_wake_up:
		trigger_wake_up()

func collect_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp)

func trigger_wake_up() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	add_trauma(1.0)
	player_woke_up.emit()
	set_physics_process(false)
	set_process_unhandled_input(false)
	print("Game Over: Player woke up!")
