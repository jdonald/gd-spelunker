extends CanvasLayer
class_name GameUI

@onready var hearts_container: HBoxContainer = $MarginContainer/VBoxContainer/TopBar/HeartsContainer
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var coordinates_label: Label = $MarginContainer/VBoxContainer/TopBar/CoordinatesLabel
@onready var exploration_label: Label = $MarginContainer/VBoxContainer/TopBar/ExplorationLabel
@onready var exploration_popup: Panel = $ExplorationPopup
@onready var exploration_popup_label: Label = $ExplorationPopup/Label

var heart_full_texture: Texture2D
var heart_empty_texture: Texture2D
var max_hearts: int = 10
var current_hearts: int = 10

func _ready():
	# Create simple heart textures using placeholder
	exploration_popup.visible = false
	update_hearts_display()
	update_score(0)
	update_coordinates(Vector2.ZERO)
	update_exploration_level(0)

func connect_to_player(player: Player):
	player.health_changed.connect(_on_health_changed)
	player.score_changed.connect(_on_score_changed)
	player.position_changed.connect(_on_position_changed)
	player.exploration_level_changed.connect(_on_exploration_level_changed)

func _on_health_changed(current: int, maximum: int):
	current_hearts = current
	max_hearts = maximum
	update_hearts_display()

func _on_score_changed(score: int):
	update_score(score)

func _on_position_changed(pos: Vector2):
	update_coordinates(pos)

func _on_exploration_level_changed(level: int):
	update_exploration_level(level)
	show_exploration_popup(level)

func update_hearts_display():
	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()

	# Create heart icons
	for i in range(max_hearts):
		var heart = ColorRect.new()
		heart.custom_minimum_size = Vector2(20, 20)
		if i < current_hearts:
			heart.color = Color(1, 0.2, 0.3)  # Red for full heart
		else:
			heart.color = Color(0.3, 0.3, 0.3)  # Gray for empty heart
		hearts_container.add_child(heart)

func update_score(score: int):
	score_label.text = "Score: %d" % score

func update_coordinates(pos: Vector2):
	var grid_x = int(pos.x / 32)
	var grid_y = int(pos.y / 32)
	coordinates_label.text = "X: %d  Y: %d" % [grid_x, grid_y]

func update_exploration_level(level: int):
	exploration_label.text = "Exploration: Lv.%d" % level

func show_exploration_popup(level: int):
	exploration_popup_label.text = "Grid Exploration Level %d!" % level
	exploration_popup.visible = true
	exploration_popup.modulate.a = 1.0

	# Animate popup
	var tween = create_tween()
	tween.tween_property(exploration_popup, "position:y", 100, 0.3).from(50)
	tween.tween_interval(2.0)
	tween.tween_property(exploration_popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): exploration_popup.visible = false)

func show_game_over():
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.add_theme_font_size_override("font_size", 64)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.anchors_preset = Control.PRESET_CENTER
	add_child(game_over_label)
