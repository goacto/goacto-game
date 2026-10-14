# PR3 proof: mobile layout, touch controls, objective tracker and interact hint

How it was checked: Godot 4.6 headless web export, then Playwright Chromium with an iPhone-like viewport (390x844, isMobile, hasTouch, DPR 2, `pointer: coarse`) and a desktop viewport (1366x768). BEFORE is `main` with only the parse-error fixes.

| Check | Before | After |
|---|---|---|
| Virtual canvas on a phone | `canvas=(1366, 768)`: a 1366px-wide world on a 390px screen (scale 0.29), with a black void above and below | `canvas=(600, 1298)`: fills the screen at scale 0.65, so text and buttons are about 2.3x larger |
| Title buttons (CSS px) | about 80x20 | about 170x40 (mobile_title.svg) |
| Touch controls | none | D-pad (72px virtual, about 47 CSS px) plus a 130px Interact button. The D-pad hides during dialogue and in bedroom/hub, which already have a joystick |
| Tap to interact | not available | tap Interact gives `dialogue_visible=true title='Food Synthesizer'`. Tapping the prompt also works |
| D-pad moves the player | n/a | `dpad Right moved player dx=141.3` |
| Interact hint | `Press SPACE to examine` | phone: `Press SPACE (or Tap Interact) to examine`. desktop: `Press SPACE (or E / click) to examine` |
| E key interacts | no | `E key -> dialogue_visible=true` (E added to `ui_accept`) |
| Objective tracker | empty | `Objective: Find Zyx's Mindscape Console somewhere on the ship` (one line, top left) |
| Desktop layout unchanged | | `canvas=(1366, 768) touch_layout=false` |

Screenshots on the box: /workspace/mindscape-proof/{before,after}-*-390x844*.png
