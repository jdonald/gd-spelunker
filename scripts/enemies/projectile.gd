extends Area2D
class_name Projectile

var velocity: Vector2 = Vector2.ZERO
var projectile_gravity: float = 400.0
var lifetime: float = 5.0

func _ready():
	add_to_group("enemy_projectile")
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	# Apply gravity for arc motion
	velocity.y += projectile_gravity * delta

	# Move
	position += velocity * delta

	# Rotate to face movement direction
	rotation = velocity.angle()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
		queue_free()
	elif body.collision_layer & 2:  # Terrain layer
		queue_free()

func _on_area_entered(area):
	# Hit by player sword
	if area.get_parent().is_in_group("player"):
		queue_free()
