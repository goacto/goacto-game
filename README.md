# Mindscape - GOACTO Game

A 2.5D isometric RPG where your inner world grows as you do. Complete real-world habits and quests to evolve your mindscape, develop aspects of yourself, and connect with others.

**GOACTO**: Growing Ourselves And Contributing To Others

## Quick Start

### Prerequisites
- [Godot 4.2+](https://godotengine.org/download) (Standard version)

### Running the Game

1. Open Godot 4
2. Click "Import" and navigate to `/godot/project.godot`
3. Click "Import & Edit"
4. Press F5 or click the Play button

### Project Structure

```
goacto-game/
├── docs/
│   └── GAME_DESIGN_DOCUMENT.md    # Full game design documentation
├── godot/
│   ├── project.godot              # Godot project file
│   ├── autoload/                  # Global singletons
│   │   ├── GameManager.gd         # Game state & progression
│   │   ├── HabitManager.gd        # Habit tracking system
│   │   └── SaveManager.gd         # Save/load functionality
│   ├── scenes/
│   │   ├── main_menu/             # Title screen
│   │   ├── mindscape/             # Main game world
│   │   ├── focus_mode/            # "Headset on" real-world task screen
│   │   └── combat/                # Turn-based battles
│   ├── scripts/
│   │   └── player/                # Avatar controller
│   └── assets/                    # Sprites, audio, fonts
└── README.md
```

## Core Gameplay Loop

```
┌─────────────────────────────────────────────────────────┐
│                     MINDSCAPE WORLD                      │
│  • View and track habits                                 │
│  • Interact with Aspects (parts of yourself)             │
│  • Explore your evolving inner world                     │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  HEADSET ON (Focus Mode)                 │
│  • Screen goes dark                                      │
│  • Put phone down                                        │
│  • Complete real-world task                              │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    HEADSET OFF (Return)                  │
│  • See your world transformed                            │
│  • Aspects grow stronger                                 │
│  • World evolves based on real progress                  │
└─────────────────────────────────────────────────────────┘
```

## Current Features (Prototype)

- [x] Main menu with new/continue game
- [x] Isometric mindscape world with avatar movement
- [x] Habit tracking system (3 preset habits)
- [x] Focus session mode (headset on/off mechanic)
- [x] World evolution based on completed habits
- [x] Discipline Aspect character with dialogue
- [x] Turn-based combat against Inner Resistance enemies
- [x] Streak bonuses for consistent habits
- [x] Save/load system

## Prototype Controls

**Desktop (for testing)**
- Arrow keys: Move avatar
- Click: Tap-to-move / Interact

**Mobile**
- Touch & drag: Virtual joystick movement
- Tap: Interact with UI

## Inner Resistance Enemies

Combat features enemies that represent internal struggles:
- **Doubt** - Questions your abilities
- **Fear** - Holds you back from growth
- **Procrastination** - Delays your progress
- **Distraction** - Pulls focus away

Defeating them grants experience and evolves your world.

## Aspects

Party members that represent parts of yourself:
- **Discipline** (unlocked) - Powered by productivity habits
- Courage, Creativity, Compassion, Wisdom, Vitality (coming soon)

## Roadmap

### Phase 1: Prototype (Current)
- Core loop functional
- All systems connected
- Placeholder visuals

### Phase 2: Vertical Slice
- Polished art for one zone
- All Aspects implemented
- Quest system

### Phase 3+
- Multiple zones
- AI NPC advisors
- Multiplayer features
- Full mobile release

## Development

Built with Godot 4.2 using GDScript.

### Key Files to Modify

| What | Where |
|------|-------|
| Add habits | `autoload/HabitManager.gd` → `_initialize_preset_habits()` |
| Add enemies | `scenes/combat/combat.gd` → `ENEMIES` dict |
| Modify Aspects | `autoload/GameManager.gd` → `ASPECTS` dict |
| World visuals | `scenes/mindscape/mindscape.gd` → `_update_world_visuals()` |

## License

[TBD]

---

*Growing Ourselves And Contributing To Others*
