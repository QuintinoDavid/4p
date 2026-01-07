extends Area2D

@onready var Shadow: Sprite2D = $shadow
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer

@export var speed: float = 250.0
@export var damage: float = 10.0
var did_damage: bool = false
var shooter_id: int = -1

func _ready():
	z_as_relative = false  
	z_index = 10          
	
func _physics_process(delta: float) -> void:
	global_position += Vector2(1, 0).rotated(rotation) * speed * delta
	Shadow.position = Vector2(-2, -2).rotated(-rotation) 

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "remove":
		if is_inside_tree():
			remove_bullet.rpc()
	
func _on_distance_timeout_timeout() -> void:
	AnimPlayer.play("remove")

func _on_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority(): return
	if !is_inside_tree(): return
	if !did_damage:
		did_damage = true
		if body and body.has_method("take_damage"):
			body.take_damage.rpc(damage, shooter_id)
		AnimPlayer.play("remove")

@rpc("any_peer", "call_local")
func remove_bullet():
	print("Removing bullet")
	# Check if bullet is still valid
	if not is_inside_tree():
		return
	queue_free()
