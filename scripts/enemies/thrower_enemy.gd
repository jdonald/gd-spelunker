extends BaseEnemy
class_name ThrowerEnemy

# Hammer Bros-like enemy that throws projectiles in an arc
# Stays mostly stationary, occasionally moves, and throws balls

const THROW_INTERVAL: float = 2.0
const MOVE_INTERVAL: float = 3.0
const MOVE_DURATION: float = 0.5

var throw_timer: float = 0.0
var move_timer: float = 0.0
var is_moving: bool = false
var move_duration_timer: float = 0.0

var projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")

@onready var wall_check: RayCast2D = $WallCheck

func setup():
	speed = 60.0
	max_health = 3
	score_value = 100
	throw_timer = randf() * THROW_INTERVAL  # Randomize initial throw time

func update_behavior(delta):
	throw_timer += delta
	move_timer += delta

	# Throw projectile
	if throw_timer >= THROW_INTERVAL:
		throw_timer = 0.0
		throw_projectile()

	# Occasionally move
	if is_moving:
		move_duration_timer += delta
		if move_duration_timer >= MOVE_DURATION:
			is_moving = false
			move_duration_timer = 0.0
			velocity.x = 0

		# Check for walls while moving
		if wall_check and wall_check.is_colliding():
			facing_right = not facing_right
			wall_check.target_position.x *= -1
	else:
		if move_timer >= MOVE_INTERVAL:
			move_timer = 0.0
			is_moving = true
			# Randomly choose direction
			if randf() > 0.5:
				facing_right = not facing_right
				wall_check.target_position.x *= -1

	# Apply movement
	if is_moving:
		if facing_right:
			velocity.x = speed
		else:
			velocity.x = -speed
	else:
		velocity.x = 0

	# Face player if visible
	var player = get_tree().get_first_node_in_group("player")
	if player and not is_moving:
		facing_right = player.global_position.x > global_position.x
		if wall_check:
			wall_check.target_position.x = abs(wall_check.target_position.x) * (1 if facing_right else -1)

func throw_projectile():
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position + Vector2(0, -10)

		# Arc velocity - throw towards player direction
		var throw_direction = 1 if facing_right else -1
		projectile.velocity = Vector2(throw_direction * 150, -200)

		get_tree().current_scene.add_child(projectile)

	if sprite:
		sprite.play("throw")

func update_animation():
	super.update_animation()
	if sprite and not sprite.is_playing() or (sprite.animation != "throw"):
		if is_moving:
			sprite.play("walk")
		else:
			sprite.play("idle")
