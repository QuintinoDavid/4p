class_name SpeedPowerUp extends PowerUp

func _init():
	id = "speed"
	display_name = "Movement Speed Boost"
	description = "Increases movement speed"

func apply(player: Player) -> void:
	player.max_speed += 20