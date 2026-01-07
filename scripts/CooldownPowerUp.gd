class_name CooldownPowerUp extends PowerUp

func _init():
	id = "cooldown"
	display_name = "Fire Rate Boost"
	description = "Reduces shooting cooldown"

func apply(player: Player) -> void:
	player.gun.shoot_cooldown *= 0.8
