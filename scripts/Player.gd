class_name Player
extends CharacterBody2D

@onready var CoyoteTimer: Timer = $CoyoteTimer
@onready var JumpBufferTimer: Timer = $JumpBufferTimer
@onready var health_bar : ProgressBar = $HealthBar
@onready var loser_popup: CanvasLayer = $LoserPopUp
@onready var winner_popup: CanvasLayer = $WinnerPopUp

@export var maxHealth: float = 40
@export var is_dead: bool = false
var coyote_time_activated: bool = false

var base_stats = {
	"maxHealth": 40,
	"max_speed": 200
}

var active_powerups: Array = []

const jump_height: float = -500
var gravity: float = 12
const max_gravity: float = 14.5

var max_speed: float = 200
const acceleration: float = 8
const friction: float = 10

const GRAVITY_NORMAL: float = 14.5
const GRAVITY_WALL: float = 130
const WALL_JUMP_PUSHBACK: float = 200
var wall_contact_coyote: float = 0.0
const WALL_CONTACT_COYOTE_TIME: float = 0.05

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.30

var look_dir_x: int = 1

var can_get_gun: bool = false
var has_gun: bool = false

@onready var gun: Node2D = $Gun

var score: int = 0


func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	# Connect to global box events
	GameEvents.player_entered_box.connect(_on_global_box_entered)
	GameEvents.player_left_box.connect(_on_global_box_exited)
	#init health
	health_bar.init_health(maxHealth)
	#setup own camera
	if has_node("Camera2D"):
		var camera = get_node("Camera2D")
		camera.enabled = is_multiplayer_authority()
	
	# Hide gun initially
	if gun:
		gun.visible = false
		has_gun = false
	
	if loser_popup:
		loser_popup.powerup_selected.connect(apply_powerup)

func _on_global_box_entered(_box_instance, _body):
	if not is_multiplayer_authority():
		return
	can_get_gun = true
	print(str(can_get_gun))
	
func _on_global_box_exited(_box_instance, _body):
	if not is_multiplayer_authority():
		return
	can_get_gun = false


func _physics_process(delta: float) -> void:
	# Only process input if this is our player
	if not is_multiplayer_authority() or is_dead or loser_popup.visible or winner_popup.visible:
		return
	
	# DEBUG: Press ESC to make the player die
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key
		die()
	
	if can_get_gun and Input.is_action_just_pressed("get_weapon") and !has_gun:
		if gun:
			gun.visible = true
			has_gun = true
			print("get_weapon")
		
	if Input.is_action_just_pressed("remove_weapon") and has_gun:
		if gun:
			gun.visible = false
			has_gun = false
			print("remove_weapon")

	
	#Left-right movement
	var x_input: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left") 
	var velocity_wheight: float = delta * (acceleration if x_input else friction)
	
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta
		velocity.x = lerp(velocity.x, x_input * max_speed, velocity_wheight * 0.5)
		#velocity.x = x_input * max_speed
	else:
		velocity.x = lerp(velocity.x, x_input * max_speed, velocity_wheight)
		#velocity.x = x_input * max_speed
	
	if is_on_floor():
		coyote_time_activated = false
		gravity = lerp(gravity, 12.0, 12.0 * delta)
	else:
		if CoyoteTimer.is_stopped() and !coyote_time_activated:
			CoyoteTimer.start()
			coyote_time_activated = true
		#Variable Jump height
		if Input.is_action_just_released("ui_up")or is_on_ceiling():
			velocity.y *= 0.5
		
		gravity = lerp(gravity, max_gravity, 12.0 * delta)
	#Jump
	if Input.is_action_just_pressed("ui_up"):  
		if JumpBufferTimer.is_stopped():
			JumpBufferTimer.start()
			
	if !JumpBufferTimer.is_stopped() and (!CoyoteTimer.is_stopped() or is_on_floor() or wall_contact_coyote > 0.0):
		velocity.y = jump_height
		JumpBufferTimer.stop()
		CoyoteTimer.stop()
		coyote_time_activated = true
		if wall_contact_coyote > 0.0:
			velocity.x = -look_dir_x * WALL_JUMP_PUSHBACK
			wall_jump_lock = WALL_JUMP_LOCK_TIME
	#Drop from platform
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		set_collision_mask_value(3, false)
		await get_tree().create_timer(0.3).timeout
		set_collision_mask_value(3, true)
	#Head nudge
	if velocity.y < jump_height/2.0:
		var HeadCollision: Array = [$LeftHeadNudge.is_colliding(), $LeftHeadNudge2.is_colliding(), $RightHeadNudge.is_colliding(), $RightHeadNudge2.is_colliding()]
		if HeadCollision.count(true) == 1:
			if HeadCollision[0]:
				global_position.x += 1.75
			if HeadCollision[2]:
				global_position.x -= 1.75
	
	#little help on jumping
	if velocity.y > -30 and velocity.y < -5 and abs(velocity.x) > 3:
		if $LeftLedgeHop.is_colliding() and !$LeftLedgeHop2.is_colliding() and velocity.x > 0:
			velocity.y += jump_height/3
		if $RightLedgeHop.is_colliding() and !$RightLedgeHop2.is_colliding() and velocity.x < 0:
			velocity.y += jump_height/3
			 
	if !is_on_floor() and velocity.y > 0 and is_on_wall() and velocity.x != 0 :
		look_dir_x = sign(velocity.x)
		wall_contact_coyote =  WALL_CONTACT_COYOTE_TIME
		velocity.y = GRAVITY_WALL
	else:
		wall_contact_coyote -= delta
		velocity.y += gravity
	
	if not is_dead:
		move_and_slide()

@rpc("any_peer", "call_local")
func take_damage(amount, shooter_id):
	health_bar._set_health(health_bar.value - amount)
	
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health_bar.value <= 0:
		die(shooter_id)

func die(shooter_id = -1):
	# Only the authority (the player themselves) should handle their death
	if not is_multiplayer_authority():
		return	
	
	health_bar._set_health(maxHealth)
	_handle_death_visuals.rpc()
	
	# Notify game that this player died
	var game_node = get_tree().current_scene
	if game_node and game_node.has_signal("player_died"):
		game_node.player_died.emit(int(str(name)), shooter_id)

@rpc("any_peer", "call_local", "reliable")
func _handle_death_visuals():
	# This runs on ALL clients to synchronize death state
	is_dead = true
	visible = false
	
	# Disable collision layers
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)
	
	if gun and has_gun:
		gun.visible = false
		has_gun = false

@rpc("any_peer", "call_local", "reliable")
func respawn():
	health_bar.health = maxHealth
	health_bar.value = maxHealth
	health_bar.get_node("DamageBar").value = maxHealth
	is_dead = false
	velocity = Vector2.ZERO
	
	# Re-enable collision layers
	set_collision_layer_value(1, true)   # Enable player collision layer
	set_collision_mask_value(1, true)    # Enable collision with other players
	set_collision_mask_value(2, true)    # Enable collision with bullets
	set_collision_mask_value(3, true)    # Enable collision with platforms
	
	# Hide popups when respawning
	# if loser_popup:
	# 	loser_popup.hide_popup()
	# if winner_popup:
	# 	winner_popup.hide_popup()
	
	# Only the authority (the player themselves) should set their position
	if is_multiplayer_authority():
		# Hide gun when respawning
		if gun:
			gun.visible = false
			has_gun = false

		# Get spawn position
		var game_node = get_tree().current_scene
		if game_node and game_node.has_method("get") and game_node.get("players"):
			var player_index = game_node.players.find(self)
			if player_index != -1:
				# Get spawn markers
				var spawn_markers = [
					game_node.get_node("Level/Spawner"),
					game_node.get_node("Level/Spawner2"),
					game_node.get_node("Level/Spawner3"),
					game_node.get_node("Level/Spawner4")
				]
				var spawn_index = player_index % spawn_markers.size()
				if spawn_markers[spawn_index]:

					position = spawn_markers[spawn_index].global_position
					print("Setting spawn position to: " + str(position))
	
	visible = true
	
	print("Player " + str(name) + " respawned at position: " + str(global_position))


func add_powerup(powerup: PowerUp) -> void:
	active_powerups.append(powerup)
	powerup.apply(self)

func remove_gun():
	if gun and has_gun:
		gun.visible = false
		has_gun = false

@rpc("any_peer", "call_local", "reliable")
func show_winner_popup_rpc():
	if is_multiplayer_authority() and winner_popup != null:
		print("Showing winner popup for player " + str(name))
		winner_popup.show_popup()

@rpc("any_peer", "call_local", "reliable")
func hide_winner_popup_rpc():
	if is_multiplayer_authority() and winner_popup != null:
		print("Hiding winner popup for player " + str(name))
		winner_popup.hide_popup()


@rpc("any_peer", "call_local", "reliable")
func show_loser_popup_rpc():
	if is_multiplayer_authority() and loser_popup != null:
		print("Showing loser popup for player " + str(name))
		loser_popup.show_popup()

@rpc("any_peer", "call_local", "reliable")
func hide_loser_popup_rpc():
	if is_multiplayer_authority() and loser_popup != null:
		print("Hiding loser popup for player " + str(name))
		loser_popup.hide_popup()

func apply_powerup(powerup: PowerUp):
	if not is_multiplayer_authority():
		return
	print("Player " + str(name) + " applying powerup: " + powerup.display_name)
	active_powerups.append(powerup)
	powerup.apply(self)
	
	# Notify game that this player is ready
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("player_ready"):
		game_node.player_ready.rpc(int(name))
