class_name Jinn
extends Enemy

@export var target: Node2D
@export var projectile_scene: PackedScene = preload("res://scenes/enemies/jinn_projectile.tscn")
@export var attack_range: float = 360.0
@export var attack_cooldown: float = 1.8
@export var projectile_speed: float = 260.0

@onready var sprite: AnimatedSprite2D = get_node_or_null("Sprite2D")

var attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	max_health = 180.0
	move_speed = 90.0
	contact_damage = 12.0
	health = max_health
	attack_timer = randf_range(0.5, 1.2)

	if sprite:
		sprite.modulate = Color(0.95, 0.5, 1.0, 1.0)
		sprite.play("walk")
		sprite.play("default")

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var distance: float = global_position.distance_to(target.global_position)
	var direction: Vector2 = global_position.direction_to(target.global_position)
	var desired_velocity: Vector2 = Vector2.ZERO

	if distance > attack_range:
		desired_velocity = direction * move_speed * 0.8
	elif distance < 180.0:
		desired_velocity = -direction * move_speed * 0.8

	velocity = desired_velocity
	move_and_slide()

	if sprite and absf(velocity.x) > 0.01:
		sprite.flip_h = velocity.x > 0.0

	attack_timer -= delta
	if attack_timer <= 0.0:
		_fire_projectile()
		attack_timer = attack_cooldown

	if target is PhysicsBody2D:
		add_collision_exception_with(target)
		target.add_collision_exception_with(self)

func _fire_projectile() -> void:
	if target == null or projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	if not projectile is Area2D:
		return

	var direction_to_target: Vector2 = global_position.direction_to(target.global_position)
	projectile.global_position = global_position
	projectile.rotation = direction_to_target.angle()
	projectile.set("direction", direction_to_target)
	projectile.set("speed", projectile_speed)
	projectile.set("damage", max(12.0, contact_damage + 8.0))

	if get_tree().current_scene:
		get_tree().current_scene.add_child(projectile)
