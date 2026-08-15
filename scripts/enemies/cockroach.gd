class_name Cockroach
extends Enemy

@export var target: Node2D

func _physics_process(_delta: float) -> void:
	if target == null:
		return

	var direction: Vector2 = global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()
