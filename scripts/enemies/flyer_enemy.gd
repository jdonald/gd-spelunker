extends BaseEnemy
class_name FlyerEnemy

# Flying enemy that moves horizontally
# Flies at a fixed height, turns when hitting walls

const FLY_SPEED: float = 80.0

@onready var wall_check: RayCast2D = $WallCheck

func setup():
	speed = FLY_SPEED
	max_health = 1
	score_value = 40

func apply_gravity(_delta):
	# Flying enemies don't fall
	pass

func update_behavior(_delta):
	# Check for walls
	if wall_check and wall_check.is_colliding():
		facing_right = not facing_right
		wall_check.target_position.x *= -1

	# Move horizontally
	if facing_right:
		velocity.x = FLY_SPEED
	else:
		velocity.x = -FLY_SPEED

	# Slight vertical wobble for visual effect
	velocity.y = sin(Time.get_ticks_msec() * 0.005) * 20

func update_animation():
	super.update_animation()
	if sprite:
		sprite.play("fly")
