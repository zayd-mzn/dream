class_name Cockroach
extends Enemy

@export var target: Node2D
@onready var sprite: AnimatedSprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	super._ready()
	if sprite:
		sprite.play("default")

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
