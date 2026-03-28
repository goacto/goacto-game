# Building a Self-Improvement RPG with Godot 4.6
## A Complete Textbook: From Beginner to Expert

> **Application**: Mindscape by GOACTO
> **Engine**: Godot 4.6 (Mobile Renderer)
> **Language**: GDScript
> **Last Updated**: March 2026

---

## Table of Contents

### Part I: Foundations (101-Level)
1. [Chapter 1: Game Engine Basics](#chapter-1-game-engine-basics)
2. [Chapter 2: GDScript Fundamentals](#chapter-2-gdscript-fundamentals)
3. [Chapter 3: Scenes and Nodes](#chapter-3-scenes-and-nodes)
4. [Chapter 4: Input Handling](#chapter-4-input-handling)
5. [Chapter 5: Basic UI with Controls](#chapter-5-basic-ui-with-controls)

### Part II: Architecture (201-Level)
6. [Chapter 6: The Autoload/Singleton Pattern](#chapter-6-the-autoloadsingleton-pattern)
7. [Chapter 7: Signal-Based Communication](#chapter-7-signal-based-communication)
8. [Chapter 8: State Machines](#chapter-8-state-machines)
9. [Chapter 9: Scene Management and Transitions](#chapter-9-scene-management-and-transitions)
10. [Chapter 10: Data Persistence with JSON](#chapter-10-data-persistence-with-json)

### Part III: Core Systems (301-Level)
11. [Chapter 11: Player Movement Systems](#chapter-11-player-movement-systems)
12. [Chapter 12: Camera and Viewport](#chapter-12-camera-and-viewport)
13. [Chapter 13: Audio Management](#chapter-13-audio-management)
14. [Chapter 14: Procedural 2D Graphics](#chapter-14-procedural-2d-graphics)
15. [Chapter 15: Dialog and Narrative Systems](#chapter-15-dialog-and-narrative-systems)

### Part IV: Game Systems (401-Level)
16. [Chapter 16: Habit Tracking System](#chapter-16-habit-tracking-system)
17. [Chapter 17: Focus Session Timer](#chapter-17-focus-session-timer)
18. [Chapter 18: Achievement and Trophy System](#chapter-18-achievement-and-trophy-system)
19. [Chapter 19: Campaign and Progression](#chapter-19-campaign-and-progression)
20. [Chapter 20: Shop and Economy](#chapter-20-shop-and-economy)

### Part V: Advanced Topics (501-Level)
21. [Chapter 21: Cross-Platform Deployment](#chapter-21-cross-platform-deployment)
22. [Chapter 22: Web Export and Browser APIs](#chapter-22-web-export-and-browser-apis)
23. [Chapter 23: Mobile Touch Controls](#chapter-23-mobile-touch-controls)
24. [Chapter 24: Save File Import/Export](#chapter-24-save-file-importexport)
25. [Chapter 25: Performance and Optimization](#chapter-25-performance-and-optimization)

---

## Part I: Foundations (101-Level)

---

### Chapter 1: Game Engine Basics

#### 1.1 What is Godot?

Godot is an open-source game engine that provides a complete set of tools for 2D and 3D game development. This project uses **Godot 4.6** with the **Mobile renderer**, optimized for cross-platform deployment.

#### 1.2 Project Configuration

Every Godot project starts with `project.godot`, the master configuration file:

```ini
# From godot/project.godot
config_version=5

[application]
config/name="Mindscape"
config/description="Grow your inner world through real-world action"
config/version="0.1.0"
run/main_scene="res://scenes/main_menu/main_menu.tscn"
config/features=PackedStringArray("4.6", "Mobile")

[display]
window/size/viewport_width=1366
window/size/viewport_height=768
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
renderer/rendering_method="mobile"
```

**Key concepts:**
- `run/main_scene` defines the entry point of your game
- `window/stretch/mode="canvas_items"` scales UI elements with the window
- `window/stretch/aspect="expand"` allows the viewport to expand on wider screens
- The `mobile` renderer is lighter than `forward_plus` and works on all platforms

#### 1.3 Project Structure

A well-organized project separates concerns into directories:

```
godot/
├── autoload/          # 17 global singleton managers
├── scenes/            # 27+ scene directories organized by feature
│   ├── main_menu/
│   ├── bedroom/
│   ├── ship/          # 9 ship room scenes
│   ├── mindscape/     # 7 mindscape region scenes
│   ├── focus_chamber/
│   ├── focus_mode/
│   ├── combat/
│   ├── transition/
│   └── settings/
├── scripts/           # Shared utility scripts
├── assets/            # Sprites, backgrounds, fonts, shaders
├── audio/             # SFX, music, voice (organized by scene)
└── resources/         # Godot .tres resource files
```

**Why this matters:** As projects grow (this one has 48+ GDScript files), organization prevents chaos. Group files by *feature*, not by *type*.

#### 1.4 The Resource Path System

Godot uses `res://` for project-relative paths and `user://` for user data:

```gdscript
# Project resources (read-only after export)
var scene = load("res://scenes/bedroom/bedroom.tscn")
var sound = load("res://audio/sfx/click.wav")

# User data (writable - saves, settings)
var file = FileAccess.open("user://mindscape_save.json", FileAccess.WRITE)
```

On different platforms, `user://` maps to:
- **Desktop**: `~/.local/share/godot/app_userdata/` (Linux) or `~/Library/Application Support/` (macOS)
- **Web**: Browser IndexedDB (requires explicit sync!)
- **Mobile**: App-specific sandboxed storage

---

### Chapter 2: GDScript Fundamentals

#### 2.1 Script Structure

Every GDScript file extends a node type and can define variables, signals, and functions:

```gdscript
extends Node
## GameManager - Global game state singleton
## Manages overall game state, scene transitions, and coordinates between systems

# Constants
const VERSION: String = "v0.1.0-prototype"
const BUILD_TIMESTAMP: String = "20260328-042518"

# Enums
enum GameState {
    MAIN_MENU,
    MINDSCAPE,
    FOCUS_MODE,
    COMBAT,
    DIALOGUE,
    PAUSED
}

# Signals
signal state_changed(new_state, old_state)
signal world_evolution_triggered(amount)
signal aspect_leveled_up(aspect_name, new_level)

# Variables
var current_state: GameState = GameState.MAIN_MENU
var player_data: Dictionary = {}

# Lifecycle functions
func _ready() -> void:
    # Called when node enters the scene tree
    pass

func _process(delta: float) -> void:
    # Called every frame
    pass
```

#### 2.2 Naming Conventions

This project follows consistent naming:

```gdscript
# Variables: snake_case
var player_data = {}
var current_streak = 0

# Constants: SCREAMING_SNAKE_CASE
const MAX_GRACE_DAYS = 3
const DEFAULT_SESSION_MINUTES = 25

# Signals: past_tense or descriptive noun
signal habit_completed(habit_id, habit_data)
signal streak_recovered(habit_id, grace_days_used)

# Functions: snake_case, verb-first
func complete_habit(habit_id: String) -> bool:
func get_habit_by_id(id: String) -> Dictionary:
func is_zone_unlocked(zone_id: String) -> bool:

# Private functions: underscore prefix
func _check_daily_reset() -> void:
func _calculate_garden_growth(stats: Dictionary) -> int:
```

#### 2.3 Type System

GDScript supports optional static typing. This project uses it extensively for clarity:

```gdscript
# Typed variables
var player_speed: float = 280.0
var player_bounds: Rect2 = Rect2(-680, -540, 1360, 1080)
var habits: Dictionary = {}
var streak_flames: Array = []

# Typed function signatures
func add_aspect_experience(aspect_id: String, exp: int) -> void:
func get_slot_info(slot: int) -> Dictionary:
func is_zone_unlocked(zone_id: String) -> bool:

# Enum typing
var current_state: GameState = GameState.MAIN_MENU
```

#### 2.4 Common Gotcha: JSON Deserialization Types

When loading data from JSON files, **all numbers become floats**:

```gdscript
# JSON stores: {"total_login_days": 5}
# After parsing: total_login_days is 5.0 (float), not 5 (int)

# This CRASHES: float % int is invalid in GDScript
var day = (player_data.total_login_days - 1) % 30  # ERROR!

# Fix: always cast to int when doing integer operations
var day = (int(player_data.total_login_days) - 1) % 30  # OK

# Also fix at load time:
func _ensure_login_data() -> void:
    if player_data.has("total_login_days"):
        player_data["total_login_days"] = int(player_data["total_login_days"])
```

#### 2.5 Null Safety

GDScript uses `null` (displayed as `Nil` in errors). A common crash pattern:

```gdscript
# CRASHES if get_item() returns null:
var item = ShopManager.get_item(item_id)
if item.is_empty():  # "Nonexistent function 'is_empty' in base 'Nil'"
    return

# SAFE pattern:
var item = ShopManager.get_item(item_id)
if not item or (item is Dictionary and item.is_empty()):
    return
```

---

### Chapter 3: Scenes and Nodes

#### 3.1 The Scene Tree

Godot's architecture is built on a tree of nodes. Every game object is a node, and scenes are reusable branches:

```
Main Menu (Control)
├── Background (ColorRect)
├── Title (Label)
├── ButtonContainer (VBoxContainer)
│   ├── NewGameButton (Button)
│   ├── ContinueButton (Button)
│   └── LoadButton (Button)
└── VersionLabel (Label)
```

#### 3.2 Scene Files (.tscn)

Scenes are saved as text-based `.tscn` files:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/transition/headset_transition.gd" id="1_transition"]

[node name="HeadsetTransition" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_transition")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.02, 0.04, 0.08, 1)
```

**Key points:**
- `parent="."` means the node is a child of the root
- `anchors_preset = 15` means `PRESET_FULL_RECT` (fills parent)
- Resources are loaded via `ExtResource()` references

#### 3.3 Dynamic Node Creation

This project creates most UI elements programmatically rather than in the editor:

```gdscript
# Creating a styled button dynamically
var btn = Button.new()
btn.text = "Start Focus Session"
btn.custom_minimum_size = Vector2(0, 55)
btn.add_theme_font_size_override("font_size", 20)
btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
btn.pressed.connect(func(): _start_session())
container.add_child(btn)
```

**Why dynamic over editor?** When UI is data-driven (shop items, habit lists, save slots), building it in code is more flexible than pre-building in the editor.

#### 3.4 Scene Inheritance with Base Classes

Shared behavior is extracted into base classes:

```gdscript
# godot/scenes/ship/ship_scene_base.gd
extends Control
## Base class for all ship room scenes

var player: Node2D
var player_speed: float = 280.0
var player_bounds: Rect2

func _handle_movement(delta: float) -> void:
    var input_dir = Vector2.ZERO
    if Input.is_action_pressed("move_up"): input_dir.y -= 1
    if Input.is_action_pressed("move_down"): input_dir.y += 1
    if Input.is_action_pressed("move_left"): input_dir.x -= 1
    if Input.is_action_pressed("move_right"): input_dir.x += 1

    if input_dir != Vector2.ZERO:
        input_dir = input_dir.normalized()
        # Cardinal movement (W=up, S=down, A=left, D=right)
        var new_pos = player.position + input_dir * player_speed * delta
        # Clamp to bounds
        new_pos.x = clamp(new_pos.x, player_bounds.position.x, ...)
        player.position = new_pos
```

Each ship room (kitchen.gd, hallway.gd, etc.) inherits from this base and customizes as needed.

---

### Chapter 4: Input Handling

#### 4.1 Input Actions

Input actions are defined in `project.godot` and referenced by name:

```ini
[input]
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,...,"physical_keycode":87)]
}
move_down={...physical_keycode:83...}  # S key
move_left={...physical_keycode:65...}  # A key
move_right={...physical_keycode:68...} # D key
```

```gdscript
# Using input actions (platform-agnostic)
if Input.is_action_pressed("move_up"):
    input_dir.y -= 1

# Touch emulation setting allows mouse to simulate touch
[input_devices]
pointing/emulate_touch_from_mouse=true
```

#### 4.2 Cardinal vs Isometric Movement

A key architectural decision: this game uses **cardinal movement** (up/down/left/right) rather than isometric diagonal movement:

```gdscript
# Cardinal movement - intuitive for players
var new_pos = player.position + input_dir * player_speed * delta

# vs. Isometric movement (removed) - confusing for players
# W moved up-left, S moved down-right, etc.
# var iso_movement = Vector2(
#     input_dir.x + input_dir.y,
#     (input_dir.y - input_dir.x) * 0.5
# )
```

**Lesson learned:** Even in a 2.5D isometric-looking game, cardinal movement is more intuitive. The visual style can be isometric while input remains cardinal.

#### 4.3 Multi-Input Support

The game supports keyboard, mouse/touch, and virtual joystick simultaneously:

```gdscript
func _physics_process(delta: float) -> void:
    var input_direction = Vector2.ZERO

    # Keyboard input (WASD and arrow keys)
    if Input.is_action_pressed("move_right"): input_direction.x += 1
    if Input.is_action_pressed("move_left"): input_direction.x -= 1
    if Input.is_action_pressed("move_down"): input_direction.y += 1
    if Input.is_action_pressed("move_up"): input_direction.y -= 1

    # Virtual joystick overrides keyboard
    if joystick_input != Vector2.ZERO:
        input_direction = joystick_input

    # Keyboard/joystick takes priority over tap-to-move
    if input_direction != Vector2.ZERO:
        has_target = false
        velocity = input_direction.normalized() * SPEED
    elif has_target:
        # Tap-to-move fallback
        var direction = (target_position - global_position)
        if direction.length() > 10:
            velocity = direction.normalized() * SPEED

    move_and_slide()
```

---

### Chapter 5: Basic UI with Controls

#### 5.1 Layout Containers

Godot's UI system uses containers for automatic layout:

```gdscript
# Vertical list of items
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 12)

# Horizontal row of buttons
var hbox = HBoxContainer.new()
hbox.alignment = BoxContainer.ALIGNMENT_CENTER
hbox.add_theme_constant_override("separation", 15)

# Scrollable content
var scroll = ScrollContainer.new()
scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

# Grid layout (e.g., shop items)
var grid = GridContainer.new()
grid.columns = 4
grid.add_theme_constant_override("h_separation", 15)
grid.add_theme_constant_override("v_separation", 15)
```

#### 5.2 Styling with StyleBoxFlat

Custom panel appearances are created with StyleBoxFlat:

```gdscript
var style = StyleBoxFlat.new()
style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
style.border_color = Color(0.5, 0.4, 0.7, 0.6)
style.set_border_width_all(2)
style.set_corner_radius_all(12)
panel.add_theme_stylebox_override("panel", style)
```

#### 5.3 Anchors and Positioning

Controls use anchors to respond to screen resizing:

```gdscript
# Center on screen
panel.set_anchors_preset(Control.PRESET_CENTER)
panel.offset_left = -300
panel.offset_right = 300
panel.offset_top = -200
panel.offset_bottom = 200

# Full screen coverage
overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

# Bottom-center
prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
```

#### 5.4 Z-Index Layering

When elements overlap, z_index controls render order:

```gdscript
# Game world elements
window.z_index = 10       # Wall-mounted, above player
lock_icon.z_index = 5     # Floating above objects

# UI panels must be above game world elements
dialogue_panel.z_index = 20
save_panel.z_index = 20

# System overlays (always on top)
# GameManager's version overlay: CanvasLayer.layer = 100
# GameManager's transition overlay: CanvasLayer.layer = 100
```

**Important:** CanvasLayer nodes render independently of the scene tree's z_index. A CanvasLayer at layer 100 is always above everything in the default canvas.

---

## Part II: Architecture (201-Level)

---

### Chapter 6: The Autoload/Singleton Pattern

#### 6.1 What Are Autoloads?

Autoloads are scripts that Godot loads once at startup and keeps alive across all scene changes. They act as global singletons:

```ini
# project.godot autoload registration
[autoload]
ThemeConfig="*res://autoload/ThemeConfig.gd"
CampaignManager="*res://autoload/CampaignManager.gd"
GameManager="*res://autoload/GameManager.gd"
HabitManager="*res://autoload/HabitManager.gd"
SaveManager="*res://autoload/SaveManager.gd"
AudioManager="*res://autoload/AudioManager.gd"
# ... 17 total
```

The `*` prefix means "auto-start" - the node is created automatically.

#### 6.2 Load Order Matters

Autoloads initialize top-to-bottom. This project's order is deliberate:

1. **ThemeConfig** - Colors/constants (no dependencies)
2. **CampaignManager** - Story state
3. **GameManager** - Core state (may reference CampaignManager)
4. **HabitManager** - Habits (references GameManager for XP rewards)
5. **SaveManager** - Persistence (references all managers)
6. **AudioManager** - Sound (independent)
7. ... etc.

**Rule:** If Manager A references Manager B, B must load first.

#### 6.3 Manager Pattern

Each manager follows a consistent pattern:

```gdscript
extends Node
## HabitManager - Habit tracking, streaks, grace day recovery

# Signals for external communication
signal habit_completed(habit_id, habit_data)
signal habit_streak_updated(habit_id, streak)

# Internal state
var habits: Dictionary = {}
var topics: Dictionary = {}

# Public API
func create_habit(data: Dictionary) -> String: ...
func complete_habit(habit_id: String) -> bool: ...
func get_all_habits() -> Array: ...

# Save/Load interface (every manager implements this)
func get_save_data() -> Dictionary:
    return {
        "habits": habits,
        "topics": topics,
        # ...
    }

func load_save_data(data: Dictionary) -> void:
    if data.has("habits"): habits = data.habits
    if data.has("topics"): topics = data.topics
```

#### 6.4 Accessing Autoloads

Autoloads are accessible by name from anywhere:

```gdscript
# Direct access (the autoload name IS the variable)
GameManager.player_data["world_evolution_level"]
HabitManager.complete_habit("exercise")
SaveManager.save_game()
AudioManager.play_sfx(sound)

# Safe access (for optional managers)
var audio = get_node_or_null("/root/AudioManager")
if audio and audio.has_method("play_voice"):
    audio.play_voice(path)
```

---

### Chapter 7: Signal-Based Communication

#### 7.1 Why Signals?

Signals provide **loose coupling** between systems. A habit completion triggers XP rewards, achievement checks, campaign progress, and auto-save - but HabitManager doesn't need to know about any of those systems:

```gdscript
# HabitManager just emits:
habit_completed.emit(habit_id, habit_data)

# Multiple systems connect and react independently:
# GameManager._on_habit_completed -> awards XP, evolves world
# AchievementManager._on_habit_completed -> checks achievement conditions
# CampaignManager._on_habit_completed -> checks chapter requirements
# SaveManager auto-saves
```

#### 7.2 Signal Declaration and Emission

```gdscript
# Declaration (at class level)
signal habit_completed(habit_id: String, habit_data: Dictionary)
signal streak_recovered(habit_id: String, grace_days_used: int)

# Emission (when event occurs)
func complete_habit(habit_id: String) -> bool:
    # ... completion logic ...
    habit_completed.emit(habit_id, habit_data)
    return true
```

#### 7.3 Connection Patterns

```gdscript
# Named function connection
HabitManager.habit_completed.connect(_on_habit_completed)

func _on_habit_completed(habit_id: String, habit_data: Dictionary) -> void:
    add_aspect_experience(domain_to_aspect[habit_data.domain], habit_data.exp_reward)

# Lambda connection (for simple callbacks)
btn.pressed.connect(func(): _start_session())

# One-shot connection
timer.timeout.connect(func(): _complete(), CONNECT_ONE_SHOT)

# Bound parameters
delete_btn.pressed.connect(_confirm_delete.bind(topic_id, topic_name))
```

---

### Chapter 8: State Machines

#### 8.1 Enum-Based State Machine

```gdscript
# GameManager.gd
enum GameState {
    MAIN_MENU,
    MINDSCAPE,
    FOCUS_MODE,
    COMBAT,
    DIALOGUE,
    PAUSED
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

func change_state(new_state: GameState) -> void:
    if new_state == current_state:
        return
    previous_state = current_state
    current_state = new_state
    state_changed.emit(new_state, previous_state)
```

#### 8.2 Scene-Level State

Individual scenes use simpler state tracking:

```gdscript
# Focus chamber step progression
enum Step { DURATION_DIFFICULTY, FOCUS_SELECTION, ACTIVE_SESSION, REFLECTION }
var current_step: Step = Step.DURATION_DIFFICULTY

func _show_step(step: Step) -> void:
    current_step = step
    _clear_content()
    match step:
        Step.DURATION_DIFFICULTY: _build_duration_step()
        Step.FOCUS_SELECTION: _build_focus_selection_step()
        Step.ACTIVE_SESSION: _build_active_session()
        Step.REFLECTION: _build_reflection_step()
```

---

### Chapter 9: Scene Management and Transitions

#### 9.1 Scene Transitions with Fade

GameManager provides a global fade transition system:

```gdscript
# GameManager creates a CanvasLayer overlay at layer 100
func _create_transition_overlay() -> void:
    transition_overlay = CanvasLayer.new()
    transition_overlay.layer = 100  # Above everything
    transition_rect = ColorRect.new()
    transition_rect.color = Color(0.02, 0.03, 0.06, 0.0)  # Transparent
    transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

func goto_scene(scene_path: String) -> void:
    # Fade out
    var tween = create_tween()
    tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
    tween.tween_callback(func():
        get_tree().change_scene_to_file(scene_path)
        # Fade in (0.8s smooth cubic ease)
        var fade_in = create_tween()
        fade_in.tween_interval(0.15)
        fade_in.tween_property(transition_rect, "color:a", 0.0, 0.8)
            .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    )
```

#### 9.2 Themed Transitions

The headset transition creates an immersive VR headset animation for entering/exiting the mindscape:

```gdscript
# Enter: hands raise headset from below → lenses darken → portal animation
# Exit: portal animation → headset lifts away → hands catch it

# Phase system:
# Enter: 0=headset_on, 1=portal_fade_in, 2=hold, 3=portal_fade_out
# Exit:  0=portal_fade_in, 1=hold, 2=portal_fade_out, 3=headset_off
```

The headset is built from Polygon2D nodes: frame mask with lens cutouts, foam padding rings, nose bridge, head straps, and blocky character-style hands gripping the sides.

---

### Chapter 10: Data Persistence with JSON

#### 10.1 Save Architecture

```gdscript
# SaveManager aggregates all manager data into one JSON file
func save_game() -> void:
    var save_data = {
        "version": "0.3.2",
        "timestamp": Time.get_unix_time_from_system(),
        "player": GameManager.player_data,
        "habits": HabitManager.get_save_data(),
        "goals": GoalManager.get_save_data(),
        "scripts": ScriptManager.get_save_data(),
        "challenges": ChallengeManager.get_save_data(),
        "achievements": AchievementManager.get_save_data(),
        "campaign": CampaignManager.get_save_data(),
        "shop": ShopManager.get_save_data(),
        "mail": MailManager.get_save_data(),
        "relationships": RelationshipManager.get_save_data()
    }

    var json_string = JSON.stringify(save_data, "\t")
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(json_string)
    file.close()

    # CRITICAL for web: sync to IndexedDB
    _sync_web_filesystem()
```

#### 10.2 Web Filesystem Sync

On web, Godot uses Emscripten's virtual filesystem backed by IndexedDB. Writes are buffered and **can be lost if the tab closes before sync**:

```gdscript
func _sync_web_filesystem() -> void:
    if OS.get_name() == "Web":
        JavaScriptBridge.eval(
            "if (typeof FS !== 'undefined' && FS.syncfs) { " +
            "FS.syncfs(false, function(err) { " +
            "if (err) console.warn('FS sync error:', err); }); }"
        )
```

#### 10.3 Multi-Slot Save System

```gdscript
const SAVE_PATH = "user://mindscape_save.json"  # Auto-save

func save_to_slot(slot: int, custom_name: String = "") -> bool:
    var path = "user://mindscape_save_slot_%d.json" % slot
    # ... save with slot metadata ...

func get_slot_info(slot: int) -> Dictionary:
    # Returns preview metadata without loading full save
    return {
        "exists": true,
        "slot_name": "My Journey",
        "date_string": "2026-03-28",
        "evolution_level": 15.5,
        "focus_sessions": 42
    }
```

#### 10.4 Import/Export for Portability

The save system supports multiple transfer methods:

```gdscript
# File download (web: browser download, desktop: Downloads folder)
func _download_save_file() -> void:
    var json = SaveManager.export_save_data()
    if OS.get_name() == "Web":
        # JavaScript Blob download
        JavaScriptBridge.eval("""
        (function() {
            var blob = new Blob([...], {type: 'application/json'});
            var a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = 'mindscape_save.json';
            a.click();
        })();
        """)
    else:
        # Native file write to Downloads
        var file = FileAccess.open(path, FileAccess.WRITE)
        file.store_string(json)

# File upload (web: <input type="file">, desktop: FileDialog)
# Clipboard copy/paste as fallback
```

---

## Part III: Core Systems (301-Level)

---

### Chapter 11: Player Movement Systems

#### 11.1 Bounded Movement with Regions

The bedroom uses a plus-shaped walkable area:

```gdscript
func _clamp_to_plus_bounds(pos: Vector2, current_pos: Vector2) -> Vector2:
    # Plus-shaped floor bounds:
    # Top arm: x from -180 to 180, y from -540 to -180
    # Center bar: x from -680 to 680, y from -180 to 180
    # Bottom arm: x from -180 to 180, y from 180 to 540

    var current_region = "center"
    if current_pos.y < -180 and current_pos.x >= -180 and current_pos.x <= 180:
        current_region = "top"
    elif current_pos.y > 180 and current_pos.x >= -180 and current_pos.x <= 180:
        current_region = "bottom"

    match current_region:
        "top":
            if pos.y >= -180:
                result.x = clamp(pos.x, -680, 680)  # Transition to center
            else:
                result.x = clamp(pos.x, -180, 180)  # Stay in narrow arm
        # ... etc
```

#### 11.2 Movement Sound Design

```gdscript
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.3

# In movement handler:
if input_dir != Vector2.ZERO:
    move_sound_timer += delta
    if move_sound_timer >= move_sound_interval:
        move_sound_timer = 0.0
        _play_sfx("res://audio/sfx/hover_move.wav", -12.0)  # Quiet footsteps
else:
    move_sound_timer = 0.0  # Reset when stopped
```

---

### Chapter 12: Camera and Viewport

#### 12.1 Pseudo-Camera System

Instead of a Camera2D node, this project moves the isometric base:

```gdscript
func _update_camera() -> void:
    var screen_center = game_world.size / 2
    var target_pos = screen_center - (player.position * camera_zoom)
    isometric_base.position = target_pos
    isometric_base.scale = Vector2(camera_zoom, camera_zoom)

func _apply_zoom(amount: float) -> void:
    camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
    _update_camera()
```

This approach gives full control over the view without Camera2D's built-in smoothing.

---

### Chapter 13: Audio Management

#### 13.1 Multi-Channel Audio System

```gdscript
# AudioManager provides separate channels:
# - Music (with crossfade between 2 players)
# - Voice (with automatic music ducking)
# - Ambient (with crossfade)
# - SFX pool (8 simultaneous sounds)

func play_voice(path: String) -> void:
    # Auto-duck music to 50% while voice plays
    _duck_music()
    voice_player.stream = load(path)
    voice_player.play()
    voice_player.finished.connect(_unduck_music, CONNECT_ONE_SHOT)

func crossfade_to(path: String, duration: float = 2.0) -> void:
    # Smooth transition between music tracks
    music_secondary.stream = load(path)
    music_secondary.play()
    var tween = create_tween()
    tween.tween_property(music_primary, "volume_db", -80, duration)
    tween.parallel().tween_property(music_secondary, "volume_db", 0, duration)
```

---

### Chapter 14: Procedural 2D Graphics

#### 14.1 Polygon2D-Based Visuals

This entire game uses no sprite images for characters or UI - everything is built from Polygon2D shapes:

```gdscript
# Player character (from .tscn):
# Body: trapezoid shape
polygon = PackedVector2Array([-18, 35], [-18, 0], [-12, -20],
                              [12, -20], [18, 0], [18, 35])
color = Color(0.83, 0.66, 0.29)  # Gold

# Head: rectangle
polygon = PackedVector2Array([-14, 10], [-14, -10], [14, -10], [14, 10])

# Antenna tip: diamond
polygon = PackedVector2Array([-4, 0], [0, -6], [4, 0], [0, 4])
```

#### 14.2 Dynamic Polygon Generation

```gdscript
# Create a circle from polygon points
func _create_circle(radius: float, segments: int) -> PackedVector2Array:
    var points = PackedVector2Array()
    for i in range(segments):
        var angle = i * TAU / segments
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    return points

# Create an oval ring (for foam padding, etc.)
func _create_oval_ring(cx, cy, inner_rx, inner_ry, outer_rx, outer_ry, color, segments):
    for i in range(segments):
        var a1 = (float(i) / segments) * TAU
        var a2 = (float(i + 1) / segments) * TAU
        var quad = Polygon2D.new()
        quad.polygon = PackedVector2Array([
            Vector2(cx + cos(a1) * outer_rx, cy + sin(a1) * outer_ry),
            Vector2(cx + cos(a2) * outer_rx, cy + sin(a2) * outer_ry),
            Vector2(cx + cos(a2) * inner_rx, cy + sin(a2) * inner_ry),
            Vector2(cx + cos(a1) * inner_rx, cy + sin(a1) * inner_ry),
        ])
        quad.color = color
```

---

### Chapter 15: Dialog and Narrative Systems

#### 15.1 Typewriter Text Effect

```gdscript
func _start_typing_effect(text: String) -> void:
    dialogue_text.text = text
    dialogue_text.visible_ratio = 0.0

    var duration = text.length() * 0.025  # 25ms per character
    duration = clamp(duration, 0.5, 6.0)

    typing_tween = create_tween()
    typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)

func _skip_typing() -> void:
    if typing_tween and typing_tween.is_valid():
        typing_tween.kill()
    dialogue_text.visible_ratio = 1.0
```

#### 15.2 One-Shot Dialogue (Play Once)

```gdscript
# Track whether auto-dialogues have been shown
if not GameManager.player_data.get("kitchen_intro_shown", false):
    GameManager.player_data["kitchen_intro_shown"] = true
    _show_dialogue("Dr. Lumina", "Your great-elder Zyx's console...")
    SaveManager.save_game()
# After first showing, player must interact manually
```

---

## Part IV: Game Systems (401-Level)

---

### Chapter 16: Habit Tracking System

#### 16.1 Habit Data Model

```gdscript
habit = {
    "id": String,
    "name": String,
    "domain": HabitDomain,   # HEALTH, LEARNING, MINDFULNESS, etc.
    "frequency": HabitFrequency,
    "exp_reward": int,
    "evolution_reward": float,
    "streak": int,
    "best_streak": int,
    "total_completions": int,
    "is_preset": bool,
    "archived": bool,
    "completion_history": Array,
    "last_completed": String  # ISO date
}
```

#### 16.2 Grace Day System

A compassionate streak recovery system - the game never punishes:

```gdscript
const MAX_GRACE_DAYS = 3

# Earning: 1 grace day per 7-day streak
# Usage: recover streak if missed only 1 day
# Philosophy: "Recovery, not failure"
```

#### 16.3 Topic System with Archive

Topics track focus session subjects. They support archiving to reduce clutter:

```gdscript
func get_all_topics() -> Array:
    return topics.values().filter(func(t): return not t.get("archived", false))

func get_archived_topics() -> Array:
    return topics.values().filter(func(t): return t.get("archived", false))

func archive_topic(topic_id: String) -> void:
    topics[topic_id]["archived"] = true
    SaveManager.save_game()
```

---

### Chapter 17: Focus Session Timer

#### 17.1 Session Flow

```
Select Duration (25 min default) → Choose Difficulty (Standard/Hard)
→ Select Topic/Script → START timer → Real-world work happens
→ Timer complete → Journal Reflection (LAGG format)
→ XP calculated → Return to hub
```

#### 17.2 XP Calculation

```gdscript
# Base: 2 XP per minute (50 XP for 25 min)
# Difficulty multiplier: Standard 0.7x, Hard 1.5x
# Streak bonus: 10% per streak day (capped)
func complete_focus_session_with_multiplier(minutes: int, topic: String, multiplier: float):
    var base_xp = minutes * 2
    var total = int(base_xp * multiplier)
    add_aspect_experience(linked_aspect, total)
    evolve_world(minutes * 0.02)
```

---

### Chapter 18: Achievement and Trophy System

#### 18.1 Trophy Tiers

| Tier | Examples | XP Range |
|------|----------|----------|
| Bronze | Story milestones, first-time | 10-50 |
| Silver | Streak milestones (7/14/21/30 days) | 50-100 |
| Gold | Aspect mastery (Level 5+) | 100-250 |
| Platinum | Secret achievements, year-long | 250-1000 |

---

### Chapter 19: Campaign and Progression

#### 19.1 Chapter-Based Progression

```gdscript
const CHAPTERS = {
    "chapter_1": {
        "name": "First Contact",
        "completion_requirements": [
            {"type": "focus_sessions", "count": 1}
        ],
        "rooms_to_unlock": ["focus_chamber"],
    },
    "chapter_2": {
        "name": "The Mindscape Opens",
        "unlock_conditions": [{"type": "chapter_complete", "chapter": "chapter_1"}],
        "completion_requirements": [
            {"type": "focus_sessions", "count": 3},
            {"type": "habits_created", "count": 1}
        ],
        "aspects_to_unlock": ["discipline"]
    },
}
```

#### 19.2 Aspect Awakening Order

1. **Discipline** (Chapter 2) - Foundation
2. **Vitality** (Chapter 3) - Physical wellness
3. **Wisdom** (Chapter 4) - Clarity
4. **Compassion** (Chapter 6) - Heart
5. **Courage** (Chapter 7) - Bravery
6. **Creativity** (Chapter 8) - Innovation

---

### Chapter 20: Shop and Economy

#### 20.1 Multi-Currency System

Each Aspect has its own XP currency:

```gdscript
# Item cost example:
item = {
    "name": "Crystal Fern",
    "category": ItemCategory.ROOM_DECOR,
    "rarity": ItemRarity.UNCOMMON,
    "cost": {"vitality": 100, "creativity": 50}
}

func can_afford(item_id: String) -> bool:
    var cost = SHOP_CATALOG[item_id].get("cost", {})
    for aspect in cost:
        if _get_aspect_xp(aspect) < cost[aspect]:
            return false
    return true
```

#### 20.2 IRL Gifts Integration

A bridge between game progress and real-world rewards:

```gdscript
# Focus coins: 1 earned per completed focus session
var focus_coins = GameManager.player_data.get("total_focus_sessions", 0)

# Redeem for discount codes at goacto.shop
var irl_items = [
    {"name": "Sticker Pack", "coins": 10, "url": "https://goacto.shop/stickers"},
    {"name": "Growth Journal", "coins": 25, "url": "https://goacto.shop/journal"},
]

# Opens browser and copies discount code to clipboard
func _on_irl_gift_redeem(gift):
    DisplayServer.clipboard_set(gift.discount)
    OS.shell_open(gift.url)
```

---

## Part V: Advanced Topics (501-Level)

---

### Chapter 21: Cross-Platform Deployment

#### 21.1 Export Presets

The project supports 6 platforms:

```ini
# export_presets.cfg
Preset 0: iOS
Preset 1: Android
Preset 2: macOS
Preset 3: Windows Desktop
Preset 4: Linux
Preset 5: Web (PWA enabled)
```

#### 21.2 Vercel Deployment (Web)

```json
// vercel.json
{
    "buildCommand": null,
    "outputDirectory": "build/web",
    "headers": [
        {
            "source": "/(.*)",
            "headers": [
                {"key": "Cross-Origin-Opener-Policy", "value": "same-origin"},
                {"key": "Cross-Origin-Embedder-Policy", "value": "require-corp"}
            ]
        }
    ]
}
```

**Key:** COOP/COEP headers are required for SharedArrayBuffer, which Godot's web export needs.

---

### Chapter 22: Web Export and Browser APIs

#### 22.1 JavaScriptBridge

Godot communicates with the browser via `JavaScriptBridge`:

```gdscript
# Trigger file download
JavaScriptBridge.eval("""
(function() {
    var blob = new Blob([data], {type: 'application/json'});
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url; a.download = 'save.json';
    a.click();
})();
""")

# File upload via hidden input
JavaScriptBridge.eval("""
(function() {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = function(e) {
        var reader = new FileReader();
        reader.onload = function(ev) {
            window._godotUploadedSave = ev.target.result;
            window._godotUploadReady = true;
        };
        reader.readAsText(e.target.files[0]);
    };
    input.click();
})();
""")

# Poll for result from GDScript
var ready = JavaScriptBridge.eval("window._godotUploadReady === true")
```

#### 22.2 Web Font and Emoji Support

Godot's built-in font lacks emoji glyphs on web. Fix with a SystemFont resource:

```ini
# resources/default_font.tres
[gd_resource type="SystemFont" format=3]
[resource]
font_names = PackedStringArray("Segoe UI", "SF Pro Display", "Roboto", "sans-serif")
allow_system_fallback = true

# project.godot
[gui]
theme/default_font="res://resources/default_font.tres"
```

The `allow_system_fallback = true` flag lets the OS emoji renderer handle emoji characters.

---

### Chapter 23: Mobile Touch Controls

#### 23.1 Dynamic Virtual Joystick

```gdscript
# The joystick appears wherever the user touches on the left half of the screen
func _handle_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        var is_left_half = event.position.x < viewport_size.x * 0.5
        if is_left_half and not _is_pressed:
            # Reposition joystick to touch point
            global_position = event.position - _joystick_center
            _is_pressed = true
    else:
        _is_pressed = false
        _return_to_default_position()  # Snap back when released
```

#### 23.2 Platform Detection

```gdscript
# MobileUIManager.gd
func _detect_platform() -> void:
    var os = OS.get_name()
    if os == "iOS" or os == "Android":
        is_mobile = true
    elif os == "Web":
        # Check viewport width for responsive detection
        is_mobile = viewport.x < BREAKPOINT_TABLET  # 768px
    else:
        is_mobile = false
```

#### 23.3 Touch Target Sizing

Apple HIG minimum is 44px. This project uses larger targets:

```gdscript
# Interact button: 100x100px with 48px circle
interact_button.custom_minimum_size = Vector2(100, 100)
bg.polygon = _create_circle(48, 24)

# Minimum button sizes throughout UI
button.custom_minimum_size = Vector2(0, 45)  # 45px height minimum
```

---

### Chapter 24: Save File Import/Export

#### 24.1 Complete Transfer System

The game provides four methods for save data portability:

1. **Download Save** - Triggers a file download (`.json`)
2. **Upload Save** - Opens native file picker
3. **Copy JSON** - Clipboard copy for manual transfer
4. **Paste JSON** - Clipboard paste with validation

#### 24.2 Import Validation

```gdscript
func _confirm_import_save(json_content: String) -> void:
    var json = JSON.new()
    var parse_result = json.parse(json_content)
    if parse_result != OK:
        _show_toast("Invalid file: not valid JSON.", false)
        return

    var data = json.data
    if not data is Dictionary or not data.has("player"):
        _show_toast("Invalid save file: missing player data.", false)
        return

    # Show confirmation with save details before overwriting
    var upload_name = data.player.get("name", "Unknown")
    var upload_evo = int(data.player.get("world_evolution_level", 0))
    # ... show confirmation dialog with slot selection
```

---

### Chapter 25: Performance and Optimization

#### 25.1 Mobile Renderer

The project uses Godot's mobile renderer for maximum compatibility:

```ini
[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

#### 25.2 Procedural vs Pre-built

**Trade-off:** This project builds most UI in code (dynamic) rather than in the editor (static). This means:
- **Pro:** Extremely flexible, data-driven, easy to update
- **Con:** Longer initial load, more memory allocation per scene
- **Mitigation:** Use `queue_free()` aggressively, avoid creating nodes in `_process()`

#### 25.3 Companion Tip Frequency

Periodic effects (like the companion spirit's tips) should be tuned for UX:

```gdscript
var companion_tip_cooldown: float = 120.0  # 2 minutes (was 30s - too frequent)
```

---

## Appendix A: Brand Color Reference

```gdscript
# ThemeConfig.gd
const CHARCOAL = Color("#3D3D3D")
const GOLD = Color("#D4A84B")
const BRIGHT_GOLD = Color("#EBC059")
const DEEP_SPACE = Color("#0a0a12")
const SPACE = Color("#0f1019")
const NEBULA = Color("#1a1a2e")
const PANEL = Color("#16213e")
const FOCUS_GREEN = Color("#2ecc71")
const JOURNAL_BLUE = Color("#3498db")
const ASPECTS_PURPLE = Color("#9b59b6")
const GOALS_GOLD = Color("#f39c12")
const HABITS_TEAL = Color("#1abc9c")
const ARENA_RED = Color("#e74c3c")
const SCRIPTS_BRONZE = Color("#cd7f32")
```

---

## Appendix B: Design Philosophy

### Never Punish, Always Encourage
- Broken streaks show "Recovery" not "Failed"
- Missed days trigger supportive dialogue
- Every return is celebrated
- Progress is never lost, only paused

### The GOACTO Frame
- Player was CHOSEN because they can do this
- An alien across galaxies believes in them
- Every action ripples across the cosmos
- Self-improvement framed as adventure, not obligation

---

## Document Maintenance

This textbook is updated with each deployment to GitHub. When making changes:
1. New systems or patterns should be documented in the appropriate chapter
2. Bug fixes that reveal common pitfalls should be added to relevant sections
3. Architecture decisions should be explained with rationale

**Last comprehensive update**: March 2026
