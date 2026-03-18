# Mindscape by GOACTO - Development Backlog

## Priority 1: Core Gameplay Polish

### Onboarding & First-Time Experience
- [x] Replace placeholder square icons in onboarding slides with proper themed icons (polygon graphics)
- [x] Add visual illustrations to each onboarding slide (mindscape visuals, habit examples)
- [x] Smooth transition from onboarding to first mindscape exploration
- [x] Tutorial tooltips for key UI elements on first visit (hub, bedroom, regions)

### Habit System Enhancements
- [x] Add habit reordering via drag-and-drop (drag handles, visual preview, drop highlighting)
- [x] Habit categories/tags for organization (comma-separated tags, tag colors)
- [x] Custom habit icons selection (25+ icons including emoji)
- [x] Habit reminders/notifications (per-habit time settings, day selection, in-app notifications)
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
- [x] Northern Gardens expansion (Seed Garden with intention planting, Wishing Fountain)
- [x] Eastern Shores activities (Tide Pool with wisdom creatures, Message Bottle to future self)
- [x] Western Depths expansion (Healing Pool with meditation, Memory Cave with journey stats)

### Audio
- [x] Generate core SFX (UI, focus, habits, portals)
- [x] Wire up ambient sounds to all scenes
- [x] Add music tracks for different areas (hub, ship, focus, regions)
- [ ] Voice acting for key dialogue (Mom, Narrator)
- [x] Dynamic audio mixing based on game state (8 audio states, mood modifiers, smooth transitions)

---

## Priority 3: Narrative & Content

### Story Progression
- [x] Chapter system with clear progression (10 chapters, 3 acts, objectives, progress tracking)
- [x] Cutscene system for key story moments (full dialogue system, typewriter, voice support)
- [x] Chapter UI panel with journey overview and objectives
- [x] Cutscene Theater for replaying past scenes
- [x] Character relationship tracking (Mom, Aspects, bond levels, progress tracking, UI display)
- [ ] Multiple ending possibilities based on habits

### Aspects (Discipline, Focus, etc.)
- [x] Aspect awakening ceremonies (visual ceremony at levels 2/3/5/7/10 with speeches)
- [x] Aspect dialogue trees (advice, encouragement, challenges, progress sharing)
- [x] Aspect-specific quests/challenges (18 quests, 3 per aspect, difficulty tiers, auto-tracking, rewards)
- [x] Aspect evolution visuals (dynamic shrine graphics, evolution tiers, XP progress bars, level-based effects)

### Lore & World-Building
- [x] Data archive entries (expanded to 11 books with ship logs, traditions, aspects, letters, mission briefing)
- [x] Photo album with family history (12 photos, chapter-based unlocking, family memories)
- [x] Ship logs and mission details (included in Data Archive)
- [x] Goactorian culture exposition (included in Data Archive)

---

## Priority 4: Systems & Features

### Progression System
- [x] XP and leveling system (Aspect XP, evolution levels)
- [x] Unlockable cosmetics/decorations (Shop with skin colors, outfits, accessories)
- [x] Player appearance rendering (equipped items show on player sprite)
- [x] Campaign progression gates (bedroom items unlock with engagement)
- [x] Evolution stages for mindscape (5 tiers with crystals, floating islands, runes, mystical aura)
- [x] Achievement system with rewards (45+ achievements, XP rewards, notifications, progress tracking)
- [x] Garden patches evolution based on habits

### Social Features (Future)
- [ ] Friend system for accountability
- [ ] Shared challenges
- [ ] Community goals
- [ ] Leaderboards (opt-in)

### Accessibility
- [x] Font size options (small/medium/large in Settings)
- [x] High contrast mode (toggle in Settings)
- [ ] Screen reader support
- [x] Reduced motion option (toggle in Settings)
- [x] Colorblind-friendly indicators (deuteranopia/protanopia/tritanopia modes in Settings)

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
- [x] Mobile touch controls optimization (interact button, auto-hide on panels)
- [x] iOS/Android export setup (export presets configured)
- [ ] Desktop window management
- [ ] Steam/itch.io integration

---

## Known Bugs to Fix

- [x] Mindscape onboarding panel node lookup error (fixed: path-based lookup with fallback)
- [x] Check for null references in animation callbacks (verified: is_instance_valid used)
- [x] Verify all voice file paths exist before playing (verified: ResourceLoader.exists checks)
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
- [x] Northern Gardens Expansion (Seed Garden with 6 seed types, intention planting, watering system, growth levels; Wishing Fountain with wish casting, categories, fulfillment tracking)
- [x] Eastern Shores Activities (Tide Pool with 10 wisdom creatures collection, seek wisdom feature; Message Bottle with timed delivery to future self, archive)
- [x] Achievement System Enhanced (45+ achievements across 6 categories, XP rewards, progress tracking, notification popups, achievement pedestals in hub)
- [x] Western Depths Expansion (Healing Pool with breathing exercises/meditation, Memory Cave with journey stats/history review)
- [x] Chapter System & Story UI (10 chapters across 3 acts, progress tracking, objectives, journey panel in hub)
- [x] Cutscene Theater (replay past scenes, 13 cutscenes with full dialogue, character portraits, transitions)
- [x] Aspect Awakening Ceremonies (level 2/3/5/7/10 ceremonies with unique speeches per aspect)
- [x] Music wired to all scenes (hub, ship, focus, all mindscape regions)
- [x] Accessibility Options (font size, high contrast, reduced motion, colorblind modes)
- [x] Compact progress popup (bottom-left corner, horizontal stats bar)
- [x] Habit custom icons (25+ emoji icons for habits)
- [x] Habit tags system (comma-separated tags, tag filtering in habits view)
- [x] Aspect dialogue enhancements (challenges, progress sharing, contextual responses)
- [x] Character Relationship Tracking (Mom & 6 aspects, bond levels, progress tracking, UI display in Progress tab)
- [x] Aspect Quest System (18 quests across 6 aspects, 3 difficulty tiers, auto-tracking, XP & bond rewards)
- [x] Aspect Evolution Visuals (dynamic shrine graphics, evolution tiers, animated rings/particles, XP progress bars)
- [x] Data Archive Expansion (11 lore books: ship logs, Goactorian traditions, Six Aspects study, Mom's letters, mission briefing)
- [x] Script Lab template preview (View All Lines button shows full 25-line script before applying)
- [x] Family Photo Album (12 photos with chapter-based unlocking, family memories, visual representations)
- [x] Dynamic Audio Mixing (8 audio states, mood-based modifiers, smooth crossfade transitions, integration with focus/meditation/achievements)
- [x] Accessibility Settings UI (font size, high contrast, reduced motion, colorblind modes in Settings menu)
- [x] Bedroom tutorial tooltips (first-time visitor guidance for key interactions)
- [x] Sleep pod save/load menu (Quick Save, Quick Load, Manage Save Slots)
- [x] Master key photo album unlock (master key holders can view all family photos)
- [x] Mindscape Evolution Stages (5 tiers: platform crystals, floating islands, ancient runes, mystical aura, tier-up celebrations)
- [x] Habit Reminders System (per-habit time/day settings, in-app notifications, reminder UI)
- [x] Daily Login Rewards System (30-day reward cycle, streak tracking, special bonuses at milestones)
- [x] Personal Milestones Celebrations (7/14/30/60/90/180/365 day achievements with XP rewards and titles)
- [x] Companion Evolution System (8 evolution stages based on login days, visual changes, accessories)
- [x] Expanded Bedroom Layout (plus-shaped room with proper bounds, reorganized furniture)

---

## Immediate Next Steps (Suggested)

1. **Multiple Endings** - Story branches based on habits
2. **Voice acting for key dialogue** - Mom, Narrator voices
3. **Screen reader support** - Accessibility enhancement
4. **Code refactoring** - Reduce duplicate code across scenes

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
