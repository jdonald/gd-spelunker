extends CharacterBody2D
class_name Player

signal health_changed(current_health: int, max_health: int)
signal score_changed(score: int)
signal position_changed(pos: Vector2)
signal exploration_level_changed(level: int)
signal player_died

# Movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const WALL_SLIDE_SPEED = 50.0
const WALL_JUMP_VELOCITY = Vector2(250, -300)
const SWIM_SPEED = 150.0
const SWIM_JUMP_VELOCITY = -150.0

# Physics
var gravity = 800.0

# State
var max_health: int = 10
var current_health: int = 10
var score: int = 0
var max_exploration_level: int = 0
var is_wall_sliding: bool = false
var can_double_jump: bool = true
var has_double_jumped: bool = false
var is_swimming: bool = false
var facing_right: bool = true
var is_attacking: bool = false
var attack_direction: String = "side"  # "side", "up", "down"
var is_flinching: bool = false
var flinch_timer: float = 0.0
const FLINCH_DURATION = 0.5
const INVINCIBILITY_DURATION = 1.5
var invincibility_timer: float = 0.0

# References
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_collision: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight
@onready var water_check: Area2D = $WaterCheck
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	sword_collision.disabled = true
	emit_signal("health_changed", current_health, max_health)
	emit_signal("score_changed", score)
	check_exploration_level()

func _physics_process(delta):
	if is_flinching:
		flinch_timer -= delta
		if flinch_timer <= 0:
			is_flinching = false

	if invincibility_timer > 0:
		invincibility_timer -= delta
		# Flash effect during invincibility
		sprite.modulate.a = 0.5 if fmod(invincibility_timer * 10, 1.0) > 0.5 else 1.0
	else:
		sprite.modulate.a = 1.0

	# Check if in water
	is_swimming = water_check.has_overlapping_areas() or water_check.has_overlapping_bodies()

	if is_swimming:
		handle_swimming(delta)
	else:
		handle_normal_movement(delta)

	move_and_slide()

	# Update facing direction
	if velocity.x > 0:
		facing_right = true
		sprite.flip_h = false
	elif velocity.x < 0:
		facing_right = false
		sprite.flip_h = true

	# Update sword hitbox position based on facing and attack direction
	update_sword_position()

	# Emit position for UI
	emit_signal("position_changed", global_position)
	check_exploration_level()

	update_animation()

func handle_normal_movement(delta):
	# Wall sliding check
	var on_wall_left = wall_check_left.is_colliding()
	var on_wall_right = wall_check_right.is_colliding()
	var on_wall = on_wall_left or on_wall_right

	# Apply gravity
	if not is_on_floor():
		if on_wall and velocity.y > 0 and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
			# Wall sliding
			is_wall_sliding = true
			velocity.y = min(velocity.y + gravity * delta * 0.1, WALL_SLIDE_SPEED)
		else:
			is_wall_sliding = false
			velocity.y += gravity * delta
	else:
		is_wall_sliding = false
		has_double_jumped = false
		can_double_jump = true

	# Handle jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_wall_sliding:
			# Wall jump
			velocity.y = WALL_JUMP_VELOCITY.y
			if on_wall_left:
				velocity.x = WALL_JUMP_VELOCITY.x
			else:
				velocity.x = -WALL_JUMP_VELOCITY.x
			is_wall_sliding = false
		elif can_double_jump and not has_double_jumped:
			# Double jump
			velocity.y = JUMP_VELOCITY * 0.85
			has_double_jumped = true
			can_double_jump = false

	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	if not is_flinching:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * 0.2)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.05)

	# Handle attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()

func handle_swimming(delta):
	is_wall_sliding = false
	has_double_jumped = false
	can_double_jump = true

	# Slower gravity in water
	velocity.y += gravity * delta * 0.3
	velocity.y = min(velocity.y, SWIM_SPEED)

	# Swim up with jump button (like Mario)
	if Input.is_action_just_pressed("jump"):
		velocity.y = SWIM_JUMP_VELOCITY

	# Horizontal movement (slower in water)
	var direction = Input.get_axis("move_left", "move_right")
	if not is_flinching:
		if direction:
			velocity.x = direction * SWIM_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SWIM_SPEED * 0.1)

	# Can still attack underwater
	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()

func perform_attack():
	is_attacking = true

	# Determine attack direction
	if Input.is_action_pressed("move_up"):
		attack_direction = "up"
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		attack_direction = "down"
	else:
		attack_direction = "side"

	update_sword_position()
	sword_collision.disabled = false
	attack_timer.start(0.3)

	# Play attack animation
	if attack_direction == "up":
		sprite.play("attack_up")
	elif attack_direction == "down":
		sprite.play("attack_down")
	else:
		sprite.play("attack_side")

func update_sword_position():
	if not sword_hitbox:
		return

	match attack_direction:
		"up":
			sword_hitbox.position = Vector2(0, -30)
			sword_hitbox.rotation_degrees = 0
		"down":
			sword_hitbox.position = Vector2(0, 30)
			sword_hitbox.rotation_degrees = 0
		"side":
			if facing_right:
				sword_hitbox.position = Vector2(25, 0)
			else:
				sword_hitbox.position = Vector2(-25, 0)
			sword_hitbox.rotation_degrees = 0

func _on_attack_timer_timeout():
	is_attacking = false
	sword_collision.disabled = true

func update_animation():
	if is_attacking:
		return  # Don't interrupt attack animation

	if is_swimming:
		sprite.play("swim")
	elif is_wall_sliding:
		sprite.play("wall_slide")
	elif not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	elif abs(velocity.x) > 10:
		sprite.play("run")
	else:
		sprite.play("idle")

func take_damage(amount: int = 1, source_position: Vector2 = Vector2.ZERO):
	if invincibility_timer > 0:
		return

	current_health -= amount
	emit_signal("health_changed", current_health, max_health)

	# Flinch effect
	is_flinching = true
	flinch_timer = FLINCH_DURATION
	invincibility_timer = INVINCIBILITY_DURATION

	# Knockback
	if source_position != Vector2.ZERO:
		var knockback_dir = (global_position - source_position).normalized()
		velocity = knockback_dir * 200
		velocity.y = -150

	if current_health <= 0:
		die()

func heal(amount: int = 1):
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)

func add_score(points: int):
	score += points
	emit_signal("score_changed", score)

func check_exploration_level():
	# Calculate manhattan distance from origin in 100x100 grid units
	var grid_x = int(abs(global_position.x) / 100.0 / 32.0)  # 32 pixels per tile
	var grid_y = int(abs(global_position.y) / 100.0 / 32.0)
	var manhattan_distance = grid_x + grid_y

	if manhattan_distance > max_exploration_level:
		var old_level = max_exploration_level
		max_exploration_level = manhattan_distance
		emit_signal("exploration_level_changed", max_exploration_level)
		# Award points for exploration
		add_score((max_exploration_level - old_level) * 100)

func die():
	emit_signal("player_died")
	# Could add death animation here
	queue_free()

func _on_sword_hitbox_area_entered(area):
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(1, global_position)

func _on_sword_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)

func _on_hurtbox_area_entered(area):
	if area.is_in_group("enemy_hitbox") or area.is_in_group("enemy_projectile"):
		take_damage(1, area.global_position)

func _on_hurtbox_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage(1, body.global_position)
