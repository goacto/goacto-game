extends Control
## Combat - Turn-based battle against Inner Resistance
## Players use Aspects to overcome internal enemies like Doubt, Fear, Procrastination

# Enemy types
const ENEMIES = {
	"doubt": {
		"name": "DOUBT",
		"max_health": 80,
		"attack": 10,
		"color": Color(0.5, 0.2, 0.3),
		"defeat_message": "You faced your doubt and emerged stronger.",
		"exp_reward": 50,
		"evolution_reward": 1.0
	},
	"fear": {
		"name": "FEAR",
		"max_health": 100,
		"attack": 15,
		"color": Color(0.3, 0.2, 0.5),
		"defeat_message": "Fear retreats. Courage grows.",
		"exp_reward": 75,
		"evolution_reward": 1.5
	},
	"procrastination": {
		"name": "PROCRASTINATION",
		"max_health": 60,
		"attack": 8,
		"color": Color(0.4, 0.4, 0.3),
		"defeat_message": "Action defeats inaction. Always.",
		"exp_reward": 40,
		"evolution_reward": 0.8
	},
	"distraction": {
		"name": "DISTRACTION",
		"max_health": 50,
		"attack": 12,
		"color": Color(0.6, 0.4, 0.2),
		"defeat_message": "Your focus cuts through the noise.",
		"exp_reward": 35,
		"evolution_reward": 0.7
	}
}

# UI References
@onready var enemy_name_label: Label = $BattleArena/EnemyArea/EnemyName
@onready var enemy_sprite: Polygon2D = $BattleArena/EnemyArea/EnemySprite
@onready var enemy_health_bar: ProgressBar = $BattleArena/EnemyArea/EnemyHealthBar
@onready var player_health_bar: ProgressBar = $BattleArena/PlayerArea/PlayerPanel/PlayerHealth
@onready var aspect_name_label: Label = $BattleArena/PlayerArea/AspectPanel/AspectName
@onready var aspect_health_bar: ProgressBar = $BattleArena/PlayerArea/AspectPanel/AspectHealth
@onready var aspect_sprite: Polygon2D = $BattleArena/PlayerArea/AspectPanel/AspectSprite

@onready var attack_button: Button = $UI/ActionPanel/Margin/VBox/ActionButtons/AttackButton
@onready var defend_button: Button = $UI/ActionPanel/Margin/VBox/ActionButtons/DefendButton
@onready var special_button: Button = $UI/ActionPanel/Margin/VBox/ActionButtons/SpecialButton
@onready var battle_log: Label = $UI/ActionPanel/Margin/VBox/BattleLog
@onready var action_label: Label = $UI/ActionPanel/Margin/VBox/ActionLabel

@onready var result_panel: PanelContainer = $UI/ResultPanel
@onready var result_title: Label = $UI/ResultPanel/Margin/VBox/ResultTitle
@onready var result_message: Label = $UI/ResultPanel/Margin/VBox/ResultMessage
@onready var continue_button: Button = $UI/ResultPanel/Margin/VBox/ContinueButton

# Combat state
var current_enemy: Dictionary = {}
var current_enemy_type: String = ""
var enemy_health: int = 0
var player_health: int = 100
var aspect_health: int = 100
var is_defending: bool = false
var is_player_turn: bool = true
var battle_over: bool = false

# Current aspect in battle
var active_aspect: String = "discipline"


func _ready() -> void:
	# Connect buttons
	attack_button.pressed.connect(_on_attack)
	defend_button.pressed.connect(_on_defend)
	special_button.pressed.connect(_on_special)
	continue_button.pressed.connect(_on_continue)

	# Start battle with random enemy
	_start_battle(_get_random_enemy())

	GameManager.change_state(GameManager.GameState.COMBAT)
	print("[Combat] Battle started")


func _start_battle(enemy_type: String) -> void:
	current_enemy_type = enemy_type
	if not ENEMIES.has(enemy_type):
		push_error("[Combat] Unknown enemy type: " + enemy_type)
		return
	current_enemy = ENEMIES[enemy_type].duplicate()
	enemy_health = current_enemy.max_health

	# Setup UI
	enemy_name_label.text = current_enemy.name
	enemy_sprite.color = current_enemy.color
	enemy_health_bar.max_value = current_enemy.max_health
	enemy_health_bar.value = enemy_health

	# Setup aspect
	var aspect_data = GameManager.player_data.aspects[active_aspect]
	aspect_name_label.text = aspect_data.name
	aspect_sprite.color = aspect_data.color
	special_button.text = aspect_data.name + "\n(Special)"

	# Calculate player stats based on habits
	var streak_bonus = _calculate_streak_bonus()
	player_health = 100 + (streak_bonus * 10)
	aspect_health = 80 + (aspect_data.level * 20)

	player_health_bar.max_value = player_health
	player_health_bar.value = player_health
	aspect_health_bar.max_value = aspect_health
	aspect_health_bar.value = aspect_health

	battle_log.text = "A wild " + current_enemy.name + " appears in your mindscape..."


func _get_random_enemy() -> String:
	var enemy_types = ENEMIES.keys()
	return enemy_types[randi() % enemy_types.size()]


func _calculate_streak_bonus() -> int:
	var total_streak = 0
	for habit in HabitManager.habits.values():
		total_streak += habit.streak
	return total_streak


func _on_attack() -> void:
	if not is_player_turn or battle_over:
		return

	is_defending = false

	# Calculate damage (base + aspect level bonus)
	var aspect_data = GameManager.player_data.aspects[active_aspect]
	var damage = 15 + (aspect_data.level * 3)

	enemy_health = max(0, enemy_health - damage)
	enemy_health_bar.value = enemy_health

	battle_log.text = "You focus your will! " + str(damage) + " damage to " + current_enemy.name + "!"

	_check_battle_end()

	if not battle_over:
		_enemy_turn()


func _on_defend() -> void:
	if not is_player_turn or battle_over:
		return

	is_defending = true
	battle_log.text = "You take a deep breath and center yourself..."

	# Heal slightly when defending
	player_health = min(player_health_bar.max_value, player_health + 10)
	player_health_bar.value = player_health

	_enemy_turn()


func _on_special() -> void:
	if not is_player_turn or battle_over:
		return

	is_defending = false

	# Powerful attack but costs aspect health
	var aspect_data = GameManager.player_data.aspects[active_aspect]
	var damage = 25 + (aspect_data.level * 5)

	# Cost
	aspect_health = max(0, aspect_health - 15)
	aspect_health_bar.value = aspect_health

	enemy_health = max(0, enemy_health - damage)
	enemy_health_bar.value = enemy_health

	battle_log.text = aspect_data.name + " channels your growth! " + str(damage) + " damage!"

	_check_battle_end()

	if not battle_over:
		_enemy_turn()


func _enemy_turn() -> void:
	is_player_turn = false
	_set_buttons_enabled(false)

	# Delay for drama
	await get_tree().create_timer(1.0).timeout

	if battle_over:
		return

	var damage = current_enemy.attack
	if is_defending:
		damage = damage / 2

	# Enemy attacks player or aspect randomly
	if randi() % 2 == 0:
		player_health = max(0, player_health - damage)
		player_health_bar.value = player_health
		battle_log.text = current_enemy.name + " attacks you for " + str(damage) + " damage!"
	else:
		aspect_health = max(0, aspect_health - damage)
		aspect_health_bar.value = aspect_health
		battle_log.text = current_enemy.name + " attacks " + aspect_name_label.text + " for " + str(damage) + " damage!"

	_check_battle_end()

	if not battle_over:
		is_player_turn = true
		_set_buttons_enabled(true)
		action_label.text = "Your turn:"


func _check_battle_end() -> void:
	# Victory
	if enemy_health <= 0:
		battle_over = true
		_show_victory()
		return

	# Defeat
	if player_health <= 0 and aspect_health <= 0:
		battle_over = true
		_show_defeat()
		return


func _show_victory() -> void:
	_set_buttons_enabled(false)

	# Award rewards
	GameManager.add_aspect_experience(active_aspect, current_enemy.exp_reward)
	GameManager.evolve_world(current_enemy.evolution_reward)

	# Track for campaign progress
	CampaignManager.record_combat_victory(current_enemy_type)

	SaveManager.save_game()

	result_title.text = current_enemy.name + " OVERCOME"
	result_title.add_theme_color_override("font_color", ThemeConfig.TEXT_SUCCESS)
	result_message.text = current_enemy.defeat_message + "\n\n+" + str(current_enemy.exp_reward) + " Experience\n+" + str(current_enemy.evolution_reward) + " World Evolution"
	result_panel.visible = true


func _show_defeat() -> void:
	_set_buttons_enabled(false)

	# No harsh punishment - just encouragement
	result_title.text = "RETREAT"
	result_title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5))
	result_message.text = "You withdraw to recover.\n\nThis resistance remains, but so do you.\nReturn stronger."
	result_panel.visible = true


func _on_continue() -> void:
	GameManager.change_state(GameManager.GameState.MINDSCAPE)
	GameManager.goto_scene("res://scenes/mindscape/mindscape_hub.tscn")


func _set_buttons_enabled(enabled: bool) -> void:
	attack_button.disabled = not enabled
	defend_button.disabled = not enabled
	special_button.disabled = not enabled
