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
  health = max_health

func take_damage(damage_amount: float) -> void:
  health -= damage_amount
  emit_signal("damaged", self, damage_amount)

  if health <= 0:
    die()

func die() -> void:
  emit_signal("died", self)
  queue_free()
