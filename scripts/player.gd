extends CharacterBody2D

const MODIFIER_FACTORY = preload("res://scripts/modifiers/modifier_factory.gd")

# Signals
signal wake_up_changed(current_value: float, max_value: float)
signal player_woke_up
signal xp_changed(current_xp: int)
signal health_changed(current_hp: float, max_hp: float)
signal player_died
signal shot_fired
signal special_charges_changed(charges: int)

# Movement & Combat parameters
@export var base_speed: float = 220.0
@export var speed: float = 220.0
@export var sndala_scene: PackedScene
@export var contact_damage_interval: float = 0.35
@export var knockback_force: float = 180.0

# Wake-up and Health settings
@export var max_wake_up: float = 100.0
@export var max_hp: float = 100.0
var current_xp: int = 0
var current_wake_up: float = 0.0
var current_hp: float = 100.0
var level: int = 1
var xp_to_next_level: int = 10
var level_up_bonus: int = 5
var is_invulnerable: bool = false
var is_dead: bool = false
var last_contact_damage_time: float = 0.0
var damage_bonus: float = 1.0
var speed_multiplier: float = 1.0
var shoot_cooldown: float = 0.2
var triple_shot: bool = false
var piercing: bool = false
var special_charges: int = 0

# Camera Shake Settings
@export var max_shake_offset: float = 8.0
var trauma: float = 0.0
var trauma_decay: float = 1.8

# Node References
@onready var sprite: CanvasItem = $AnimatedSprite2D
@onready var shoot_pivot: Node2D = $ShootPivot
@onready var spawn_point: Marker2D = $ShootPivot/SndalaSpawnPoint
@onready var special_timer: Timer = get_node_or_null("SpecialCooldown")
@onready var shoot_timer: Timer = $ShootCooldown
@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var health_bar: ProgressBar = $HealthBar

# Optional nodes
@onready var invuln_timer: Timer = get_node_or_null("InvincibilityTimer")
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")

func _ready() -> void:
	add_to_group("Player")

	if hurtbox == null:
		hurtbox = get_node_or_null("HitBox")
	if invuln_timer == null:
		invuln_timer = Timer.new()
		invuln_timer.name = "InvincibilityTimer"
		invuln_timer.one_shot = true
		add_child(invuln_timer)
		if not invuln_timer.timeout.is_connected(_on_invincibility_timeout):
			invuln_timer.timeout.connect(_on_invincibility_timeout)

	# Initialize stats
	current_hp = max_hp
	current_wake_up = 0.0
	xp_to_next_level = get_xp_threshold_for_level(level)
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	health_changed.emit(current_hp, max_hp)
	wake_up_changed.emit(current_wake_up, max_wake_up)

	if camera:
		camera.ignore_rotation = true

	if hurtbox:
		if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.connect(_on_hurtbox_area_entered)
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	handle_movement()
	handle_aim()
	handle_contact_damage()
	handle_camera_shake(delta)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	if event.is_action_pressed("shoot") and shoot_timer.is_stopped():
		shoot_sndala()
		shoot_timer.start(shoot_cooldown)

	if event.is_action_pressed("special") and special_charges > 0:
		use_special_ability()

# --- Movement & Aim ---
func handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir.length() > 0.01:
		velocity = input_dir.normalized() * speed
		$AnimatedSprite2D.play("walk")
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")

	if velocity.x > 0.0:
		sprite.flip_h = true
	elif velocity.x < 0.0:
		sprite.flip_h = false

	move_and_slide()

func handle_aim() -> void:
	if shoot_pivot:
		shoot_pivot.look_at(get_global_mouse_position())

# --- Sandal Combat Actions ---
func shoot_sndala() -> void:
	if not sndala_scene:
		push_warning("Sndala Scene is not assigned in the Player Inspector!")
		return

	add_trauma(0.1)
	shot_fired.emit()

	if triple_shot:
		for angle_offset in [-15.0, 0.0, 15.0]:
			_spawn_sndala(deg_to_rad(angle_offset))
	else:
		_spawn_sndala(0.0)

func _spawn_sndala(angle_offset: float) -> void:
	var sndala = sndala_scene.instantiate()
	if "damage" in sndala:
		sndala.damage *= damage_bonus
	if "piercing" in sndala:
		sndala.piercing = piercing
	sndala.global_position = spawn_point.global_position
	sndala.rotation = shoot_pivot.global_rotation + angle_offset
	get_tree().current_scene.add_child(sndala)

func use_special_ability() -> void:
	special_charges = 0
	special_charges_changed.emit(special_charges)
	add_trauma(0.7)
	shot_fired.emit()
	var count: int = 12
	for i in range(count):
		var angle: float = (TAU / count) * i
		_spawn_sndala_at_angle(angle)

func _spawn_sndala_at_angle(angle: float) -> void:
	var sndala = sndala_scene.instantiate()
	if "damage" in sndala:
		sndala.damage *= damage_bonus
	if "piercing" in sndala:
		sndala.piercing = piercing
	sndala.global_position = global_position
	sndala.rotation = angle
	get_tree().current_scene.add_child(sndala)

# --- Damage, Health & Death ---
func take_damage(amount: float = 15.0, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_dead:
		return

	if get_tree().current_scene and get_tree().current_scene.has_method("show_damage_number"):
		get_tree().current_scene.show_damage_number(global_position, amount, Color(1.0, 0.35, 0.35, 1.0))

	current_hp = max(0.0, current_hp - amount)
	update_health_ui()
	health_changed.emit(current_hp, max_hp)

	if source_position != Vector2.ZERO:
		var knockback_dir: Vector2 = (global_position - source_position).normalized()
		velocity += knockback_dir * knockback_force

	add_trauma(0.4)
	start_invulnerability(1.0)

	if current_hp <= 0.0:
		die()

func heal(amount: float = 15.0) -> void:
	if is_dead:
		return
	current_hp = min(max_hp, current_hp + amount)
	update_health_ui()
	health_changed.emit(current_hp, max_hp)

func update_health_ui() -> void:
	if health_bar:
		var tween = create_tween()
		tween.tween_property(health_bar, "value", current_hp, 0.15)

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
		take_damage(dmg, area.global_position)

func handle_contact_damage() -> void:
	if not hurtbox or is_dead:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_contact_damage_time < contact_damage_interval:
		return

	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies") and not is_invulnerable:
			last_contact_damage_time = now
			take_damage(15.0, body.global_position)
			return

	for area in hurtbox.get_overlapping_areas():
		if area.is_in_group("enemy_hitbox") and not is_invulnerable:
			var dmg: float = 15.0
			if "damage" in area:
				dmg = area.damage
			last_contact_damage_time = now
			take_damage(dmg, area.global_position)
			return

func get_xp_threshold_for_level(level_number: int) -> int:
	return int(10 + (level_number - 1) * 8)

func increase_wake_up(amount: float) -> void:
	current_wake_up = min(max_wake_up, current_wake_up + amount)
	wake_up_changed.emit(current_wake_up, max_wake_up)

	if current_wake_up >= max_wake_up:
		trigger_wake_up()

func collect_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		xp_to_next_level = get_xp_threshold_for_level(level)
		trigger_level_up()
	update_xp_bar()
	xp_changed.emit(current_xp)

func update_xp_bar() -> void:
	if not is_inside_tree():
		return
	var bar = get_tree().current_scene.get_node_or_null("UI/Control/XpBar")
	if bar:
		bar.max_value = xp_to_next_level
		bar.value = current_xp
		var tween = create_tween()
		tween.tween_property(bar, "value", current_xp, 0.12)

func trigger_level_up() -> void:
	special_charges = 1
	special_charges_changed.emit(special_charges)
	player_woke_up.emit()
	if get_tree().current_scene and get_tree().current_scene.has_method("request_modifier_menu"):
		get_tree().current_scene.request_modifier_menu()

func trigger_wake_up() -> void:
	player_woke_up.emit()
	print("Wake Up complete!")

func apply_speed_modifier(multiplier: float) -> void:
	speed_multiplier *= multiplier
	speed = base_speed * speed_multiplier

func apply_damage_modifier(multiplier: float) -> void:
	damage_bonus *= multiplier

func apply_cooldown_modifier(reduction: float) -> void:
	shoot_cooldown = max(0.05, shoot_cooldown + reduction)

func apply_triple_shot() -> void:
	triple_shot = true

func apply_piercing() -> void:
	piercing = true

func apply_max_health_modifier(extra_hp: float) -> void:
	max_hp += extra_hp
	current_hp = min(max_hp, current_hp + extra_hp)
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	health_changed.emit(current_hp, max_hp)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	add_trauma(1.0)
	player_died.emit()
	set_physics_process(false)
	set_process_unhandled_input(false)
	print("Game Over: Player Died!")

# --- Camera Shake System ---
func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func handle_camera_shake(delta: float) -> void:
	if not camera:
		return

	if trauma > 0.0:
		var shake_amount: float = trauma * trauma
		camera.offset = Vector2(
			randf_range(-max_shake_offset, max_shake_offset) * shake_amount,
			randf_range(-max_shake_offset, max_shake_offset) * shake_amount
		)
		trauma = max(0.0, trauma - trauma_decay * delta)
	else:
		camera.offset = Vector2.ZERO
