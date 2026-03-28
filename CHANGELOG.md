# Mindscape by GOACTO - Changelog

> A record of the journey. Every feature, fix, and milestone.

---

## [0.1.0-prototype] - March 2026

### March 28, 2026 - Polish & Quality of Life
- **Feedback System**: "Report Bugs & Share Feedback" button with Google Form integration, auto-fills game context (version, platform, player name, evolution level, chapter, scene)
- **Settings Fix**: Fixed crash when opening settings from main menu (`get_font_size_scale` renamed to `get_font_size_multiplier`)
- **Kitchen Dialogue**: Dr. Lumina's greeting now plays only once automatically, not every re-entry
- **Old Storage Voice Lines**: Wired up 5 voice line slots for the storage room (room enter, console found, examine chest/shelf/portrait)
- **Tutorial Fix**: Skipping onboarding now marks all tutorial tooltips as seen (no more re-appearing tips)
- **Tutorial Z-Index**: Tutorial tooltips now render above zone labels (no more text overlap)
- **Console Alert Fix**: "Console Ready" hint no longer shows after player has already entered mindscape
- **Web Save Persistence**: Added `FS.syncfs()` calls after every save/delete to prevent data loss on web tab close
- **Emoji Font Support**: Added SystemFont with cross-platform fallback as project default font, restored emoji icons
- **Mobile Touch**: Dynamic joystick (touch anywhere on left half), larger interact button (100px), "TAP" label
- **Topic Archive System**: Archive topics to hide from active list, restore from archive, permanent delete option
- **Topic Session Counts**: Show completed sessions in button text, e.g. "Claude/AI (5)"
- **Save Download/Upload**: File-based save transfer (browser download on web, native FileDialog on desktop)
- **Import Confirmation**: Upload shows save details and warns before overwriting, slot selection for import
- **Clipboard Fallback**: Copy JSON / Paste JSON as secondary save transfer option
- **Null Safety Fixes**: Fixed `is_empty()` on nil for milestone, shop items; fixed float % int for login days/streak

### March 27, 2026 - Major UI/UX Overhaul
- **Cardinal Movement**: Fixed WASD across all 13 scenes to use cardinal directions instead of confusing isometric diagonal
- **Console Placement Fix**: Fixed `is_empty` crash when placing mindscape console in bedroom
- **VR Headset Transition**: First-person animation when entering/exiting mindscape - blocky hands raise headset with dual oval lenses, foam padding, nose bridge, head straps
- **Pulsing Ring Removed**: Removed distracting evolution ring from mindscape hub center
- **Stars Expanded**: Background stars now fill the full zoomed-out view (was only center 1/3)
- **Hub Layout Cleanup**: Garden patches, achievement pedestals, and experience shop repositioned to reduce overlap
- **IRL Gifts Tab**: New shop category with focus coin rewards redeemable for discount codes at goacto.shop
- **Reset Scene Button**: Replaced static "Reset" text with functional button that reloads current scene
- **Greeting Centered**: Fixed welcome text alignment in mindscape hub header
- **Achievement Pedestals**: Enlarged 2.5x with hex base, front-lit pillar, trophy platform, numbered labels
- **Daily Reward Timing**: Waits for onboarding AND tutorial tooltips before showing
- **Bedroom Window**: Moved higher on wall (z_index=10), no longer walkable-behind
- **Smoother Transitions**: Scene fade-in increased to 0.8s with cubic ease-out
- **Companion Tips**: Reduced ding frequency from 30s to 120s
- **Dialogue Z-Index**: DialoguePanel and InteractionPrompt render above window/lock icons

### March 23, 2026 - Web Build & Stability
- **Web/PWA Build**: First successful Vercel deployment with COOP/COEP headers for SharedArrayBuffer
- **JSON Save/Load**: Import/export save data via clipboard from main menu
- **Build Timestamp**: Version overlay shows build date with relative time ("2d ago")
- **WASD Fix**: Corrected movement controls and dialog overlap issues
- **Console Visual**: Fixed mindscape console display and placement
- **Vercel Config**: Proper MIME types for .wasm, .pck, .js files; disabled caching

### March 20, 2026 - First Web Deployment
- **Vercel PWA**: Progressive Web App deployment with offline support
- **Movement Fixes**: Resolved various movement and UI issues for web platform
- **Feedback System**: Initial feedback form integration
- **Force Reset**: Added Ctrl+Shift+R hotkey hint (later replaced with button)

### March 18, 2026 - Mobile & Multi-Platform
- **Mobile UI System**: MobileUIManager with platform detection, responsive scaling, safe area support
- **Virtual Joystick**: Touch-based movement control with interact button
- **iOS/Android Export**: Export presets configured for mobile platforms
- **Desktop Export**: macOS, Windows, and Linux presets for Steam
- **Hallway Detail Views**: Split graphic views for hallway interactive items
- **Bug Fixes**: Bedroom teleportation fix, hallway text centering, mobile touch polish

### March 17, 2026 - Engagement Systems
- **Daily Rewards**: 30-day reward cycle with XP, milestones, and special bonuses
- **Login Streaks**: Consecutive day tracking with streak recovery
- **Personal Milestones**: Celebrations at 7, 14, 30, 60, 90, 180, 365 days
- **Companion Spirit**: Floating guide that offers contextual tips in the mindscape
- **Companion Evolution**: Visual changes based on player's total login days
- **Bedroom Expansion**: Larger layout with more interactive areas

### March 16, 2026 - Foundation
- **Initial Commit**: Complete game foundation with Godot 4.6
- **17 Autoload Managers**: GameManager, HabitManager, GoalManager, ScriptManager, SaveManager, CampaignManager, AudioManager, ShopManager, CustomizationManager, ChallengeManager, AchievementManager, MindscapeRegionManager, TransitionManager, MailManager, ThemeConfig, RelationshipManager, MobileUIManager
- **27+ Scenes**: Main menu, bedroom, 9 ship rooms, mindscape hub + 6 regions, focus chamber, focus mode, combat, cutscene, daily rituals, settings, transitions
- **6 Aspects**: Discipline, Courage, Creativity, Compassion, Wisdom, Vitality
- **Personal OS System**: Layers, packages, and scripts (PSA files) for life scripting
- **15-Chapter Campaign**: Progressive story from First Contact to Contribution Certification
- **Focus Sessions**: 25-minute Pomodoro-style deep work with LAGG journal reflection
- **Habit Tracking**: Daily habits with streaks, grace days, and domain-based XP
- **World Evolution**: Visual mindscape transformation based on player progress (0-100%)
- **Shop System**: Cosmetics economy with aspect-based currency
- **Relationship Tracker**: Track and nurture important relationships with interaction logging
- **Combat System**: Turn-based battles against inner resistance (Doubt, Fear, Procrastination)
- **CLAUDE.md**: Comprehensive application overview document for AI-assisted development

---

## The Vision

**GOACTO: Growing Ourselves And Contributing To Others**

A self-improvement RPG where real-world focus sessions, habits, and personal growth drive an alien's journey to help humanity reach its potential. Every feature exists to make self-improvement feel like an adventure, not an obligation.

*"You were detected across galaxies because of your exceptional potential."*
