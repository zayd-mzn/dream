class_name EnemyHitbox
extends Area2D

@export var damage: float = 10.0

@onready var enemy = get_parent()

func _ready() -> void:
	add_to_group("enemy_hitbox")
	add_to_group("enemy")

	if enemy and "contact_damage" in enemy:
		damage = enemy.contact_damage

func take_damage(amount: float) -> void:
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(amount)
