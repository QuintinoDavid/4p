extends CanvasLayer

signal powerup_selected(powerup: PowerUp)

@onready var buttons = [$HBoxContainer/Button, $HBoxContainer/Button2, $HBoxContainer/Button3, $HBoxContainer/Button4]

func _ready():
	hide_popup()
	# Connect all buttons to the same handler
	for btn in buttons:
		btn.pressed.connect(_on_any_button_pressed.bind(btn))

func show_popup():
	visible = true
	randomize_powerups()

func hide_popup():
	visible = false

func randomize_powerups():
	var all_powerups = [
		DamagePowerUp.new(),
		HealthPowerUp.new(),
		CooldownPowerUp.new(),
		BulletSpeedPowerUp.new(),
		SpeedPowerUp.new()
	]
	all_powerups.shuffle()
	
	# Assign random powerups to buttons
	for i in range(min(4, buttons.size())):
		buttons[i].text = all_powerups[i].display_name
		buttons[i].set_meta("powerup", all_powerups[i])

func _on_any_button_pressed(button: Button):
	var powerup = button.get_meta("powerup") as PowerUp
	powerup_selected.emit(powerup)
	hide_popup()
