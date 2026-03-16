# Kitchen Background Specification

## Image Requirements

- **Filename:** `kitchen_bg.png`
- **Resolution:** 2560x1440 pixels (16:9 aspect ratio)
- **Format:** PNG with transparency (optional, solid also works)

## Art Direction

### Style
- Isometric perspective (approximately 30° angle)
- Soft purple/blue color palette matching existing theme
- Futuristic minimalist sci-fi design
- Digital art style, clean lines
- Subtle ambient lighting effects

### Color Palette
- Background: `#140F1F` (deep purple)
- Floor: `#1E1A2D` (dark purple-gray)
- Walls: `#19152B` (slightly lighter purple)
- Accent lights: `#7080FF` (soft blue glow)
- Window: Shows starfield

### Elements to Include (left to right)
1. **Large Window** (left side) - Shows stars/nebula
2. **Back Wall** with subtle sci-fi paneling
3. **Dining Table** (center) - Isometric hexagonal/diamond shape
4. **Decorative Rug** under table
5. **Food Synthesizer Unit** (right side) - Glowing screen
6. **Counter** (right side)
7. **Door to Hallway** (far right) - With ambient glow frame

### Important Notes
- **NO characters** - Player (Goacto) and Mom (Lumina) are rendered separately
- **Leave space for character positions:**
  - Mom stands at approximately x=-150, y=80 from center
  - Player starts at approximately x=-50, y=50 from center
- Center of image = center of isometric space (640, 360 in game coordinates)

## AI Generation Prompts

### Primary Prompt
```
Isometric sci-fi spaceship kitchen interior, soft purple and blue color palette,
futuristic minimalist design, hexagonal floor pattern, large window showing starfield
on the left, metallic dining table in center, glowing food synthesizer unit on the right,
sliding door with cyan glow frame, kitchen counter, ambient lighting from window
and screens, no characters, digital art style, inspired by Moebius and retro sci-fi,
clean geometric lines, dark atmosphere with subtle glows
```

### Negative Prompt (if supported)
```
people, characters, text, watermark, realistic, photograph, cluttered, messy
```

### Recommended Tools
- Midjourney (best for consistent style)
- DALL-E 3
- Stable Diffusion with sci-fi checkpoint

## Integration

Once generated, place the image at:
```
godot/assets/backgrounds/kitchen_bg.png
```

The kitchen scene will automatically use it if present.
