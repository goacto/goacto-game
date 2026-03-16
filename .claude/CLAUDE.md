# GOACTO Game - Comprehensive Application Overview

> **Document Version**: 1.0.0
> **Last Updated**: March 2026
> **Application**: Mindscape by GOACTO
> **Engine**: Godot 4.6 (Mobile Renderer)
> **Platform**: Cross-platform (Desktop, Mobile)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Philosophy](#product-philosophy)
3. [Technical Architecture](#technical-architecture)
4. [Project Structure](#project-structure)
5. [Core Systems & Managers](#core-systems--managers)
6. [Game Mechanics](#game-mechanics)
7. [Scene Architecture](#scene-architecture)
8. [Data Models & Persistence](#data-models--persistence)
9. [Campaign & Narrative System](#campaign--narrative-system)
10. [Complete Story & Player Experience](#complete-story--player-experience)
11. [Integration Points](#integration-points)
12. [Asset Pipeline](#asset-pipeline)
13. [Development Guidelines](#development-guidelines)
14. [GOACTO Ecosystem Integration](#goacto-ecosystem-integration)
15. [Complete Player Journey](#complete-player-journey)

---

## Executive Summary

**GOACTO: Growing Ourselves And Contributing To Others** is a 2.5D isometric self-improvement RPG that gamifies real-world personal development. The game creates a powerful psychological feedback loop where players' actual self-improvement journey mirrors their character's evolution in the game.

### Core Concept
Players assume the role of Agent Goacto, a young alien on the intergalactic cruise ship "Stellar Wanderer," who is completing their "Contribution Certification" by helping a human (the player themselves) achieve meaningful growth through the game "Human Potential."

### Key Metrics
- **45+ GDScript files** across managers, scenes, and utilities
- **26 scene files** (.tscn) organized by feature area
- **16 autoload singleton managers** for global systems
- **6 Aspects** (character development archetypes)
- **6 life domain layers** in the Personal Operating System
- **15 campaign chapters** with progressive unlocks
- **50+ shop items** across multiple categories
- **20+ achievements** with tiered rewards

---

## Product Philosophy

### GOACTO Values
The name encapsulates the philosophy: **G**rowing **O**urselves **A**nd **C**ontributing **T**o **O**thers.

### Design Principles

1. **Never Punish, Always Encourage**
   - Broken streaks show "Recovery" not "Failed"
   - Missed days trigger supportive dialogue
   - Every return is celebrated
   - Progress is never lost, only paused

2. **Real-World Action Drives Inner-World Growth**
   - Focus sessions create tangible in-game evolution
   - Habit completion powers Aspect development
   - Journaling unlocks deeper game features

3. **Graceful Progression**
   - Grace days system for streak recovery
   - No harsh penalties for missed activities
   - Visual regression is gentle (dims, doesn't destroy)

4. **The Goacto Frame**
   - Player was CHOSEN because they can do this
   - An alien across galaxies believes in them
   - Every action ripples across the cosmos

---

## Technical Architecture

### Engine Configuration
```ini
Engine: Godot 4.6
Renderer: Mobile (optimized for cross-platform)
Viewport: 1366x768 with canvas stretch
Input: WASD/Arrow keys + Touch emulation
Audio Buses: Master, Music, Voice, Ambient, SFX
```

### Design Patterns

| Pattern | Implementation | Purpose |
|---------|---------------|---------|
| **Singleton/Autoload** | 16 global managers | Cross-scene state management |
| **Signal/Observer** | Godot signals | Loose coupling between systems |
| **Scene Base Classes** | `ship_scene_base.gd`, `mindscape_region_base.gd` | Code reuse via inheritance |
| **State Machine** | `GameManager.GameState` enum | Game flow control |
| **Data-Driven** | JSON serialization | Persistence and configuration |

### Autoload Load Order
```
1. ThemeConfig         # Brand colors and UI constants
2. CampaignManager     # Story progression, chapter unlocks
3. GameManager         # Core state, player data, aspects
4. HabitManager        # Habit tracking, streaks, grace days
5. GoalManager         # Daily/weekly/milestone goals
6. ScriptManager       # Personal OS (layers, packages, scripts)
7. SaveManager         # Persistence to JSON files
8. MindscapeRegionManager  # Regional state and transitions
9. ChallengeManager    # Daily/weekly bonus objectives
10. AchievementManager # Badge/trophy system
11. AudioManager       # Sound, music, voice, ambient
12. TransitionManager  # Scene transition effects
13. ShopManager        # Cosmetics economy
14. CustomizationManager  # Avatar appearance
15. MailManager        # Package delivery system
16. RelationshipManager # Relationship health tracking
```

---

## Project Structure

```
goacto-game/
├── .claude/                      # Claude Code configuration
│   └── CLAUDE.md                 # This document
├── .git/                         # Git repository
├── .gitignore
│
├── docs/                         # Design documentation
│   ├── GAME_DESIGN_DOCUMENT.md   # Core mechanics, systems overview
│   ├── CAMPAIGN_DESIGN.md        # Narrative framework, chapters
│   └── CAMPAIGN_COMPLETE.md      # Full campaign specification
│
├── godot/                        # Main Godot project
│   ├── project.godot             # Project configuration
│   │
│   ├── autoload/                 # Global singleton managers (16 files)
│   │   ├── GameManager.gd        # Core state, aspects, evolution
│   │   ├── HabitManager.gd       # Habits, streaks, grace days
│   │   ├── GoalManager.gd        # Goals with timeframes
│   │   ├── ScriptManager.gd      # Personal OS system
│   │   ├── SaveManager.gd        # JSON persistence
│   │   ├── CampaignManager.gd    # Story progression
│   │   ├── AudioManager.gd       # Sound management
│   │   ├── ShopManager.gd        # Cosmetics shop
│   │   ├── CustomizationManager.gd # Avatar customization
│   │   ├── ChallengeManager.gd   # Daily/weekly challenges
│   │   ├── AchievementManager.gd # Achievement tracking
│   │   ├── MindscapeRegionManager.gd # Region transitions
│   │   ├── TransitionManager.gd  # Scene transitions
│   │   ├── MailManager.gd        # Package delivery
│   │   └── ThemeConfig.gd        # Brand colors
│   │
│   ├── scenes/                   # Game scenes organized by feature
│   │   ├── main_menu/            # Entry point, new/load game
│   │   ├── bedroom/              # Agent Goacto's cabin
│   │   ├── ship/                 # Ship room scenes (9 rooms)
│   │   │   ├── hallway.tscn/.gd
│   │   │   ├── kitchen.tscn/.gd
│   │   │   ├── living_room.tscn/.gd
│   │   │   ├── stairs.tscn/.gd
│   │   │   ├── cargo_hold.tscn/.gd
│   │   │   ├── old_storage.tscn/.gd
│   │   │   ├── mail_room.tscn/.gd
│   │   │   ├── observatory.tscn/.gd
│   │   │   ├── viewing_balcony.tscn/.gd
│   │   │   └── ship_scene_base.gd  # Shared ship logic
│   │   │
│   │   ├── mindscape/            # Inner world scenes
│   │   │   ├── mindscape_hub.tscn/.gd  # Central hub
│   │   │   ├── mindscape_north.tscn/.gd
│   │   │   ├── mindscape_east.tscn/.gd
│   │   │   ├── mindscape_south.tscn/.gd
│   │   │   ├── mindscape_west.tscn/.gd
│   │   │   ├── mindscape_legacy.tscn/.gd
│   │   │   ├── script_lab.tscn/.gd  # Personal OS interface
│   │   │   └── mindscape_region_base.gd  # Shared region logic
│   │   │
│   │   ├── focus_chamber/        # Focus session entry
│   │   ├── focus_mode/           # Active focus timer
│   │   ├── daily_rituals/        # Habit tracking UI
│   │   ├── combat/               # Turn-based battles
│   │   ├── cutscene/             # Story sequences
│   │   ├── transition/           # Portal & headset transitions
│   │   └── settings/             # Game settings
│   │
│   ├── scripts/                  # Utility scripts
│   │   ├── player/player.gd      # Avatar controller
│   │   └── ui_sounds.gd          # UI sound effects
│   │
│   ├── assets/                   # Visual assets
│   │   ├── sprites/              # UI, characters, enemies
│   │   ├── backgrounds/          # Scene backgrounds
│   │   ├── fonts/                # Typography
│   │   └── shaders/              # Custom effects
│   │
│   ├── audio/                    # Audio assets
│   │   ├── sfx/                  # Sound effects
│   │   ├── music/                # Background tracks
│   │   └── voice/                # Voice acting (organized by scene)
│   │
│   └── resources/                # Godot resources
│       └── audio_bus_layout.tres # Audio bus configuration
│
├── README.md                     # Quick start guide
├── BACKLOG.md                    # Development roadmap
├── AUDIO_PRODUCTION_GUIDE.md     # Audio asset guidelines
└── VOICE_SCRIPTS.txt             # Voice recording scripts
```

---

## Core Systems & Managers

### GameManager.gd (16.5 KB)
**Purpose**: Central game state, player data, aspect system, evolution tracking

#### State Machine
```gdscript
enum GameState {
    MAIN_MENU,
    MINDSCAPE,
    FOCUS_MODE,
    COMBAT,
    DIALOGUE,
    PAUSED
}
```

#### Player Data Structure
```gdscript
player_data = {
    "name": String,
    "avatar": Dictionary,  # Equipped cosmetics
    "world_evolution_level": float,  # 0.0-100.0
    "total_focus_minutes": int,
    "total_focus_sessions": int,
    "total_habits_completed": int,
    "current_streak_days": int,
    "aspects": {
        "discipline": {"level": 1, "experience": 0, "unlocked": true},
        "courage": {"level": 1, "experience": 0, "unlocked": false},
        "creativity": {"level": 1, "experience": 0, "unlocked": false},
        "compassion": {"level": 1, "experience": 0, "unlocked": false},
        "wisdom": {"level": 1, "experience": 0, "unlocked": false},
        "vitality": {"level": 1, "experience": 0, "unlocked": false}
    },
    "unlocked_zones": Array,
    "inventory": Array,
    "has_completed_onboarding": bool,
    "seen_tutorials": Array,
    "discovered_objects": Array,
    "bedroom_items_installed": Array,
    "console_placed_in_bedroom": bool,
    "closet_unlocked": bool,
    "mirror_unlocked": bool,
    "bookshelf_unlocked": bool
}
```

#### Key Signals
```gdscript
signal state_changed(new_state, old_state)
signal world_evolution_triggered(amount)
signal aspect_leveled_up(aspect_name, new_level)
signal zone_unlocked(zone_id)
```

#### Key Methods
```gdscript
func change_state(new_state: GameState)
func goto_scene(path: String)  # With fade transitions
func add_aspect_experience(aspect_id: String, exp: int)
func evolve_world(amount: float)
func is_zone_unlocked(zone_id: String) -> bool
func complete_focus_session(minutes: int, topic: String)
func complete_focus_session_with_multiplier(minutes: int, topic: String, multiplier: float)
```

---

### HabitManager.gd (24.3 KB)
**Purpose**: Habit tracking, streaks, grace day recovery system

#### Habit Domains
```gdscript
enum HabitDomain {
    HEALTH,      # Powers Vitality
    LEARNING,    # Powers Creativity
    MINDFULNESS, # Powers Wisdom
    SOCIAL,      # Powers Compassion
    PRODUCTIVITY,# Powers Discipline
    CUSTOM       # Powers Courage
}
```

#### Grace Day System
- **Maximum**: 3 grace days (capped)
- **Earning**: 1 grace day per 7-day streak
- **Usage**: Allows streak recovery if missed 1 day
- **Expiration**: Pending breaks expire after 1 day

#### Habit Structure
```gdscript
habit = {
    "id": String,
    "name": String,
    "description": String,
    "domain": HabitDomain,
    "frequency": HabitFrequency,  # DAILY, WEEKLY, CUSTOM
    "icon": String,
    "exp_reward": int,  # XP to linked aspect
    "evolution_reward": float,  # World evolution contribution
    "streak": int,
    "best_streak": int,
    "total_completions": int,
    "is_preset": bool,
    "archived": bool,
    "order": int,
    "completion_history": Array,  # Array of date strings
    "last_completed": String  # ISO date
}
```

#### Preset Habits
1. **Move Your Body** (Health domain, powers Vitality)
2. **Mindful Moment** (Mindfulness domain, powers Wisdom)
3. **Learn Something** (Learning domain, powers Creativity)

#### Key Signals
```gdscript
signal habit_completed(habit_id, habit_data)
signal habit_streak_updated(habit_id, streak)
signal streak_recovered(habit_id, grace_days_used)
signal daily_reset_occurred
```

---

### ScriptManager.gd (51.9 KB)
**Purpose**: Personal Operating System - life scripting system

#### Philosophy
*"Life is the result of the scripts we allow ourselves to run."*

#### Structure Hierarchy
```
YourName.OS (Personal Operating System)
├── mind.layer (Mental growth, learning, focus)
├── body.layer (Physical health, movement)
├── soul.layer (Purpose, meaning, spirituality)
├── social.layer (Relationships, community)
├── career.layer (Work, craft, contribution)
└── wealth.layer (Financial growth, resources)
    └── package (Specific area, e.g., morning_routine.pkg)
        └── script.psa (25 lines = 25-minute focus session)
```

#### Operational Layers
| Type | Color | Purpose |
|------|-------|---------|
| **baseline** | Purple | Heartbeat scripts - daily essentials |
| **update** | Blue | Learning & improvement activities |
| **upgrade** | Green | Paradigm shifts that level you up |
| **bloatware** | Orange | Routines to remove/optimize |
| **virus** | Red | Limiting beliefs to debug |

#### Script (PSA) Structure
```gdscript
script = {
    "id": String,
    "name": String,
    "package_id": String,
    "layer_id": String,
    "operational_layer": String,
    "type": ScriptType,
    "lines": Array,  # 25 action items (1 line = 1 minute)
    "description": String,
    "duration_minutes": 25,
    "times_executed": int,
    "last_executed": int,  # Unix timestamp
    "completion_rate": float,
    "created_at": int
}
```

#### Template Library
18 curated templates across all domains and operational types for quick script creation.

---

### SaveManager.gd (16.4 KB)
**Purpose**: JSON persistence with slot system

#### Save File Locations
| File | Path | Purpose |
|------|------|---------|
| Auto-save | `user://mindscape_save.json` | Primary game state |
| Settings | `user://mindscape_settings.json` | Audio, preferences |
| Slot 1-3 | `user://mindscape_save_slot_N.json` | Manual saves |
| Focus Journal | `user://mindscape_journal[_slot_N].json` | Session entries |
| Gratitude | `user://gratitude_journal[_slot_N].json` | Gratitude entries |
| Dream | `user://dream_journal[_slot_N].json` | Dream journal |
| Shadow | `user://shadow_journal[_slot_N].json` | Shadow work |

#### Aggregated Save Format (v0.3.2)
```json
{
    "version": "0.3.2",
    "timestamp": 1234567890,
    "player": { /* GameManager.player_data */ },
    "habits": { /* HabitManager state */ },
    "goals": { /* GoalManager state */ },
    "scripts": { /* ScriptManager state */ },
    "challenges": { /* ChallengeManager state */ },
    "achievements": { /* AchievementManager state */ },
    "campaign": { /* CampaignManager state */ },
    "shop": { /* ShopManager state */ },
    "mail": { /* MailManager state */ }
}
```

#### Key Methods
```gdscript
func save_game() -> bool
func load_game() -> bool
func save_to_slot(slot: int) -> bool  # 1-3
func load_from_slot(slot: int) -> bool
func delete_slot(slot: int)
func get_slot_info(slot: int) -> Dictionary  # Metadata preview
func has_save() -> bool
func export_save_data() -> String  # For sharing
```

---

### CampaignManager.gd (34.9 KB)
**Purpose**: Story progression, chapter unlocks, trophies, aspect awakenings

#### Chapter Progression
```gdscript
const CHAPTERS = {
    "chapter_1": {
        "name": "First Contact",
        "unlock_conditions": [],  # Always unlocked
        "completion_requirements": [
            {"type": "focus_sessions", "count": 1}
        ],
        "rooms_to_unlock": ["focus_chamber"],
        "aspects_to_unlock": [],
        "cutscenes": ["intro", "earth_scan", "connection"]
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
    # ... chapters 3-15
}
```

#### Aspect Awakening Order
1. **Discipline** (Chapter 2) - Foundation
2. **Vitality** (Chapter 3) - Physical wellness
3. **Wisdom** (Chapter 4) - Clarity
4. **Compassion** (Chapter 6) - Heart
5. **Courage** (Chapter 7) - Bravery
6. **Creativity** (Chapter 8) - Innovation

#### Trophy Tiers
- **Bronze**: Story progression, first-time achievements
- **Silver**: Streak milestones (7/14/21/30/60/90/180/365 days)
- **Gold**: Aspect mastery (Level 5+)
- **Platinum**: Secret achievements, long-term goals

#### Key Signals
```gdscript
signal chapter_completed(chapter_id)
signal chapter_unlocked(chapter_id)
signal trophy_earned(trophy)
signal room_unlocked(room_id)
signal aspect_awakened(aspect_id)
signal cutscene_requested(cutscene_id)
signal bedroom_item_unlocked(item_id)
```

---

### AudioManager.gd (26.7 KB)
**Purpose**: Complete audio management with crossfading and ducking

#### Audio Players
| Player | Purpose | Features |
|--------|---------|----------|
| Music Primary | Background music | Crossfade support |
| Music Secondary | Crossfade target | Smooth transitions |
| Voice | Voiceovers, dialogue | Auto-ducking |
| Ambient Primary | Background ambience | Loop, crossfade |
| Ambient Secondary | Crossfade target | Smooth transitions |
| SFX Pool (8) | Sound effects | Simultaneous playback |

#### Volume Defaults
```gdscript
var volumes = {
    "master": 1.0,
    "music": 0.7,
    "voice": 1.0,
    "sfx": 0.8,
    "ambient": 0.5
}
```

#### Key Methods
```gdscript
func play_music(path: String, loop: bool = true)
func crossfade_to(path: String, duration: float = 2.0)
func play_voice(path: String)
func play_ambient(path: String, loop: bool = true)
func play_sfx(path: String)
func play_focus_ambient(type: String)  # space, rain, forest, ship, mindscape
func set_master_volume(value: float)
func toggle_mute(bus: String)
```

#### Audio Ducking
When voice plays, music automatically reduces to 50% volume and restores when voice completes.

---

### ShopManager.gd (16.0 KB)
**Purpose**: Cosmetics economy with aspect-based currency

#### Item Categories
```gdscript
enum ItemCategory {
    COSMETIC_COLOR,  # Skin colors
    OUTFIT,          # Body wear
    HAT,             # Head wear
    CAPE,            # Back accessories
    GLASSES,         # Face accessories
    AURA,            # Particle effects
    DECORATION,      # Room items
    FUNCTIONAL,      # Gameplay items
    COLLECTIBLE      # Rare items
}
```

#### Item Rarity
```gdscript
enum ItemRarity {
    COMMON,     # Standard items
    UNCOMMON,   # Slightly rare
    RARE,       # Hard to obtain
    LEGENDARY   # Extremely rare
}
```

#### Currency System
Each aspect has its own XP currency:
- Discipline XP
- Courage XP
- Creativity XP
- Compassion XP
- Wisdom XP
- Vitality XP

#### Item Structure
```gdscript
item = {
    "name": String,
    "description": String,
    "category": ItemCategory,
    "rarity": ItemRarity,
    "cost": {"aspect_id": xp_amount},  # e.g., {"discipline": 100}
    "is_default": bool,
    "preview_color": Color,
    "owned": bool,
    "equipped_slot": String
}
```

---

### GoalManager.gd (9.6 KB)
**Purpose**: Goal tracking with timeframes and aspect linking

#### Goal Timeframes
| Type | Reset | Reward | Use Case |
|------|-------|--------|----------|
| **Daily** | Each morning | 15 XP, 0.3 evolution | Quick intentions |
| **Weekly** | Each Monday | 50 XP, 1.0 evolution | Week priorities |
| **Milestone** | Never (until done) | 100 XP, 2.5 evolution | Big targets |

#### Goal Structure
```gdscript
goal = {
    "id": String,
    "title": String,
    "description": String,
    "timeframe": GoalTimeframe,
    "status": GoalStatus,  # ACTIVE, COMPLETED, ARCHIVED
    "aspect": String,  # Which aspect gains XP
    "progress": int,  # Current progress
    "target_progress": int,  # For milestones
    "created_at": int,
    "created_date": String,
    "completed_at": int,
    "exp_reward": int,
    "evolution_reward": float
}
```

---

## Game Mechanics

### Focus Session Flow
```
1. Enter Focus Chamber
   ↓
2. Select topic/habit OR freeform session
   ↓
3. Choose difficulty (Easy: 0.7x XP, Normal: 1.0x, Hard: 1.5x)
   ↓
4. Choose ambient sound (Silence, Space, Ship, Rain, Forest)
   ↓
5. START → 25-minute timer begins
   ↓
6. (Real-world deep work happens)
   ↓
7. Timer expires OR manual COMPLETE
   ↓
8. Journal reflection (LAGG format):
   - Learned: What new knowledge?
   - Accomplished: What was done?
   - Goals: Next session intentions?
   - Gratitude: Positive reflection?
   ↓
9. Rewards calculated:
   - Base: 2 XP per minute (50 XP for 25 min)
   - Difficulty multiplier applied
   - Streak bonus (if habit-linked)
   ↓
10. Return to Hub → See evolution increase
```

### World Evolution System
| Level | Progress | Visual State |
|-------|----------|--------------|
| 1 | 0-10% | Barren, dim, single light |
| 2 | 10-25% | First plants, crystal glows |
| 3 | 25-50% | Garden emerges, structures detail |
| 4 | 50-75% | Full lush environment |
| 5 | 75-90% | Crystalline structures, waterfalls |
| 6 | 90-100% | Transcendence, cosmic integration |

### Zone Unlock Tiers
```gdscript
const ZONE_TIERS = {
    0: [],  # Always accessible
    1: ["focus_chamber"],  # Chapter 1
    2: ["daily_rituals"],  # Chapter 2
    3: ["reflection_pool"],  # Chapter 3
    4: ["goal_compass", "observatory"],  # Chapter 4
    5: ["training_arena"],  # Chapter 5
    6: ["script_lab"]  # Chapter 8
}
```

### Aspect Leveling
```gdscript
# XP required per level (scales)
func xp_for_level(level: int) -> int:
    return level * 100  # Level 1: 100, Level 2: 200, etc.
```

### Combat System
- **Turn-based** party battles using awakened Aspects
- **Enemy types**: Doubt, Fear, Procrastination, Distraction, Perfectionism, Comparison
- **Actions**: Attack, Defend, Special (aspect-specific abilities)
- **Rewards**: XP to all participating aspects + evolution

### Streak Celebrations
Visual effects trigger at streak milestones:
- 3 days: Small sparkles
- 7 days: Medium confetti
- 14 days: Large celebration
- 21 days: Habit transformation
- 30/60/90/100+ days: Major ceremonies

---

## Scene Architecture

### Scene Hierarchy

```
Main Menu (entry point)
├── New Game → Onboarding (4 slides) → Bedroom
├── Continue → Last Save → Bedroom
└── Load Game → Slot Selection → Bedroom

Bedroom (Agent Goacto's cabin)
├── Door → Hallway → Ship Rooms
├── Mindscape Console → Mindscape Hub
├── Observation Window → Space View
├── Sleep Pod → Dream Sequences
├── Wardrobe → Avatar Customization
├── Data Archive → Lore Books (6)
└── Holographic Mirror → Avatar Preview

Mindscape Hub (central nexus)
├── Focus Chamber Portal → Focus Mode
├── Daily Rituals Portal → Habit Tracking
├── Reflection Pool Portal → Journaling
├── Goal Compass Portal → Goal Setting
├── Aspect Shrine Portal → Aspect Interaction
├── Training Arena Portal → Combat
├── Script Lab Portal → Personal OS
├── North Portal → Mindscape North
├── East Portal → Mindscape East
├── South Portal → Mindscape South
├── West Portal → Mindscape West
└── Exit Crystal → Return to Bedroom

Ship Rooms
├── Hallway → Connections to all rooms
├── Kitchen → Family interactions
├── Living Room → Relaxation
├── Stairs → Ship views
├── Cargo Hold → Storage
├── Old Storage → Console discovery
├── Mail Room → Package collection
├── Observatory → Telescope, meditation
└── Viewing Balcony → Telescope, meditation bench
```

### Base Classes

#### ship_scene_base.gd
Shared functionality for all ship room scenes:
- Space view rendering
- Door navigation
- Ambient audio
- Interaction system

#### mindscape_region_base.gd
Shared functionality for mindscape regions:
- Portal system
- Player spawning
- Ambient effects
- Zone-specific logic

---

## Data Models & Persistence

### Complete Save Data Structure
```gdscript
var save_data = {
    "version": "0.3.2",
    "timestamp": Unix_timestamp,
    "creation_timestamp": Unix_timestamp,
    "last_saved_timestamp": Unix_timestamp,
    "days_completed": int,

    "player": {
        # Full player_data from GameManager
    },

    "habits": {
        "habits": [/* Array of habit objects */],
        "topics": [/* Array of topic objects */],
        "grace_days": int,
        "pending_streak_breaks": [/* Array of pending breaks */],
        "last_daily_reset": String
    },

    "goals": {
        "goals": [/* Array of goal objects */],
        "last_daily_reset": String,
        "last_weekly_reset": String
    },

    "scripts": {
        "personal_os_name": String,
        "layers": [/* Array of layer objects */],
        "packages": [/* Array of package objects */],
        "scripts": [/* Array of script objects */],
        "run_records": [/* Array of execution records */],
        "favorites": [/* Array of script IDs */]
    },

    "challenges": {
        "daily_challenges": [/* Array */],
        "weekly_challenge": Object,
        "last_daily_refresh": String,
        "last_weekly_refresh": String
    },

    "achievements": {
        "unlocked": [/* Array of achievement IDs */],
        "progress": {/* Partial progress tracking */}
    },

    "campaign": {
        "current_chapter": String,
        "chapters_completed": [/* Array of chapter IDs */],
        "trophies_earned": [/* Array of trophy objects */],
        "cutscenes_seen": [/* Array of cutscene IDs */],
        "aspects_awakened": [/* Array of aspect IDs */]
    },

    "shop": {
        "owned_items": [/* Array of item IDs */],
        "equipped": {
            "skin_color": String,
            "outfit": String,
            "hat": String,
            "cape": String,
            "glasses": String,
            "aura": String
        }
    },

    "mail": {
        "pending_packages": [/* Array of package objects */],
        "collected_items": [/* Array of item IDs */]
    }
}
```

### Journal Entry Structure
```gdscript
journal_entry = {
    "id": String,
    "date": String,  # ISO format
    "timestamp": int,
    "topic": String,
    "duration_minutes": int,
    "difficulty": String,  # easy, normal, hard
    "learned": String,
    "accomplished": String,
    "goals": String,
    "gratitude": String,
    "aspect_xp_earned": int,
    "evolution_earned": float
}
```

---

## Campaign & Narrative System

### Story Acts

#### Act I: "Connection" (Chapters 1-3)
- Discovery and first contact
- Aspects awakened: Discipline, Vitality
- Key mechanic: Basic focus sessions, habits

#### Act II: "Growth" (Chapters 4-7)
- Expansion and challenges
- Aspects awakened: Wisdom, Compassion, Courage
- Key mechanic: Goals, combat, recovery

#### Act III: "Integration" (Chapters 8-10)
- Systems thinking, advanced techniques
- Aspects awakened: Creativity
- Key mechanic: Script Lab, personal OS

#### Act IV: "Mastery" (Chapters 11-15)
- Long-term content, community features
- Advanced resistance, multiplayer hooks

### Key Characters

#### Goacto Family (Ship NPCs)
| Character | Role | Personality |
|-----------|------|-------------|
| **Agent Goacto** | Player avatar | Curious, empathetic, growing |
| **Commander Arctis** | Father, navigator | Patient, wise, deliberate |
| **Dr. Lumina** | Mother, xenobiologist | Enthusiastic, nurturing |
| **Zyx** | Younger sibling | Chaotic, asks obvious questions |
| **Great-Elder Chronos** | Grandparent | Ancient wisdom, playful |

#### The Six Aspects
| Aspect | Domain | Color | Voice |
|--------|--------|-------|-------|
| **Discipline** | Productivity | Blue/Gold | "Less thinking. More doing." |
| **Courage** | Growth | Red | "Fear is excitement without breath." |
| **Creativity** | Learning | Purple | "What if... what if... oh, what if THIS?!" |
| **Compassion** | Social | Teal | "You're doing your best. That matters." |
| **Wisdom** | Mindfulness | Azure | "What do you think that means?" |
| **Vitality** | Health | Lime | "Feel that? That's you being ALIVE!" |

#### Inner Resistance (Enemies)
| Enemy | Visual | Weakness |
|-------|--------|----------|
| **Doubt** | Dark mirror | Consistent small actions |
| **Fear** | Shapeless darkness | Direct confrontation |
| **Procrastination** | Warm, soft being | Momentum (any action) |
| **Distraction** | Glittering swarm | Single-pointed focus |
| **Perfectionism** | Stern judge | Completion over perfection |
| **Comparison** | Endless mirrors | Self-compassion |

---

## Complete Story & Player Experience

### The Meta-Narrative Framework

The game operates on a beautiful narrative duality that creates emotional distance from self-improvement while making it deeply personal:

**Layer 1: The Alien Perspective**
- Player IS Agent Goacto, a young alien (127 cycles old, equivalent to human teenager)
- On a 50-year intergalactic vacation aboard the Stellar Wanderer
- Must complete "Contribution Certification" before adulthood
- Discovers the ancient "Human Potential" game in their cabin

**Layer 2: The Human Connection**
- The "human" Goacto helps is actually the player themselves
- Every real-world focus session = Goacto assisting their chosen human
- Creates a gentle fiction that transforms self-improvement into adventure
- The game never explicitly breaks this fourth wall

**Psychological Impact:**
Every action the player takes is simultaneously:
- Goacto helping their chosen human succeed
- The player actually improving themselves

This framing makes self-improvement feel like an exciting adventure rather than an obligation.

---

### The GOACTO Universe

#### The Goactorian Civilization
The Goactorians are a benevolent alien species who discovered millennia ago that the key to their own evolution was helping other civilizations grow. Their core values became encoded in their very name:

> **G**rowing **O**urselves **A**nd **C**ontributing **T**o **O**thers

Young Goactorians must complete their "Contribution Certification" before reaching adulthood - a rite of passage where they help at least one being from another world achieve meaningful growth.

#### The Stellar Wanderer
A massive, city-sized intergalactic cruise ship carrying thousands of Goactorian families on a 50-year vacation across the galaxy. The ship features:

| Location | Purpose |
|----------|---------|
| **Observation Decks** | View different worlds |
| **The Potential Archive** | Database of beings with high growth potential |
| **Sync Stations** | Connect consciousness to support beings remotely |
| **The Growth Garden** | Communal space that blooms based on collective contribution |
| **Personal Cabins** | Where Agent Goacto lives with family |

---

### Complete Chapter Breakdown

#### CHAPTER 1: "First Contact"
**Theme:** Discovery and Wonder

**Part 1.1 - "A Restless Spirit"**
- **Trigger:** New game started
- **Location:** Kitchen → Bedroom
- **Scene:** Goacto gazes at stars, feeling restless. Mom (Dr. Lumina) notices and suggests exploring the archive in their bedroom.

*Key Dialogue:*
> GOACTO: "Another rest stop. Another week of waiting."
> LUMINA: "The journey is the destination, little one."
> GOACTO: "I want to DO something. Help someone."

**Part 1.2 - "The Archive Discovery"**
- **Trigger:** First time entering bedroom
- **Scene:** Goacto examines the console. "Human Potential by GOACTO v3.2" boot sequence. System scans Earth, detects player's "potential signature."

*Key Revelation:* The system was created by Goacto's great-elder for his own Contribution Certification.

**Part 1.3 - "Neural Sync"**
- **Trigger:** Activating console
- **Scene:** Console activation animation, Earth scan visualization, "CANDIDATE DETECTED - Potential: EXCEPTIONAL", neural sync establishment, first glimpse of empty mindscape.

**Unlocks:** Focus Chamber (basic), Mindscape Hub access

**Completion Requirements:**
- Complete 1 focus session (any duration)

**Trophies Earned:**
- "First Contact" (25 XP) - Begin first focus session
- "Chosen One" (10 XP) - Human selected
- "Neural Link" (15 XP) - Enter mindscape first time

---

#### CHAPTER 2: "The Mindscape Opens"
**Theme:** Potential and Emptiness Before Growth

**Part 2.1 - "A Barren World"**
- **Scene:** Goacto fully enters the mindscape. Empty, dark platform floating in void. Single flickering light in the distance.
- **Visual:** Hub is barren gray, single platform, few dim stars.

**Part 2.2 - "The Foundation Awakens"**
- **Trigger:** Complete 3 focus sessions
- **Scene:** Golden light pulses at platform center. Discipline emerges.

*Discipline's Awakening Speech:*
> "You have begun. That is what matters. I am Discipline - the foundation upon which all growth is built. I have slept here, waiting for someone to take the first step. Help your human build habits, and I will grow stronger."

**Part 2.3 - "The First Routine"**
- **Scene:** Discipline guides to Daily Rituals. Tutorial for creating first habit. Explanation of streaks and rewards.

**Unlocks:** Daily Rituals (full), Discipline as companion, Habit creation

**Completion Requirements:**
- Complete 3 focus sessions
- Create 1 habit
- Complete 1 habit

**Trophies Earned:**
- "World Builder" (30 XP)
- "Routine Architect" (25 XP)
- "Discipline Awakened" (50 XP)

---

#### CHAPTER 3: "Growing Roots"
**Theme:** First Signs of Consistent Growth

**Part 3.1 - "Signs of Life"**
- **Trigger:** 3-day streak on any habit
- **Scene:** Hub platform shows green growth spots. Ground begins to glow. Something stirs underground.

**Part 3.2 - "Vitality Emerges"**
- **Trigger:** 5-day habit streak

*Vitality's Awakening Speech:*
> "Feel that? That's the human being ALIVE! I am Vitality - the root system of their being. Every movement, every breath, every moment of physical care makes me stronger. Let's get them moving!"

**Part 3.3 - "Family Dinner"**
- **Location:** Kitchen (ship)
- **Scene:** Family dinner with Goacto excitedly describing their human.

*Key Dialogue:*
> ZYX: "But can the human SEE you?"
> LUMINA: "The connection is felt, not seen. When the human feels motivated, supported, guided... that's Goacto."

**Part 3.4 - "Reflection's Mirror"**
- **Scene:** Reflection Pool zone materializes. Player can now review past journals.

**Unlocks:** Reflection Pool, Vitality as companion, Journal review, Ship family interactions

**Completion Requirements:**
- Maintain 5-day habit streak
- Complete reflection after session
- Complete 5 total focus sessions

---

#### CHAPTER 4: "The Compass Points"
**Theme:** Direction and Intentionality

**Part 4.1 - "Wandering Without Purpose"**
- **Trigger:** Chapter 3 complete + 10 focus sessions
- **Scene:** Goacto observes growing mindscape. Activity is good but seems random.

*Discipline suggests:* "Action without direction is just motion."

**Part 4.2 - "Wisdom's Clarity"**
- **Trigger:** Set first goal

*Wisdom's Awakening Speech:*
> "Interesting. Your human works hard but... where are they going? I am Wisdom - I help them see the path through the forest. Let us set intentions together."

**Part 4.3 - "The Navigator's Lesson"**
- **Location:** Ship - Commander Arctis scene
- **Scene:** Dad finds Goacto pondering. Navigation metaphor: "A ship without heading just drifts."

**Unlocks:** Goal Compass (full), Wisdom as companion, Commander Arctis interactions, Daily/Weekly/Milestone goals

---

#### CHAPTER 5: "Shadows Stir"
**Theme:** First Real Challenge - Facing Resistance

**Part 5.1 - "The First Fall"**
- **Trigger:** First missed habit day
- **Scene:** Mindscape darkens. Cold whisper echoes: "You knew this would happen..."

**Part 5.2 - "Doubt Emerges"**

*Doubt's Introduction:*
> "You thought this would be easy? Look at how quickly they stumble. One missed day... then two... then why bother at all? I've seen it countless times."

**Part 5.3 - "The First Battle"**
- Combat tutorial in Training Arena
- Player defeats Doubt (scripted to win first time)
- Doubt shrinks but doesn't vanish

*Discipline explains:* "It never truly leaves. We just get stronger."

**Part 5.4 - "Recovery"**
- Grace day system introduced
- Streak recovery mechanics
- Emphasis: Missing a day isn't failure

**Unlocks:** Training Arena, Combat system, Grace days feature, Streak recovery

---

#### CHAPTER 6: "The Heart Opens"
**Theme:** Self-Compassion and Emotional Growth

**Part 6.2 - "Compassion's Embrace"**
- **Trigger:** 7-day streak achieved

*Compassion's Awakening Speech:*
> "You've been pushing so hard. That's beautiful... and exhausting. I am Compassion - the reminder that you're doing your best, and that matters. Growth includes gentleness."

**Part 6.3 - "The Elder's Visit"**
- Great-Elder Chronos appears via hologram
- Shares stories of his 1,000+ contributions
- "In my cycle, we learned: discipline without compassion burns out"

**Unlocks:** Aspect Shrine (full), Compassion as companion, Great-Elder Chronos interactions, Aspect level-up system

---

#### CHAPTER 7: "The Spark of Creation"
**Theme:** Creativity and Expression

**Part 7.2 - "Creativity Manifests"**
- **Trigger:** Complete focus session on learning/creative topic

*Creativity's Awakening Speech:*
> "What if... what if... oh, WHAT IF?! I am Creativity - the part that sees connections everywhere! Let's make this human's growth into something BEAUTIFUL!"

**Part 7.3 - "The Script Lab"**
- Personal Operating System concept introduced
- Layers, packages, scripts (PSA files)
- Player can organize their growth as "code"

**Unlocks:** Script Lab, Creativity as companion, Personal OS system, Custom script creation

---

#### CHAPTER 8: "The Gathering Dark"
**Theme:** Multiple Resistances Combine

**Part 8.2 - "The Resistance Council"**
- **Trigger:** Miss 2+ habits in a week OR long break from app

*The Resistance Speaks:*
> DOUBT: "Look at how far you've come... just to fall."
> FEAR: "What if all this work was pointless?"
> PROCRASTINATION: "Shh... rest now. Tomorrow will be different..."

**Part 8.3 - "Tactical Retreat"**
- Family rallies around Goacto
- Dad: "Every agent faces this moment"
- Mom: "The human's resistance is fighting back because you're WINNING"
- Zyx: "Punch the bad guys harder!"

---

#### CHAPTER 9: "Courage Rises"
**Theme:** Facing Fear Directly

**Part 9.2 - "Courage Ignites"**
- **Trigger:** Complete a goal marked as "challenging"

*Courage's Awakening Speech:*
> "ENOUGH COWERING! I am Courage - the part that runs TOWARD what scares us! Fear looks big but watch what happens when we face it directly!"

**Part 9.3 - "The Fear Boss Battle"**
- Epic battle against Fear
- Courage leads the charge
- Fear shrinks with each faced challenge

---

#### CHAPTER 10: "The Midnight Hour"
**Theme:** The Deepest Challenge - Complete Stagnation

**Part 10.1 - "Everything Stops"**
- **Trigger:** 7+ day break from app OR all habits at 0 streaks
- Mindscape is dim, cold, still
- Aspects are faded, sleeping
- Inner monologue: "Did I fail them?"

**Part 10.2 - "The Return"**
- Single focus session begins to light the world
- Aspects stir one by one
- No judgment - only welcome
- Compassion: "You came back. That's all that matters."

**Part 10.3 - "Phoenix Protocol"**
- Chronos reveals: "I've seen agents lose their humans"
- "But the ones who return? They become the greatest."
- Phoenix Protocol unlocked: boosted rewards for returning

**Unlocks:** Phoenix Protocol (return bonuses), No-judgment return system, Extended grace day bank, Recovery missions

---

#### CHAPTER 11: "All Aspects Aligned"
**Theme:** Integration and Wholeness

**Part 11.2 - "The Inner Council"**
- **Trigger:** Complete 50 total focus sessions
- All Aspects form a circle
- Combined energy returns to Goacto
- Realization: The player IS the final piece

*The Realization:*
> DISCIPLINE: "We are fragments..."
> WISDOM: "...of a greater whole..."
> CREATIVITY: "...that whole is..."
> ALL: "...the human themselves. And us. And you, Agent."

**Part 11.3 - "Unity Achieved"**
- Mindscape dramatically transforms
- All zones now connected visually
- True hub evolution achieved

---

#### CHAPTERS 12-15: "Mastery"
**Theme:** Certification, Final Battles, Legacy

**Chapter 12: "The Contribution Exam"**
- Official Goactorian notification arrives
- Growth portfolio assembled
- 14-day streak required

**Chapter 13: "Masters of Resistance"**
- All Resistance enemies combine into "The Void"
- Ultimate boss battle representing total self-sabotage

*The Void Speaks:*
> "I am everything that holds the human back. I am the sum of every doubt, every fear, every excuse. You cannot defeat me... I AM them."

*Aspect Response:*
> "No. You are a PART of them. A part that can be acknowledged, managed, and transcended. We are ready."

**Chapter 14: "Contribution Certified"**
- 100 focus sessions required
- Official ceremony with Elder Council
- "Contribution Agent, First Class" title earned
- Realization: The journey IS the destination

**Chapter 15: "Pay It Forward"**
- Goacto becomes a mentor
- Helps train new agents
- Legacy system unlocked
- Credits roll with growth montage

---

### Emotional Design System

#### Core Emotional Journey
| Phase | Emotion | Player State |
|-------|---------|--------------|
| Act I | Wonder | "I'm part of something bigger" |
| Act II | Challenge | "This is hard but I'm growing" |
| Act III | Breakthrough | "I can see my transformation" |
| Act IV | Mastery | "I am becoming who I want to be" |

#### Never Punish, Always Encourage
- Broken streaks show "Recovery" not "Failed"
- Missed days trigger supportive dialogue
- Every return is celebrated
- Progress is never lost, only paused

#### The Goacto Frame Messaging
Always remind the player:
- An alien believes in them
- Their potential was detected across galaxies
- They were CHOSEN because they can do this
- Every action ripples across the cosmos

---

### Dialogue System

#### Aspect Conversations
Context-sensitive responses based on player progress:

**Discipline (When streak is broken):**
```
DISCIPLINE: "You missed a day. That happens. What matters is what happens next."

OPTIONS:
1. "I feel terrible about it."
   → "Feeling bad is information, not punishment. What will you do differently?"

2. "I'll get back on track."
   → "Good. Starting now. Not tomorrow. Now."

3. "Maybe this habit isn't right for me."
   → "Perhaps. Or perhaps the resistance is speaking. Sit with that question."
```

**Courage (Before a difficult task):**
```
COURAGE: "Something big ahead? I can feel your heart racing. That's good."
COURAGE: "Fear means you care. It means this matters."
COURAGE: "Let's walk INTO it, not around it."

OPTIONS:
1. "I'm scared I'll fail."
   → "Then fail. And try again. That's not tragedy - that's how anything good gets built."

2. "Let's do this."
   → "YES! I'll be right here with you."

3. "Maybe I should do something easier first."
   → "Is that wisdom... or comfort seeking? You decide."
```

---

### World Evolution Visual Stages

| Progress | Visual State | Description |
|----------|--------------|-------------|
| 0-10% | The Void | Barren platform, single dim light, no growth |
| 10-25% | First Growth | Small plants at edges, crystal glows, faint particles |
| 25-50% | Garden Emerges | Vegetation spreads, structures more detailed, ambient wildlife |
| 50-75% | The Sanctuary | Full lush environment, ornate structures, floating islands appear |
| 75-90% | The Cathedral | Massive crystalline structures, waterfalls of light, sacred feeling |
| 90-100% | Transcendence | Reality seems malleable, stars visible in ground, cosmic integration |

---

### Bedroom Evolution Stages

The bedroom visually evolves as items are installed:

**Stage 1: Basic (Start)**
```
┌────────────────────────────────┐
│ [Window]              [Fern]   │
│                                │
│                                │
│ [Sleep Pod]       [Earth]      │
│                                │
│            [Door]              │
└────────────────────────────────┘
```
- Sparse, empty feeling
- Minimal interaction points
- "Your journey begins here..."

**Stage 2: Connected (After Mindscape Console)**
- Console glows with connection
- Subtle particle effects
- Access to mindscape enabled

**Stage 3: Personal (After Wardrobe + Mirror)**
- Closet and mirror add warmth
- Player's chosen cosmetics reflected
- Personalization begins

**Stage 4: Established (After Data Archive)**
- Full bedroom complete
- Cozy, personalized space
- "This feels like home now"

---

### Trophy & Achievement System

#### Trophy Tiers
| Tier | Examples | XP Range |
|------|----------|----------|
| **Bronze** | Story milestones, first-time achievements | 10-50 |
| **Silver** | Streak milestones (7/14/21/30 days), session counts | 50-100 |
| **Gold** | Aspect mastery (Level 5+), major completions | 100-250 |
| **Platinum** | Secret achievements, year-long goals | 250-1000 |

#### Streak Trophy Progression
| Streak | Trophy Name | XP |
|--------|-------------|-----|
| 3 days | "Spark" | 25 |
| 7 days | "Flame" | 75 |
| 14 days | "Fire" | 100 |
| 21 days | "Inferno" | 150 |
| 30 days | "Eternal Flame" | 200 |
| 60 days | "Phoenix" | 300 |
| 90 days | "Solar" | 400 |
| 180 days | "Supernova" | 500 |
| 365 days | "Cosmic" | 1000 |

#### Focus Session Milestones
| Sessions | Trophy Name | XP |
|----------|-------------|-----|
| 10 | "Beginner's Mind" | 25 |
| 25 | "Focused" | 50 |
| 50 | "Concentrated" | 100 |
| 100 | "Deep Work" | 200 |
| 250 | "Flow State" | 300 |
| 500 | "Time Bender" | 500 |
| 1000 | "Transcendent" | 1000 |

#### Secret Trophies
| Trophy | Secret Condition | XP |
|--------|-----------------|-----|
| Early Bird | Complete 5 sessions before 7am | 100 |
| Night Owl | Complete 5 sessions after 10pm | 100 |
| Marathon | Complete 5 sessions in one day | 150 |
| Perfect Week | Complete all habits for 7 days | 200 |
| Perfect Month | Complete all habits for 30 days | 500 |
| Year One | Use app for 365 days | 1000 |
| The Collector | Find all lore entries | 300 |

---

### Ship & Mindscape Unlock Progression

#### Ship Room Unlocks
| Room | Unlock Trigger | Chapter |
|------|---------------|---------|
| Bedroom | Start | 1 |
| Kitchen | After intro cutscene | 1 |
| Hallway | After intro cutscene | 1 |
| Mail Room | First package notification | 1 |
| Observatory | 10 focus sessions | 4 |
| Cargo Hold | First shop purchase | 4+ |

#### Mindscape Zone Unlocks
| Zone | Unlock Trigger | Chapter |
|------|---------------|---------|
| Focus Chamber | Start | 1 |
| Daily Rituals | Discipline awakens | 2 |
| Reflection Pool | First reflection | 3 |
| Goal Compass | Set first goal | 4 |
| Training Arena | Doubt emerges | 5 |
| Aspect Shrine (full) | Compassion awakens | 6 |
| Script Lab | Creativity awakens | 7 |

#### Bedroom Item Delivery Schedule
| Item | Unlock Trigger | Package Contents |
|------|---------------|------------------|
| Mindscape Console | Complete Intro Part 1.2 | "Human Potential" console |
| Wardrobe Closet | First focus session | Closet unit for customization |
| Holographic Mirror | 3-day streak | Preview cosmetics |
| Data Archive | First reflection | View journals and history |

---

### Voice Line Requirements by Chapter

| Chapter | Speakers | Estimated Lines |
|---------|----------|-----------------|
| 1 | Goacto, Lumina, System | ~15 |
| 2 | Goacto, Discipline | ~12 |
| 3 | Goacto, Vitality, Lumina, Zyx | ~20 |
| 4 | Goacto, Wisdom, Arctis | ~15 |
| 5 | Goacto, Discipline, Doubt | ~18 |
| 6 | Goacto, Compassion, Chronos | ~15 |
| 7 | Goacto, Creativity | ~12 |
| 8 | Goacto, All Resistance, Family | ~25 |
| 9 | Goacto, Courage, Fear | ~18 |
| 10 | Goacto, Compassion | ~10 |
| 11 | All Aspects, Goacto | ~20 |
| 12-15 | Various | ~50 |

**Total: ~230 voice lines needed**

---

## Integration Points

### Signal-Based Event System

All managers communicate through Godot signals for loose coupling:

```gdscript
# Example: Habit completion flow
HabitManager.habit_completed.emit(habit_id, habit_data)
    ↓
GameManager._on_habit_completed(habit_id, habit_data):
    add_aspect_experience(domain_to_aspect[habit.domain], habit.exp_reward)
    evolve_world(habit.evolution_reward)
    ↓
AchievementManager._on_habit_completed(habit_id, habit_data):
    check_habit_achievements()
    ↓
CampaignManager._on_habit_completed(habit_id, habit_data):
    check_chapter_completion_requirements()
    ↓
SaveManager.save_game()  # Auto-save
```

### Scene Navigation
```gdscript
# Standard scene transition
GameManager.goto_scene("res://scenes/mindscape/mindscape_hub.tscn")

# With transition effect
TransitionManager.transition_to("res://scenes/bedroom/bedroom.tscn", "fade")
```

### Audio Integration
```gdscript
# Play contextual audio
AudioManager.play_music("res://audio/music/mindscape_ambient.ogg")
AudioManager.play_sfx("res://audio/sfx/habit_complete.wav")
AudioManager.play_voice("res://audio/voice/bedroom/mom_greeting.ogg")

# Focus session ambient
AudioManager.play_focus_ambient("space")  # Options: space, rain, forest, ship, mindscape
```

---

## Asset Pipeline

### Audio Organization
```
godot/audio/
├── sfx/
│   ├── focus_active.ogg
│   ├── focus_chamber.ogg
│   ├── habit_complete.wav
│   ├── achievement.ogg
│   ├── ui_click.wav
│   ├── portal_enter.wav
│   └── ambient_*.wav  # Various ambient sounds
│
├── music/
│   └── (Background tracks - TBD)
│
└── voice/  # Organized by scene/context
    ├── onboarding/slide_0-3.ogg
    ├── bedroom/*.ogg
    ├── bedroom/books/*.ogg
    ├── mindscape/*.ogg
    ├── intro_part1/*.ogg
    └── (aspect awakenings, story beats)
```

### Visual Assets
```
godot/assets/
├── sprites/
│   ├── ui/         # Buttons, icons, panels
│   ├── environment/  # Mindscape elements
│   ├── characters/   # Player, Aspects
│   └── enemies/      # Inner Resistance
│
├── backgrounds/      # Scene backdrops
├── fonts/           # Typography
└── shaders/         # Custom effects
```

### Brand Colors (ThemeConfig.gd)
```gdscript
# Primary Brand
const CHARCOAL = Color("#3D3D3D")
const GOLD = Color("#D4A84B")
const BRIGHT_GOLD = Color("#EBC059")

# Backgrounds
const DEEP_SPACE = Color("#0a0a12")
const SPACE = Color("#0f1019")
const NEBULA = Color("#1a1a2e")
const PANEL = Color("#16213e")

# Zone Accents
const FOCUS_GREEN = Color("#2ecc71")
const JOURNAL_BLUE = Color("#3498db")
const ASPECTS_PURPLE = Color("#9b59b6")
const GOALS_GOLD = Color("#f39c12")
const HABITS_TEAL = Color("#1abc9c")
const ARENA_RED = Color("#e74c3c")
const SCRIPTS_BRONZE = Color("#cd7f32")
```

---

## Development Guidelines

### Code Conventions

#### Naming
```gdscript
# Variables: snake_case
var player_data = {}
var current_streak = 0

# Constants: SCREAMING_SNAKE_CASE
const MAX_GRACE_DAYS = 3
const DEFAULT_SESSION_MINUTES = 25

# Signals: past_tense_verb or noun
signal habit_completed(habit_id, habit_data)
signal streak_recovered(habit_id, grace_days_used)

# Functions: snake_case, verb-first
func complete_habit(habit_id: String) -> bool:
func get_habit_by_id(id: String) -> Dictionary:
func is_zone_unlocked(zone_id: String) -> bool:
```

#### Signal Patterns
```gdscript
# Emission
HabitManager.habit_completed.emit(habit_id, habit_data)

# Connection
HabitManager.habit_completed.connect(_on_habit_completed)

# Handler naming
func _on_[source]_[signal_name](params):
func _on_habit_manager_habit_completed(habit_id, habit_data):
```

### Adding New Features

#### New Manager Checklist
1. Create `godot/autoload/NewManager.gd`
2. Add to `project.godot` autoload section
3. Define signals for external communication
4. Implement `get_save_data()` and `load_save_data()`
5. Register with SaveManager

#### New Scene Checklist
1. Create `.tscn` in appropriate `scenes/` subdirectory
2. Create matching `.gd` script
3. Inherit from base class if applicable
4. Add to navigation system (doors, portals)
5. Add ambient audio calls

#### New Achievement Checklist
1. Add definition to `AchievementManager.ACHIEVEMENTS`
2. Create condition check in relevant manager
3. Call `AchievementManager.check_achievement(id)`
4. Add trophy to `CampaignManager` if story-related

### Testing Considerations
- All managers are singletons (test in isolation difficult)
- Save/load cycle testing critical
- Test grace day edge cases
- Test streak calculations across day boundaries
- Test campaign progression gates

---

## GOACTO Ecosystem Integration

### Product Ecosystem Context

GOACTO is a broader self-improvement platform. This game ("Mindscape" or "Human Potential") is one touchpoint in a larger ecosystem that may include:

- **GOACTO Web Platform**: Browser-based dashboard
- **GOACTO Mobile App**: Native iOS/Android companion
- **GOACTO API**: Backend services for sync
- **GOACTO Community**: Social features, shared challenges

### Integration Opportunities

#### Data Synchronization
The game's save format is JSON-based, enabling:
```javascript
// Example sync payload
{
    "user_id": "goacto_user_123",
    "game_version": "0.1.0",
    "sync_timestamp": 1234567890,
    "habits": [/* Portable habit data */],
    "focus_sessions": [/* Session history */],
    "achievements": [/* Earned badges */],
    "evolution_level": 45.5
}
```

#### Shared Habit System
Habits created in the game could sync with a central GOACTO habit tracker:
- Same domain categories (Health, Learning, Mindfulness, Social, Productivity, Custom)
- Streak data portable across platforms
- XP rewards translatable to universal GOACTO points

#### Achievement Portability
Game achievements could unlock badges in the broader GOACTO ecosystem:
- Trophy tiers (Bronze/Silver/Gold/Platinum) map to platform rewards
- Story progression unlocks exclusive content
- Cross-platform recognition

#### Community Features (Future)
- Shared challenges (ChallengeManager compatible)
- Friend accountability (signal-based events)
- Leaderboards (opt-in, focus metrics)

### API Endpoints (Proposed)

```
POST /api/v1/sync/habits
POST /api/v1/sync/focus-sessions
POST /api/v1/sync/achievements
POST /api/v1/sync/evolution
GET  /api/v1/user/profile
GET  /api/v1/challenges/active
POST /api/v1/challenges/complete
```

### Webhook Events (Proposed)

The game could emit webhooks for key events:
```json
{
    "event": "habit_completed",
    "user_id": "goacto_user_123",
    "payload": {
        "habit_id": "move_your_body",
        "streak": 14,
        "timestamp": 1234567890
    }
}
```

### Configuration for Integration

Add to `project.godot` or separate config:
```ini
[goacto]
api_base_url="https://api.goacto.com"
sync_enabled=true
sync_interval_minutes=15
community_features=false  # Future
```

### Shared Brand Guidelines

All UI elements follow GOACTO brand standards:
- Gold accent (#D4A84B) for key interactions
- Deep space backgrounds (#0a0a12 to #1a1a2e)
- Encouraging, never punishing messaging
- Growth-oriented language

---

## Quick Reference

### Manager Access
```gdscript
GameManager.player_data["world_evolution_level"]
HabitManager.get_all_habits()
GoalManager.get_active_goals()
ScriptManager.get_all_scripts()
SaveManager.save_game()
CampaignManager.get_current_chapter()
AudioManager.play_sfx("res://audio/sfx/ui_click.wav")
ShopManager.purchase_item("golden_cape")
CustomizationManager.equip_cosmetic("cape", "golden_cape")
ChallengeManager.get_daily_challenges()
AchievementManager.check_achievement("first_focus")
```

### Common Operations
```gdscript
# Complete a habit
HabitManager.complete_habit("habit_id")

# Start focus session
GameManager.change_state(GameManager.GameState.FOCUS_MODE)

# Award XP
GameManager.add_aspect_experience("discipline", 50)

# Evolve world
GameManager.evolve_world(0.5)

# Check zone access
if GameManager.is_zone_unlocked("script_lab"):
    # Allow entry

# Transition scenes
GameManager.goto_scene("res://scenes/mindscape/mindscape_hub.tscn")
```

### File Paths
| Resource | Path |
|----------|------|
| Main Scene | `res://scenes/main_menu/main_menu.tscn` |
| Bedroom | `res://scenes/bedroom/bedroom.tscn` |
| Mindscape Hub | `res://scenes/mindscape/mindscape_hub.tscn` |
| Focus Mode | `res://scenes/focus_mode/focus_mode.tscn` |
| Player Save | `user://mindscape_save.json` |
| Settings | `user://mindscape_settings.json` |

---

---

## Complete Player Journey

### First-Time Player Experience (Day 1)

```
LAUNCH GAME
    ↓
Main Menu → "New Game"
    ↓
Onboarding (4 slides with voice narration):
    Slide 1: "You are Agent Goacto..."
    Slide 2: "Your mission: help a human grow..."
    Slide 3: "Every focus session helps them evolve..."
    Slide 4: "Are you ready to begin?"
    ↓
Kitchen Scene:
    • Goacto at window, gazing at stars
    • Mom notices restlessness
    • Dialogue about contribution certification
    • Directed to explore bedroom
    ↓
Bedroom (Minimal State):
    • Only fern, window, sleep pod, door visible
    • Console package notification appears
    • Navigate to mail room → collect console
    • Return → install console (installation animation)
    ↓
Console Activation:
    • "Human Potential v3.2" boot sequence
    • Earth scan visualization
    • "CANDIDATE DETECTED - Potential: EXCEPTIONAL"
    • Neural sync established
    ↓
First Mindscape Entry:
    • Barren, dark platform
    • Single light in distance
    • Ethereal, empty feeling
    • Exit crystal available to return
    ↓
Focus Chamber (Tutorial):
    • Basic timer interface
    • Select any topic OR freeform
    • 25-minute session (can end early for tutorial)
    ↓
First Session Complete:
    • Journal reflection (LAGG format)
    • Rewards: 50 XP to Discipline, evolution +0.5
    • "First Contact" trophy earned
    • Wardrobe package notification
    ↓
Return to Hub:
    • Subtle changes visible
    • "This is just the beginning..."
```

---

### Weekly Player Rhythm

**Typical Engaged Week:**

| Day | Activity | Reward |
|-----|----------|--------|
| Monday | Check-in + 1 focus session | Goals reset, fresh start |
| Tuesday | Habit completion + session | Streak building |
| Wednesday | Session + journal reflection | XP accumulation |
| Thursday | Session + explore new zone | Discovery rewards |
| Friday | Session + combat practice | Combat XP |
| Saturday | Multiple sessions (catch-up) | Bonus XP |
| Sunday | Weekly Synthesis ritual | 50 XP + reflection |

**Weekly Synthesis Flow:**
1. Auto-gathered stats displayed
2. Focus sessions completed
3. Habits maintained
4. Goals achieved
5. Written reflection prompts
6. 50 XP reward
7. New week motivation

---

### Long-Term Progression Arc

**Month 1: Foundation (Chapters 1-4)**
- Master basic focus sessions
- Establish 2-3 core habits
- Meet Discipline, Vitality, Wisdom
- Complete 15-20 sessions
- Reach evolution level ~15%

**Month 2: Growth (Chapters 5-7)**
- Face first challenges (Doubt, missed days)
- Use grace day system
- Meet Compassion, Courage, Creativity
- Unlock Script Lab
- Complete 40-50 total sessions
- Reach evolution level ~35%

**Month 3: Integration (Chapters 8-11)**
- Face Resistance Council
- Phoenix Protocol (if needed)
- All Aspects at Level 3+
- Unity ceremony
- Complete 75-100 sessions
- Reach evolution level ~60%

**Months 4-6: Mastery (Chapters 12-15)**
- Contribution Certification prep
- The Void boss battle
- 100+ sessions
- 30+ day streaks
- Evolution level 80-100%
- Full campaign completion

**Post-Campaign:**
- Prestige system available
- Aspect mastery (Level 10+)
- Community features
- Endless progression
- Secret achievement hunting

---

### The Complete Game Loop Visualized

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           REAL WORLD                                     │
│  Player decides to focus on personal growth                              │
└─────────────────────────────────────────┬───────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        STELLAR WANDERER (Ship)                          │
│                                                                          │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│   │ Bedroom  │────│ Hallway  │────│ Kitchen  │────│ Other    │         │
│   │ (Save,   │    │ (Hub)    │    │ (Family) │    │ Rooms    │         │
│   │ Console) │    │          │    │          │    │          │         │
│   └────┬─────┘    └──────────┘    └──────────┘    └──────────┘         │
│        │                                                                  │
│        │ Activate Mindscape Console                                      │
└────────┼────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      MINDSCAPE HUB (Inner World)                         │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────┐       │
│   │                    Central Platform                          │       │
│   │   • Evolution level visible                                  │       │
│   │   • Awakened Aspects present                                 │       │
│   │   • Garden patches growing                                   │       │
│   │   • Weather reflects progress                                │       │
│   └─────────────────────────────────────────────────────────────┘       │
│                                                                          │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│   │ Focus   │  │ Daily   │  │Reflect  │  │  Goal   │  │ Script  │      │
│   │ Chamber │  │ Rituals │  │  Pool   │  │ Compass │  │   Lab   │      │
│   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │
│        │            │            │            │            │             │
│        │            │            │            │            │             │
│   ┌────┴────┐  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐      │
│   │ Aspect  │  │Training │  │  North  │  │  East   │  │ South/  │      │
│   │ Shrine  │  │  Arena  │  │ Region  │  │ Region  │  │ West    │      │
│   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ Enter Focus Mode
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FOCUS MODE                                       │
│                                                                          │
│   1. Select Topic (habit-linked or freeform)                            │
│   2. Choose Difficulty (Easy 0.7x / Normal 1.0x / Hard 1.5x)            │
│   3. Choose Ambient (Silence, Space, Ship, Rain, Forest)                │
│   4. Optional: Load Script (25 lines displayed during session)          │
│   5. START → 25-minute timer                                            │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────┐       │
│   │                    REAL WORLD WORK                           │       │
│   │        (Phone aside, deep focus on chosen topic)             │       │
│   └─────────────────────────────────────────────────────────────┘       │
│                                                                          │
│   6. Timer complete OR manual COMPLETE                                  │
│   7. Journal Reflection (LAGG):                                         │
│      • Learned: What new knowledge?                                     │
│      • Accomplished: What was done?                                     │
│      • Goals: Next session intentions?                                  │
│      • Gratitude: Positive reflection?                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ Session Complete
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       REWARDS & PROGRESSION                              │
│                                                                          │
│   XP Calculation:                                                        │
│   • Base: 2 XP per minute (50 XP for 25 min)                            │
│   • Difficulty multiplier applied                                        │
│   • Streak bonus (10% per streak day, capped)                           │
│   • Challenge bonus (if applicable)                                      │
│                                                                          │
│   Distributed To:                                                        │
│   • Linked Aspect gains XP                                              │
│   • World evolution increases                                           │
│   • Achievement progress updates                                        │
│   • Campaign requirements checked                                        │
│   • Challenge progress tracked                                          │
│                                                                          │
│   Visible Changes:                                                       │
│   • Evolution bar increases                                             │
│   • Aspect level-up celebrations                                        │
│   • Hub visual improvements                                             │
│   • New zone unlocks (if threshold met)                                 │
│   • Story cutscene triggers                                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ Return to Hub
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        CONTINUE JOURNEY                                  │
│                                                                          │
│   Options:                                                               │
│   • Another focus session                                               │
│   • Check/complete habits in Daily Rituals                              │
│   • Review journals in Reflection Pool                                  │
│   • Set/track goals in Goal Compass                                     │
│   • Train combat in Training Arena                                      │
│   • Create/edit scripts in Script Lab                                   │
│   • Talk to Aspects at Shrine                                           │
│   • Explore regional zones                                              │
│   • Return to Ship (exit crystal)                                       │
│   • Shop for cosmetics                                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### Key Emotional Touchpoints

#### Moments of Wonder
- First mindscape entry (barren → potential)
- First Aspect awakening (golden light)
- Family dinner scene (connection)
- World evolution milestones (visual transformation)
- Certification ceremony (recognition)

#### Moments of Challenge
- First missed habit day (Doubt emerges)
- Resistance Council battle (multiple enemies)
- The Midnight Hour (everything stops)
- The Void boss battle (ultimate resistance)

#### Moments of Triumph
- First 7-day streak (Flame trophy)
- Each Aspect awakening (new ally)
- Unity ceremony (all Aspects aligned)
- Contribution Certification (official recognition)

#### Moments of Reflection
- Post-session journaling (daily)
- Weekly Synthesis ritual (weekly)
- Phoenix Protocol return (after break)
- Credits sequence (journey review)

---

### The GOACTO Promise

**To the Player:**
> "You were detected across galaxies because of your exceptional potential. An alien civilization believes you can grow. Every focus session proves them right. Every habit you build makes your inner world flourish. You are not alone in this journey - Agent Goacto walks beside you, and six Aspects of your own being are awakening to support you.
>
> The resistance will come - Doubt, Fear, Procrastination. They always do. But now you have the tools and companions to face them. And if you fall? You return. No judgment. Only welcome. Because the humans who return become the greatest of all.
>
> Growing Ourselves And Contributing To Others. That's not just a philosophy - it's a way of life. And it starts with a single focus session. Are you ready?"

---

## Document Maintenance

This document should be updated when:
- New managers are added
- Data structures change significantly
- New game mechanics are implemented
- Integration points are modified
- Campaign chapters are added
- Story content expands
- New emotional touchpoints are designed

**Last comprehensive review**: March 2026
**Document Version**: 1.1.0
