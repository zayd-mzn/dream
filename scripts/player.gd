extends CharacterBody2D

# Signals
signal wake_up_changed(current_value, max_value)
signal player_woke_up

# Movement & Combat parameters
@export var speed: float = 220.0
@export var sndala_scene: PackedScene

# Wake-up Bar Settings (Replaces HP)
@export var max_wake_up: float = 100.0
var current_wake_up: float = 0.0

# Camera Shake Settings
@export var max_shake_offset: float = 8.0
var trauma: float = 0.0
var trauma_decay: float = 1.8

@onready var shoot_pivot: Node2D = $ShootPivot
@onready var spawn_point: Marker2D = $ShootPivot/SndalaSpawnPoint
@onready var special_timer: Timer = $SpecialCooldown
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	current_wake_up = 0.0
	wake_up_changed.emit(current_wake_up, max_wake_up)
	# Ensures camera doesn't rotate when player aims
	if camera:
		camera.ignore_rotation = true

func _physics_process(delta: float) -> void:
	handle_movement()
	handle_aim()
	handle_camera_shake(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	# Shoots immediately on every click with no delay
	if event.is_action_pressed("shoot"):
		shoot_sndala()

	if event.is_action_pressed("special") and special_timer.is_stopped():
		use_special_ability()
		special_timer.start()

# --- Movement & Aim ---
func handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()

func handle_aim() -> void:
	shoot_pivot.look_at(get_global_mouse_position())

# --- Camera Shake System ---
func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func handle_camera_shake(delta: float) -> void:
	if not camera:
		return
		
	# Constant low-level ambient shake when Wake-Up bar is above 60%
	var wake_ratio: float = current_wake_up / max_wake_up
	var ambient_shake: float = 0.0
	if wake_ratio > 0.6:
		ambient_shake = (wake_ratio - 0.6) * 0.4  # Scales from 0.0 to ~0.16
	
	var effective_trauma: float = clamp(trauma + ambient_shake, 0.0, 1.0)
	
	if effective_trauma > 0.0:
		# Shake drops quadratically for a punchy feel
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
	if not sndala_scene:
		push_warning("Sndala Scene is not assigned in the Player Inspector!")
		return
	
	add_trauma(0.1) # Subtle kickback shake
	
	var sndala = sndala_scene.instantiate()
	sndala.global_position = spawn_point.global_position
	# Change 'rotation' to 'shoot_pivot.global_rotation'
	sndala.rotation = shoot_pivot.global_rotation
	get_tree().current_scene.add_child(sndala)
	
func use_special_ability() -> void:
	increase_wake_up(25.0)
	add_trauma(0.7) # Heavy impact shake
	print("Lucid shockwave used!")

# --- Wake-up Bar Management ---
func take_hit(amount: float = 15.0) -> void:
	add_trauma(0.4) # Medium shake on enemy hit
	increase_wake_up(amount)

func calm_down(amount: float = 10.0) -> void:
	current_wake_up = max(0.0, current_wake_up - amount)
	wake_up_changed.emit(current_wake_up, max_wake_up)

func increase_wake_up(amount: float) -> void:
	current_wake_up = min(max_wake_up, current_wake_up + amount)
	wake_up_changed.emit(current_wake_up, max_wake_up)
	
	if current_wake_up >= max_wake_up:
		trigger_wake_up()

func trigger_wake_up() -> void:
	add_trauma(1.0)
	player_woke_up.emit()
	set_physics_process(false)
	set_process_unhandled_input(false)
	print("Game Over: Player woke up!")
