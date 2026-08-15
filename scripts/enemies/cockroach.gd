class_name Cockroach
extends Enemy

@export var target: Node2D

func _physics_process(delta: float) -> void:
    if target:
        var direction: Vector2 = (target.global_position - global_position).normalized()
        velocity = direction * move_speed
        move_and_slide()
