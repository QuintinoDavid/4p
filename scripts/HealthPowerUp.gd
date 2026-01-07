class_name HealthPowerUp extends PowerUp

func _init():
	id = "health"
	display_name = "Health Boost"
	description = "Increases max health"

func apply(player: Player) -> void:
	player.maxHealth += 10
	player.health_bar.max_value = player.maxHealth