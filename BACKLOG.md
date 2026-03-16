# Mindscape by GOACTO - Development Backlog

## Priority 1: Core Gameplay Polish

### Onboarding & First-Time Experience
- [ ] Replace placeholder square icons in onboarding slides with proper themed icons
- [ ] Add visual illustrations to each onboarding slide (mindscape visuals, habit examples)
- [ ] Smooth transition from onboarding to first mindscape exploration
- [ ] Tutorial tooltips for key UI elements on first visit

### Habit System Enhancements
- [ ] Add habit reordering via drag-and-drop (cleaner than arrow buttons)
- [ ] Habit categories/tags for organization
- [ ] Custom habit icons selection
- [ ] Habit reminders/notifications integration
- [ ] Weekly/monthly habit statistics view
- [ ] Habit streaks celebration animations

### Focus Mode Improvements
- [x] Session notes during focus timer (collapsible panel, saves to journal)
- [x] Return to spawn position near Focus Chamber after session
- [ ] Background audio/ambient sounds during focus sessions
- [ ] Focus session statistics and history
- [ ] Pomodoro-style break reminders
- [ ] Session completion rewards (XP bonuses, visual effects)

---

## Priority 2: Visual & Audio Polish

### Room Scenes (Ship)
- [x] Kitchen space view with unique elements
- [x] Stairs space view with Starship
- [x] Bedroom space view with galaxy/moon
- [x] Bedroom fern detail view
- [ ] Hallway unique interactive elements
- [ ] Add detail views for bookshelf (individual book interactions)
- [ ] Add detail views for sleep pod (dream sequences?)

### Mindscape Hub
- [x] Gateway portal graphics (themed decorations for each direction)
- [x] Portal transition animations (centered, fullscreen, viewport responsive)
- [x] Hub orbs refined (smaller, subtle glows)
- [ ] Expand platform size for more exploration space
- [ ] Add progress indicators (streak flames, evolution ring, garden patches)
- [ ] Achievement pedestals showing recent unlocks
- [ ] Lore stones with discoverable backstory
- [ ] Companion spirit NPC with contextual tips
- [ ] Weather/atmosphere changes based on progress

### Audio
- [x] Generate core SFX (UI, focus, habits, portals)
- [x] Wire up ambient sounds to all scenes
- [ ] Add music tracks for different areas
- [ ] Voice acting for key dialogue (Mom, Narrator)
- [ ] Dynamic audio mixing based on game state

---

## Priority 3: Narrative & Content

### Story Progression
- [ ] Chapter system with clear progression
- [ ] Cutscene system for key story moments
- [ ] Character relationship tracking (Mom, Aspects)
- [ ] Multiple ending possibilities based on habits

### Aspects (Discipline, Focus, etc.)
- [ ] Aspect awakening ceremonies
- [ ] Aspect dialogue treesww
- [ ] Aspect-specific quests/challenges
- [ ] Aspect evolution visuals

### Lore & World-Building
- [ ] Data archive entries (readable lore)
- [ ] Photo album with family history
- [ ] Ship logs and mission details
- [ ] Goactorian culture exposition

---

## Priority 4: Systems & Features

### Progression System
- [ ] XP and leveling system
- [ ] Evolution stages for mindscape
- [ ] Unlockable cosmetics/decorations
- [ ] Achievement system with rewards

### Social Features (Future)
- [ ] Friend system for accountability
- [ ] Shared challenges
- [ ] Community goals
- [ ] Leaderboards (opt-in)

### Accessibility
- [ ] Font size options
- [ ] High contrast mode
- [ ] Screen reader support
- [ ] Reduced motion option
- [ ] Colorblind-friendly indicators

---

## Priority 5: Technical & Performance

### Code Quality
- [ ] Refactor duplicate code across room scenes
- [ ] Create reusable space view component
- [ ] Centralize animation constants
- [ ] Add unit tests for HabitManager

### Performance
- [ ] Profile and optimize particle systems
- [ ] Lazy loading for heavy scenes
- [ ] Memory usage optimization
- [ ] Save data compression

### Platform Support
- [ ] Mobile touch controls optimization
- [ ] iOS/Android export setup
- [ ] Desktop window management
- [ ] Steam/itch.io integration

---

## Known Bugs to Fix

- [ ] Mindscape onboarding panel node lookup error (mitigated)
- [ ] Check for null references in animation callbacks
- [ ] Verify all voice file paths exist before playing
- [x] TextEdit autowrap parser error (fixed: use TextEdit.LINE_WRAPPING_BOUNDARY)
- [x] Southern Peaks invisible terrain (fixed: container ordering, not negative z_index)
- [x] Portal transition off-center (fixed: dynamic viewport centering)
- [x] Bedroom movement delay on continue (fixed: non-blocking wake-up animation)

---

## Recently Completed

- [x] Bedroom visual enhancements (hologram, particles, floor lighting)
- [x] Animated fern with swaying and bioluminescence
- [x] Sleep pod holographic status display
- [x] Personal items (photo frame, floating trinket, memory crystal)
- [x] Proximity highlight glows for interactive objects
- [x] Space views for all windows (kitchen, stairs, bedroom)
- [x] SPACE key to close all fullscreen views
- [x] Hidden reorder arrows in habit list (cleaner UI)
- [x] Daily Rituals panel repositioned to right side
- [x] Fern detail view with large animated fern graphic
- [x] Hub orbs refined (smaller, more subtle, less distracting)
- [x] Focus Chamber 1/3, 2/3 zone panel layout
- [x] Gateway portal graphics (nature/celestial/crystal/mountain themes)
- [x] Focus session notes panel (collapsible, carries to journal)
- [x] Script Lab button navigates to Southern Peaks
- [x] Southern Peaks graphics fix (proper container ordering, brighter terrain)
- [x] Wake-up animation for continue journey (non-blocking)
- [x] Focus session return spawns near Focus Chamber
- [x] Mindscape ambient audio looping fix
- [x] Portal transition dynamic centering (viewport responsive)
- [x] Eastern Observatory graphics enhancement

---

## Immediate Next Steps (Suggested)

1. **Western Depths Enhancement** - Bring graphics up to par with other regions
2. **Progress Indicators** - Add streak flames, evolution ring to hub
3. **Hub Platform Expansion** - Larger exploration area
4. **Hallway Enhancements** - Bring hallway up to par with other rooms
5. **Music Integration** - Add background music tracks
6. **Achievement Pedestals** - Display recent unlocks in hub
7. **Onboarding Icons** - Replace square placeholders with proper icons

---

## Design Notes

### Visual Style
- Polygon-based 2D graphics (no external assets required)
- Color palette: deep purples, teals, golds, soft greens
- Isometric 2.5D perspective for room scenes
- Glowing/pulsing effects for interactive elements

### Audio Style
- Ambient ship hum for Stellar Wanderer scenes
- Ethereal/mystical sounds for Mindscape
- Satisfying UI feedback sounds
- Calm, encouraging tone throughout

### Narrative Tone
- Gentle encouragement, never punishing
- Focus on growth and self-improvement
- Sci-fi setting with emotional core
- Family bonds and connection themes
