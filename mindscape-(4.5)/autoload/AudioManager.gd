extends Node
## AudioManager - Handles all audio playback: music, voiceovers, and sound effects
## Autoload singleton for global audio control

# Audio players
var music_player: AudioStreamPlayer
var music_player_secondary: AudioStreamPlayer  # For true crossfading
var voice_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var ambient_player_secondary: AudioStreamPlayer  # For ambient crossfading

# SFX pool for overlapping sounds
var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 8

# Crossfade settings
const DEFAULT_MUSIC_FADE: float = 2.0
const DEFAULT_AMBIENT_FADE: float = 3.0
var active_music_player: int = 0  # 0 = primary, 1 = secondary
var active_ambient_player: int = 0

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.7
var voice_volume: float = 1.0
var sfx_volume: float = 0.8
var ambient_volume: float = 0.5

# State tracking
var current_music: AudioStream = null
var is_voice_playing: bool = false
var is_muted: bool = false
var pre_mute_volume: float = 1.0

# Ducking settings (lower music when voice is playing)
const DUCKING_AMOUNT: float = 0.5  # Music volume multiplier when voice plays (50%)
const DUCKING_FADE_TIME: float = 0.3  # Fade time for ducking
var is_ducked: bool = false
var ducking_tween: Tween = null

# Signals
signal voice_finished
signal music_changed(track_name: String)


func _ready() -> void:
	_setup_audio_players()
	_load_volume_settings()
	print("[AudioManager] Initialized")


func _setup_audio_players() -> void:
	# Music player (primary) - for background music
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	# Music player (secondary) - for true crossfading
	music_player_secondary = AudioStreamPlayer.new()
	music_player_secondary.name = "MusicPlayerSecondary"
	music_player_secondary.bus = "Music"
	music_player_secondary.finished.connect(_on_music_secondary_finished)
	add_child(music_player_secondary)

	# Voice player - for voiceovers/dialogue
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = "Voice"
	voice_player.finished.connect(_on_voice_finished)
	add_child(voice_player)

	# Ambient player (primary) - for background ambience
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Ambient"
	add_child(ambient_player)

	# Ambient player (secondary) - for true crossfading
	ambient_player_secondary = AudioStreamPlayer.new()
	ambient_player_secondary.name = "AmbientPlayerSecondary"
	ambient_player_secondary.bus = "Ambient"
	add_child(ambient_player_secondary)

	# SFX pool - for overlapping sound effects
	for i in range(SFX_POOL_SIZE):
		var sfx = AudioStreamPlayer.new()
		sfx.name = "SFXPlayer_%d" % i
		sfx.bus = "SFX"
		sfx.finished.connect(_return_sfx_to_pool.bind(sfx))
		add_child(sfx)
		sfx_pool.append(sfx)


# =============================================================================
# MUSIC
# =============================================================================

func play_music(stream: AudioStream, fade_in: float = DEFAULT_MUSIC_FADE, loop: bool = true) -> void:
	if stream == current_music:
		# Check if already playing on either player
		var primary_playing = music_player.playing and music_player.stream == stream
		var secondary_playing = music_player_secondary.playing and music_player_secondary.stream == stream
		if primary_playing or secondary_playing:
			return  # Already playing this track

	# Enable looping on the stream
	if loop:
		_enable_stream_loop(stream)

	# Get the currently active player and the inactive one
	var outgoing_player = _get_active_music_player()
	var incoming_player = _get_inactive_music_player()

	if outgoing_player.playing and fade_in > 0:
		# True crossfade: both tracks play simultaneously
		_crossfade_music(stream, fade_in, incoming_player, outgoing_player)
	else:
		# No crossfade needed, just play
		current_music = stream
		incoming_player.stream = stream
		incoming_player.volume_db = linear_to_db(music_volume * master_volume)
		incoming_player.play()
		active_music_player = 0 if incoming_player == music_player else 1
		music_changed.emit(_get_stream_name(stream))


func _get_active_music_player() -> AudioStreamPlayer:
	return music_player if active_music_player == 0 else music_player_secondary


func _get_inactive_music_player() -> AudioStreamPlayer:
	return music_player_secondary if active_music_player == 0 else music_player


func _crossfade_music(new_stream: AudioStream, duration: float, incoming: AudioStreamPlayer, outgoing: AudioStreamPlayer) -> void:
	# Start the new track quietly
	current_music = new_stream
	incoming.stream = new_stream
	incoming.volume_db = -40.0
	incoming.play()

	# Swap active player
	active_music_player = 0 if incoming == music_player else 1

	# Create parallel tweens for smooth crossfade
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out old track
	tween.tween_property(outgoing, "volume_db", -40.0, duration).set_ease(Tween.EASE_IN)

	# Fade in new track
	var target_db = linear_to_db(music_volume * master_volume)
	tween.tween_property(incoming, "volume_db", target_db, duration).set_ease(Tween.EASE_OUT)

	# Stop the old player after fade completes
	tween.set_parallel(false)
	tween.tween_callback(func():
		outgoing.stop()
		music_changed.emit(_get_stream_name(new_stream))
	)


func stop_music(fade_out: float = DEFAULT_MUSIC_FADE) -> void:
	current_music = null
	var active_player = _get_active_music_player()
	var inactive_player = _get_inactive_music_player()

	# Stop inactive player immediately
	if inactive_player.playing:
		inactive_player.stop()

	# Fade out active player
	if fade_out > 0 and active_player.playing:
		var tween = create_tween()
		tween.tween_property(active_player, "volume_db", -40.0, fade_out).set_ease(Tween.EASE_IN)
		tween.tween_callback(active_player.stop)
	else:
		active_player.stop()


func pause_music() -> void:
	music_player.stream_paused = true
	music_player_secondary.stream_paused = true


func resume_music() -> void:
	music_player.stream_paused = false
	music_player_secondary.stream_paused = false


func _on_music_finished() -> void:
	# Fallback: replay music if it wasn't set to loop
	if current_music and not music_player_secondary.playing:
		print("[AudioManager] Music finished, restarting track")
		music_player.stream = current_music
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		music_player.play()
		active_music_player = 0


func _on_music_secondary_finished() -> void:
	# Fallback: replay music if it wasn't set to loop
	if current_music and not music_player.playing:
		print("[AudioManager] Music (secondary) finished, restarting track")
		music_player_secondary.stream = current_music
		music_player_secondary.volume_db = linear_to_db(music_volume * master_volume)
		music_player_secondary.play()
		active_music_player = 1


## Enable looping on an audio stream based on its type
func _enable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD


## Play music from a file path
func play_music_from_path(path: String, fade_in: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		print("[AudioManager] Music file not found: ", path)
		return

	var stream = load(path) as AudioStream
	if stream:
		play_music(stream, fade_in)


## Play main menu music
func play_music_main_menu() -> void:
	play_music_from_path("res://audio/music/main_menu.ogg")


## Play mindscape hub music
func play_music_mindscape() -> void:
	play_music_from_path("res://audio/music/mindscape_hub.ogg")


## Play ship ambient music
func play_music_ship() -> void:
	play_music_from_path("res://audio/music/ship_ambient.ogg")


## Play focus session music
func play_music_focus() -> void:
	play_music_from_path("res://audio/music/focus_active.ogg")


## Play cutscene intro music (at reduced volume for narration)
func play_music_cutscene_intro() -> void:
	_play_cutscene_music("res://audio/music/cutscene_intro.ogg")


## Play cutscene awakening music (at reduced volume for narration)
func play_music_cutscene_awakening() -> void:
	_play_cutscene_music("res://audio/music/cutscene_awakening.ogg")


## Play cutscene music at reduced volume (35% of normal for voice clarity)
func _play_cutscene_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("[AudioManager] Cutscene music not found: ", path)
		return

	var stream = load(path) as AudioStream
	if stream:
		# Enable looping
		_enable_stream_loop(stream)

		# Play at reduced volume for cutscenes (low to not overpower voice)
		var cutscene_volume_multiplier = 0.35
		var target_db = linear_to_db(music_volume * master_volume * cutscene_volume_multiplier)

		# Get the inactive player for crossfade
		var outgoing = _get_active_music_player()
		var incoming = _get_inactive_music_player()

		if outgoing.playing:
			# Crossfade to new track at lower volume
			current_music = stream
			incoming.stream = stream
			incoming.volume_db = -40.0
			incoming.play()
			active_music_player = 0 if incoming == music_player else 1

			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(outgoing, "volume_db", -40.0, DEFAULT_MUSIC_FADE)
			tween.tween_property(incoming, "volume_db", target_db, DEFAULT_MUSIC_FADE)
			tween.set_parallel(false)
			tween.tween_callback(outgoing.stop)
		else:
			# Just play
			current_music = stream
			incoming.stream = stream
			incoming.volume_db = target_db
			incoming.play()
			active_music_player = 0 if incoming == music_player else 1


## Play music for a specific cutscene by ID
func play_music_for_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"intro", "intro_part1", "intro_part2":
			play_music_cutscene_intro()
		"awakening":
			play_music_cutscene_awakening()
		_:
			# Default cutscene music
			play_music_cutscene_intro()


# =============================================================================
# VOICE / DIALOGUE
# =============================================================================

func play_voice(stream: AudioStream, volume_multiplier: float = 1.0) -> void:
	if stream == null:
		return

	# Stop any currently playing voice
	if voice_player.playing:
		voice_player.stop()

	voice_player.stream = stream
	voice_player.volume_db = linear_to_db(voice_volume * master_volume * volume_multiplier)
	voice_player.play()
	is_voice_playing = true

	# Duck the music
	_duck_music()


func play_voice_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("[AudioManager] Voice file not found: ", path)
		return

	var stream = load(path) as AudioStream
	if stream:
		play_voice(stream)


func stop_voice() -> void:
	voice_player.stop()
	is_voice_playing = false
	_unduck_music()


func is_voice_active() -> bool:
	return voice_player.playing


func _on_voice_finished() -> void:
	is_voice_playing = false
	_unduck_music()
	voice_finished.emit()


func _duck_music() -> void:
	if is_ducked:
		return
	is_ducked = true

	# Cancel any existing ducking tween
	if ducking_tween and ducking_tween.is_valid():
		ducking_tween.kill()

	var ducked_db = linear_to_db(music_volume * master_volume * DUCKING_AMOUNT)

	ducking_tween = create_tween()
	ducking_tween.set_parallel(true)
	if music_player.playing:
		ducking_tween.tween_property(music_player, "volume_db", ducked_db, DUCKING_FADE_TIME)
	if music_player_secondary.playing:
		ducking_tween.tween_property(music_player_secondary, "volume_db", ducked_db, DUCKING_FADE_TIME)


func _unduck_music() -> void:
	if not is_ducked:
		return
	is_ducked = false

	# Cancel any existing ducking tween
	if ducking_tween and ducking_tween.is_valid():
		ducking_tween.kill()

	var normal_db = linear_to_db(music_volume * master_volume)

	ducking_tween = create_tween()
	ducking_tween.set_parallel(true)
	if music_player.playing:
		ducking_tween.tween_property(music_player, "volume_db", normal_db, DUCKING_FADE_TIME)
	if music_player_secondary.playing:
		ducking_tween.tween_property(music_player_secondary, "volume_db", normal_db, DUCKING_FADE_TIME)


# =============================================================================
# SOUND EFFECTS
# =============================================================================

func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if stream == null:
		return

	var player = _get_available_sfx_player()
	if player == null:
		print("[AudioManager] No available SFX players")
		return

	player.stream = stream
	# Apply state-based SFX multiplier for dynamic mixing
	player.volume_db = linear_to_db(sfx_volume * master_volume * _current_sfx_multiplier)

	if pitch_variation > 0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0

	player.play()


func play_sfx_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("[AudioManager] SFX file not found: ", path)
		return

	var stream = load(path) as AudioStream
	if stream:
		play_sfx(stream)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_pool:
		if not player.playing:
			return player
	# All players busy, return first one (will interrupt oldest sound)
	return sfx_pool[0]


func _return_sfx_to_pool(player: AudioStreamPlayer) -> void:
	# Player automatically returns to pool when done
	pass


# =============================================================================
# AMBIENT
# =============================================================================

func _get_active_ambient_player() -> AudioStreamPlayer:
	return ambient_player if active_ambient_player == 0 else ambient_player_secondary


func _get_inactive_ambient_player() -> AudioStreamPlayer:
	return ambient_player_secondary if active_ambient_player == 0 else ambient_player


func play_ambient(stream: AudioStream, fade_in: float = DEFAULT_AMBIENT_FADE) -> void:
	# Check if already playing this stream
	var active = _get_active_ambient_player()
	if active.playing and active.stream == stream:
		return

	var outgoing = _get_active_ambient_player()
	var incoming = _get_inactive_ambient_player()

	if outgoing.playing and fade_in > 0:
		# True crossfade: both ambient tracks play simultaneously
		incoming.stream = stream
		incoming.volume_db = -40.0
		incoming.play()

		# Swap active player
		active_ambient_player = 0 if incoming == ambient_player else 1

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(outgoing, "volume_db", -40.0, fade_in).set_ease(Tween.EASE_IN)
		tween.tween_property(incoming, "volume_db", linear_to_db(ambient_volume * master_volume), fade_in).set_ease(Tween.EASE_OUT)
		tween.set_parallel(false)
		tween.tween_callback(outgoing.stop)
	else:
		incoming.stream = stream
		incoming.volume_db = linear_to_db(ambient_volume * master_volume)
		incoming.play()
		active_ambient_player = 0 if incoming == ambient_player else 1


func stop_ambient(fade_out: float = DEFAULT_AMBIENT_FADE) -> void:
	var active = _get_active_ambient_player()
	var inactive = _get_inactive_ambient_player()

	# Stop inactive player immediately
	if inactive.playing:
		inactive.stop()

	# Fade out active player
	if fade_out > 0 and active.playing:
		var tween = create_tween()
		tween.tween_property(active, "volume_db", -40.0, fade_out).set_ease(Tween.EASE_IN)
		tween.tween_callback(active.stop)
	else:
		active.stop()


## Play ship ambient (kitchen, hallway, stairs, bedroom)
func play_ambient_ship() -> void:
	var path = "res://audio/sfx/ambient_ship_hum.wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			# Ensure loop is enabled for ambient
			if stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			play_ambient(stream)
			print("[AudioManager] Playing ship ambient")
	else:
		print("[AudioManager] Ship ambient not found: ", path)


## Play mindscape ambient (hub, regions)
func play_ambient_mindscape() -> void:
	var path = "res://audio/sfx/ambient_mindscape.wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			# Ensure loop is enabled for ambient
			if stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			play_ambient(stream)
			print("[AudioManager] Playing mindscape ambient")
	else:
		print("[AudioManager] Mindscape ambient not found: ", path)


## Play ambient from a specified path
func play_ambient_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("[AudioManager] Ambient not found: ", path)
		return

	var stream = load(path)
	if stream:
		# Ensure loop is enabled for ambient
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		play_ambient(stream)
		print("[AudioManager] Playing ambient from: ", path)


## Play focus session ambient (space, rain, forest, etc.)
func play_focus_ambient(ambient_type: String) -> void:
	var paths = {
		"space": "res://audio/sfx/ambient_focus_space.wav",
		"ship": "res://audio/sfx/ambient_ship_hum.wav",
		"mindscape": "res://audio/sfx/ambient_mindscape.wav",
		"rain": "res://audio/sfx/ambient_rain.wav",
		"forest": "res://audio/sfx/ambient_forest.wav"
	}

	var path = paths.get(ambient_type, "")
	if path != "" and ResourceLoader.exists(path):
		play_ambient_from_path(path)
	else:
		# Fall back to mindscape ambient
		print("[AudioManager] Focus ambient not found, using mindscape: ", ambient_type)
		play_ambient_mindscape()


# =============================================================================
# VOLUME CONTROL
# =============================================================================

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	is_muted = (master_volume <= 0.01)
	_update_all_volumes()
	_save_volume_settings()


func toggle_mute() -> void:
	if is_muted:
		# Unmute - restore previous volume
		is_muted = false
		master_volume = pre_mute_volume if pre_mute_volume > 0.1 else 0.8
	else:
		# Mute - save current volume and set to 0
		pre_mute_volume = master_volume
		is_muted = true
		master_volume = 0.0
	_update_all_volumes()
	_save_volume_settings()


func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	var target_db = linear_to_db(music_volume * master_volume)
	# Update whichever player is currently active
	if music_player.playing:
		music_player.volume_db = target_db
	if music_player_secondary.playing:
		music_player_secondary.volume_db = target_db
	_save_volume_settings()


func set_voice_volume(value: float) -> void:
	voice_volume = clamp(value, 0.0, 1.0)
	voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	_save_volume_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_save_volume_settings()


func set_ambient_volume(value: float) -> void:
	ambient_volume = clamp(value, 0.0, 1.0)
	var target_db = linear_to_db(ambient_volume * master_volume)
	# Update whichever player is currently active
	if ambient_player.playing:
		ambient_player.volume_db = target_db
	if ambient_player_secondary.playing:
		ambient_player_secondary.volume_db = target_db
	_save_volume_settings()


func _update_all_volumes() -> void:
	var music_db = linear_to_db(music_volume * master_volume)
	var ambient_db = linear_to_db(ambient_volume * master_volume)

	# Update both music players (whichever is playing)
	if music_player.playing:
		music_player.volume_db = music_db
	if music_player_secondary.playing:
		music_player_secondary.volume_db = music_db

	# Update voice player
	voice_player.volume_db = linear_to_db(voice_volume * master_volume)

	# Update both ambient players (whichever is playing)
	if ambient_player.playing:
		ambient_player.volume_db = ambient_db
	if ambient_player_secondary.playing:
		ambient_player_secondary.volume_db = ambient_db


func _save_volume_settings() -> void:
	var settings = {
		"master": master_volume,
		"music": music_volume,
		"voice": voice_volume,
		"sfx": sfx_volume,
		"ambient": ambient_volume
	}
	GameManager.player_data["audio_settings"] = settings


func _load_volume_settings() -> void:
	var settings = GameManager.player_data.get("audio_settings", {})
	master_volume = settings.get("master", 1.0)
	music_volume = settings.get("music", 0.7)
	voice_volume = settings.get("voice", 1.0)
	sfx_volume = settings.get("sfx", 0.8)
	ambient_volume = settings.get("ambient", 0.5)
	_update_all_volumes()


# =============================================================================
# UTILITIES
# =============================================================================

func _get_stream_name(stream: AudioStream) -> String:
	if stream == null:
		return ""
	return stream.resource_path.get_file().get_basename()


# Preload common SFX for instant playback
var _preloaded_sfx: Dictionary = {}

func preload_sfx(name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_preloaded_sfx[name] = load(path)


func play_preloaded_sfx(name: String) -> void:
	if _preloaded_sfx.has(name):
		play_sfx(_preloaded_sfx[name])


# =============================================================================
# UI SOUNDS
# =============================================================================

# UI sound cache
var _ui_sounds: Dictionary = {}

func _init_ui_sounds() -> void:
	# Try to load UI sound files, fall back to generated sounds
	var sound_paths = {
		"click": "res://audio/sfx/ui_click.wav",
		"hover": "res://audio/sfx/ui_hover.wav",
		"confirm": "res://audio/sfx/ui_confirm.wav",
		"cancel": "res://audio/sfx/ui_close.wav",
		"success": "res://audio/sfx/achievement_unlock.wav",
		"error": "res://audio/sfx/ui_error.wav"
	}

	for sound_name in sound_paths:
		var path = sound_paths[sound_name]
		if ResourceLoader.exists(path):
			_ui_sounds[sound_name] = load(path)
		else:
			# Generate procedural sound as fallback
			_ui_sounds[sound_name] = _generate_ui_sound(sound_name)


func _generate_ui_sound(sound_type: String) -> AudioStreamWAV:
	# Generate simple procedural sounds
	var sample_rate = 22050
	var duration = 0.08  # Very short
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)  # 16-bit mono

	var frequency = 440.0
	var volume = 0.3

	match sound_type:
		"click":
			frequency = 800.0
			duration = 0.05
		"hover":
			frequency = 600.0
			duration = 0.03
			volume = 0.15
		"confirm":
			frequency = 880.0
			duration = 0.1
		"cancel":
			frequency = 300.0
			duration = 0.1
		"success":
			frequency = 1000.0
			duration = 0.15
		"error":
			frequency = 200.0
			duration = 0.15

	samples = int(sample_rate * duration)
	data.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / samples)  # Decay envelope
		envelope = envelope * envelope  # Quadratic decay
		var sample_value = sin(t * frequency * TAU) * volume * envelope
		var sample_int = int(sample_value * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data

	return stream


## Play UI click sound
func play_ui_click() -> void:
	if not _ui_sounds.has("click"):
		_init_ui_sounds()
	if _ui_sounds.has("click"):
		play_sfx(_ui_sounds["click"])


## Play UI hover sound
func play_ui_hover() -> void:
	if not _ui_sounds.has("hover"):
		_init_ui_sounds()
	if _ui_sounds.has("hover"):
		play_sfx(_ui_sounds["hover"])


## Play UI confirm sound (positive action)
func play_ui_confirm() -> void:
	if not _ui_sounds.has("confirm"):
		_init_ui_sounds()
	if _ui_sounds.has("confirm"):
		play_sfx(_ui_sounds["confirm"])


## Play UI cancel sound
func play_ui_cancel() -> void:
	if not _ui_sounds.has("cancel"):
		_init_ui_sounds()
	if _ui_sounds.has("cancel"):
		play_sfx(_ui_sounds["cancel"])


## Play success sound (achievement, completion)
func play_ui_success() -> void:
	if not _ui_sounds.has("success"):
		_init_ui_sounds()
	if _ui_sounds.has("success"):
		play_sfx(_ui_sounds["success"])


## Play error sound
func play_ui_error() -> void:
	if not _ui_sounds.has("error"):
		_init_ui_sounds()
	if _ui_sounds.has("error"):
		play_sfx(_ui_sounds["error"])


## Play UI open sound (panel/menu opening)
func play_ui_open() -> void:
	play_sfx_from_path("res://audio/sfx/ui_open.wav")


## Play UI close sound (panel/menu closing)
func play_ui_close() -> void:
	play_sfx_from_path("res://audio/sfx/ui_close.wav")


# =============================================================================
# FOCUS SESSION SOUNDS
# =============================================================================

## Play focus session start sound
func play_focus_start() -> void:
	play_sfx_from_path("res://audio/sfx/focus_start.wav")


## Play focus session complete sound
func play_focus_complete() -> void:
	play_sfx_from_path("res://audio/sfx/focus_complete.wav")


# =============================================================================
# HABIT & PROGRESS SOUNDS
# =============================================================================

## Play habit completion sound
func play_habit_complete() -> void:
	play_sfx_from_path("res://audio/sfx/habit_complete.wav")


## Play streak increase sound
func play_streak_increase() -> void:
	play_sfx_from_path("res://audio/sfx/streak_increase.wav")


# =============================================================================
# MINDSCAPE SOUNDS
# =============================================================================

## Play portal enter sound
func play_portal_enter() -> void:
	play_sfx_from_path("res://audio/sfx/portal_enter.wav")


## Play portal activate sound
func play_portal_activate() -> void:
	play_sfx_from_path("res://audio/sfx/portal_activate.wav")


## Play crystal pulse sound
func play_crystal_pulse() -> void:
	play_sfx_from_path("res://audio/sfx/crystal_pulse.wav")


## Play aspect awaken sound
func play_aspect_awaken() -> void:
	play_sfx_from_path("res://audio/sfx/aspect_awaken.wav")


# =============================================================================
# NOTIFICATION SOUNDS
# =============================================================================

## Play notification sound
func play_notification() -> void:
	play_sfx_from_path("res://audio/sfx/notification.wav")


## Play achievement unlock sound
func play_achievement_unlock() -> void:
	play_sfx_from_path("res://audio/sfx/achievement_unlock.wav")


## Play companion tip sound
func play_companion_tip() -> void:
	play_sfx_from_path("res://audio/sfx/companion_tip.wav")


# =============================================================================
# DYNAMIC AUDIO MIXING SYSTEM
# =============================================================================

## Audio states for different game contexts
enum AudioState {
	EXPLORATION,     # Ship exploration, mindscape wandering
	FOCUS,           # Active focus session
	MEDITATION,      # Meditation exercises (breathing, reflection)
	MENU,            # Pause menu, settings
	CUTSCENE,        # Watching cutscenes
	ACHIEVEMENT,     # Achievement unlock moment
	INTENSE,         # Important moments, ceremonies
	CALM             # Relaxed moments, post-session
}

# Current audio state
var current_audio_state: AudioState = AudioState.EXPLORATION
var previous_audio_state: AudioState = AudioState.EXPLORATION
var state_transition_tween: Tween = null

# Mixing profiles for each audio state
# Each profile defines volume multipliers for different audio channels
const AUDIO_MIXING_PROFILES = {
	AudioState.EXPLORATION: {
		"music_mult": 1.0,
		"ambient_mult": 1.0,
		"sfx_mult": 1.0,
		"low_pass_freq": 20000,  # No filtering
		"reverb": 0.0
	},
	AudioState.FOCUS: {
		"music_mult": 0.6,       # Lower music during focus
		"ambient_mult": 1.3,     # Louder ambient for immersion
		"sfx_mult": 0.7,         # Quieter UI sounds
		"low_pass_freq": 20000,
		"reverb": 0.1
	},
	AudioState.MEDITATION: {
		"music_mult": 0.4,       # Very quiet music
		"ambient_mult": 1.5,     # Enhanced ambient
		"sfx_mult": 0.5,         # Minimal UI sounds
		"low_pass_freq": 8000,   # Subtle warmth filter
		"reverb": 0.3            # Spacious reverb
	},
	AudioState.MENU: {
		"music_mult": 0.8,
		"ambient_mult": 0.3,     # Reduced ambient in menus
		"sfx_mult": 1.2,         # Clearer UI sounds
		"low_pass_freq": 20000,
		"reverb": 0.0
	},
	AudioState.CUTSCENE: {
		"music_mult": 0.35,      # Very low for voice clarity
		"ambient_mult": 0.2,
		"sfx_mult": 0.6,
		"low_pass_freq": 20000,
		"reverb": 0.1
	},
	AudioState.ACHIEVEMENT: {
		"music_mult": 0.5,       # Duck music for achievement fanfare
		"ambient_mult": 0.3,
		"sfx_mult": 1.5,         # Louder achievement sounds
		"low_pass_freq": 20000,
		"reverb": 0.2
	},
	AudioState.INTENSE: {
		"music_mult": 1.2,       # Slightly louder music
		"ambient_mult": 0.8,
		"sfx_mult": 1.1,
		"low_pass_freq": 20000,
		"reverb": 0.15
	},
	AudioState.CALM: {
		"music_mult": 0.7,
		"ambient_mult": 1.2,
		"sfx_mult": 0.8,
		"low_pass_freq": 12000,  # Warmer sound
		"reverb": 0.2
	}
}

# Mood-based volume adjustments (based on player progress)
var mood_music_modifier: float = 1.0    # 0.8 to 1.2 based on mood
var mood_ambient_modifier: float = 1.0

# Transition timing
const STATE_TRANSITION_TIME: float = 1.5
const MOOD_TRANSITION_TIME: float = 3.0

# Signals for state changes
signal audio_state_changed(new_state: AudioState, old_state: AudioState)


## Set the current audio state with smooth transition
func set_audio_state(new_state: AudioState, transition_time: float = STATE_TRANSITION_TIME) -> void:
	if new_state == current_audio_state:
		return

	previous_audio_state = current_audio_state
	current_audio_state = new_state

	print("[AudioManager] Audio state: %s -> %s" % [AudioState.keys()[previous_audio_state], AudioState.keys()[new_state]])

	# Cancel any existing transition
	if state_transition_tween and state_transition_tween.is_valid():
		state_transition_tween.kill()

	# Apply new mixing profile with transition
	_apply_mixing_profile(new_state, transition_time)

	audio_state_changed.emit(new_state, previous_audio_state)


## Get the current audio state
func get_audio_state() -> AudioState:
	return current_audio_state


## Apply a mixing profile with smooth transition
func _apply_mixing_profile(state: AudioState, transition_time: float) -> void:
	var profile = AUDIO_MIXING_PROFILES.get(state, AUDIO_MIXING_PROFILES[AudioState.EXPLORATION])

	# Calculate target volumes with mood modifiers
	var target_music_vol = music_volume * master_volume * profile["music_mult"] * mood_music_modifier
	var target_ambient_vol = ambient_volume * master_volume * profile["ambient_mult"] * mood_ambient_modifier

	var target_music_db = linear_to_db(target_music_vol)
	var target_ambient_db = linear_to_db(target_ambient_vol)

	# Store SFX multiplier for future SFX calls
	_current_sfx_multiplier = profile["sfx_mult"]

	if transition_time <= 0:
		# Instant transition
		if music_player.playing:
			music_player.volume_db = target_music_db
		if music_player_secondary.playing:
			music_player_secondary.volume_db = target_music_db
		if ambient_player.playing:
			ambient_player.volume_db = target_ambient_db
		if ambient_player_secondary.playing:
			ambient_player_secondary.volume_db = target_ambient_db
	else:
		# Smooth transition
		state_transition_tween = create_tween()
		state_transition_tween.set_parallel(true)

		if music_player.playing:
			state_transition_tween.tween_property(music_player, "volume_db", target_music_db, transition_time).set_ease(Tween.EASE_IN_OUT)
		if music_player_secondary.playing:
			state_transition_tween.tween_property(music_player_secondary, "volume_db", target_music_db, transition_time).set_ease(Tween.EASE_IN_OUT)
		if ambient_player.playing:
			state_transition_tween.tween_property(ambient_player, "volume_db", target_ambient_db, transition_time).set_ease(Tween.EASE_IN_OUT)
		if ambient_player_secondary.playing:
			state_transition_tween.tween_property(ambient_player_secondary, "volume_db", target_ambient_db, transition_time).set_ease(Tween.EASE_IN_OUT)


## Current SFX volume multiplier based on audio state
var _current_sfx_multiplier: float = 1.0


## Update mood-based audio modifiers based on player progress
func update_mood_from_progress(mood_data: Dictionary = {}) -> void:
	## mood_data can include:
	## - streak: int (current habit streak)
	## - mood_score: float (from daily check-in, 1-10)
	## - energy_level: float (from daily check-in, 1-10)
	## - focus_minutes_today: int
	## - achievements_recent: int

	var base_music_mod = 1.0
	var base_ambient_mod = 1.0

	# Adjust based on streak (higher streak = slightly more upbeat)
	var streak = mood_data.get("streak", 0)
	if streak >= 7:
		base_music_mod += 0.1
	elif streak >= 3:
		base_music_mod += 0.05

	# Adjust based on mood score (from daily check-in)
	var mood_score = mood_data.get("mood_score", 5.0)
	if mood_score >= 8:
		base_music_mod += 0.1
		base_ambient_mod += 0.05
	elif mood_score <= 3:
		base_music_mod -= 0.1
		base_ambient_mod += 0.1  # More ambient for calming

	# Adjust based on energy level
	var energy = mood_data.get("energy_level", 5.0)
	if energy >= 8:
		base_music_mod += 0.05
	elif energy <= 3:
		base_ambient_mod += 0.1  # More ambient for low energy

	# Adjust based on recent achievements
	var achievements = mood_data.get("achievements_recent", 0)
	if achievements >= 3:
		base_music_mod += 0.1

	# Clamp values
	base_music_mod = clamp(base_music_mod, 0.8, 1.2)
	base_ambient_mod = clamp(base_ambient_mod, 0.8, 1.3)

	# Smooth transition to new mood values
	_transition_mood_modifiers(base_music_mod, base_ambient_mod)


## Smoothly transition mood modifiers
func _transition_mood_modifiers(target_music: float, target_ambient: float) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "mood_music_modifier", target_music, MOOD_TRANSITION_TIME)
	tween.tween_property(self, "mood_ambient_modifier", target_ambient, MOOD_TRANSITION_TIME)

	# Re-apply current profile with new mood modifiers
	tween.set_parallel(false)
	tween.tween_callback(func(): _apply_mixing_profile(current_audio_state, 0.5))


## Convenience methods for common state transitions

func enter_focus_mode() -> void:
	set_audio_state(AudioState.FOCUS)


func exit_focus_mode() -> void:
	set_audio_state(AudioState.EXPLORATION)


func enter_meditation_mode() -> void:
	set_audio_state(AudioState.MEDITATION)


func exit_meditation_mode() -> void:
	set_audio_state(AudioState.CALM, 2.0)  # Gentle transition to calm


func enter_menu() -> void:
	set_audio_state(AudioState.MENU, 0.5)  # Quick transition


func exit_menu() -> void:
	set_audio_state(previous_audio_state, 0.5)


func enter_cutscene() -> void:
	set_audio_state(AudioState.CUTSCENE)


func exit_cutscene() -> void:
	set_audio_state(AudioState.EXPLORATION)


func trigger_achievement_moment(duration: float = 3.0) -> void:
	## Temporarily switch to achievement state, then return
	var return_state = current_audio_state
	set_audio_state(AudioState.ACHIEVEMENT, 0.3)

	# Schedule return to previous state
	await get_tree().create_timer(duration).timeout
	if current_audio_state == AudioState.ACHIEVEMENT:
		set_audio_state(return_state, 1.0)


func enter_intense_moment() -> void:
	set_audio_state(AudioState.INTENSE, 0.5)


func exit_intense_moment() -> void:
	set_audio_state(AudioState.EXPLORATION)


## Temporary audio adjustments (for specific moments)

var _temporary_volume_tween: Tween = null

func temporarily_duck_all(duck_amount: float = 0.3, duration: float = 2.0, fade_time: float = 0.3) -> void:
	## Temporarily lower all audio volumes
	if _temporary_volume_tween and _temporary_volume_tween.is_valid():
		_temporary_volume_tween.kill()

	var original_music_db = music_player.volume_db if music_player.playing else -40.0
	var original_ambient_db = ambient_player.volume_db if ambient_player.playing else -40.0

	var ducked_music_db = original_music_db + linear_to_db(duck_amount)
	var ducked_ambient_db = original_ambient_db + linear_to_db(duck_amount)

	_temporary_volume_tween = create_tween()

	# Duck down
	_temporary_volume_tween.set_parallel(true)
	if music_player.playing:
		_temporary_volume_tween.tween_property(music_player, "volume_db", ducked_music_db, fade_time)
	if music_player_secondary.playing:
		_temporary_volume_tween.tween_property(music_player_secondary, "volume_db", ducked_music_db, fade_time)
	if ambient_player.playing:
		_temporary_volume_tween.tween_property(ambient_player, "volume_db", ducked_ambient_db, fade_time)
	if ambient_player_secondary.playing:
		_temporary_volume_tween.tween_property(ambient_player_secondary, "volume_db", ducked_ambient_db, fade_time)

	# Wait
	_temporary_volume_tween.set_parallel(false)
	_temporary_volume_tween.tween_interval(duration)

	# Restore
	_temporary_volume_tween.set_parallel(true)
	if music_player.playing:
		_temporary_volume_tween.tween_property(music_player, "volume_db", original_music_db, fade_time)
	if music_player_secondary.playing:
		_temporary_volume_tween.tween_property(music_player_secondary, "volume_db", original_music_db, fade_time)
	if ambient_player.playing:
		_temporary_volume_tween.tween_property(ambient_player, "volume_db", original_ambient_db, fade_time)
	if ambient_player_secondary.playing:
		_temporary_volume_tween.tween_property(ambient_player_secondary, "volume_db", original_ambient_db, fade_time)


func temporarily_boost_music(boost_amount: float = 1.3, duration: float = 5.0, fade_time: float = 0.5) -> void:
	## Temporarily boost music volume (for impactful moments)
	if _temporary_volume_tween and _temporary_volume_tween.is_valid():
		_temporary_volume_tween.kill()

	var active_player = _get_active_music_player()
	if not active_player.playing:
		return

	var original_db = active_player.volume_db
	var boosted_db = original_db + linear_to_db(boost_amount)

	_temporary_volume_tween = create_tween()

	# Boost up
	_temporary_volume_tween.tween_property(active_player, "volume_db", boosted_db, fade_time)

	# Wait
	_temporary_volume_tween.tween_interval(duration)

	# Restore
	_temporary_volume_tween.tween_property(active_player, "volume_db", original_db, fade_time)


## Auto-update mood from GameManager data
func refresh_mood_from_game_state() -> void:
	var mood_data = {}

	# Get streak
	var habit_manager = get_node_or_null("/root/HabitManager")
	if habit_manager and habit_manager.has_method("get_current_streak"):
		mood_data["streak"] = habit_manager.get_current_streak()
	else:
		mood_data["streak"] = GameManager.player_data.get("current_streak", 0)

	# Get mood/energy from daily check-in
	var today = Time.get_date_string_from_system()
	var checkins = GameManager.player_data.get("daily_checkins", {})
	if checkins.has(today):
		var today_checkin = checkins[today]
		mood_data["mood_score"] = today_checkin.get("mood", 5.0)
		mood_data["energy_level"] = today_checkin.get("energy", 5.0)

	# Get focus minutes today
	var focus_sessions = GameManager.player_data.get("focus_sessions", [])
	var focus_today = 0
	for session in focus_sessions:
		if session.get("date", "") == today:
			focus_today += session.get("duration", 0)
	mood_data["focus_minutes_today"] = focus_today

	# Get recent achievements (last 24 hours)
	var recent_achievements = 0
	var achievements = GameManager.player_data.get("achievements_unlocked", [])
	var now = Time.get_unix_time_from_system()
	for achievement in achievements:
		if achievement is Dictionary and achievement.has("timestamp"):
			if now - achievement["timestamp"] < 86400:  # 24 hours
				recent_achievements += 1
	mood_data["achievements_recent"] = recent_achievements

	update_mood_from_progress(mood_data)
