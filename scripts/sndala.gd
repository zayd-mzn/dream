extends Area2D

@export var speed: float = 650.0
@export var spin_speed: float = 18.0
@export var damage: float = 25.0
var piercing: bool = false

var _hit_count: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	add_to_group("Weapon")
	area_entered.connect(_on_area_entered)
	screen_notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	# 1. Move forward in the direction the projectile is facing
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * speed * delta

	# 2. Spin the sprite locally for the animation effect
	if sprite:
		sprite.rotation += spin_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		if piercing and _hit_count < 1:
			_hit_count += 1
		else:
			queue_free()
