extends Node
## SceneLoader - Background scene preloading and caching
## Reduces loading times by preloading scenes in background threads

# =============================================================================
# CONFIGURATION
# =============================================================================

## Scenes to preload on game start (in order of priority)
const PRELOAD_ON_START = [
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/mindscape/mindscape_hub.tscn"
]

## Scenes to preload when entering ship
const PRELOAD_ON_SHIP = [
	"res://scenes/ship/hallway.tscn",
	"res://scenes/ship/kitchen.tscn",
	"res://scenes/ship/living_room.tscn",
	"res://scenes/ship/stairs.tscn"
]

## Scenes to preload when entering mindscape
const PRELOAD_ON_MINDSCAPE = [
	"res://scenes/mindscape/mindscape_north.tscn",
	"res://scenes/mindscape/mindscape_south.tscn",
	"res://scenes/mindscape/mindscape_east.tscn",
	"res://scenes/mindscape/mindscape_west.tscn",
	"res://scenes/focus_chamber/focus_chamber.tscn",
	"res://scenes/daily_rituals/daily_rituals.tscn"
]

## Maximum cached scenes
const MAX_CACHED_SCENES = 8

## Cache TTL in seconds (scenes not accessed for this long get freed)
const CACHE_TTL = 300.0  # 5 minutes

# =============================================================================
# STATE
# =============================================================================

var scene_cache: Dictionary = {}  # path -> {scene, last_access}
var loading_queue: Array[String] = []
var currently_loading: String = ""
var is_loading: bool = false
var loader_thread: Thread = null
var is_web_platform: bool = false  # Disable threaded loading on web

# Progress tracking
var loading_progress: float = 0.0
var loading_status: String = ""

# =============================================================================
# SIGNALS
# =============================================================================

signal scene_loaded(path: String, scene: PackedScene)
signal scene_load_failed(path: String, error: String)
signal preload_started(paths: Array)
signal preload_complete
signal loading_progress_changed(progress: float, status: String)


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Check if running on web platform (threaded loading not supported)
	is_web_platform = OS.get_name() == "Web"

	if is_web_platform:
		print("[SceneLoader] Ready - web platform detected, background loading disabled")
		return

	# Start preloading essential scenes after a short delay (non-web only)
	await get_tree().create_timer(1.0).timeout
	preload_scenes(PRELOAD_ON_START)
	print("[SceneLoader] Ready - background loading enabled")


func _process(delta: float) -> void:
	# Process loading queue
	if not is_loading and loading_queue.size() > 0:
		_load_next_scene()

	# Clean up old cached scenes
	_cleanup_cache(delta)


func _exit_tree() -> void:
	# Clean up thread if running
	if loader_thread and loader_thread.is_started():
		loader_thread.wait_to_finish()


# =============================================================================
# PUBLIC API
# =============================================================================

## Check if a scene is cached
func is_cached(path: String) -> bool:
	return scene_cache.has(path)


## Get a cached scene (or null if not cached)
func get_cached_scene(path: String) -> PackedScene:
	if scene_cache.has(path):
		scene_cache[path].last_access = Time.get_ticks_msec()
		return scene_cache[path].scene
	return null


## Load a scene (returns immediately if cached, otherwise loads)
func load_scene(path: String) -> PackedScene:
	# Check cache first
	if scene_cache.has(path):
		scene_cache[path].last_access = Time.get_ticks_msec()
		return scene_cache[path].scene

	# Load synchronously
	if ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		if scene:
			_cache_scene(path, scene)
			return scene

	return null


## Queue scene for background loading
func queue_load(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[SceneLoader] Scene not found: " + path)
		return

	if scene_cache.has(path):
		return  # Already cached

	if path in loading_queue:
		return  # Already queued

	if path == currently_loading:
		return  # Currently loading

	loading_queue.append(path)


## Preload multiple scenes in background
func preload_scenes(paths: Array) -> void:
	var to_load: Array = []
	for path in paths:
		if not scene_cache.has(path) and path not in loading_queue:
			to_load.append(path)

	if to_load.size() > 0:
		preload_started.emit(to_load)
		for path in to_load:
			queue_load(path)


## Preload scenes based on current location
func preload_for_location(location: String) -> void:
	match location:
		"ship":
			preload_scenes(PRELOAD_ON_SHIP)
		"mindscape":
			preload_scenes(PRELOAD_ON_MINDSCAPE)
		"bedroom":
			preload_scenes(PRELOAD_ON_SHIP)
		"kitchen", "hallway", "living_room", "stairs":
			# Preload adjacent ship areas
			var ship_scenes = PRELOAD_ON_SHIP.duplicate()
			ship_scenes.append("res://scenes/bedroom/bedroom.tscn")
			preload_scenes(ship_scenes)


## Clear all cached scenes
func clear_cache() -> void:
	scene_cache.clear()
	print("[SceneLoader] Cache cleared")


## Get loading status
func get_status() -> Dictionary:
	return {
		"is_loading": is_loading,
		"queue_size": loading_queue.size(),
		"cached_scenes": scene_cache.keys(),
		"progress": loading_progress,
		"status": loading_status
	}


# =============================================================================
# INTERNAL LOADING
# =============================================================================

func _load_next_scene() -> void:
	if loading_queue.size() == 0:
		return

	currently_loading = loading_queue.pop_front()
	is_loading = true
	loading_progress = 0.0
	loading_status = "Loading: " + currently_loading.get_file()

	# On web, use synchronous loading instead of threaded
	if is_web_platform:
		_load_scene_sync(currently_loading)
		return

	# Use ResourceLoader for background loading (non-web)
	var error = ResourceLoader.load_threaded_request(currently_loading)
	if error != OK:
		var failed_path = currently_loading
		push_warning("[SceneLoader] Failed to start loading: " + failed_path)
		is_loading = false
		currently_loading = ""
		scene_load_failed.emit(failed_path, "Failed to start loading")
		return

	# Poll for completion in process
	_poll_loading()


func _load_scene_sync(path: String) -> void:
	# Synchronous loading for web platform
	if ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		if scene:
			_cache_scene(path, scene)
			scene_loaded.emit(path, scene)
			print("[SceneLoader] Loaded (sync): " + path.get_file())
		else:
			scene_load_failed.emit(path, "Failed to load resource")
	else:
		scene_load_failed.emit(path, "Resource not found")

	is_loading = false
	currently_loading = ""
	loading_progress = 1.0

	if loading_queue.size() == 0:
		preload_complete.emit()


func _poll_loading() -> void:
	if currently_loading == "":
		return

	var status = ResourceLoader.load_threaded_get_status(currently_loading)

	var path = currently_loading

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(path) as PackedScene
			if scene:
				_cache_scene(path, scene)
				scene_loaded.emit(path, scene)
				print("[SceneLoader] Loaded: " + path.get_file())
			else:
				scene_load_failed.emit(path, "Failed to get loaded resource")

			is_loading = false
			currently_loading = ""
			loading_progress = 1.0

			if loading_queue.size() == 0:
				preload_complete.emit()
			return

		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var progress: Array = []
			ResourceLoader.load_threaded_get_status(path, progress)
			if progress.size() > 0:
				loading_progress = progress[0]
			loading_progress_changed.emit(loading_progress, loading_status)
			# Continue polling next frame
			await get_tree().process_frame
			_poll_loading()
			return

		ResourceLoader.THREAD_LOAD_FAILED:
			scene_load_failed.emit(path, "Loading failed")
			is_loading = false
			currently_loading = ""
			return

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			scene_load_failed.emit(path, "Invalid resource")
			is_loading = false
			currently_loading = ""
			return


func _cache_scene(path: String, scene: PackedScene) -> void:
	# Enforce cache size limit
	if scene_cache.size() >= MAX_CACHED_SCENES:
		_evict_oldest_scene()

	scene_cache[path] = {
		"scene": scene,
		"last_access": Time.get_ticks_msec()
	}


func _evict_oldest_scene() -> void:
	var oldest_path = ""
	var oldest_time = Time.get_ticks_msec()

	for path in scene_cache:
		var entry = scene_cache[path]
		if entry.last_access < oldest_time:
			oldest_time = entry.last_access
			oldest_path = path

	if oldest_path != "":
		scene_cache.erase(oldest_path)
		print("[SceneLoader] Evicted: " + oldest_path.get_file())


var cleanup_timer: float = 0.0

func _cleanup_cache(delta: float) -> void:
	cleanup_timer += delta
	if cleanup_timer < 60.0:  # Check every minute
		return
	cleanup_timer = 0.0

	var current_time = Time.get_ticks_msec()
	var ttl_ms = CACHE_TTL * 1000

	var to_remove: Array = []
	for path in scene_cache:
		var entry = scene_cache[path]
		if current_time - entry.last_access > ttl_ms:
			to_remove.append(path)

	for path in to_remove:
		scene_cache.erase(path)
		print("[SceneLoader] Cache expired: " + path.get_file())


# =============================================================================
# UTILITY
# =============================================================================

## Load and change to a scene with optional preloading hint
func goto_scene_cached(path: String, preload_hint: String = "") -> void:
	var scene = load_scene(path)
	if scene:
		get_tree().change_scene_to_packed(scene)
		if preload_hint != "":
			preload_for_location(preload_hint)
	else:
		# Fallback to regular loading
		get_tree().change_scene_to_file(path)


## Get memory usage estimate
func get_cache_memory_estimate() -> int:
	# Rough estimate based on scene count
	return scene_cache.size() * 1024 * 500  # ~500KB per scene estimate
