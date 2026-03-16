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
- [x] Weekly/monthly habit statistics view (toggle, completion rates, per-habit stats)
- [x] Habit streaks celebration animations (confetti, sparkles at 3/7/14/21/30/60/90/100 days)

### Focus Mode Improvements
- [x] Session notes during focus timer (collapsible panel, saves to journal)
- [x] Return to spawn position near Focus Chamber after session
- [x] Focus Analytics Dashboard (bedroom, unlocks after 1st session)
- [x] Background audio/ambient sounds during focus sessions (5 options: silence, space, ship, rain, forest)
- [x] Pomodoro-style break reminders (25-min intervals, mini-break timer)
- [x] Session completion rewards (XP bonuses, visual effects)

### Self-Improvement Features (NEW)
- [x] Daily Check-In System (mood/energy tracking, trends, history)
- [x] Weekly Synthesis Ritual (auto-gathered stats, reflections, XP rewards)
- [x] Values Compass (define 3-5 core values, weekly alignment check)
- [x] Kindness/Contribution Log (6 categories, streak tracking, Compassion XP)
- [x] Affirmations system (daily positive statements, custom affirmations, streaks)
- [x] Relationship health tracker (add relationships, log interactions, health levels, streaks, Compassion XP)
- [x] Gratitude prompts integration with check-ins (random prompts, +5 bonus XP, history display)

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
- [x] Hallway interactive elements (bulletin board, ship status, achievements, poster)
- [x] Mail room package collection flow (collect individual/all, item lists)
- [x] Add detail views for sleep pod (dream sequences, rest meditation)

### Mindscape Hub
- [x] Gateway portal graphics (themed decorations for each direction)
- [x] Portal transition animations (centered, fullscreen, viewport responsive)
- [x] Hub orbs refined (smaller, subtle glows)
- [x] Experience Shop (purchase cosmetics with XP)
- [x] Daily Check-In tab in Reflection Pool
- [x] Weekly Synthesis tab in Reflection Pool
- [x] Expand platform size for more exploration space (65% larger, pathway markers, 4 discovery zones)
- [x] Progress indicators (streak flames, evolution ring with level colors)
- [x] Garden patches evolution based on habits (6 domain patches, 5 growth levels)
- [x] Achievement pedestals showing recent unlocks (3 pedestals, 20+ achievements)
- [x] Lore stones with discoverable backstory (3 stones with world-building content)
- [x] Companion spirit NPC with contextual tips (floating orb, follows player)
- [x] Weather/atmosphere changes based on progress (5 atmosphere levels, aurora for streaks)

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
- [x] Garden patches evolution based on habits

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
- [x] Affirmations system (daily positive statements, custom affirmations, streaks)
- [x] Progress indicators (streak flames, evolution ring in hub)
- [x] Background Focus Audio (space, rain, forest ambient sounds)
- [x] Hallway enhancements (bulletin board, ship status, achievements, poster)
- [x] Habit streak celebrations (confetti, sparkles at milestones)
- [x] Garden patches evolution (6 domains, 5 growth levels based on habit streaks)
- [x] Lore stones (3 discoverable backstory stones in hub)
- [x] Gratitude prompts integration (random prompts, +5 bonus XP, history display)
- [x] Weather/Atmosphere changes (5 levels, aurora for streaks)
- [x] Pomodoro break reminders (25-min intervals, mini-break timer)
- [x] Sleep pod dream sequences (progress-based dreams, rest meditation)
- [x] Hub platform expansion (65% larger, pathway markers, 4 discovery zones)
- [x] Script Lab template library (18 curated templates across all domains/operational types)
- [x] Relationship Health Tracker (RelationshipManager autoload, 6 categories, 10 interaction types, health levels, streaks, Compassion XP rewards)
- [x] CLAUDE.md comprehensive app overview document (~2100 lines, full story bible, system documentation)

---

## Immediate Next Steps (Suggested)

1. **Northern Gardens Expansion** - More interactive plants and activities
2. **Eastern Shores Activities** - Water-themed interactive elements
3. **Chapter System** - Clear story progression with cutscenes
4. **Music Tracks** - Add ambient music for different areas
5. **Accessibility Options** - Font size, high contrast, colorblind modes

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
