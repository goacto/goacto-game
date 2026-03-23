class_name ParticleManager extends Node
## Optimized particle management system
## Provides object pooling, LOD, and performance-aware particle effects

# =============================================================================
# CONFIGURATION
# =============================================================================

## Maximum particles per effect type (can be reduced based on device)
const MAX_PARTICLES = {
	"ambient": 40,
	"weather": 50,
	"celebration": 30,
	"portal": 20,
	"sparkle": 15,
	"glow": 10
}

## Performance levels
enum PerformanceLevel {
	LOW,     # Minimal particles (mobile/weak devices)
	MEDIUM,  # Balanced
	HIGH     # Full effects
}

var current_performance_level: PerformanceLevel = PerformanceLevel.MEDIUM

# =============================================================================
# STATE
# =============================================================================

var particle_pools: Dictionary = {}  # type -> Array[Node2D]
var active_particles: Dictionary = {}  # type -> Array[{node, data}]
var reduced_motion: bool = false
var viewport_rect: Rect2 = Rect2()

# Performance tracking
var frame_particle_updates: int = 0
var max_updates_per_frame: int = 100


func _ready() -> void:
	# Check reduced motion setting
	if GameManager:
		reduced_motion = GameManager.is_reduced_motion()

	# Initialize pools
	for particle_type in MAX_PARTICLES:
		particle_pools[particle_type] = []
		active_particles[particle_type] = []

	# Detect performance level
	_detect_performance_level()


func _process(_delta: float) -> void:
	viewport_rect = get_viewport().get_visible_rect()
	frame_particle_updates = 0


# =============================================================================
# PERFORMANCE DETECTION
# =============================================================================

func _detect_performance_level() -> void:
	# Check if mobile
	if OS.get_name() in ["Android", "iOS", "Web"]:
		var mobile_ui = get_node_or_null("/root/MobileUIManager")
		if mobile_ui and mobile_ui.is_mobile:
			current_performance_level = PerformanceLevel.LOW
			return

	# Default to medium
	current_performance_level = PerformanceLevel.MEDIUM


## Get the particle limit multiplier based on performance
func get_particle_multiplier() -> float:
	match current_performance_level:
		PerformanceLevel.LOW:
			return 0.3
		PerformanceLevel.MEDIUM:
			return 0.7
		PerformanceLevel.HIGH:
			return 1.0
	return 0.7


## Get max particle count for a type
func get_max_particles(particle_type: String) -> int:
	var base = MAX_PARTICLES.get(particle_type, 20)
	return int(base * get_particle_multiplier())


# =============================================================================
# OBJECT POOLING
# =============================================================================

## Get a particle from pool or create new
func acquire_particle(particle_type: String, parent: Node) -> Node2D:
	if reduced_motion:
		return null

	var pool = particle_pools.get(particle_type, [])
	var particle: Node2D = null

	if pool.size() > 0:
		particle = pool.pop_back()
		particle.visible = true
	else:
		particle = _create_particle_node(particle_type)

	if particle and is_instance_valid(particle):
		if particle.get_parent() != parent:
			if particle.get_parent():
				particle.get_parent().remove_child(particle)
			parent.add_child(particle)

	return particle


## Return particle to pool
func release_particle(particle_type: String, particle: Node2D) -> void:
	if not is_instance_valid(particle):
		return

	particle.visible = false

	var pool = particle_pools.get(particle_type, [])
	var max_pool_size = MAX_PARTICLES.get(particle_type, 20) * 2

	if pool.size() < max_pool_size:
		pool.append(particle)
	else:
		particle.queue_free()


func _create_particle_node(particle_type: String) -> Node2D:
	var particle = Node2D.new()
	particle.name = "Particle_" + particle_type

	match particle_type:
		"ambient", "weather", "sparkle":
			var polygon = Polygon2D.new()
			polygon.polygon = PackedVector2Array([
				Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)
			])
			polygon.color = Color.WHITE
			particle.add_child(polygon)

		"portal":
			var polygon = Polygon2D.new()
			var points = PackedVector2Array()
			for i in range(6):
				var angle = i * TAU / 6
				points.append(Vector2(cos(angle) * 3, sin(angle) * 3))
			polygon.polygon = points
			polygon.color = Color.WHITE
			particle.add_child(polygon)

		"glow":
			var glow = Polygon2D.new()
			var points = PackedVector2Array()
			for i in range(8):
				var angle = i * TAU / 8
				points.append(Vector2(cos(angle) * 5, sin(angle) * 5))
			glow.polygon = points
			glow.color = Color(1, 1, 1, 0.5)
			particle.add_child(glow)

		"celebration":
			var polygon = Polygon2D.new()
			polygon.polygon = PackedVector2Array([
				Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
			])
			polygon.color = Color.WHITE
			particle.add_child(polygon)

	return particle


# =============================================================================
# PARTICLE CREATION HELPERS
# =============================================================================

## Create ambient floating particles
func create_ambient_particles(parent: Node, count: int, area: Rect2, color_palette: Array[Color]) -> Array:
	if reduced_motion:
		return []

	var particles = []
	var actual_count = min(count, get_max_particles("ambient"))

	for i in range(actual_count):
		var particle = acquire_particle("ambient", parent)
		if particle:
			particle.position = Vector2(
				randf_range(area.position.x, area.position.x + area.size.x),
				randf_range(area.position.y, area.position.y + area.size.y)
			)

			var color = color_palette[randi() % color_palette.size()] if color_palette.size() > 0 else Color.WHITE
			var polygon = particle.get_child(0) as Polygon2D
			if polygon:
				polygon.color = color

			particle.set_meta("velocity", Vector2(randf_range(-10, 10), randf_range(-20, -5)))
			particle.set_meta("lifetime", randf_range(3.0, 6.0))
			particle.set_meta("age", 0.0)
			particle.set_meta("area", area)
			particles.append(particle)

	return particles


## Create weather particles (snow, rain, etc.)
func create_weather_particles(parent: Node, count: int, weather_type: String, area: Rect2) -> Array:
	if reduced_motion:
		return []

	var particles = []
	var actual_count = min(count, get_max_particles("weather"))

	for i in range(actual_count):
		var particle = acquire_particle("weather", parent)
		if particle:
			particle.position = Vector2(
				randf_range(area.position.x, area.position.x + area.size.x),
				randf_range(area.position.y - 100, area.position.y)
			)

			var polygon = particle.get_child(0) as Polygon2D
			if polygon:
				match weather_type:
					"snow":
						polygon.color = Color(0.9, 0.95, 1.0, 0.8)
						particle.scale = Vector2.ONE * randf_range(0.5, 1.5)
					"rain":
						polygon.color = Color(0.6, 0.7, 0.9, 0.6)
						polygon.polygon = PackedVector2Array([Vector2(0, -5), Vector2(1, 5), Vector2(-1, 5)])

			var velocity = Vector2.ZERO
			match weather_type:
				"snow":
					velocity = Vector2(randf_range(-20, 20), randf_range(30, 60))
				"rain":
					velocity = Vector2(randf_range(-10, 10), randf_range(200, 300))

			particle.set_meta("velocity", velocity)
			particle.set_meta("weather_type", weather_type)
			particle.set_meta("area", area)
			particles.append(particle)

	return particles


## Create celebration particles (confetti)
func create_celebration_particles(parent: Node, position: Vector2, count: int) -> Array:
	if reduced_motion:
		return []

	var particles = []
	var actual_count = min(count, get_max_particles("celebration"))
	var celebration_colors = [
		Color(1, 0.8, 0.2),  # Gold
		Color(0.2, 0.8, 0.4),  # Green
		Color(0.4, 0.6, 1),  # Blue
		Color(1, 0.4, 0.6),  # Pink
		Color(0.8, 0.4, 1)   # Purple
	]

	for i in range(actual_count):
		var particle = acquire_particle("celebration", parent)
		if particle:
			particle.position = position

			var polygon = particle.get_child(0) as Polygon2D
			if polygon:
				polygon.color = celebration_colors[randi() % celebration_colors.size()]

			var angle = randf_range(-PI, PI)
			var speed = randf_range(200, 400)
			particle.set_meta("velocity", Vector2(cos(angle), sin(angle)) * speed)
			particle.set_meta("gravity", 300.0)
			particle.set_meta("lifetime", randf_range(1.5, 2.5))
			particle.set_meta("age", 0.0)
			particle.set_meta("rotation_speed", randf_range(-5, 5))
			particles.append(particle)

	return particles


## Create portal particles
func create_portal_particles(parent: Node, center: Vector2, radius: float, count: int, color: Color) -> Array:
	if reduced_motion:
		return []

	var particles = []
	var actual_count = min(count, get_max_particles("portal"))

	for i in range(actual_count):
		var particle = acquire_particle("portal", parent)
		if particle:
			var angle = randf_range(0, TAU)
			var dist = randf_range(radius * 0.7, radius)
			particle.position = center + Vector2(cos(angle), sin(angle)) * dist

			var polygon = particle.get_child(0) as Polygon2D
			if polygon:
				polygon.color = color

			particle.set_meta("center", center)
			particle.set_meta("orbit_angle", angle)
			particle.set_meta("orbit_radius", dist)
			particle.set_meta("orbit_speed", randf_range(0.5, 1.5))
			particle.set_meta("bob_phase", randf() * TAU)
			particles.append(particle)

	return particles


# =============================================================================
# PARTICLE UPDATES
# =============================================================================

## Update ambient particles
func update_ambient_particles(particles: Array, delta: float) -> void:
	if reduced_motion:
		return

	for particle in particles:
		if not is_instance_valid(particle):
			continue

		if frame_particle_updates >= max_updates_per_frame:
			break
		frame_particle_updates += 1

		var velocity = particle.get_meta("velocity")
		var age = particle.get_meta("age") + delta
		var lifetime = particle.get_meta("lifetime")
		var area = particle.get_meta("area")

		particle.position += velocity * delta
		particle.set_meta("age", age)

		# Fade based on lifetime
		var life_ratio = age / lifetime
		particle.modulate.a = 1.0 - life_ratio

		# Respawn if dead or out of area
		if age >= lifetime or not area.has_point(particle.position):
			particle.position = Vector2(
				randf_range(area.position.x, area.position.x + area.size.x),
				area.position.y + area.size.y
			)
			particle.set_meta("age", 0.0)
			particle.modulate.a = 1.0


## Update weather particles
func update_weather_particles(particles: Array, delta: float) -> void:
	if reduced_motion:
		return

	for particle in particles:
		if not is_instance_valid(particle):
			continue

		if frame_particle_updates >= max_updates_per_frame:
			break
		frame_particle_updates += 1

		var velocity = particle.get_meta("velocity")
		var area = particle.get_meta("area")
		var weather_type = particle.get_meta("weather_type")

		particle.position += velocity * delta

		# Add sway for snow
		if weather_type == "snow":
			particle.position.x += sin(particle.position.y * 0.02) * 0.5

		# Respawn at top if past bottom
		if particle.position.y > area.position.y + area.size.y:
			particle.position.y = area.position.y - 50
			particle.position.x = randf_range(area.position.x, area.position.x + area.size.x)


## Update celebration particles
func update_celebration_particles(particles: Array, delta: float) -> Array:
	var remaining = []

	for particle in particles:
		if not is_instance_valid(particle):
			continue

		if frame_particle_updates >= max_updates_per_frame:
			remaining.append(particle)
			continue
		frame_particle_updates += 1

		var velocity = particle.get_meta("velocity")
		var gravity = particle.get_meta("gravity")
		var age = particle.get_meta("age") + delta
		var lifetime = particle.get_meta("lifetime")
		var rotation_speed = particle.get_meta("rotation_speed")

		# Apply gravity
		velocity.y += gravity * delta
		particle.set_meta("velocity", velocity)
		particle.set_meta("age", age)

		particle.position += velocity * delta
		particle.rotation += rotation_speed * delta

		# Fade out
		var life_ratio = age / lifetime
		particle.modulate.a = 1.0 - life_ratio

		if age < lifetime:
			remaining.append(particle)
		else:
			release_particle("celebration", particle)

	return remaining


## Update portal particles
func update_portal_particles(particles: Array, delta: float, time: float) -> void:
	if reduced_motion:
		return

	for particle in particles:
		if not is_instance_valid(particle):
			continue

		if frame_particle_updates >= max_updates_per_frame:
			break
		frame_particle_updates += 1

		var center = particle.get_meta("center")
		var orbit_angle = particle.get_meta("orbit_angle")
		var orbit_radius = particle.get_meta("orbit_radius")
		var orbit_speed = particle.get_meta("orbit_speed")
		var bob_phase = particle.get_meta("bob_phase")

		# Update orbit angle
		orbit_angle += orbit_speed * delta
		particle.set_meta("orbit_angle", orbit_angle)

		# Calculate new position with bob
		var bob = sin(time * 2 + bob_phase) * 5
		particle.position = center + Vector2(
			cos(orbit_angle) * (orbit_radius + bob),
			sin(orbit_angle) * (orbit_radius + bob) * 0.5  # Elliptical
		)

		# Pulse alpha
		particle.modulate.a = 0.5 + sin(time * 3 + bob_phase) * 0.3


# =============================================================================
# CLEANUP
# =============================================================================

## Release all particles of a type
func release_all(particle_type: String, particles: Array) -> void:
	for particle in particles:
		release_particle(particle_type, particle)
	particles.clear()


## Clear all pools (call when changing scenes)
func clear_pools() -> void:
	for particle_type in particle_pools:
		var pool = particle_pools[particle_type]
		for particle in pool:
			if is_instance_valid(particle):
				particle.queue_free()
		pool.clear()

	for particle_type in active_particles:
		active_particles[particle_type].clear()
