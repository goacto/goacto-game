# Audio Production Guide - Mindscape by GOACTO

This guide documents all audio assets needed for the game: voice clips, music, and sound effects. Includes AI generation prompts and production workflows.

---

## Table of Contents

### Voice
1. [Voice Characters](#voice-characters)
2. [ElevenLabs Setup](#elevenlabs-setup)
3. [Voice Clip Inventory](#voice-clip-inventory)
4. [Voice Production Workflow](#voice-production-workflow)

### Music
5. [Music Overview](#music-overview)
6. [Music Track List](#music-track-list)
7. [AI Music Prompts (Suno/Udio)](#ai-music-prompts)

### Sound Effects
8. [Sound Effects Overview](#sound-effects-overview)
9. [SFX Inventory](#sfx-inventory)
10. [AI SFX Prompts](#ai-sfx-prompts)

### Technical
11. [File Naming Convention](#file-naming-convention)
12. [Export Settings](#export-settings)

---

## Voice Characters

### 1. Agent Goacto (Main Character)
- **Voice Type**: Young, enthusiastic, warm
- **Gender**: Neutral/Androgynous
- **Tone**: Curious, optimistic, determined
- **ElevenLabs Voice**: "Adam" or "Antoni" (or create custom)
- **Settings**:
  - Stability: 50%
  - Clarity + Similarity: 75%
  - Style Exaggeration: 30%

### 2. Dr. Lumina (Goacto's Mother)
- **Voice Type**: Mature, wise, gentle
- **Gender**: Female
- **Tone**: Nurturing, knowing, slightly playful
- **ElevenLabs Voice**: "Rachel" or "Bella"
- **Settings**:
  - Stability: 65%
  - Clarity + Similarity: 70%
  - Style Exaggeration: 20%

### 3. Narrator
- **Voice Type**: Deep, cinematic, epic
- **Gender**: Male or neutral
- **Tone**: Grand, storytelling, atmospheric
- **ElevenLabs Voice**: "Daniel" or "Arnold"
- **Settings**:
  - Stability: 70%
  - Clarity + Similarity: 80%
  - Style Exaggeration: 15%

### 4. System
- **Voice Type**: Robotic, clean, precise
- **Gender**: Neutral
- **Tone**: Technical, informative, slightly warm
- **ElevenLabs Voice**: "Elli" or use Speech Synthesis with robotic effect
- **Settings**:
  - Stability: 85%
  - Clarity + Similarity: 90%
  - Style Exaggeration: 0%
- **Post-processing**: Add slight reverb and robotic filter in Audacity

### 5. Discipline (Spirit Guide)
- **Voice Type**: Resonant, powerful, ancient
- **Gender**: Deep/masculine
- **Tone**: Wise, commanding, encouraging
- **ElevenLabs Voice**: "Josh" or "Clyde"
- **Settings**:
  - Stability: 60%
  - Clarity + Similarity: 75%
  - Style Exaggeration: 25%

---

## ElevenLabs Setup

### Account Requirements
- **Plan**: Creator ($22/mo) or higher recommended
- **Characters/month**: ~100,000 characters for full game
- **Features needed**: Voice cloning (optional), Projects

### Initial Setup Steps

1. **Create Account**
   - Go to [elevenlabs.io](https://elevenlabs.io)
   - Sign up for Creator plan or higher

2. **Set Up Voices**
   - Navigate to "Voices" section
   - For each character, either:
     - Select a pre-made voice
     - Clone a voice (requires 1+ min of sample audio)
     - Use Voice Design to create custom voice

3. **Create Project**
   - Go to "Projects" section
   - Create new project: "Mindscape by GOACTO"
   - Add all voices to the project

4. **Test Voices**
   - Generate test clips for each character
   - Adjust settings until satisfied
   - Save voice settings

---

## Voice Clip Inventory

### CUTSCENE: intro_part1 (10 clips)
**Location**: `audio/voice/intro_part1/`

| File | Speaker | Scene | Text |
|------|---------|-------|------|
| `s0_d0.ogg` | narrator | 0 | "Year 3,847 of the Galactic Calendar. The Stellar Wanderer cruises through the cosmos on a 50-year voyage across the galaxy." |
| `s0_d1.ogg` | narrator | 0 | "Aboard this vessel, thousands of Goactorian families enjoy their intergalactic vacation..." |
| `s0_d2.ogg` | narrator | 0 | "...while their children dream of adventure." |
| `s1_d0.ogg` | goacto | 1 | "Another rest stop. Another week of waiting." |
| `s1_d1.ogg` | goacto | 1 | "I wish I could DO something. Something that matters." |
| `s1_d2.ogg` | lumina | 1 | "Still restless, little one? The journey is the destination, remember?" |
| `s1_d3.ogg` | goacto | 1 | "I know, Mom. But... I want to help someone. Really help them grow." |
| `s1_d4.ogg` | lumina | 1 | "Hmm. You know, there IS that old program in the ship's archive..." |
| `s1_d5.ogg` | goacto | 1 | "Program? What program?" |
| `s1_d6.ogg` | lumina | 1 | "Mindscape - your great-elder used it for his first Contribution Certification. It connects you with beings on distant worlds who have... untapped potential." |
| `s1_d7.ogg` | goacto | 1 | "Connect? You mean I could actually HELP someone?!" |
| `s1_d8.ogg` | lumina | 1 | "Why don't you see for yourself? The console is in your room." |

---

### CUTSCENE: intro_part2 (12 clips)
**Location**: `audio/voice/intro_part2/`

| File | Speaker | Scene | Text |
|------|---------|-------|------|
| `s0_d0.ogg` | goacto | 0 | "Mindscape by GOACTO... let's see what this is about." |
| `s0_d1.ogg` | system | 0 | "MINDSCAPE by GOACTO version 3.2. Contribution Training Program. Initializing neural link..." |
| `s0_d2.ogg` | system | 0 | "Scanning Sector 7G... Planet: Earth. Species: Human. Searching for high-potential candidates..." |
| `s0_d3.ogg` | goacto | 0 | "Earth? I've heard of that place. Fascinating species - so much potential, but they struggle to see it themselves." |
| `s0_d4.ogg` | system | 0 | "CANDIDATE DETECTED. Potential Index: EXCEPTIONAL. Growth Trajectory: UNTAPPED. Contribution Capacity: HIGH. This human shows remarkable potential for growth and positive impact." |
| `s0_d5.ogg` | goacto | 0 | "Exceptional potential? This is the one. Show me their mindscape." |
| `s1_d0.ogg` | system | 1 | "MINDSCAPE VISUALIZATION ACTIVE. Note: This space reflects the human's inner world. It will evolve as they grow." |
| `s1_d1.ogg` | goacto | 1 | "It's... empty. Just a barren platform floating in darkness." |
| `s1_d2.ogg` | goacto | 1 | "But I can feel it. The potential. It's all there, waiting to bloom." |
| `s1_d3.ogg` | goacto | 1 | "I'll help them see what they can become. Every focus session, every habit, every goal - I'll be there supporting them." |
| `s1_d4.ogg` | system | 1 | "NEURAL SYNC ESTABLISHED. You are now connected to your human. When they focus, you assist. When they grow, you guide." |
| `s1_d5.ogg` | goacto | 1 | "Alright, human. Let's begin your transformation. First step: a Focus Session. Let's see what you're capable of." |

---

### CUTSCENE: discipline_awakens (9 clips)
**Location**: `audio/voice/discipline_awakens/`

| File | Speaker | Scene | Text |
|------|---------|-------|------|
| `s0_d0.ogg` | goacto | 0 | "Look at this! The mindscape is starting to change!" |
| `s0_d1.ogg` | narrator | 0 | "A golden light pulses at the center of the platform..." |
| `s0_d2.ogg` | discipline | 0 | "You have begun. That is what matters." |
| `s0_d3.ogg` | goacto | 0 | "What... who are you?" |
| `s0_d4.ogg` | discipline | 0 | "I am Discipline. The foundation upon which all growth is built. I have slept here, waiting for someone to take the first step." |
| `s0_d5.ogg` | discipline | 0 | "Your human has shown commitment. Consistency. The willingness to begin. These are my gifts to nurture." |
| `s0_d6.ogg` | goacto | 0 | "So you're... part of them? Part of their potential?" |
| `s0_d7.ogg` | discipline | 0 | "I am the part that shows up. Every day. Regardless of feeling. Help them build habits, and I will grow stronger." |
| `s0_d8.ogg` | discipline | 0 | "Now. There is work to do. The Daily Rituals await." |

---

### CUTSCENE: _placeholder (4 clips)
**Location**: `audio/voice/_placeholder/`

| File | Speaker | Scene | Text |
|------|---------|-------|------|
| `s0_d0.ogg` | system | 0 | "TRANSMISSION INTERRUPTED. This chapter of your journey is still being written..." |
| `s0_d1.ogg` | goacto | 0 | "Hmm, it seems the neural link is experiencing some interference." |
| `s0_d2.ogg` | goacto | 0 | "Don't worry - the story continues. Keep growing, and this path will reveal itself soon." |
| `s0_d3.ogg` | system | 0 | "RETURNING TO MINDSCAPE... Your progress has been saved." |

---

### ONBOARDING: Mindscape Introduction (4 clips)
**Location**: `audio/voice/onboarding/`

These slides introduce new players to the core concepts of Mindscape. Goacto explains each feature in an encouraging, welcoming tone.

| File | Speaker | Text |
|------|---------|------|
| `slide_0.ogg` | goacto | "This is your inner world - a place that grows and evolves as you do. Every real-world action you take transforms this space into something beautiful." |
| `slide_1.ogg` | goacto | "Enter the Focus Chamber to start 25-minute deep work sessions. Put your phone aside and do real work. When you return, reflect on what you learned." |
| `slide_2.ogg` | goacto | "Discipline, Courage, Creativity, Compassion, Wisdom, and Vitality - these Aspects represent parts of yourself. They grow stronger as you build habits in their domains." |
| `slide_3.ogg` | goacto | "More regions will unlock as you progress. Build habits, complete focus sessions, and watch your mindscape transform. Your human is counting on you, Agent Goacto!" |

**Voice Direction**:
- Warm and welcoming tone
- Slightly slower pace for clarity
- Encouraging, like a friend introducing something exciting
- Build enthusiasm toward the final slide

---

### KITCHEN: Dr. Lumina Dialogues (10 clips)
**Location**: `audio/voice/kitchen/`

Dr. Lumina (Goacto's mother) provides guidance and encouragement based on the player's progress. Her voice should be warm, nurturing, and wise.

#### Initial Visit (First time in kitchen)
| File | Text |
|------|------|
| `lumina_intro.ogg` | "Go on then! The console is in your room down the hallway. I can't wait to hear about your first human!" |

#### Pre-Mindscape (Hasn't connected to human yet)
| File | Text |
|------|------|
| `lumina_go_find.ogg` | "What are you waiting for? Go find your human! The console is in your room - down the hallway and up the stairs." |

#### Post-Connection (Connected but no focus sessions)
| File | Text |
|------|------|
| `lumina_connected.ogg` | "You've connected! How exciting! Now help them focus. That's where the real growth begins. Go back to your room and start a Focus Session with them." |

#### Making Progress (Has done focus sessions, pre-Discipline)
| File | Text |
|------|------|
| `lumina_progress_0.ogg` | "You're making progress! I can feel the connection strengthening. Keep guiding them. The mindscape will reveal more soon." |
| `lumina_progress_1.ogg` | "Tell me about your human! What have you learned about them? Every focus session brings you closer." |
| `lumina_progress_2.ogg` | "The neural link is stabilizing nicely. Your human is lucky to have you. Patience, little one. Great things are coming." |

#### Post-Discipline (Met Discipline aspect)
| File | Text |
|------|------|
| `lumina_discipline_0.ogg` | "I can see it in your eyes - your human is growing, aren't they? Discipline chose well when they awakened for you." |
| `lumina_discipline_1.ogg` | "Your great-elder would be so proud. The mindscape connection suits you. Remember: growth takes patience. Both for you and your human." |
| `lumina_discipline_2.ogg` | "How is your human doing? I remember my first contribution certification... The bond you're building will last a lifetime." |

**Voice Direction (Lumina)**:
- Warm, maternal, nurturing tone
- Proud and encouraging
- Slight playfulness in early dialogues
- More reflective/wistful in later dialogues
- Gentle smile audible in voice

#### Narrator - Item Discovery
| File | Text |
|------|------|
| `narrator_master_key.ogg` | "You found a mysterious key! This ancient artifact seems to resonate with the neural link technology. The key glows faintly and vanishes into your inventory. With this, all areas of your human's mindscape will be accessible." |

**Voice Direction (Narrator)**:
- Deep, cinematic narrator voice
- Sense of wonder and discovery
- Slightly mystical tone for the artifact
- Build anticipation for what the key unlocks

---

## Voice Production Workflow

### Step 1: Prepare Scripts
1. Copy each dialogue line from the tables above
2. Remove stage directions (text in asterisks `*like this*`)
3. Clean up formatting (remove `\n\n` etc.)

### Step 2: Generate in ElevenLabs

For each voice clip:

1. **Open ElevenLabs Projects**
2. **Select the correct voice** for the speaker
3. **Paste the dialogue text**
4. **Generate audio**
5. **Listen and adjust** settings if needed
6. **Regenerate** if quality isn't satisfactory
7. **Download** as MP3

### Step 3: Convert to OGG

Using FFmpeg (recommended for batch conversion):

```bash
# Single file
ffmpeg -i input.mp3 -c:a libvorbis -q:a 6 output.ogg

# Batch convert all MP3s in a folder
for f in *.mp3; do ffmpeg -i "$f" -c:a libvorbis -q:a 6 "${f%.mp3}.ogg"; done
```

Or using Audacity:
1. File > Open (MP3)
2. File > Export > Export as OGG
3. Quality: 6 (good balance of quality/size)

### Step 4: Post-Processing (Optional)

For **System** voice (robotic effect):
1. Open in Audacity
2. Effect > Reverb (light, short decay)
3. Effect > High Pass Filter (80Hz)
4. Optional: Add slight chorus effect

### Step 5: Organize Files

Place files in the correct folders:
```
godot/audio/voice/
├── intro_part1/
│   ├── s0_d0.ogg
│   ├── s0_d1.ogg
│   └── ...
├── intro_part2/
│   ├── s0_d0.ogg
│   └── ...
├── discipline_awakens/
│   └── ...
└── _placeholder/
    └── ...
```

### Step 6: Test in Game
1. Run the game
2. Play through cutscenes
3. Verify voice clips play correctly
4. Check timing with text display
5. Adjust volume levels if needed

---

# MUSIC PRODUCTION

## Music Overview

The game uses layered ambient music that reflects the player's location and emotional state. Music should feel cosmic, introspective, and hopeful - matching the game's theme of personal growth and space exploration.

**Style Reference**: Interstellar OST, Journey game soundtrack, Stellaris ambient tracks, lo-fi space ambient

**Technical Requirements**:
- Format: OGG Vorbis
- Sample Rate: 44100 Hz
- Loop Points: Seamlessly loopable (most tracks)
- Duration: 2-4 minutes per track

---

## Music Track List

### Location: `godot/audio/music/`

| File | Location/Use | Duration | Loop |
|------|--------------|----------|------|
| `main_menu.ogg` | Main menu screen | 3:00 | Yes |
| `ship_ambient.ogg` | Stellar Wanderer (kitchen, hallway, stairs) | 3:30 | Yes |
| `bedroom_calm.ogg` | Goacto's bedroom, pre-mindscape | 2:30 | Yes |
| `mindscape_hub.ogg` | Mindscape central platform | 4:00 | Yes |
| `focus_chamber.ogg` | During focus session setup | 2:00 | Yes |
| `focus_active.ogg` | While focus timer running | 25:00 | Yes |
| `cutscene_intro.ogg` | intro_part1 and intro_part2 cutscenes | 3:00 | No |
| `cutscene_awakening.ogg` | discipline_awakens cutscene | 2:00 | No |
| `achievement.ogg` | Achievement unlock sting | 0:05 | No |
| `level_up.ogg` | Character/aspect level up | 0:08 | No |

---

## AI Music Prompts

### Tool: Suno AI or Udio

Below are prompts optimized for AI music generation. Adjust style tags as needed.

---

### main_menu.ogg
**Prompt**:
```
ambient electronic, cosmic, hopeful, space exploration theme,
gentle synth pads, soft arpeggios, sense of wonder and possibility,
stars twinkling, beginning of adventure, warm and inviting,
80 bpm, key of D major, cinematic, no drums, ethereal
```

**Style Tags**: `ambient, electronic, cinematic, space, hopeful`

---

### ship_ambient.ogg
**Prompt**:
```
spaceship interior ambience, soft mechanical hum undertones,
warm synth layers, cozy space vessel atmosphere,
gentle electronic pulses like life support systems,
family home in space, safe and comfortable,
70 bpm, peaceful, subtle bass, no percussion
```

**Style Tags**: `ambient, sci-fi, warm, electronic, minimal`

---

### bedroom_calm.ogg
**Prompt**:
```
personal space ambient, young character's room,
dreamy synth textures, stars outside window feeling,
anticipation and curiosity, gentle crescendo moments,
lo-fi electronic, soft chimes, peaceful contemplation,
75 bpm, key of G major, introspective
```

**Style Tags**: `ambient, lo-fi, dreamy, electronic, introspective`

---

### mindscape_hub.ogg
**Prompt**:
```
inner world ambient, vast empty potential space,
crystalline tones, deep reverb, floating in void,
beautiful desolation, seeds of growth, mystical,
slowly evolving textures, distant harmonics,
60 bpm, key of E minor to E major shift, ethereal choir pads,
meditation music, transcendent
```

**Style Tags**: `ambient, meditation, mystical, electronic, ethereal`

---

### focus_chamber.ogg
**Prompt**:
```
preparation music, building anticipation,
focus and concentration theme, clean electronic,
rising energy, determination, mental clarity,
binaural-inspired tones, alpha wave frequencies,
subtle pulse building, motivational undercurrent,
90 bpm, key of A minor, progressive build
```

**Style Tags**: `ambient, focus, electronic, motivational, building`

---

### focus_active.ogg
**Prompt**:
```
deep focus music, 25 minute concentration aid,
minimal distractions, flowing ambient textures,
productivity music, study music, gentle waves,
consistent energy level, not too dynamic,
binaural beats undertone optional, alpha waves,
60 bpm, key of C major, loopable, no sudden changes,
lo-fi ambient, soft piano notes occasional
```

**Style Tags**: `focus, ambient, lo-fi, study, minimal, loopable`

---

### cutscene_intro.ogg
**Prompt**:
```
cinematic opening theme, space voyage epic,
orchestral synth hybrid, sense of scale and wonder,
hopeful adventure beginning, family warmth,
builds from quiet to full, emotional crescendo,
110 bpm, key of D major, strings and synths,
film score style, inspiring, momentous
```

**Style Tags**: `cinematic, orchestral, electronic, epic, inspiring`

---

### cutscene_awakening.ogg
**Prompt**:
```
mystical awakening theme, spirit emerging,
ancient power revealing itself, golden light feeling,
deep resonant bass, ethereal high tones,
transformation moment, awe and reverence,
slow build to powerful moment,
70 bpm, key of F# minor, tribal undertones, mystical
```

**Style Tags**: `cinematic, mystical, epic, ambient, spiritual`

---

### achievement.ogg (5 second sting)
**Prompt**:
```
achievement unlock sound, victory fanfare,
short triumphant sting, bright and celebratory,
synth chime cascade, ascending notes,
satisfying completion feeling, rewarding,
quick 5 seconds, key of C major
```

**Style Tags**: `fanfare, electronic, victory, short`

---

### level_up.ogg (8 second sting)
**Prompt**:
```
level up celebration, power increase moment,
ascending synth sweep, magical transformation,
growing stronger feeling, radiant energy,
8 second sting, builds and resolves,
key of A major, triumphant but mystical
```

**Style Tags**: `fanfare, electronic, magical, power, short`

---

# SOUND EFFECTS PRODUCTION

## Sound Effects Overview

Sound effects should feel clean, futuristic, and satisfying. UI sounds are subtle and non-intrusive. Environmental sounds add atmosphere without overwhelming.

**Style Reference**: Clean sci-fi UI sounds, soft synthetic tones, crystalline impacts

**Technical Requirements**:
- Format: OGG Vorbis (or WAV for very short clips)
- Sample Rate: 44100 Hz
- Bit Depth: 16-bit
- Duration: 0.1s - 3s typically

---

## SFX Inventory

### Location: `godot/audio/sfx/`

#### UI Sounds

| File | Trigger | Description |
|------|---------|-------------|
| `ui_click.ogg` | Button press | Soft click/tap |
| `ui_hover.ogg` | Button hover | Subtle whoosh |
| `ui_back.ogg` | Back/cancel action | Soft descending tone |
| `ui_confirm.ogg` | Confirm action | Bright ascending chime |
| `ui_error.ogg` | Invalid action | Soft buzz/negative tone |
| `ui_open.ogg` | Panel/menu open | Soft whoosh out |
| `ui_close.ogg` | Panel/menu close | Soft whoosh in |
| `ui_slider.ogg` | Slider adjustment | Soft tick |
| `ui_toggle.ogg` | Toggle switch | Click with resonance |
| `ui_type.ogg` | Text typing | Soft keystroke |

#### Character & Movement

| File | Trigger | Description |
|------|---------|-------------|
| `hover_move.ogg` | Player moving (looped) | Soft hover/float sound |
| `footstep_ship.ogg` | Walking on ship | Soft metallic tap |
| `footstep_mindscape.ogg` | Walking in mindscape | Ethereal soft step |
| `player_spawn.ogg` | Player appears | Materialization shimmer |
| `character_talk.ogg` | NPC dialogue start | Soft attention chime |

#### Items & Interactions

| File | Trigger | Description |
|------|---------|-------------|
| `item_pickup.ogg` | Pick up item | Satisfying collect sound |
| `key_pickup.ogg` | Pick up Master Key | Mystical resonant chime |
| `door_interact.ogg` | Approach/touch door | Soft panel beep |
| `door_open.ogg` | Door opens | Sci-fi door swoosh |
| `door_locked.ogg` | Locked door | Negative buzz + rattle |
| `interact_object.ogg` | Generic interaction | Soft confirmation |

#### Mindscape & Focus

| File | Trigger | Description |
|------|---------|-------------|
| `portal_enter.ogg` | Enter portal zone | Whoosh with shimmer |
| `portal_activate.ogg` | Portal activation | Energy surge |
| `crystal_pulse.ogg` | Center crystal pulse | Deep resonant hum |
| `aspect_awaken.ogg` | Aspect awakens | Powerful reveal |
| `focus_start.ogg` | Focus session begins | Transition into focus |
| `focus_tick.ogg` | Timer tick (optional) | Subtle pulse |
| `focus_complete.ogg` | Focus session done | Triumphant completion |
| `habit_complete.ogg` | Habit marked done | Satisfying check |
| `streak_increase.ogg` | Streak goes up | Ascending chime |

#### Ambient Loops

| File | Trigger | Description |
|------|---------|-------------|
| `ambient_ship_hum.ogg` | Ship background | Engine/life support hum |
| `ambient_stars.ogg` | Window/space view | Subtle cosmic whisper |
| `ambient_mindscape.ogg` | Mindscape background | Ethereal void sound |

#### Notifications

| File | Trigger | Description |
|------|---------|-------------|
| `notification.ogg` | General notification | Attention chime |
| `achievement_unlock.ogg` | Achievement pops | Triumphant sting |
| `companion_tip.ogg` | Companion speaks | Soft bell |

---

## AI SFX Prompts

### Tool: ElevenLabs Sound Effects, Audiocraft, or describe for Freesound search

---

### UI Sounds

#### ui_click.ogg
```
soft digital click, button press, minimal, clean,
high-end smartphone tap sound, subtle and satisfying,
0.1 seconds, no reverb
```

#### ui_hover.ogg
```
subtle UI hover sound, soft whoosh, gentle air movement,
high frequency shimmer, barely audible,
0.15 seconds, light and airy
```

#### ui_confirm.ogg
```
positive confirmation chime, ascending two-note,
bright and clean, satisfying, success sound,
0.3 seconds, major key interval
```

#### ui_error.ogg
```
soft error sound, gentle negative feedback,
low buzz with slight wobble, not harsh,
0.25 seconds, subtle and non-jarring
```

#### ui_open.ogg
```
panel opening sound, soft whoosh outward,
interface expanding, clean and modern,
0.3 seconds, slight reverb tail
```

---

### Movement Sounds

#### hover_move.ogg
```
soft alien hover sound, gentle floating movement,
light whoosh with subtle hum, sci-fi levitation,
ethereal and gentle, not mechanical,
0.3 seconds, subtle, can loop/repeat,
low volume, background movement sound
```

---

### Door Sounds

#### door_interact.ogg
```
door panel touch, soft electronic beep,
sci-fi interface acknowledgment, subtle confirmation,
spaceship door sensor activated,
0.2 seconds, clean and high-tech
```

#### door_open.ogg
```
sci-fi automatic door opening, smooth swoosh,
spaceship airlock style, futuristic sliding door,
pneumatic with electronic undertone,
0.6 seconds, satisfying mechanical movement
```

---

### Item Sounds

#### item_pickup.ogg
```
item collect sound, satisfying pickup,
bright chime with sparkle, game reward sound,
0.4 seconds, ascending notes, magical
```

#### key_pickup.ogg
```
mystical key pickup, ancient artifact sound,
deep resonant chime, golden shimmer,
crystalline with low undertone, magical discovery,
0.8 seconds, reverb, awe-inspiring
```

---

### Mindscape Sounds

#### portal_enter.ogg
```
portal entrance whoosh, dimensional transition,
swirling energy, sci-fi teleport beginning,
0.6 seconds, building energy
```

#### portal_activate.ogg
```
portal full activation, energy surge complete,
powerful sci-fi whoosh, reality bending,
1.0 seconds, dramatic with tail
```

#### crystal_pulse.ogg
```
crystal resonance pulse, deep harmonic,
mystical gemstone vibration, heartbeat of space,
2.0 seconds, loopable drone element
```

#### aspect_awaken.ogg
```
spirit awakening reveal, powerful emergence,
ancient entity materializing, dramatic moment,
choir-like shimmer, building to peak,
2.5 seconds, epic and mystical
```

---

### Focus Session Sounds

#### focus_start.ogg
```
focus session beginning, mental entering state,
calming transition, world fading away,
meditative gong with soft shimmer,
1.5 seconds, peaceful and centering
```

#### focus_complete.ogg
```
focus session complete, triumphant return,
achievement unlocked feeling, satisfying resolution,
bright ascending chimes, accomplishment,
2.0 seconds, celebratory but calm
```

#### habit_complete.ogg
```
checkbox completion, task done sound,
satisfying tick with resonance, productive feeling,
0.4 seconds, clean and rewarding
```

---

### Ambient Sounds

#### ambient_ship_hum.ogg
```
spaceship interior ambience, constant hum,
life support systems, engine drone,
warm and safe feeling, subtle movement,
30 seconds loopable, very subtle
```

#### ambient_mindscape.ogg
```
void space ambient, ethereal emptiness,
cosmic silence with subtle presence,
distant stars, infinite potential feeling,
30 seconds loopable, mystical and vast
```

---

## SFX Production Tips

### Using ElevenLabs Sound Effects
1. Navigate to Sound Effects tool
2. Enter descriptive prompt
3. Generate multiple variations
4. Choose best match
5. Download and convert to OGG

### Using Freesound.org
1. Search using keywords from prompts
2. Filter by license (CC0 preferred)
3. Download highest quality
4. Edit in Audacity if needed
5. Convert to OGG

### Post-Processing in Audacity
1. **Normalize** to -3dB for consistency
2. **Trim** silence from start/end
3. **Fade in/out** (10-50ms) to prevent clicks
4. **EQ** if needed (cut harsh frequencies)
5. **Export** as OGG quality 6

---

## File Naming Convention

```
s{scene_index}_d{dialogue_index}.ogg
```

- `s` = Scene number (0-indexed)
- `d` = Dialogue number within scene (0-indexed)
- Format: OGG Vorbis

**Examples**:
- `s0_d0.ogg` = Scene 0, Dialogue 0 (first line)
- `s1_d3.ogg` = Scene 1, Dialogue 3 (fourth line of second scene)

---

## Export Settings

### ElevenLabs Export
- Format: MP3 (then convert to OGG)
- Quality: Highest available

### OGG Conversion (FFmpeg)
- Codec: libvorbis
- Quality: 6 (-q:a 6)
- Sample rate: 44100 Hz (default)

### Godot Import Settings
After placing files in `audio/voice/`, Godot will auto-import them.

Check `.import` settings:
- Loop: OFF (for voice clips)
- Force Mono: ON (saves space, voice doesn't need stereo)

---

## Summary Statistics

| Cutscene/Section | Total Clips | Characters Used |
|------------------|-------------|-----------------|
| intro_part1 | 12 | narrator, goacto, lumina |
| intro_part2 | 12 | goacto, system |
| discipline_awakens | 9 | goacto, narrator, discipline |
| _placeholder | 4 | system, goacto |
| onboarding | 4 | goacto |
| kitchen | 10 | lumina |
| **TOTAL** | **51 clips** | 5 unique voices |

### Estimated ElevenLabs Usage
- Average ~150 characters per clip
- Total: ~7,650 characters
- Well within free tier limits for testing
- Creator plan provides ample headroom for iterations

---

## Quick Start Checklist

- [ ] Create ElevenLabs account
- [ ] Set up 5 character voices
- [ ] Generate intro_part1 clips (12 clips)
- [ ] Generate intro_part2 clips (12 clips)
- [ ] Generate discipline_awakens clips (9 clips)
- [ ] Generate _placeholder clips (4 clips)
- [ ] Generate onboarding clips (4 clips)
- [ ] Generate kitchen/lumina clips (10 clips)
- [ ] Convert all to OGG format
- [ ] Place in `godot/audio/voice/{section}/`
- [ ] Test in game
- [ ] Adjust volumes in AudioManager settings

---

## Notes

- **Pacing**: Voice clips should be long enough to cover the typing animation
- **Silence**: Leave ~0.2s silence at start, ~0.3s at end of each clip
- **Consistency**: Generate all clips for one character in the same session
- **Backup**: Save the ElevenLabs project for future edits
