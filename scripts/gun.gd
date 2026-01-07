extends Node2D

const bullet_scene = preload("res://Scenes/bullet.tscn")

@onready var RotationOffset: Node2D = $RotationOffset
@onready var SpriteShadow: Sprite2D = $RotationOffset/Sprite2D/shadow
@onready var ShootPos: Marker2D = $RotationOffset/Sprite2D/shoot_pos

var shoot_cooldown: float = 0.5
var can_shoot: bool = true
 
func _ready() -> void:
	$ShotTimer.wait_time = shoot_cooldown

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Don't process if gun is not visible
	if not visible:
		return
	
	RotationOffset.rotation = lerp_angle(RotationOffset.rotation, (get_global_mouse_position() - global_position).angle(), 6.5 * delta)
	SpriteShadow.position = Vector2(-2,2).rotated(RotationOffset.rotation)
	
	if get_global_mouse_position().x  < global_position.x:
		$RotationOffset/Sprite2D.flip_v = true
	else:
		$RotationOffset/Sprite2D.flip_v = false
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot.rpc(multiplayer.get_unique_id())
		can_shoot = false
		$ShotTimer.start()

@rpc("call_local")
func _shoot(data):
	# Check if gun is still valid and in tree
	if not is_inside_tree():
		return
	
	# Find the Game node (root of the scene)
	var game_node = get_tree().current_scene
	if game_node == null:
		print("Error: Could not find game node")
		return
	
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = ShootPos.global_position
	new_bullet.global_rotation = ShootPos.global_rotation
	new_bullet.set_multiplayer_authority(data)
	new_bullet.shooter_id = data 
	game_node.add_child(new_bullet)

func _on_shot_timer_timeout() -> void:
	can_shoot = true
