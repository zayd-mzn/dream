class_name XPOrb
extends Area2D

@export var xp_amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("collect_xp"):
		body.collect_xp(xp_amount)
		queue_free()