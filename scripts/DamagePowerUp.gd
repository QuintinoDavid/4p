class_name DamagePowerUp extends PowerUp

func _init():
	id = "damage"
	display_name = "Damage Boost"
	description = "Increases bullet damage"

func apply(player: Player) -> void:
	player.gun.bullet_damage += 5
