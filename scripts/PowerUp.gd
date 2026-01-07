class_name PowerUp
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null

# Override this method in subclasses to apply the powerup effect
func apply(_player: Player) -> void:
	push_error("PowerUp.apply() must be overridden in subclass")
