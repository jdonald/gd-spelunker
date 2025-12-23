extends BaseEnemy
class_name BouncerEnemy

# Bouncing enemy like a paratroopa
# Bounces up and down while moving horizontally

const BOUNCE_VELOCITY: float = -300.0
const HORIZONTAL_SPEED: float = 30.0

@onready var wall_check: RayCast2D = $WallCheck

func setup():
	speed = HORIZONTAL_SPEED
	max_health = 2
	score_value = 50
	gravity = 600.0  # Slightly lower gravity for floatier bounce

func update_behavior(_delta):
	# Bounce when hitting ground
	if is_on_floor():
		velocity.y = BOUNCE_VELOCITY

	# Check for walls
	if wall_check and wall_check.is_colliding():
		facing_right = not facing_right
		wall_check.target_position.x *= -1

	# Move horizontally
	if facing_right:
		velocity.x = HORIZONTAL_SPEED
	else:
		velocity.x = -HORIZONTAL_SPEED

func update_animation():
	super.update_animation()
	if sprite:
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
