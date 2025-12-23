extends BaseEnemy
class_name WalkerEnemy

# Simple walking enemy that walks back and forth
# Similar to a Goomba - just walks until hitting a wall, then turns

@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck

func setup():
	speed = 40.0
	max_health = 1
	score_value = 25

func update_behavior(_delta):
	if is_on_floor():
		# Check for wall or edge
		var should_turn = false

		if wall_check and wall_check.is_colliding():
			should_turn = true

		if floor_check and not floor_check.is_colliding():
			should_turn = true

		if should_turn:
			facing_right = not facing_right
			wall_check.target_position.x *= -1
			floor_check.position.x *= -1

		# Move in facing direction
		if facing_right:
			velocity.x = speed
		else:
			velocity.x = -speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 0.1)

func update_animation():
	super.update_animation()
	if sprite:
		if is_on_floor():
			sprite.play("walk")
		else:
			sprite.play("idle")
