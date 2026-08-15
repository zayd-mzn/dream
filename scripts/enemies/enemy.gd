class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)
signal damaged(enemy: Enemy, damage_amount: float)

@export var max_health: float = 100.0
@export var move_speed: float = 100.0
@export var contact_damage: float = 10.0
@export var xp_value: int = 10

var health: float = max_health

func _ready() -> void:
	add_to_group("enemies")
	health = max_health

	for other_enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if other_enemy != self and other_enemy is PhysicsBody2D:
			add_collision_exception_with(other_enemy)
			other_enemy.add_collision_exception_with(self)

func take_damage(damage_amount: float) -> void:
	health -= damage_amount
	damaged.emit(self, damage_amount)

	if health <= 0:
		die()

func die() -> void:
	died.emit(self)
	queue_free()
