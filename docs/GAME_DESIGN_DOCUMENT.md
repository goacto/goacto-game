# Mindscape - Game Design Document

## Vision Statement
**Mindscape** is a 2.5D isometric RPG where your inner world — your personal home base — grows as you do. By completing real-world focus sessions, tracking habits, and reflecting through journaling, players evolve their base, develop aspects of themselves, and connect with others on the same journey.

**Core Philosophy (GOACTO):** Growing Ourselves And Contributing To Others

---

## The Home Base

Your mindscape is a personal sanctuary that reflects your growth. It's structured as a **hub with distinct zones**, each serving a purpose:

| Zone | Purpose | Function |
|------|---------|----------|
| **Focus Chamber** | Deep work | Start timed focus sessions, linked to habits or freeform |
| **Reflection Pool** | Journaling | View past entries, see growth over time |
| **Aspect Shrine** | Character growth | Meet and develop your Aspects |
| **Goal Compass** | Objectives | Set and track intentions (future) |
| **Daily Rituals** | Habits | Check off daily habits, see streaks |
| **Training Arena** | Combat | Battle inner resistance enemies |

---

## Core Loop

```
┌─────────────────────────────────────────────────────────┐
│                      HOME BASE                           │
│  • Navigate between zones                                │
│  • Check habits, talk to Aspects                         │
│  • See your base evolve as you grow                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   FOCUS CHAMBER                          │
│  • Select topic/habit                                    │
│  • Start 25-minute timer                                 │
│  • Put phone aside, do real work                         │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  QUICK REFLECTION                        │
│  • What did you learn?                                   │
│  • What did you accomplish?                              │
│  • Goals for next session?                               │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    RETURN TO BASE                        │
│  • See base evolution increase                           │
│  • Aspects gain experience                               │
│  • Journal entry saved                                   │
└─────────────────────────────────────────────────────────┘
```

---

## Technical Specifications

| Aspect | Choice |
|--------|--------|
| Engine | Godot 4 |
| Platform | Cross-platform, mobile-first |
| Visual Style | 2.5D Isometric |
| Art Style | Hand-painted with retro/nostalgic hints |
| Monetization | Freemium (AI features premium, offline mode free) |

---

## Systems Overview

### 1. Habit Tracking System

Players define and track real-world habits across domains:

| Domain | Examples | Powers Aspect |
|--------|----------|---------------|
| Health | Exercise, sleep, nutrition | Vitality |
| Learning | Reading, skill practice | Creativity |
| Mindfulness | Meditation, gratitude | Wisdom |
| Social | Connection, kindness | Compassion |
| Productivity | Focus sessions, deep work | Discipline |
| Growth | Fear-facing, challenges | Courage |

**Mechanics:**
- Habits have frequency (daily, weekly, custom)
- Streaks multiply rewards
- Habits directly power related Aspect growth
- Graceful handling of missed days (no harsh punishment)

### 2. Focus Session System

The Focus Chamber provides a clean interface for deep work:

1. **Select topic** — Quick session or habit-linked
2. **Start timer** — Default 25 minutes (Pomodoro)
3. **Work** — Phone aside, real-world focus
4. **Reflect** — Quick journal entry:
   - What did you learn?
   - What did you accomplish?
   - Goals for next session?
5. **Return** — See progress reflected in base evolution

### 3. Journaling System

Entries are saved with:
- Timestamp and date
- Topic/habit reference
- Duration
- Three reflection prompts
- Growth metrics

Players can review past entries in the Reflection Pool.

### 4. Goal Compass System

The Goal Compass is where players set and track objectives:

**Goal Types:**

| Type | Duration | Reward | Use Case |
|------|----------|--------|----------|
| **Daily** | Resets each day | 15 XP, 0.3 evolution | Quick intentions, today's focus |
| **Weekly** | Resets each week | 50 XP, 1.0 evolution | This week's priorities |
| **Milestone** | Until completed | 100 XP, 2.5 evolution | Bigger targets with progress tracking |

**Goal Structure:**
- Title (what you want to accomplish)
- Linked Aspect (which part of yourself it develops)
- Target progress (for milestones with multiple steps)
- Status (active, completed, archived)

**Features:**
- Create goals linked to any of the 6 Aspects
- View goals by timeframe (Today / Week / Milestone tabs)
- Check off completed goals
- Increment progress for milestone goals
- Automatic daily/weekly reset (incomplete goals archived, no punishment)

**Integration:**
- Completing goals awards XP to the linked Aspect
- Completing goals contributes to base evolution
- Goals provide structure alongside habits

### 5. Character System

**Aspects (Party Members):**
Six Aspects represent parts of yourself:

| Aspect | Domain | Color | Personality |
|--------|--------|-------|-------------|
| **Discipline** | Productivity | Blue | Stern but encouraging |
| **Courage** | Growth | Red | Bold, adventurous |
| **Creativity** | Learning | Purple | Playful, abstract |
| **Compassion** | Social | Green | Warm, nurturing |
| **Wisdom** | Mindfulness | Gold | Calm, insightful |
| **Vitality** | Health | Bright Green | Energetic, physical |

Each Aspect:
- Levels up through related habits and focus sessions
- Has unique abilities in combat
- Provides dialogue and guidance
- Unlocks as player progresses (Discipline starts unlocked)

**Archetype Guides (AI NPCs - Premium):**
- Mentor figures with contextual conversations
- Different personalities per archetype
- Available offline with pre-written dialogue (free tier)

### 6. Combat/Challenge System

**Inner Resistance Enemies:**
- Doubt, Fear, Procrastination, Distraction, Anxiety
- Defeated through Aspect abilities

**Combat Mechanics:**
- Turn-based, party-based
- Aspects use abilities tied to their domain
- Real-world habit streaks provide combat bonuses
- No harsh penalties for defeat — encouragement to return

### 8. Script Lab System (Personal OS)

**Philosophy:** *"Life is the result of the scripts we allow ourselves to run."*

The Script Lab allows players to code their own operating system for life.

**Structure:**
```
YourName.OS (Personal Operating System)
├── mind.layer
│   ├── learning.pkg
│   │   ├── reading.psa (25 lines of code)
│   │   └── course_study.psa
│   └── focus.pkg
├── body.layer
├── soul.layer
├── social.layer
├── career.layer
└── wealth.layer
```

**Components:**

| Component | Extension | Description |
|-----------|-----------|-------------|
| Layer | .layer | Life domain (Mind, Body, Soul, Social, Career, Wealth) |
| Package | .pkg | Group of related scripts (e.g., morning_routine.pkg) |
| Script (PSA) | .psa | Personal Self Action - 25 lines = 25 minute focus session |

**Script Types (.posl):**

| Type | Color | Purpose |
|------|-------|---------|
| **update** | Blue | Learning & improvement activities |
| **upgrade** | Green | Paradigm shifts that level you up |
| **downgrade** | Orange | Routines/apps slowing your system (to remove) |
| **virus** | Red | Limiting beliefs to debug and address |

**PSA File Structure:**
- 25 lines of code (actions/intentions)
- Each line = approximately 1 minute of focus
- Lines are displayed during focus sessions with progress highlighting

**Batch Execution:**
- Packages can be run as batches
- Example: 4 scripts in morning_routine.pkg = 100 minute session
- Each script gets its own journal entry
- Seamless transitions between scripts

**Integration:**
- Scripts are linked to Layers, which map to Aspects
- Running scripts awards XP to the corresponding Aspect
- Script execution feeds base evolution

---

### 9. Base Evolution System

As you grow IRL, your home base transforms:

| Progress | Visual Change |
|----------|---------------|
| 0-20% | Barren, dim |
| 20-40% | First growth appears |
| 40-60% | Structures emerge |
| 60-80% | Vibrant, alive |
| 80-100% | Flourishing sanctuary |

**Setback Handling:**
- Graceful fade (base dims slowly, doesn't punish)
- Gentle signals (NPCs express concern, encourage return)
- No permanent regression

---

## Prototype Scope

### Current Features:
- [x] Home base with 6 navigable zones
- [x] Focus Chamber with timer
- [x] Quick reflection journaling
- [x] Reflection Pool to view entries
- [x] All 6 Aspects with dialogue
- [x] Daily Rituals habit tracking
- [x] Training Arena combat
- [x] Base evolution visuals
- [x] Save/load system
- [x] Goal Compass with daily/weekly/milestone goals

- [x] Script Lab - Personal OS with layers, packages, and PSA files

### Coming Next:
- [ ] Aspect unlock progression
- [ ] More enemies and combat depth
- [ ] Custom habit creation UI
- [ ] AI NPC conversations (premium)
- [ ] Multiplayer features

---

## File Structure

```
godot/
├── project.godot
├── autoload/
│   ├── GameManager.gd      # Global game state, Aspects
│   ├── HabitManager.gd     # Habit tracking
│   └── SaveManager.gd      # Persistence
├── scenes/
│   ├── main_menu/          # Title screen
│   ├── mindscape/          # Home base hub
│   ├── focus_mode/         # Focus session + journaling
│   └── combat/             # Battle system
├── scripts/
│   └── player/             # Avatar (for future exploration)
└── assets/
    └── sprites/audio/fonts/shaders
```

---

## Development Phases

### Phase 1: Prototype (Current)
- Core loop functional
- All zones accessible
- Placeholder art

### Phase 2: Vertical Slice
- Polished art for base
- Goal system complete
- Aspect unlock progression

### Phase 3: Alpha
- Full content
- All combat enemies
- Quest system

### Phase 4: Beta
- AI NPC integration
- Multiplayer foundations
- Polish and balance

### Phase 5: Launch
- Mobile release (iOS/Android)
- Desktop follows

---

*Document Version: 0.4*
*Last Updated: March 2026*
