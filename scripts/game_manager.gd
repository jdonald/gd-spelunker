extends Node2D
class_name GameManager

@onready var player: Player = $Player
@onready var terrain_generator: TerrainGenerator = $TerrainGenerator
@onready var game_ui: GameUI = $GameUI
@onready var parallax_background: ParallaxManager = $ParallaxBackground

func _ready():
	# Connect all systems
	setup_game()

func setup_game():
	# Add player to group for easy reference
	player.add_to_group("player")

	# Connect terrain generator to player
	terrain_generator.set_player(player)

	# Connect UI to player
	game_ui.connect_to_player(player)

	# Connect parallax to player and terrain
	parallax_background.set_player(player)
	parallax_background.set_terrain_generator(terrain_generator)

	# Connect player death signal
	player.player_died.connect(_on_player_died)

	# Position player at spawn point (slightly above ground)
	var spawn_x = 0
	var surface_y = terrain_generator.get_surface_height_at(spawn_x)
	player.global_position = Vector2(spawn_x, surface_y - 64)

func _on_player_died():
	game_ui.show_game_over()
	# Restart after delay
	get_tree().create_timer(3.0).timeout.connect(func():
		get_tree().reload_current_scene()
	)

func _input(event):
	# Debug: Restart game with R key
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()

	# Debug: Toggle fullscreen with F11
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
