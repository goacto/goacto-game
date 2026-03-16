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
- [x] Focus Analytics Dashboard (bedroom, unlocks after 1st session)
- [ ] Background audio/ambient sounds during focus sessions
- [ ] Pomodoro-style break reminders
- [ ] Session completion rewards (XP bonuses, visual effects)

### Self-Improvement Features (NEW)
- [x] Daily Check-In System (mood/energy tracking, trends, history)
- [x] Weekly Synthesis Ritual (auto-gathered stats, reflections, XP rewards)
- [x] Values Compass (define 3-5 core values, weekly alignment check)
- [x] Kindness/Contribution Log (6 categories, streak tracking, Compassion XP)
- [ ] Affirmations system (daily positive statements)
- [ ] Relationship health tracker
- [ ] Gratitude prompts integration with check-ins

---

## Priority 2: Visual & Audio Polish

### Room Scenes (Ship)
- [x] Kitchen space view with unique elements
- [x] Stairs space view with Starship
- [x] Bedroom space view with galaxy/moon
- [x] Bedroom fern detail view
- [x] Wardrobe customization UI (closet, category tabs, preview, equip)
- [x] Data archive/bookshelf (6 interactive books with lore)
- [x] Holographic mirror (avatar preview)
- [x] Bedroom item progression gates (locked visuals, unlock hints)
- [x] Observatory telescope viewer (6 celestial objects, XP rewards)
- [x] Observatory meditation panel (breathing exercises)
- [x] Viewing balcony telescope (5 discoverable objects)
- [x] Viewing balcony meditation bench (timed sessions)
- [x] Console placement system (find in storage, place in bedroom)
- [x] Room access gating (observatory, mail room unlock conditions)
- [ ] Hallway unique interactive elements
- [ ] Mail room package collection flow
- [ ] Add detail views for sleep pod (dream sequences?)

### Mindscape Hub
- [x] Gateway portal graphics (themed decorations for each direction)
- [x] Portal transition animations (centered, fullscreen, viewport responsive)
- [x] Hub orbs refined (smaller, subtle glows)
- [x] Experience Shop (purchase cosmetics with XP)
- [x] Daily Check-In tab in Reflection Pool
- [x] Weekly Synthesis tab in Reflection Pool
- [ ] Expand platform size for more exploration space
- [ ] Add progress indicators (streak flames, evolution ring, garden patches)
- [ ] Achievement pedestals showing recent unlocks
- [ ] Lore stones with discoverable backstory
- [ ] Companion spirit NPC with contextual tips
- [ ] Weather/atmosphere changes based on progress

### Mindscape Regions
- [x] Values Compass in Goal Compass (South)
- [x] Kindness Log in Aspect Shrine (West)
- [x] Constellation mini-game in observatory
- [ ] Northern Gardens expansion (more interactive plants)
- [ ] Eastern Shores activities
- [ ] Western Depths graphics enhancement

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
- [x] XP and leveling system (Aspect XP, evolution levels)
- [x] Unlockable cosmetics/decorations (Shop with skin colors, outfits, accessories)
- [x] Player appearance rendering (equipped items show on player sprite)
- [x] Campaign progression gates (bedroom items unlock with engagement)
- [ ] Evolution stages for mindscape (visual changes)
- [ ] Achievement system with rewards
- [ ] Garden patches evolution based on habits

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

## Recently Completed (March 2026)

- [x] Daily Check-In System (mood/energy sliders, trends, history)
- [x] Weekly Synthesis Ritual (auto stats, reflections, 50 XP reward)
- [x] Values Compass (3-5 core values, weekly alignment check)
- [x] Kindness/Contribution Log (6 categories, streaks, Compassion XP)
- [x] Wardrobe customization UI (category tabs, preview, equip/apply)
- [x] Player appearance rendering (skin colors, outfits, accessories on sprite)
- [x] Data archive with 6 interactive lore books
- [x] Bedroom item progression gates (locked visuals, unlock requirements)
- [x] Focus Analytics Dashboard (stats, graphs, history, insights)
- [x] Observatory telescope viewer (6 celestial objects, XP rewards)
- [x] Observatory meditation panel (breathing exercises, timed sessions)
- [x] Viewing balcony telescope and meditation bench
- [x] Console placement system (find in storage, place in bedroom)
- [x] Room access gating (observatory, mail room unlock conditions)
- [x] Constellation mini-game (5 constellations, XP rewards)
- [x] Package management UI in Script Lab
- [x] ShipSceneBase class for code reuse
- [x] GitHub repository created and pushed

---

## Immediate Next Steps (Suggested)

1. **Affirmations System** - Daily positive statements with reminders
2. **Progress Indicators** - Add streak flames, evolution ring to hub
3. **Hub Platform Expansion** - Larger exploration area with more zones
4. **Hallway Enhancements** - Interactive elements, visual polish
5. **Mail Room Package Flow** - Collect and open packages
6. **Achievement Pedestals** - Display recent unlocks in hub
7. **Background Focus Audio** - Ambient sounds during focus sessions
8. **Garden Patches** - Visual evolution based on habit completion

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
