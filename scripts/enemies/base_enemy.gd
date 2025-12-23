extends CharacterBody2D
class_name BaseEnemy

signal died(enemy: BaseEnemy)

@export var max_health: int = 2
@export var speed: float = 50.0
@export var damage: int = 1
@export var score_value: int = 50
@export var heart_drop_chance: float = 0.3

var current_health: int
var gravity: float = 800.0
var facing_right: bool = true
var is_dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

var heart_pickup_scene: PackedScene = preload("res://scenes/pickups/heart_pickup.tscn")

func _ready():
	current_health = max_health
	add_to_group("enemies")
	if hitbox:
		hitbox.add_to_group("enemy_hitbox")
	if hurtbox:
		hurtbox.add_to_group("enemy_hurtbox")
	setup()

func setup():
	# Override in child classes
	pass

func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)
	update_behavior(delta)
	move_and_slide()
	update_animation()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func update_behavior(_delta):
	# Override in child classes
	pass

func update_animation():
	if sprite:
		sprite.flip_h = not facing_right

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if is_dead:
		return

	current_health -= amount

	# Flash red
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)
		get_tree().create_timer(0.1).timeout.connect(func():
			if sprite:
				sprite.modulate = Color.WHITE
		)

	# Knockback
	if source_position != Vector2.ZERO:
		var knockback_dir = (global_position - source_position).normalized()
		velocity = knockback_dir * 150
		velocity.y = -100

	if current_health <= 0:
		die()

func die():
	is_dead = true

	# Award score to player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_score"):
		player.add_score(score_value)

	# Chance to drop heart
	if randf() < heart_drop_chance:
		drop_heart()

	emit_signal("died", self)

	# Death animation or just remove
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func drop_heart():
	var heart = heart_pickup_scene.instantiate()
	heart.global_position = global_position
	get_tree().current_scene.add_child(heart)
