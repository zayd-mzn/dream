class_name Jinn
extends Enemy

@export var target: Node2D

@onready var sprite: AnimatedSprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	super._ready()
	max_health = 180.0
	move_speed = 90.0
	contact_damage = 12.0
	health = max_health

	if sprite:
		sprite.modulate = Color(0.95, 0.5, 1.0, 1.0)
		sprite.play("walk")

func _physics_process(_delta: float) -> void:
	if target == null:
		return

	var distance: float = global_position.distance_to(target.global_position)
	var direction: Vector2 = global_position.direction_to(target.global_position)

	if distance < 35.0:
		var push_dir: Vector2 = (global_position - target.global_position).normalized()
		velocity = push_dir * (move_speed * 0.8)
		move_and_slide()
		return

	velocity = direction * move_speed
	move_and_slide()

	if sprite and absf(velocity.x) > 0.01:
		sprite.flip_h = velocity.x > 0.0
