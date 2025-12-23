extends Area2D
class_name HeartPickup

const FLOAT_SPEED = 1.0
const FLOAT_AMPLITUDE = 5.0

var initial_y: float
var time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	initial_y = position.y
	add_to_group("pickups")

func _physics_process(delta):
	time += delta
	# Float up and down
	position.y = initial_y + sin(time * FLOAT_SPEED * TAU) * FLOAT_AMPLITUDE

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(1)
		# Pickup effect
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.1)
		tween.tween_callback(queue_free)
