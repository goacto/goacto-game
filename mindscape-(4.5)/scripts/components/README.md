# Reusable Components

These components reduce code duplication and file sizes for better token efficiency.

## UIBuilder (Static Utility)

```gdscript
# Create styled elements without boilerplate
var panel = UIBuilder.create_panel(Vector2(400, 300))
var btn = UIBuilder.create_button("Click Me", Vector2(120, 40))
var label = UIBuilder.create_header("Title", 24)
var input = UIBuilder.create_text_input("Enter name...")
var card = UIBuilder.create_card(Vector2(150, 100))
var progress = UIBuilder.create_progress_bar(50, 100)
var stat_row = UIBuilder.create_stat_row("⚡", "Energy", "100%", Color.YELLOW)
```

## DialogueComponent

```gdscript
# In your scene script
var dialogue = DialogueComponent.new()
add_child(dialogue)

# Show dialogue
dialogue.show_dialogue(
    self,                           # parent scene
    "Title",                        # title text
    "This is the message content.", # body text
    _on_dialogue_closed,            # callback (optional)
    "res://audio/voice/line.ogg"    # voice (optional)
)

# Handle input (in _input)
if dialogue.handle_input(event):
    return
```

## FocusDashboardComponent

```gdscript
var dashboard = FocusDashboardComponent.new()
add_child(dashboard)

# Check if unlocked
if dashboard.is_unlocked():
    dashboard.show(self, _on_dashboard_closed)

# Signals
dashboard.dashboard_opened.connect(_on_opened)
dashboard.dashboard_closed.connect(_on_closed)
```

## PauseMenuComponent

```gdscript
var pause_menu = PauseMenuComponent.new()
add_child(pause_menu)

# Show pause menu
pause_menu.show(
    self,
    _on_resume,      # resume callback
    _on_settings,    # settings callback
    _on_main_menu    # main menu callback
)

# Handle input (in _input)
if pause_menu.handle_input(event):
    return
```

## SpaceViewComponent

```gdscript
var space_view = SpaceViewComponent.new()
add_child(space_view)

space_view.show(self, {
    "info_text": "Gazing at the stars...",
    "show_comet": true,
    "num_stars": 300
}, _on_space_view_closed)

# Update animation (in _process)
space_view.update(delta)
```

## Migration Guide

To reduce a scene file size, replace inline UI code with component calls:

**Before (inline):**
```gdscript
func _open_focus_dashboard():
    # 700+ lines of dashboard creation code...
```

**After (component):**
```gdscript
var dashboard_component = FocusDashboardComponent.new()

func _ready():
    add_child(dashboard_component)

func _open_focus_dashboard():
    if dashboard_component.show(self, _on_dashboard_closed):
        in_dialogue = true
```

This reduces bedroom.gd by ~700 lines per extracted component.
