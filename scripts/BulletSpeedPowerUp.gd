class_name BulletSpeedPowerUp extends PowerUp

func _init():
	id = "bullet_speed"
	display_name = "Bullet Speed Boost"
	description = "Increases bullet velocity"

func apply(player: Player) -> void:
	player.gun.bullet_speed *= 1.20
