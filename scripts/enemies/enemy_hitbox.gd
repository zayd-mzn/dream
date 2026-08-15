class_name EnemyHitbox
extends Area2D

@export var damage: float = 10.0

@onready var enemy: Enemy = get_parent() as Enemy

func _ready() -> void:
	add_to_group("enemy_hitbox")
	add_to_group("enemy")

	if enemy:
		damage = enemy.contact_damage

func take_damage(amount: float) -> void:
	if enemy:
		enemy.take_damage(amount)