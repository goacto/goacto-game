extends Control
## Cutscene - Narrative sequences with dialogue and visuals
## Used for story progression and chapter introductions

signal cutscene_finished(cutscene_id: String)

# Voice clip cache - loaded on demand
var voice_clips: Dictionary = {}
var voice_base_path: String = "res://audio/voice/"

@onready var background: ColorRect = $Background
@onready var scene_container: Control = $SceneContainer
@onready var character_left: Control = $SceneContainer/CharacterLeft
@onready var character_right: Control = $SceneContainer/CharacterRight
@onready var character_center: Control = $SceneContainer/CharacterCenter
@onready var character_system: Control = $SceneContainer/CharacterSystem
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/Margin/VBox/SpeakerLabel
@onready var dialogue_label: Label = $DialoguePanel/Margin/VBox/DialogueLabel
@onready var continue_hint: Label = $DialoguePanel/Margin/VBox/ContinueHint
@onready var back_button: Button = $BackButton
@onready var skip_button: Button = $SkipButton
@onready var click_area: Button = $ClickArea
@onready var location_label: Label = $LocationLabel
@onready var spaceship: Node2D = $Spaceship
@onready var stars: Node2D = $Stars
@onready var fade_overlay: ColorRect = $FadeOverlay

# Kitchen elements (created dynamically)
var kitchen_elements: Node2D = null

# Current cutscene state
var current_cutscene_id: String = ""
var current_scene_index: int = 0
var current_dialogue_index: int = 0
var scenes: Array = []
var is_typing: bool = false
var full_text: String = ""
var displayed_chars: int = 0
var type_speed: float = 0.03
var type_timer: float = 0.0
var is_finishing: bool = false
var animation_time: float = 0.0

# Character definitions
const CHARACTERS = {
	"goacto": {
		"name": "Agent Goacto",
		"color": Color(0.83, 0.66, 0.29),  # Gold
		"position": "center"
	},
	"arctis": {
		"name": "Commander Arctis",
		"color": Color(0.4, 0.6, 0.9),  # Blue
		"position": "left"
	},
	"lumina": {
		"name": "Dr. Lumina",
		"color": Color(0.7, 0.5, 0.8),  # Purple
		"position": "left"
	},
	"zyx": {
		"name": "Zyx",
		"color": Color(0.5, 0.8, 0.6),  # Green
		"position": "right"
	},
	"system": {
		"name": "SYSTEM",
		"color": Color(0.4, 0.8, 0.7),  # Cyan
		"position": "system"
	},
	"narrator": {
		"name": "",
		"color": Color(0.7, 0.7, 0.75),
		"position": "none"
	},
	"discipline": {
		"name": "Discipline",
		"color": Color(0.83, 0.66, 0.29),  # Gold
		"position": "center"
	},
	"vitality": {
		"name": "Vitality",
		"color": Color(0.4, 0.85, 0.5),  # Green
		"position": "center"
	},
	"wisdom": {
		"name": "Wisdom",
		"color": Color(0.4, 0.6, 0.9),  # Blue
		"position": "center"
	},
	"courage": {
		"name": "Courage",
		"color": Color(0.9, 0.5, 0.3),  # Orange
		"position": "center"
	},
	"creativity": {
		"name": "Creativity",
		"color": Color(0.8, 0.4, 0.7),  # Magenta
		"position": "center"
	},
	"compassion": {
		"name": "Compassion",
		"color": Color(0.9, 0.6, 0.7),  # Pink
		"position": "center"
	}
}

# Cutscene definitions
const CUTSCENES = {
	# Part 1: Ship exterior and conversation with Mom - ends with transition to bedroom
	"intro_part1": {
		"id": "intro_part1",
		"scenes": [
			{
				"background": "space",
				"location": "The Stellar Wanderer - Deep Space",
				"dialogues": [
					{"speaker": "narrator", "text": "Year 3,847 of the Galactic Calendar.\n\nThe Stellar Wanderer cruises through the cosmos on a 50-year voyage across the galaxy."},
					{"speaker": "narrator", "text": "Aboard this vessel, thousands of Goactorian families enjoy their intergalactic vacation..."},
					{"speaker": "narrator", "text": "...while their children dream of adventure."}
				]
			},
			{
				"background": "kitchen",
				"location": "The Stellar Wanderer - Kitchen",
				"dialogues": [
					{"speaker": "goacto", "text": "*stares out the window at passing stars*\n\nAnother rest stop. Another week of waiting.\n\nI'll keep practicing my narrator voice later... but right now I just feel stuck."},
					{"speaker": "goacto", "text": "I wish I could DO something. Something that matters."},
					{"speaker": "lumina", "text": "Still restless, little one? The journey is the destination, remember?"},
					{"speaker": "goacto", "text": "I know, Mom. But... I want to help someone. Really help them grow."},
					{"speaker": "lumina", "text": "Hmm. You know, there IS that old program in the ship's archive..."},
					{"speaker": "goacto", "text": "Program? What program?"},
					{"speaker": "lumina", "text": "\"Mindscape\" by GOACTO - your great-elder created it for his first Contribution Certification.\n\nIt connects you with beings on distant worlds who have... untapped potential."},
					{"speaker": "goacto", "text": "Connect? You mean I could actually HELP someone?!"},
					{"speaker": "lumina", "text": "*smiles warmly*\n\nWhy don't you see for yourself? Your great-elder Zyx's console should be somewhere on the ship.\n\nExplore around - their belongings are stored somewhere aboard."}
				]
			}
		],
		"transition_to": "kitchen"  # Start in kitchen with mom, then navigate to bedroom
	},
	# Part 2: Console activation and first mindscape entry - triggered from bedroom
	"intro_part2": {
		"id": "intro_part2",
		"scenes": [
			{
				"background": "console",
				"location": "Goacto's Room - Personal Console",
				"dialogues": [
					{"speaker": "goacto", "text": "*activates console*\n\nMindscape by GOACTO... let's see what this is about."},
					{"speaker": "system", "text": "MINDSCAPE by GOACTO v3.2\nContribution Training Program\n\nInitializing neural link..."},
					{"speaker": "system", "text": "Scanning Sector 7G...\nPlanet: Earth\nSpecies: Human\n\nSearching for high-potential candidates..."},
					{"speaker": "goacto", "text": "Earth? I've heard of that place. Fascinating species - so much potential, but they struggle to see it themselves."},
					{"speaker": "system", "text": "CANDIDATE DETECTED\n\nPotential Index: EXCEPTIONAL\nGrowth Trajectory: UNTAPPED\nContribution Capacity: HIGH\n\nThis human shows remarkable potential for growth and positive impact."},
					{"speaker": "goacto", "text": "Exceptional potential? This is the one.\n\n*leans forward eagerly*\n\nShow me their mindscape."}
				]
			},
			{
				"background": "mindscape_empty",
				"location": "Human Mindscape - First Contact",
				"dialogues": [
					{"speaker": "system", "text": "MINDSCAPE VISUALIZATION ACTIVE\n\nNote: This space reflects the human's inner world.\nIt will evolve as they grow."},
					{"speaker": "goacto", "text": "It's... empty. Just a barren platform floating in darkness."},
					{"speaker": "goacto", "text": "But I can feel it. The potential. It's all there, waiting to bloom."},
					{"speaker": "goacto", "text": "I'll help them see what they can become.\n\nEvery focus session, every habit, every goal - I'll be there supporting them."},
					{"speaker": "system", "text": "NEURAL SYNC ESTABLISHED\n\nYou are now connected to your human.\nWhen they focus, you assist.\nWhen they grow, you guide."},
					{"speaker": "goacto", "text": "Alright, human. Let's begin your transformation.\n\nFirst step: a Focus Session. Let's see what you're capable of."}
				]
			}
		],
		"transition_to": "mindscape"
	},
	# Legacy "intro" now points to part 1 for backwards compatibility
	"intro": {
		"id": "intro",
		"scenes": [
			{
				"background": "space",
				"location": "The Stellar Wanderer - Deep Space",
				"dialogues": [
					{"speaker": "narrator", "text": "Year 3,847 of the Galactic Calendar.\n\nThe Stellar Wanderer cruises through the cosmos on a 50-year voyage across the galaxy."},
					{"speaker": "narrator", "text": "Aboard this vessel, thousands of Goactorian families enjoy their intergalactic vacation..."},
					{"speaker": "narrator", "text": "...while their children dream of adventure."}
				]
			},
			{
				"background": "kitchen",
				"location": "The Stellar Wanderer - Kitchen",
				"dialogues": [
					{"speaker": "goacto", "text": "*stares out the window at passing stars*\n\nAnother rest stop. Another week of waiting.\n\nI'll keep practicing my narrator voice later... but right now I just feel stuck."},
					{"speaker": "goacto", "text": "I wish I could DO something. Something that matters."},
					{"speaker": "lumina", "text": "Still restless, little one? The journey is the destination, remember?"},
					{"speaker": "goacto", "text": "I know, Mom. But... I want to help someone. Really help them grow."},
					{"speaker": "lumina", "text": "Hmm. You know, there IS that old program in the ship's archive..."},
					{"speaker": "goacto", "text": "Program? What program?"},
					{"speaker": "lumina", "text": "\"Mindscape\" by GOACTO - your great-elder created it for his first Contribution Certification.\n\nIt connects you with beings on distant worlds who have... untapped potential."},
					{"speaker": "goacto", "text": "Connect? You mean I could actually HELP someone?!"},
					{"speaker": "lumina", "text": "*smiles warmly*\n\nWhy don't you see for yourself? Your great-elder Zyx's console should be somewhere on the ship.\n\nExplore around - their belongings are stored somewhere aboard."}
				]
			}
		],
		"transition_to": "kitchen"
	},
	"discipline_awakens": {
		"id": "discipline_awakens",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape",
				"dialogues": [
					{"speaker": "goacto", "text": "Look at this! The mindscape is starting to change!"},
					{"speaker": "narrator", "text": "A golden light pulses at the center of the platform..."},
					{"speaker": "discipline", "text": "*emerges from the light*\n\nYou have begun. That is what matters."},
					{"speaker": "goacto", "text": "What... who are you?"},
					{"speaker": "discipline", "text": "I am Discipline. The foundation upon which all growth is built.\n\nI have slept here, waiting for someone to take the first step."},
					{"speaker": "discipline", "text": "Your human has shown commitment. Consistency. The willingness to begin.\n\nThese are my gifts to nurture."},
					{"speaker": "goacto", "text": "So you're... part of them? Part of their potential?"},
					{"speaker": "discipline", "text": "I am the part that shows up. Every day. Regardless of feeling.\n\nHelp them build habits, and I will grow stronger."},
					{"speaker": "discipline", "text": "Now. There is work to do.\n\nThe Daily Rituals await."}
				]
			}
		]
	},
	"vitality_awakens": {
		"id": "vitality_awakens",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Garden Stirs",
				"dialogues": [
					{"speaker": "goacto", "text": "The ground... it's changing. There's something growing beneath!"},
					{"speaker": "narrator", "text": "Green light spreads across the platform as vines burst from the surface..."},
					{"speaker": "vitality", "text": "*emerges from the foliage with boundless energy*\n\nYES! Feel that pulse? That's the human being ALIVE!"},
					{"speaker": "goacto", "text": "Another one! You're... made of plants?"},
					{"speaker": "vitality", "text": "I am Vitality - the root system of their being!\n\nEvery breath, every heartbeat, every moment of physical care makes me stronger."},
					{"speaker": "vitality", "text": "Your human has been consistent. Day after day they show up.\n\nThat kind of commitment? It feeds the body AND the soul."},
					{"speaker": "discipline", "text": "*approaches*\n\nVitality. It's good to see you awake."},
					{"speaker": "vitality", "text": "Discipline! Still as steady as ever.\n\n*turns to Goacto*\n\nWithout Discipline, I would wither. Together, we're unstoppable."},
					{"speaker": "goacto", "text": "How many of you are there?"},
					{"speaker": "vitality", "text": "Six in total. But don't rush it - each awakening takes time.\n\nFor now... let's get this human MOVING!"}
				]
			}
		]
	},
	"family_dinner": {
		"id": "family_dinner",
		"scenes": [
			{
				"background": "kitchen",
				"location": "The Stellar Wanderer - Kitchen",
				"dialogues": [
					{"speaker": "narrator", "text": "Evening meal aboard the Stellar Wanderer. The family gathers..."},
					{"speaker": "lumina", "text": "You've been spending a lot of time in your room lately. How is your project going?"},
					{"speaker": "goacto", "text": "It's amazing, Mom! My human completed another streak today. Vitality just awakened!"},
					{"speaker": "zyx", "text": "*looks up from food*\n\nWait wait wait - can the human SEE you?"},
					{"speaker": "goacto", "text": "Well... not exactly. The connection is more like..."},
					{"speaker": "lumina", "text": "The connection is felt, not seen. When the human feels motivated, supported, guided... that's Goacto's influence."},
					{"speaker": "zyx", "text": "So you're like... an invisible helper? That's kind of cool actually."},
					{"speaker": "arctis", "text": "*sets down utensils*\n\nThere's an old saying among navigators: 'The best guidance is felt, not heard.'"},
					{"speaker": "arctis", "text": "Your human doesn't need to see you to benefit from your presence.\n\nWhat matters is that you're there."},
					{"speaker": "goacto", "text": "Thanks, Dad. I just... I want them to succeed so much."},
					{"speaker": "lumina", "text": "Patience, little one. Growth takes time.\n\nBut from what you've described... this human has something special."}
				]
			}
		]
	},
	"wisdom_awakens": {
		"id": "wisdom_awakens",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Compass Forms",
				"dialogues": [
					{"speaker": "discipline", "text": "Goacto. There's something different today. Can you feel it?"},
					{"speaker": "goacto", "text": "The mindscape feels... more purposeful somehow."},
					{"speaker": "narrator", "text": "An azure light coalesces in the distance, forming geometric patterns..."},
					{"speaker": "wisdom", "text": "*emerges from crystalline structures*\n\nInteresting. Your human works hard but... where are they going?"},
					{"speaker": "goacto", "text": "You must be another Aspect. Which one are you?"},
					{"speaker": "wisdom", "text": "I am Wisdom. The contemplative one.\n\nI help your human see the path through the forest."},
					{"speaker": "wisdom", "text": "Action without direction is just motion.\n\nBut action WITH purpose? That's how mountains move."},
					{"speaker": "vitality", "text": "*bounces over*\n\nOh good, Wisdom's here! Now we can actually plan our energy instead of just spending it."},
					{"speaker": "wisdom", "text": "*smiles slightly*\n\nPrecisely. Let us set intentions together.\n\nGoacto, guide your human to the Goal Compass. It's time they learned to navigate."},
					{"speaker": "goacto", "text": "Goals... directions... I understand. The human needs a destination, not just movement."},
					{"speaker": "wisdom", "text": "You learn quickly. That gives me hope for this one."}
				]
			}
		]
	},
	"courage_awakens": {
		"id": "courage_awakens",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Arena Ignites",
				"dialogues": [
					{"speaker": "narrator", "text": "A shadow falls across the mindscape. Something stirs in the darkness..."},
					{"speaker": "goacto", "text": "What's happening? The platform is shaking!"},
					{"speaker": "wisdom", "text": "Stay calm. This was inevitable.\n\nThe human has grown enough to face what they've been avoiding."},
					{"speaker": "narrator", "text": "Dark tendrils creep from the edges - manifestations of Fear and Doubt..."},
					{"speaker": "narrator", "text": "Then... an orange flame erupts, pushing back the darkness!"},
					{"speaker": "courage", "text": "*emerges wielding a torch*\n\nNOT TODAY, shadows! Not on my watch!"},
					{"speaker": "goacto", "text": "Who are you?!"},
					{"speaker": "courage", "text": "I am Courage! The one who runs TOWARD the scary stuff!\n\n*grins*\n\nYour human has been building strength. Time to USE it."},
					{"speaker": "courage", "text": "Fear is just excitement without breath.\n\nDoubt is just wisdom asking for evidence."},
					{"speaker": "courage", "text": "We don't eliminate them - we FIGHT alongside them!\n\nThe Training Arena awaits, when your human is ready."},
					{"speaker": "discipline", "text": "Be careful with this one. Courage without wisdom is recklessness."},
					{"speaker": "courage", "text": "And wisdom without courage is paralysis.\n\n*winks*\n\nWe need each other."}
				]
			}
		]
	},
	"creativity_awakens": {
		"id": "creativity_awakens",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Lab Manifests",
				"dialogues": [
					{"speaker": "narrator", "text": "Colors begin to swirl where before there was only gray..."},
					{"speaker": "goacto", "text": "The mindscape is... painting itself? How is this possible?"},
					{"speaker": "creativity", "text": "*appears in a cascade of color and light*\n\nPossible? POSSIBLE? My dear agent, 'possible' is just a starting point!"},
					{"speaker": "goacto", "text": "Let me guess - you're Creativity?"},
					{"speaker": "creativity", "text": "Guilty as charged!\n\nI am the part of your human that sees what COULD be, not just what is."},
					{"speaker": "creativity", "text": "Every problem they solve, every connection they make, every 'what if' they explore...\n\nThat's me, dancing in their neural pathways!"},
					{"speaker": "wisdom", "text": "Creativity requires structure to flourish."},
					{"speaker": "creativity", "text": "And structure requires creativity to evolve!\n\n*spins*\n\nWe're dance partners, Wisdom. Don't pretend otherwise."},
					{"speaker": "creativity", "text": "I've prepared a space for your human to experiment.\n\nThe Script Lab - where they can write their own code for living!"},
					{"speaker": "goacto", "text": "Write their own... scripts?"},
					{"speaker": "creativity", "text": "Personal scripts! Daily affirmations, mantras, reminders of who they want to be.\n\nThe pen is mightier than... well, MOST things!"}
				]
			}
		]
	},
	"compassion_awakens": {
		"id": "compassion_awakens",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Heart Opens",
				"dialogues": [
					{"speaker": "narrator", "text": "A warmth spreads through the mindscape... gentle, accepting, kind..."},
					{"speaker": "goacto", "text": "This feeling... it's different from the others. Softer somehow."},
					{"speaker": "compassion", "text": "*emerges from warm pink light*\n\nHello, little one. You've been working so hard."},
					{"speaker": "goacto", "text": "You're the last Aspect?"},
					{"speaker": "compassion", "text": "I am Compassion. The one who reminds your human that they are enough.\n\nEven when they stumble. Especially then."},
					{"speaker": "compassion", "text": "Growth is beautiful, but so is rest.\n\nAchievement matters, but so does acceptance."},
					{"speaker": "courage", "text": "*approaches*\n\nCompassion! It's been too long."},
					{"speaker": "compassion", "text": "*embraces Courage*\n\nYou push them forward. I catch them when they fall.\n\nTogether, we make sure they keep going without breaking."},
					{"speaker": "discipline", "text": "All six of us... finally together."},
					{"speaker": "compassion", "text": "Your human has grown remarkably, Goacto.\n\nBut remember: the goal isn't perfection. It's wholeness."},
					{"speaker": "goacto", "text": "I understand. Help them grow, but also help them be kind to themselves."},
					{"speaker": "compassion", "text": "Now you're getting it.\n\n*smiles warmly*\n\nWelcome to the full family."}
				]
			}
		]
	},
	"growth_begins": {
		"id": "growth_begins",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape",
				"dialogues": [
					{"speaker": "goacto", "text": "Something's different today. The platform... it's changing."},
					{"speaker": "narrator", "text": "Faint green patches appear where once there was only gray..."},
					{"speaker": "discipline", "text": "*approaches*\n\nYou see it too. The human's consistency is taking root."},
					{"speaker": "goacto", "text": "Is this... growth? It's actually happening!"},
					{"speaker": "discipline", "text": "Three days of showing up. That's when the soil starts to shift.\n\nKeep going. Something is about to awaken."}
				]
			}
		]
	},
	"need_direction": {
		"id": "need_direction",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape",
				"dialogues": [
					{"speaker": "goacto", "text": "Ten sessions completed! The mindscape is thriving now."},
					{"speaker": "discipline", "text": "The human works hard. But I've noticed something..."},
					{"speaker": "goacto", "text": "What is it?"},
					{"speaker": "discipline", "text": "Activity without direction is just motion.\n\nYour human needs PURPOSE. Goals. A compass."},
					{"speaker": "vitality", "text": "*joins*\n\nI agree. They've got the energy, but where's it going?"},
					{"speaker": "narrator", "text": "In the distance, a faint azure light begins to pulse..."}
				]
			}
		]
	},
	"arctis_navigation": {
		"id": "arctis_navigation",
		"scenes": [
			{
				"background": "space",
				"location": "The Stellar Wanderer - Observation Deck",
				"dialogues": [
					{"speaker": "narrator", "text": "Goacto finds their father studying star charts..."},
					{"speaker": "arctis", "text": "Ah, there you are. You look troubled."},
					{"speaker": "goacto", "text": "Dad... how do you navigate across the galaxy? There are so many paths."},
					{"speaker": "arctis", "text": "*gestures to the charts*\n\nYou pick a destination. Then you chart a course. Then you follow it."},
					{"speaker": "arctis", "text": "A ship without heading just drifts with the cosmic winds.\n\nYour human is the same."},
					{"speaker": "goacto", "text": "So I need to help them set goals. Find their heading."},
					{"speaker": "arctis", "text": "Exactly. The journey is important, but without a destination...\n\n*looks at stars*\n\n...you're just wandering."},
					{"speaker": "arctis", "text": "Help them find their North Star, and everything else aligns."}
				]
			}
		]
	},
	"darkness_stirs": {
		"id": "darkness_stirs",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Shadows Gather",
				"dialogues": [
					{"speaker": "narrator", "text": "A chill settles over the mindscape..."},
					{"speaker": "goacto", "text": "What's happening? The light is... dimming?"},
					{"speaker": "wisdom", "text": "*voice serious*\n\nIt was inevitable. Growth attracts resistance."},
					{"speaker": "discipline", "text": "The human has been doing well. Too well, perhaps.\n\nTheir old patterns don't like being replaced."},
					{"speaker": "narrator", "text": "Dark tendrils creep from the edges of the platform..."},
					{"speaker": "goacto", "text": "What IS that?!"},
					{"speaker": "discipline", "text": "Doubt. Fear. The voices that tell them they can't.\n\nThey've been dormant. But now they're waking."},
					{"speaker": "wisdom", "text": "Prepare your human, Goacto. The battle for their potential begins."}
				]
			}
		]
	},
	"certification_ceremony": {
		"id": "certification_ceremony",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape - The Summit",
				"dialogues": [
					{"speaker": "narrator", "text": "All six Aspects gather in a circle of light..."},
					{"speaker": "discipline", "text": "We are here to recognize what has been achieved."},
					{"speaker": "vitality", "text": "Thirty days. THIRTY DAYS of consistent growth!"},
					{"speaker": "wisdom", "text": "Goals set and accomplished. Direction found and followed."},
					{"speaker": "courage", "text": "Fears faced. Doubts conquered. Over and over again."},
					{"speaker": "creativity", "text": "New patterns written. Old scripts rewritten. Beautiful!"},
					{"speaker": "compassion", "text": "And through it all... kindness. To self and others."},
					{"speaker": "discipline", "text": "Goacto. Step forward."},
					{"speaker": "narrator", "text": "A golden light envelops you..."},
					{"speaker": "discipline", "text": "By the authority vested in us by the human's own potential...\n\nWe grant you: CONTRIBUTION CERTIFICATION."},
					{"speaker": "goacto", "text": "*tears forming*\n\nI... thank you. All of you."},
					{"speaker": "compassion", "text": "No. Thank YOU.\n\nYou believed in this human when even they didn't believe in themselves."},
					{"speaker": "discipline", "text": "The journey continues. It always does.\n\nBut this chapter... is complete."}
				]
			}
		]
	},
	# Fallback cutscene for missing/coming soon content
	"_placeholder": {
		"id": "_placeholder",
		"scenes": [
			{
				"background": "mindscape_growing",
				"location": "Human Mindscape",
				"dialogues": [
					{"speaker": "system", "text": "TRANSMISSION INTERRUPTED\n\nThis chapter of your journey is still being written..."},
					{"speaker": "goacto", "text": "Hmm, it seems the neural link is experiencing some interference."},
					{"speaker": "goacto", "text": "Don't worry - the story continues. Keep growing, and this path will reveal itself soon."},
					{"speaker": "system", "text": "RETURNING TO MINDSCAPE...\n\nYour progress has been saved."}
				]
			}
		]
	}
}


func _ready() -> void:
	# Signals are connected in the TSCN file

	# Hide characters initially
	character_left.visible = false
	character_right.visible = false
	character_center.visible = false

	# Hide spaceship initially (shown only for space background)
	spaceship.visible = false

	# Setup button sounds
	_setup_ui_sounds()

	# Check if we should play a cutscene
	var pending = GameManager.player_data.get("pending_cutscene", "")
	if pending != "":
		GameManager.player_data.erase("pending_cutscene")
		play_cutscene(pending)
	else:
		# Default to intro for testing
		play_cutscene("intro")


func _setup_ui_sounds() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	for btn in [skip_button, back_button]:
		if btn and is_instance_valid(btn) and not btn.pressed.is_connected(audio.play_ui_click):
			btn.pressed.connect(audio.play_ui_click)


func _process(delta: float) -> void:
	animation_time += delta

	# Animate system character when visible
	if character_system.visible:
		_animate_system_character()

	if is_typing:
		type_timer += delta
		if type_timer >= type_speed:
			type_timer = 0.0
			displayed_chars += 1
			if displayed_chars >= full_text.length():
				dialogue_label.text = full_text
				is_typing = false
				continue_hint.visible = true
			else:
				dialogue_label.text = full_text.substr(0, displayed_chars)


func _animate_system_character() -> void:
	# Pulse the core
	var core_pulse = (sin(animation_time * 3.0) + 1.0) / 2.0  # 0 to 1
	var core_center = character_system.get_node_or_null("CoreCenter")
	if core_center:
		core_center.modulate.a = 0.7 + core_pulse * 0.3
		var scale_factor = 1.0 + core_pulse * 0.1
		core_center.scale = Vector2(scale_factor, scale_factor)

	var inner_core = character_system.get_node_or_null("InnerCore")
	if inner_core:
		var inner_pulse = (sin(animation_time * 2.5 + 0.5) + 1.0) / 2.0
		inner_core.modulate.a = 0.8 + inner_pulse * 0.2

	# Pulse the rings with offset phases
	var middle_ring = character_system.get_node_or_null("MiddleRing")
	if middle_ring:
		var ring_pulse = (sin(animation_time * 2.0) + 1.0) / 2.0
		middle_ring.modulate.a = 0.5 + ring_pulse * 0.3

	var outer_ring = character_system.get_node_or_null("OuterRing")
	if outer_ring:
		var ring_pulse = (sin(animation_time * 1.5 + 1.0) + 1.0) / 2.0
		outer_ring.modulate.a = 0.4 + ring_pulse * 0.3

	# Pulse the outer glow
	var outer_glow = character_system.get_node_or_null("OuterGlow")
	if outer_glow:
		var glow_pulse = (sin(animation_time * 1.0) + 1.0) / 2.0
		outer_glow.modulate.a = 0.1 + glow_pulse * 0.15

	# Flash the data lines sequentially
	for i in range(1, 7):
		var line = character_system.get_node_or_null("DataLine" + str(i))
		if line:
			var phase_offset = float(i) * 1.0
			var line_pulse = (sin(animation_time * 4.0 + phase_offset) + 1.0) / 2.0
			line.modulate.a = 0.3 + line_pulse * 0.7


func _input(event: InputEvent) -> void:
	# Handle keyboard (space/enter)
	if event.is_action_pressed("ui_accept"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func _on_click_area() -> void:
	# Handle clicks on the full-screen click area
	print("[Cutscene] Click area pressed")
	_advance_dialogue()


func play_cutscene(cutscene_id: String) -> void:
	# Use placeholder for missing cutscenes instead of failing
	if not CUTSCENES.has(cutscene_id):
		print("[Cutscene] Cutscene not yet implemented: " + cutscene_id + " - showing placeholder")
		current_cutscene_id = cutscene_id  # Keep original ID for tracking
		scenes = CUTSCENES["_placeholder"].scenes.duplicate(true)
	else:
		current_cutscene_id = cutscene_id
		scenes = CUTSCENES[cutscene_id].scenes.duplicate(true)

	current_scene_index = 0
	current_dialogue_index = 0

	# Ensure fade overlay starts opaque for intro
	fade_overlay.color.a = 1.0

	# Play cutscene music (at reduced volume - will be boosted after intro)
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music_for_cutscene"):
		audio.play_music_for_cutscene(cutscene_id)

	# For intro cutscenes, show a cinematic intro first
	if cutscene_id == "intro" or cutscene_id == "intro_part1":
		_play_cinematic_intro()
	else:
		fade_overlay.color.a = 0.0
		_show_scene(0)


func _play_cinematic_intro() -> void:
	# Setup the space scene with ship
	background.color = Color(0.02, 0.02, 0.06, 1.0)
	spaceship.visible = true
	stars.visible = true
	dialogue_panel.visible = false
	location_label.visible = false

	# Hide all characters
	character_left.visible = false
	character_right.visible = false
	character_center.visible = false
	character_system.visible = false

	# Create title text
	var title_container = Control.new()
	title_container.name = "IntroTitle"
	title_container.set_anchors_preset(Control.PRESET_CENTER)
	add_child(title_container)

	var title = Label.new()
	title.text = "MINDSCAPE"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-200, -80)
	title.custom_minimum_size = Vector2(400, 0)
	title_container.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "A Journey Within"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(-200, 20)
	subtitle.custom_minimum_size = Vector2(400, 0)
	title_container.add_child(subtitle)

	# Animate the intro sequence
	var tween = create_tween()

	# Fade from black (2 seconds)
	tween.tween_property(fade_overlay, "color:a", 0.0, 2.0).set_ease(Tween.EASE_OUT)

	# Pause to let visuals settle (1 second)
	tween.tween_interval(1.0)

	# Fade in title (1.5 seconds)
	tween.tween_property(title, "theme_override_colors/font_color:a", 1.0, 1.5).set_ease(Tween.EASE_OUT)

	# Fade in subtitle (1 second)
	tween.tween_property(subtitle, "theme_override_colors/font_color:a", 1.0, 1.0).set_ease(Tween.EASE_OUT)

	# Hold for dramatic effect (2 seconds)
	tween.tween_interval(2.0)

	# Fade out title and subtitle (1 second)
	tween.set_parallel(true)
	tween.tween_property(title, "theme_override_colors/font_color:a", 0.0, 1.0)
	tween.tween_property(subtitle, "theme_override_colors/font_color:a", 0.0, 1.0)
	tween.set_parallel(false)

	# Brief pause (0.5 seconds)
	tween.tween_interval(0.5)

	# Clean up and start the actual cutscene
	tween.tween_callback(func():
		title_container.queue_free()
		_show_scene(0)
	)


func _show_scene(index: int) -> void:
	if index >= scenes.size():
		_finish_cutscene()
		return

	var scene = scenes[index]
	var previous_scene_index = current_scene_index
	current_scene_index = index
	current_dialogue_index = 0

	# Check if we need a fade transition (scene change, not first scene)
	if index > 0 and previous_scene_index != index:
		_fade_to_scene(scene)
	else:
		_apply_scene(scene)


func _fade_to_scene(scene: Dictionary) -> void:
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_apply_scene(scene)
	)
	# Fade back in
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)


func _apply_scene(scene: Dictionary) -> void:
	# Set background
	_set_background(scene.get("background", "space"))

	# Set location
	if scene.has("location"):
		location_label.text = scene.location
		location_label.visible = true
	else:
		location_label.visible = false

	# Show first dialogue
	_show_dialogue(0)


func _set_background(bg_type: String) -> void:
	# Show spaceship and stars only in space scene
	spaceship.visible = (bg_type == "space")
	stars.visible = (bg_type == "space")

	# Show/hide kitchen elements
	if kitchen_elements:
		kitchen_elements.visible = (bg_type == "kitchen")

	# Create kitchen elements if needed
	if bg_type == "kitchen" and not kitchen_elements:
		_create_kitchen_elements()

	match bg_type:
		"space":
			background.color = Color(0.02, 0.03, 0.06)
		"kitchen":
			background.color = Color(0.08, 0.06, 0.12)
		"console":
			background.color = Color(0.04, 0.08, 0.06)
		"mindscape_empty":
			background.color = Color(0.04, 0.05, 0.08)
		"mindscape_growing":
			background.color = Color(0.06, 0.08, 0.1)
		_:
			background.color = ThemeConfig.BG_DEEP_SPACE


func _create_kitchen_elements() -> void:
	kitchen_elements = Node2D.new()
	kitchen_elements.name = "KitchenElements"
	kitchen_elements.position = Vector2(683, 350)
	add_child(kitchen_elements)
	move_child(kitchen_elements, 2)  # After Background and Stars

	# Floor
	var floor_poly = Polygon2D.new()
	floor_poly.color = Color(0.12, 0.1, 0.18, 1)
	floor_poly.polygon = PackedVector2Array([
		Vector2(-400, 50), Vector2(0, -150), Vector2(400, 50), Vector2(0, 200)
	])
	kitchen_elements.add_child(floor_poly)

	# Back wall
	var wall = Polygon2D.new()
	wall.color = Color(0.1, 0.08, 0.15, 1)
	wall.polygon = PackedVector2Array([
		Vector2(-400, -150), Vector2(-400, -350), Vector2(400, -350), Vector2(400, -150)
	])
	wall.position = Vector2(0, -50)
	kitchen_elements.add_child(wall)

	# Wall trim
	var trim = Polygon2D.new()
	trim.color = Color(0.6, 0.5, 0.8, 0.6)
	trim.polygon = PackedVector2Array([
		Vector2(-400, -345), Vector2(-400, -350), Vector2(400, -350), Vector2(400, -345)
	])
	trim.position = Vector2(0, -50)
	kitchen_elements.add_child(trim)

	# Window with stars visible through it
	var window_frame = Polygon2D.new()
	window_frame.color = Color(0.3, 0.25, 0.4, 1)
	window_frame.polygon = PackedVector2Array([
		Vector2(-80, -120), Vector2(80, -120), Vector2(80, 40), Vector2(-80, 40)
	])
	window_frame.position = Vector2(-200, -180)
	kitchen_elements.add_child(window_frame)

	var window_glass = Polygon2D.new()
	window_glass.color = Color(0.05, 0.08, 0.2, 1)
	window_glass.polygon = PackedVector2Array([
		Vector2(-70, -110), Vector2(70, -110), Vector2(70, 30), Vector2(-70, 30)
	])
	window_glass.position = Vector2(-200, -180)
	kitchen_elements.add_child(window_glass)

	# Stars in window
	var window_stars = Node2D.new()
	window_stars.position = Vector2(-200, -220)
	kitchen_elements.add_child(window_stars)

	for i in range(4):
		var star = Polygon2D.new()
		star.color = Color(1, 1, 0.9, 0.7 + randf() * 0.2)
		star.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)
		])
		star.position = Vector2(-40 + i * 30, -20 + (i % 2) * 40)
		window_stars.add_child(star)

	# Table
	var table_surface = Polygon2D.new()
	table_surface.color = Color(0.25, 0.2, 0.35, 1)
	table_surface.polygon = PackedVector2Array([
		Vector2(-100, -15), Vector2(0, -50), Vector2(100, -15), Vector2(0, 20)
	])
	table_surface.position = Vector2(150, 80)
	kitchen_elements.add_child(table_surface)

	# Table legs
	var leg1 = Polygon2D.new()
	leg1.color = Color(0.2, 0.15, 0.3, 1)
	leg1.polygon = PackedVector2Array([
		Vector2(-80, -5), Vector2(-80, 35), Vector2(-70, 40), Vector2(-70, 0)
	])
	leg1.position = Vector2(150, 80)
	kitchen_elements.add_child(leg1)

	var leg2 = Polygon2D.new()
	leg2.color = Color(0.2, 0.15, 0.3, 1)
	leg2.polygon = PackedVector2Array([
		Vector2(70, 0), Vector2(70, 40), Vector2(80, 35), Vector2(80, -5)
	])
	leg2.position = Vector2(150, 80)
	kitchen_elements.add_child(leg2)

	# Food synthesizer unit
	var synth_body = Polygon2D.new()
	synth_body.color = Color(0.3, 0.35, 0.45, 1)
	synth_body.polygon = PackedVector2Array([
		Vector2(-35, -70), Vector2(35, -70), Vector2(35, 35), Vector2(-35, 35)
	])
	synth_body.position = Vector2(280, -130)
	kitchen_elements.add_child(synth_body)

	var synth_screen = Polygon2D.new()
	synth_screen.color = Color(0.2, 0.6, 0.5, 0.8)
	synth_screen.polygon = PackedVector2Array([
		Vector2(-25, -20), Vector2(25, -20), Vector2(25, 20), Vector2(-25, 20)
	])
	synth_screen.position = Vector2(280, -160)
	kitchen_elements.add_child(synth_screen)


func _show_dialogue(index: int) -> void:
	var scene = scenes[current_scene_index]
	if index >= scene.dialogues.size():
		# Move to next scene
		_show_scene(current_scene_index + 1)
		return

	var dialogue = scene.dialogues[index]
	current_dialogue_index = index

	# Make sure dialogue panel is visible
	dialogue_panel.visible = true

	var char_data = CHARACTERS.get(dialogue.speaker, CHARACTERS.narrator)

	# Set speaker
	if char_data.name != "":
		speaker_label.text = char_data.name
		speaker_label.add_theme_color_override("font_color", char_data.color)
		speaker_label.visible = true
	else:
		speaker_label.visible = false

	# Start typing effect
	full_text = dialogue.text
	displayed_chars = 0
	dialogue_label.text = ""
	is_typing = true
	continue_hint.visible = false
	type_timer = 0.0

	# Update character positions
	_update_character_display(dialogue.speaker)

	# Update back button visibility - hide if at very first dialogue
	back_button.visible = (current_scene_index > 0 or current_dialogue_index > 0)

	# Play voice clip if available
	_play_voice_for_dialogue(current_scene_index, index)


func _update_character_display(speaker: String) -> void:
	character_left.visible = false
	character_right.visible = false
	character_center.visible = false
	character_system.visible = false

	var char_data = CHARACTERS.get(speaker, {})
	var position = char_data.get("position", "none")

	match position:
		"left":
			character_left.visible = true
			_style_character(character_left, char_data.color)
		"right":
			character_right.visible = true
			_style_character(character_right, char_data.color)
		"center":
			character_center.visible = true
			_style_character(character_center, char_data.color)
		"system":
			character_system.visible = true
			_style_character(character_system, char_data.color)


func _style_character(container: Control, color: Color) -> void:
	var sprite = container.get_node_or_null("Sprite")
	if sprite and sprite is Polygon2D:
		sprite.color = color


func _play_voice_for_dialogue(scene_idx: int, dialogue_idx: int) -> void:
	# Get AudioManager safely (avoids compile errors during editor reload)
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	# Stop any currently playing voice
	audio.stop_voice()

	# Build voice file path: voice/{cutscene_id}/s{scene}_d{dialogue}.ogg
	# Example: voice/intro_part1/s0_d0.ogg
	var voice_path = "%s%s/s%d_d%d.ogg" % [voice_base_path, current_cutscene_id, scene_idx, dialogue_idx]

	# Check cache first
	if voice_clips.has(voice_path):
		audio.play_voice(voice_clips[voice_path])
		return

	# Try to load the voice file
	if ResourceLoader.exists(voice_path):
		var stream = load(voice_path) as AudioStream
		if stream:
			voice_clips[voice_path] = stream
			audio.play_voice(stream)
			print("[Cutscene] Playing voice: ", voice_path)
	# If file doesn't exist, just continue without voice (expected during development)


func _advance_dialogue() -> void:
	if is_typing:
		# Skip typing, show full text
		dialogue_label.text = full_text
		is_typing = false
		continue_hint.visible = true
	else:
		# Move to next dialogue
		_show_dialogue(current_dialogue_index + 1)


func _on_back() -> void:
	# Stop any playing voice
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.stop_voice()

	# Go back to previous dialogue
	if is_typing:
		# If typing, just show full text first
		dialogue_label.text = full_text
		is_typing = false
		continue_hint.visible = true
		return

	if current_dialogue_index > 0:
		# Go to previous dialogue in current scene
		_show_dialogue(current_dialogue_index - 1)
	elif current_scene_index > 0:
		# Go to previous scene, last dialogue
		current_scene_index -= 1
		var prev_scene = scenes[current_scene_index]
		var dialogues = prev_scene.get("dialogues", [])
		current_dialogue_index = max(0, dialogues.size() - 1)
		_show_scene(current_scene_index)
		# Show the last dialogue of that scene
		if dialogues.size() > 0:
			_show_dialogue(current_dialogue_index)
	# If at very beginning, do nothing (button could be hidden)


var skip_confirm_panel: PanelContainer = null

func _on_skip() -> void:
	if skip_confirm_panel:
		return  # Already showing

	# Show skip confirmation dialog
	skip_confirm_panel = PanelContainer.new()
	skip_confirm_panel.name = "SkipConfirm"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = Color(0.5, 0.4, 0.6, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	skip_confirm_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	skip_confirm_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Skip Cutscene?"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var msg = Label.new()
	msg.text = "You can replay cutscenes later from the story menu."
	msg.add_theme_font_size_override("font_size", 16)
	msg.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var keep_btn = Button.new()
	keep_btn.text = "Keep Watching"
	keep_btn.custom_minimum_size = Vector2(140, 45)
	keep_btn.add_theme_font_size_override("font_size", 16)
	keep_btn.pressed.connect(_dismiss_skip_confirm)
	btn_row.add_child(keep_btn)

	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(100, 45)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.add_theme_color_override("font_color", Color(0.8, 0.6, 0.5))
	skip_btn.pressed.connect(_confirm_skip)
	btn_row.add_child(skip_btn)

	# Center on screen
	skip_confirm_panel.position = Vector2(
		(get_viewport_rect().size.x - 350) / 2,
		(get_viewport_rect().size.y - 150) / 2
	)
	skip_confirm_panel.custom_minimum_size = Vector2(350, 0)

	add_child(skip_confirm_panel)


func _dismiss_skip_confirm() -> void:
	if skip_confirm_panel:
		skip_confirm_panel.queue_free()
		skip_confirm_panel = null


func _confirm_skip() -> void:
	# Stop any playing voice
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.stop_voice()

	if skip_confirm_panel:
		skip_confirm_panel.queue_free()
		skip_confirm_panel = null

	print("[Cutscene] Skip confirmed - calling _finish_cutscene()")
	_finish_cutscene()
	print("[Cutscene] _finish_cutscene() completed")


func _finish_cutscene() -> void:
	# Prevent multiple calls
	if is_finishing:
		print("[Cutscene] Already finishing, ignoring")
		return
	is_finishing = true

	print("[Cutscene] Finishing cutscene: ", current_cutscene_id)

	# Mark cutscene as seen FIRST
	CampaignManager.mark_cutscene_seen(current_cutscene_id)
	print("[Cutscene] Marked cutscene as seen")

	cutscene_finished.emit(current_cutscene_id)

	# Check if this cutscene has a special transition
	var cutscene_data = CUTSCENES.get(current_cutscene_id, {})
	var transition_to = cutscene_data.get("transition_to", "")

	# Fade out before transitioning
	_fade_and_transition(transition_to)


func _fade_and_transition(transition_to: String) -> void:
	# Create fade out animation
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_callback(_execute_transition.bind(transition_to))


func _execute_transition(transition_to: String) -> void:
	# Check if we're in playlist mode (playing multiple cutscenes)
	var playlist = GameManager.player_data.get("cutscene_playlist", [])
	if playlist.size() > 0:
		# Play next cutscene in playlist
		var next_cutscene = playlist[0]
		playlist.remove_at(0)
		if playlist.size() == 0:
			GameManager.player_data.erase("cutscene_playlist")
		else:
			GameManager.player_data["cutscene_playlist"] = playlist

		print("[Cutscene] Playlist mode - playing next: ", next_cutscene)
		GameManager.player_data["pending_cutscene"] = next_cutscene
		GameManager.player_data["cutscene_replay_mode"] = true
		# Reload the cutscene scene to play the next one
		get_tree().reload_current_scene()
		return

	# Check if we're in replay mode (from cutscene theater)
	var replay_mode = GameManager.player_data.get("cutscene_replay_mode", false)
	if replay_mode:
		GameManager.player_data.erase("cutscene_replay_mode")
		# Return to where we came from (usually settings)
		var return_to = GameManager.previous_scene_path
		if return_to == "" or return_to.contains("cutscene"):
			return_to = "res://scenes/settings/settings.tscn"
		print("[Cutscene] Replay mode - returning to: ", return_to)
		GameManager.goto_scene(return_to)
		return

	match transition_to:
		"kitchen":
			# Transition to kitchen scene (intro flow)
			print("[Cutscene] Transitioning to kitchen...")
			GameManager.goto_scene("res://scenes/ship/kitchen.tscn")
		"bedroom":
			# Transition to Goacto's bedroom
			print("[Cutscene] Transitioning to bedroom...")
			GameManager.goto_scene("res://scenes/bedroom/bedroom.tscn")
		"mindscape", _:
			# Return to mindscape hub
			print("[Cutscene] Transitioning to mindscape hub...")
			GameManager.change_state(GameManager.GameState.MINDSCAPE)
			GameManager.goto_scene("res://scenes/mindscape/mindscape_hub.tscn")

	print("[Cutscene] goto_scene called")
