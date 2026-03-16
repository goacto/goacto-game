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
	player.volume_db = linear_to_db(sfx_volume * master_volume)

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
