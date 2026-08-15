class_name Cockroach
extends Enemy

@export var target: Node2D

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

  if target is PhysicsBody2D:
    add_collision_exception_with(target)
    target.add_collision_exception_with(self)
