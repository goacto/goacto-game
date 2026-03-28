# Social Features Design Document

> Designing for local-first with future cloud sync capability

## Architecture: Local-First, Sync Later

All social features work offline first, storing data in the save file. When a backend is added, the same data structures sync via API.

---

## Feature 1: Shared Challenges

### Concept
Players can create challenges and share them via challenge codes (short alphanumeric strings). Other players enter the code to join the same challenge.

### Data Model
```gdscript
# In ChallengeManager or new SocialManager
var shared_challenges: Dictionary = {}

# Structure
shared_challenge = {
    "id": String,           # Unique challenge ID
    "code": String,         # 6-char shareable code (e.g., "FOCUS7")
    "title": String,        # "7-Day Focus Sprint"
    "description": String,
    "creator_name": String, # Player who created it
    "challenge_type": String, # "focus_sessions", "habit_streak", "total_minutes"
    "target": int,          # Target value (e.g., 7 sessions)
    "duration_days": int,   # How long the challenge lasts
    "start_date": String,   # ISO date
    "end_date": String,     # ISO date
    "my_progress": int,     # Local player's progress
    "completed": bool,
    "participants": Array,  # [{name, progress}] - populated via sync
}
```

### Code Generation (Offline)
```gdscript
func generate_challenge_code() -> String:
    var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # No I/O/0/1 for clarity
    var code = ""
    for i in range(6):
        code += chars[randi() % chars.length()]
    return code
```

### Sharing Flow (No Backend)
1. Player creates a challenge with a target
2. System generates a 6-character code
3. Player shares code via text/social media
4. Other player enters code manually
5. Both track progress locally
6. Compare results when they meet (honor system)

### Sharing Flow (With Backend)
1. Same creation, code generated server-side
2. Code entered → fetches challenge from API
3. Progress synced periodically
4. Leaderboard visible for challenge participants

---

## Feature 2: Accountability Partners

### Concept
Pair with one friend for mutual accountability. See each other's streak status (not full data — privacy-first).

### Data Model
```gdscript
accountability_partner = {
    "partner_code": String,     # Their share code
    "partner_name": String,
    "connected_date": String,
    "last_sync": String,        # Last time data was exchanged
    "partner_status": {
        "current_streak": int,
        "habits_today": int,
        "habits_total": int,
        "last_active": String,
    },
    "my_shared_status": {       # What I share with them
        "current_streak": int,
        "habits_today": int,
        "habits_total": int,
    }
}
```

### Without Backend
- Generate a "share card" (JSON blob encoded as QR or text)
- Partner scans/pastes it to see your status
- Manual sync via copy/paste

### With Backend
- Real-time status updates
- Push notifications when partner completes habits
- Gentle nudges when partner hasn't been active

---

## Feature 3: Community Goals

### Concept
Global goals that all players contribute to. "Together, let's complete 10,000 focus sessions this month."

### Data Model
```gdscript
community_goal = {
    "id": String,
    "title": "Global Focus Month",
    "description": "The GOACTO community aims for 10,000 focus sessions",
    "target": 10000,
    "current_total": 0,        # From server
    "my_contribution": 0,      # Local tracking
    "start_date": String,
    "end_date": String,
    "reward": Dictionary,      # XP/cosmetic for participants
    "tier_rewards": [          # Milestones
        {"threshold": 2500, "reward": "community_badge_bronze"},
        {"threshold": 5000, "reward": "community_badge_silver"},
        {"threshold": 10000, "reward": "community_badge_gold"},
    ]
}
```

### Without Backend
- Pre-defined goals with estimated community progress
- Player's own contribution tracked locally
- "You contributed X of Y" messaging

### With Backend
- Real-time global counter
- Tier unlocks when community hits milestones
- Monthly rotating goals

---

## Feature 4: Leaderboards (Opt-In)

### Concept
Optional leaderboards for focus minutes, streaks, evolution level. Privacy-conscious: opt-in only, display name only.

### Data Model
```gdscript
leaderboard_entry = {
    "display_name": String,     # Not real name
    "metric": String,           # "focus_minutes", "streak_days", "evolution"
    "value": int,
    "rank": int,                # Populated by server
    "is_me": bool,
}

leaderboard_settings = {
    "opted_in": false,          # Must explicitly opt in
    "display_name": "",         # Separate from player name
    "share_metrics": [],        # Which metrics to share
}
```

### Privacy Controls
- Off by default
- Player chooses which metrics to share
- Can use pseudonym instead of player name
- Can opt out at any time (data deleted)

---

## Implementation Phases

### Phase 1: Local-Only (Now)
- Shared challenge creation with codes
- Manual progress tracking
- Exportable challenge data via clipboard

### Phase 2: Simple Sync (Future)
- GOACTO API for challenge storage
- Challenge code lookup
- Basic participant tracking

### Phase 3: Full Social (Future)
- Accountability partners with real-time sync
- Community goals with global counter
- Opt-in leaderboards
- Push notifications

---

## API Endpoints (Phase 2+)

```
POST   /api/v1/challenges          # Create shared challenge
GET    /api/v1/challenges/:code    # Join via code
PUT    /api/v1/challenges/:id/progress  # Update progress
GET    /api/v1/challenges/:id/leaderboard

POST   /api/v1/partners/connect    # Link accountability partner
GET    /api/v1/partners/status      # Get partner's shared status
PUT    /api/v1/partners/status      # Update my shared status

GET    /api/v1/community/goals      # Active community goals
PUT    /api/v1/community/contribute # Add to community total

GET    /api/v1/leaderboards/:metric # Get leaderboard
PUT    /api/v1/leaderboards/submit  # Submit my score
```
