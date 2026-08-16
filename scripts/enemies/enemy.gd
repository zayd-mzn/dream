class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)
signal damaged(enemy: Enemy, damage_amount: float)

@export var max_health: float = 100.0
@export var move_speed: float = 100.0
@export var contact_damage: float = 10.0
@export var xp_value: int = 10
@export var xp_orb_scene: PackedScene = preload("res://scenes/xp_orb.tscn")

var health: float = max_health
@onready var hitbox: Area2D = get_node_or_null("HitBox")

func _ready() -> void:
	add_to_group("enemies")
	health = max_health

	if hitbox:
		hitbox.set_deferred("monitoring", true)
		hitbox.set_deferred("monitorable", true)
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	for other_enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if other_enemy != self and other_enemy is PhysicsBody2D:
			add_collision_exception_with(other_enemy)
			other_enemy.add_collision_exception_with(self)

	for player_node: Node in get_tree().get_nodes_in_group("Player"):
		if player_node is PhysicsBody2D:
			add_collision_exception_with(player_node)
			player_node.add_collision_exception_with(self)

func take_damage(damage_amount: float) -> void:
	health -= damage_amount
	if get_tree().current_scene and get_tree().current_scene.has_method("show_damage_number"):
		get_tree().current_scene.show_damage_number(global_position, damage_amount, Color(1.0, 0.8, 0.35, 1.0))
	damaged.emit(self, damage_amount)

	if health <= 0:
		die()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() and area.get_parent().is_in_group("Player") and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(contact_damage)

func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)

func die() -> void:
	if xp_orb_scene:
		call_deferred("_spawn_xp_orb")
	died.emit(self)
	queue_free()

func _spawn_xp_orb() -> void:
	var orb = xp_orb_scene.instantiate()
	if orb is Area2D:
		orb.global_position = global_position
		orb.set("xp_amount", xp_value)
		get_tree().current_scene.add_child(orb)
