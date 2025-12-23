extends Node2D
class_name TerrainGenerator

const TILE_SIZE = 32
const CHUNK_SIZE = 16  # Tiles per chunk
const RENDER_DISTANCE = 3  # Chunks to render around player

# Tile IDs
enum Tiles {
	EMPTY = -1,
	GRASS = 0,
	DIRT = 1,
	STONE = 2,
	WATER = 3,
	CAVE_WALL = 4,
	CAVE_FLOOR = 5
}

# Terrain parameters
var surface_height_base: int = 0  # Y level for surface (0 = middle of screen)
var noise: FastNoiseLite
var cave_noise: FastNoiseLite
var water_noise: FastNoiseLite

# Chunk management
var loaded_chunks: Dictionary = {}  # Vector2i -> TileMap
var chunk_enemies: Dictionary = {}  # Vector2i -> Array of enemies

# References
@onready var terrain_tilemap: TileMapLayer = $TerrainTileMap
@onready var water_tilemap: TileMapLayer = $WaterTileMap
@onready var background_tilemap: TileMapLayer = $BackgroundTileMap

var player: Node2D = null
var enemy_scenes: Dictionary = {}

signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

func _ready():
	setup_noise()
	setup_tilesets()
	load_enemy_scenes()
	# Generate initial chunks around origin immediately
	generate_initial_chunks()

func setup_tilesets():
	# Create terrain tileset programmatically with proper collision
	var terrain_tileset = TileSet.new()
	terrain_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	terrain_tileset.add_physics_layer()
	terrain_tileset.set_physics_layer_collision_layer(0, 2)  # Layer 2 = terrain
	terrain_tileset.set_physics_layer_collision_mask(0, 1)   # Mask 1 = player

	# Create atlas source with a generated texture
	var img = Image.create(TILE_SIZE * 4, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Tile 0: Grass (green)
	for x in range(0, TILE_SIZE):
		for y in range(TILE_SIZE):
			img.set_pixel(x, y, Color(0.3, 0.7, 0.3))

	# Tile 1: Dirt (brown)
	for x in range(TILE_SIZE, TILE_SIZE * 2):
		for y in range(TILE_SIZE):
			img.set_pixel(x, y, Color(0.5, 0.35, 0.2))

	# Tile 2: Stone (gray)
	for x in range(TILE_SIZE * 2, TILE_SIZE * 3):
		for y in range(TILE_SIZE):
			img.set_pixel(x, y, Color(0.4, 0.4, 0.45))

	# Tile 3: Cave background (dark)
	for x in range(TILE_SIZE * 3, TILE_SIZE * 4):
		for y in range(TILE_SIZE):
			img.set_pixel(x, y, Color(0.25, 0.2, 0.3))

	var texture = ImageTexture.create_from_image(img)

	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Add source to tileset BEFORE creating tiles/collision so layers are recognized
	terrain_tileset.add_source(source, 0)

	# Create tiles with collision
	for i in range(4):
		source.create_tile(Vector2i(i, 0))
		if i < 3:  # First 3 tiles have collision (not cave background)
			var tile_data = source.get_tile_data(Vector2i(i, 0), 0)
			# Add collision polygon (full tile)
			var polygon = PackedVector2Array([
				Vector2(-TILE_SIZE/2, -TILE_SIZE/2),
				Vector2(TILE_SIZE/2, -TILE_SIZE/2),
				Vector2(TILE_SIZE/2, TILE_SIZE/2),
				Vector2(-TILE_SIZE/2, TILE_SIZE/2)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)

	terrain_tilemap.tile_set = terrain_tileset

	# Create water tileset
	var water_tileset = TileSet.new()
	water_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	water_tileset.add_physics_layer()
	water_tileset.set_physics_layer_collision_layer(0, 64)  # Layer 7 = water
	water_tileset.set_physics_layer_collision_mask(0, 0)

	var water_img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			water_img.set_pixel(x, y, Color(0.2, 0.5, 0.9, 0.7))

	var water_texture = ImageTexture.create_from_image(water_img)
	var water_source = TileSetAtlasSource.new()
	water_source.texture = water_texture
	water_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	water_source.create_tile(Vector2i(0, 0))

	water_tileset.add_source(water_source, 0)
	water_tilemap.tile_set = water_tileset

	# Create background tileset (no collision)
	var bg_tileset = TileSet.new()
	bg_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var bg_source = TileSetAtlasSource.new()
	bg_source.texture = texture
	bg_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in range(4):
		bg_source.create_tile(Vector2i(i, 0))

	bg_tileset.add_source(bg_source, 0)
	background_tilemap.tile_set = bg_tileset

func setup_noise():
	# Main terrain noise for surface variation
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	noise.fractal_octaves = 5

	# Cave noise for underground caverns
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = randi()
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 0.02
	cave_noise.fractal_octaves = 3

	# Water noise for water pools
	water_noise = FastNoiseLite.new()
	water_noise.seed = randi()
	water_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	water_noise.frequency = 0.03

func load_enemy_scenes():
	enemy_scenes["walker"] = preload("res://scenes/enemies/walker_enemy.tscn")
	enemy_scenes["bouncer"] = preload("res://scenes/enemies/bouncer_enemy.tscn")
	enemy_scenes["thrower"] = preload("res://scenes/enemies/thrower_enemy.tscn")
	enemy_scenes["flyer"] = preload("res://scenes/enemies/flyer_enemy.tscn")

func set_player(p: Node2D):
	player = p
	# Generate chunks around player immediately when set
	if player:
		update_chunks()

func generate_initial_chunks():
	# Generate chunks around the spawn point (0, -100) before player exists
	var spawn_chunk = world_to_chunk(Vector2(0, -100))
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for y in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk_pos = spawn_chunk + Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				load_chunk(chunk_pos)

func _process(_delta):
	if player:
		update_chunks()

func update_chunks():
	var player_chunk = world_to_chunk(player.global_position)

	# Load chunks within render distance
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for y in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				load_chunk(chunk_pos)

	# Unload distant chunks
	var chunks_to_unload: Array = []
	for chunk_pos in loaded_chunks.keys():
		var distance = abs(chunk_pos.x - player_chunk.x) + abs(chunk_pos.y - player_chunk.y)
		if distance > RENDER_DISTANCE + 2:
			chunks_to_unload.append(chunk_pos)

	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_pos.x / (CHUNK_SIZE * TILE_SIZE)),
		floor(world_pos.y / (CHUNK_SIZE * TILE_SIZE))
	)

func chunk_to_world(chunk_pos: Vector2i) -> Vector2:
	return Vector2(chunk_pos.x * CHUNK_SIZE * TILE_SIZE, chunk_pos.y * CHUNK_SIZE * TILE_SIZE)

func load_chunk(chunk_pos: Vector2i):
	loaded_chunks[chunk_pos] = true
	chunk_enemies[chunk_pos] = []

	var base_x = chunk_pos.x * CHUNK_SIZE
	var base_y = chunk_pos.y * CHUNK_SIZE

	for local_x in range(CHUNK_SIZE):
		for local_y in range(CHUNK_SIZE):
			var world_x = base_x + local_x
			var world_y = base_y + local_y
			generate_tile(world_x, world_y)

	# Spawn enemies in this chunk
	spawn_enemies_in_chunk(chunk_pos)

	emit_signal("chunk_loaded", chunk_pos)

func unload_chunk(chunk_pos: Vector2i):
	# Remove tiles from tilemaps
	var base_x = chunk_pos.x * CHUNK_SIZE
	var base_y = chunk_pos.y * CHUNK_SIZE

	for local_x in range(CHUNK_SIZE):
		for local_y in range(CHUNK_SIZE):
			var tile_pos = Vector2i(base_x + local_x, base_y + local_y)
			terrain_tilemap.set_cell(tile_pos, -1)
			water_tilemap.set_cell(tile_pos, -1)
			background_tilemap.set_cell(tile_pos, -1)

	# Remove enemies
	if chunk_enemies.has(chunk_pos):
		for enemy in chunk_enemies[chunk_pos]:
			if is_instance_valid(enemy):
				enemy.queue_free()
		chunk_enemies.erase(chunk_pos)

	loaded_chunks.erase(chunk_pos)
	emit_signal("chunk_unloaded", chunk_pos)

func generate_tile(world_x: int, world_y: int):
	var tile_pos = Vector2i(world_x, world_y)

	# Get terrain height at this x position
	var height_variation = noise.get_noise_1d(world_x * 0.1) * 20
	var surface_y = int(surface_height_base + height_variation)

	# Get cave noise value
	var cave_value = cave_noise.get_noise_2d(world_x, world_y)

	# Get water noise value
	var water_value = water_noise.get_noise_2d(world_x, world_y)

	# Check safe zone
	var is_safe_zone = abs(world_x) < 5

	# Tile atlas coordinates:
	# (0,0) = grass (green), (1,0) = dirt (brown), (2,0) = stone (gray), (3,0) = cave bg

	# Determine what type of tile this is
	if world_y < surface_y - 3:
		# Sky area - empty
		if water_value > 0.6 and world_y > surface_y - 8:
			# Surface water pool
			water_tilemap.set_cell(tile_pos, 0, Vector2i(0, 0))
		pass
	elif world_y < surface_y:
		# Near surface - could have grass or trees
		if world_y == surface_y - 1 or world_y == surface_y - 2:
			# Check for water depression
			if not is_safe_zone and water_value > 0.5:
				water_tilemap.set_cell(tile_pos, 0, Vector2i(0, 0))
		pass
	elif world_y == surface_y:
		# Surface level - grass (green tile at 0,0)
		if not is_safe_zone:
			if cave_value > 0.35: # Lower threshold for surface caves
				# Cave opening at surface
				background_tilemap.set_cell(tile_pos, 0, Vector2i(3, 0))
			elif water_value > 0.5: # Water pool surface
				# Don't place grass if it's a water pool
				pass
			else:
				terrain_tilemap.set_cell(tile_pos, 0, Vector2i(0, 0))
		else:
			# Safe zone - always solid
			terrain_tilemap.set_cell(tile_pos, 0, Vector2i(0, 0))
	elif world_y < surface_y + 4:
		# Dirt layer
		if not is_safe_zone and cave_value > 0.35:
			# Small cave opening near surface
			if water_value > 0.6:
				water_tilemap.set_cell(tile_pos, 0, Vector2i(0, 0))
		else:
			# Dirt tile at (1, 0)
			terrain_tilemap.set_cell(tile_pos, 0, Vector2i(1, 0))
	else:
		# Underground - stone with caves
		var depth = world_y - surface_y
		var cave_threshold = 0.25 - (depth * 0.002)  # Lower base threshold for larger caves

		if cave_value > cave_threshold:
			# Cave - empty space
			# Add background decoration (cave bg at 3,0)
			background_tilemap.set_cell(tile_pos, 0, Vector2i(3, 0))

			# Check for underground water
			if water_value > 0.65 and world_y > surface_y + 15:
				water_tilemap.set_cell(tile_pos, 0, Vector2i(0, 0))
		else:
			# Solid stone at (2, 0)
			terrain_tilemap.set_cell(tile_pos, 0, Vector2i(2, 0))

func spawn_enemies_in_chunk(chunk_pos: Vector2i):
	# Random chance to spawn enemies in each chunk
	var spawn_count = 2 + randi() % 4  # 2-5 enemies per chunk

	for i in range(spawn_count):
		var enemy_type = ["walker", "bouncer", "thrower", "flyer"][randi() % 4]
		var local_x = randi() % CHUNK_SIZE
		var local_y = randi() % CHUNK_SIZE

		var world_x = (chunk_pos.x * CHUNK_SIZE + local_x) * TILE_SIZE
		var world_y = (chunk_pos.y * CHUNK_SIZE + local_y) * TILE_SIZE

		# Check if there's ground below and air at spawn position
		var tile_pos = Vector2i(chunk_pos.x * CHUNK_SIZE + local_x, chunk_pos.y * CHUNK_SIZE + local_y)
		var below_pos = Vector2i(tile_pos.x, tile_pos.y + 1)

		# Only spawn in valid locations
		var current_tile = terrain_tilemap.get_cell_source_id(tile_pos)
		var below_tile = terrain_tilemap.get_cell_source_id(below_pos)

		# For flying enemies, spawn in air; for others, need ground
		if enemy_type == "flyer":
			if current_tile == -1:  # Air
				spawn_enemy(enemy_type, Vector2(world_x, world_y), chunk_pos)
		else:
			if current_tile == -1 and below_tile != -1:  # Air above ground
				spawn_enemy(enemy_type, Vector2(world_x, world_y), chunk_pos)

func spawn_enemy(enemy_type: String, position: Vector2, chunk_pos: Vector2i):
	if not enemy_scenes.has(enemy_type):
		return

	var enemy = enemy_scenes[enemy_type].instantiate()
	enemy.global_position = position
	add_child(enemy)

	if not chunk_enemies.has(chunk_pos):
		chunk_enemies[chunk_pos] = []
	chunk_enemies[chunk_pos].append(enemy)

func get_surface_height_at(world_x: float) -> float:
	var height_variation = noise.get_noise_1d(world_x / TILE_SIZE * 0.1) * 20
	return (surface_height_base + height_variation) * TILE_SIZE

func is_underground(world_pos: Vector2) -> bool:
	var surface = get_surface_height_at(world_pos.x)
	return world_pos.y > surface + TILE_SIZE * 2
