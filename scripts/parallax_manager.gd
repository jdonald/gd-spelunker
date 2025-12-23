extends ParallaxBackground
class_name ParallaxManager

# Layers for overground
@onready var sky_layer: ParallaxLayer = $SkyLayer
@onready var mountains_layer: ParallaxLayer = $MountainsLayer
@onready var hills_layer: ParallaxLayer = $HillsLayer
@onready var trees_layer: ParallaxLayer = $TreesLayer

# Layers for underground
@onready var cave_back_layer: ParallaxLayer = $CaveBackLayer
@onready var cave_mid_layer: ParallaxLayer = $CaveMidLayer

var player: Node2D = null
var terrain_generator: TerrainGenerator = null

# Threshold for switching between above/underground
var surface_threshold: float = 0.0

func _ready():
	# Set parallax motion scales for depth effect
	if sky_layer:
		sky_layer.motion_scale = Vector2(0.0, 0.0)  # Sky doesn't move
	if mountains_layer:
		mountains_layer.motion_scale = Vector2(0.1, 0.05)
	if hills_layer:
		hills_layer.motion_scale = Vector2(0.3, 0.1)
	if trees_layer:
		trees_layer.motion_scale = Vector2(0.5, 0.15)

	if cave_back_layer:
		cave_back_layer.motion_scale = Vector2(0.2, 0.1)
		cave_back_layer.visible = false
	if cave_mid_layer:
		cave_mid_layer.motion_scale = Vector2(0.4, 0.15)
		cave_mid_layer.visible = false

func set_player(p: Node2D):
	player = p

func set_terrain_generator(tg: TerrainGenerator):
	terrain_generator = tg

func _process(_delta):
	if player and terrain_generator:
		update_background_visibility()

func update_background_visibility():
	var is_underground = terrain_generator.is_underground(player.global_position)

	# Fade between overground and underground backgrounds
	if is_underground:
		# Show cave backgrounds, hide overground
		if sky_layer:
			sky_layer.visible = false
		if mountains_layer:
			mountains_layer.visible = false
		if hills_layer:
			hills_layer.visible = false
		if trees_layer:
			trees_layer.visible = false
		if cave_back_layer:
			cave_back_layer.visible = true
		if cave_mid_layer:
			cave_mid_layer.visible = true
	else:
		# Show overground backgrounds, hide cave
		if sky_layer:
			sky_layer.visible = true
		if mountains_layer:
			mountains_layer.visible = true
		if hills_layer:
			hills_layer.visible = true
		if trees_layer:
			trees_layer.visible = true
		if cave_back_layer:
			cave_back_layer.visible = false
		if cave_mid_layer:
			cave_mid_layer.visible = false
