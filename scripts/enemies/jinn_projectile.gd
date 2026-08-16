extends Area2D

@export var speed: float = 260.0
@export var damage: float = 12.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
  add_to_group("enemy_projectile")
  body_entered.connect(_on_body_entered)
  area_entered.connect(_on_area_entered)

  var timer = get_tree().create_timer(lifetime)
  timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
  if direction == Vector2.ZERO:
    return

  global_position += direction * speed * delta

  if sprite:
    sprite.rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
  if body.is_in_group("Player") and body.has_method("take_damage"):
    body.take_damage(damage, global_position)
  queue_free()

func _on_area_entered(area: Area2D) -> void:
  if area.get_parent() and area.get_parent().is_in_group("Player") and area.get_parent().has_method("take_damage"):
    area.get_parent().take_damage(damage, global_position)
    queue_free()
