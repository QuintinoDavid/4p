class_name Game
extends Node

const PLAYER = preload("res://Scenes/Player.tscn")
const VICTORY_SCREEN = preload("res://Scenes/victory_screen.tscn")

var players:Array[Player] = []
@export var player_scores: Dictionary = {}
var players_ready: Dictionary = {}  # player_id: bool
@export var winning_score: int = 10
var victory_screen_instance: CanvasLayer = null

# Signal for when a player dies
signal player_died(dead_player_id: int, killer_id: int)

func _ready() -> void:
	# Check if multiplayer is set up
	if multiplayer.multiplayer_peer:
		print("Game starting with multiplayer configured")
		
		# Connect multiplayer signals
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		$MultiplayerSpawner.spawn_function = add_player
		# Connect to player death signal
		player_died.connect(_on_player_died)
		
	# Wait for the scene tree to be fully ready before spawning
	await get_tree().process_frame
	
	# Spawn the host/local player immediately
	if multiplayer.is_server():
		var my_id = multiplayer.get_unique_id()
		print("Spawning host player: " + str(my_id))
		$MultiplayerSpawner.spawn(my_id)

func add_player(pid):
	print("add_player called for pid: " + str(pid))
	print("Current players count: " + str(players.size()))
	
	var player = PLAYER.instantiate()
	player.name = str(pid)
	
	# Get spawn position from spawn markers
	var spawn_markers = [
		$Level/Spawner,
		$Level/Spawner2,
		$Level/Spawner3,
		$Level/Spawner4
	]
	
	var spawn_index = players.size() % spawn_markers.size()
	player.global_position = spawn_markers[spawn_index].global_position
	players.append(player)
	player_scores[pid] = 0
	
	# Create score label for this player
	var label = Label.new()
	label.name = "Player" + str(pid) + "Score"
	label.text = "Player " + str(players.size()) + ": 0"
	label.add_theme_font_size_override("font_size", 24)
	
	# Position label with spacing
	if has_node("Points"):
		var player_index = players.size() - 1
		label.position = Vector2(10, 30 + (player_index * 35))
		$Points.add_child(label)
	
	print("Player spawned at position: " + str(player.global_position))
	return player

func _on_peer_connected(pid: int):
	print("Peer " + str(pid) + " connected in game!")
	# Only host spawns players
	if multiplayer.is_server():
		print("Host spawning player: " + str(pid))
		$MultiplayerSpawner.spawn(pid)

func _on_peer_disconnected(pid: int):
	print("Peer " + str(pid) + " disconnected!")

func _on_player_died(dead_player_id: int, killer_id: int):	
	print("Player " + str(dead_player_id) + " died. Killer: " + str(killer_id))
	
	# Count alive players
	var alive_count = 0
	var survivor_id = -1
	for player in players:
		if player != null and not player.is_dead:
			alive_count += 1
			survivor_id = int(player.name)
	
	# Only respawn if there's 1 or fewer players alive (round is over)
	if alive_count <= 1:
		print("Round over! Only " + str(alive_count) + " player(s) alive")
		
		# Clear all bullets from the scene
		var bullets = get_tree().get_nodes_in_group("Bullets")
		print ("Removing " + str(bullets.size()) + " bullets from scene")
		for bullet in bullets:
			# Stop any ongoing animations to prevent double deletion
			if bullet.has_node("AnimationPlayer"):
				bullet.get_node("AnimationPlayer").stop()
			if bullet.has_method("remove_bullet"):
				bullet.remove_bullet.rpc()

		# Award point to survivor (only on server)
		#multiplayer.is_server() and
		if  alive_count == 1 and survivor_id != -1:
			
			add_score.rpc(survivor_id)
			update_scores.rpc()

			# Check if player won the game
			if player_scores[survivor_id] >= winning_score:
				show_victory_screen.rpc(survivor_id)
				return  # Don't show popups or respawn


		# Show popups to each player using RPC
		for player in players:
			if player != null:
				var player_id = int(player.name)
				if player.is_dead:
					print("Calling loser popup for player " + str(player_id))
					player.show_loser_popup_rpc.rpc_id(player_id)
					players_ready[player_id] = false
				else:
					print("Calling winner popup for player " + str(player_id))
					player.show_winner_popup_rpc.rpc_id(player_id)
		
		print("Waiting for " + str(players_ready.size()) + " loser(s) to pick powerups...")
		
		# If no losers (draw), respawn immediately
		if players_ready.size() == 0:
			respawn_players()
	else:
		print(str(alive_count) + " players still alive - round continues")



func respawn_players():
	close_all_popups.rpc()

	for player in players:
		if player.has_method("respawn"):
			player.respawn.rpc()

func get_score(player_id: int) -> int:
		return player_scores.get(player_id, 0)

@rpc("any_peer", "call_local", "reliable")
func add_score(player_id: int):
	player_scores[player_id] += 1

@rpc("any_peer", "call_local")
func update_scores():
	# Update score display for each player
	for i in range(players.size()):
		if i < players.size() and players[i] != null:
			var pid = int(players[i].name)
			var label_name = "Player" + str(pid) + "Score"
			if has_node("Points/" + label_name):
				$Points.get_node(label_name).text = "Player " + str(i + 1) + ": " + str(get_score(pid))

@rpc("any_peer", "call_local", "reliable")
func player_ready(player_id: int):
	if players_ready.has(player_id):
		players_ready[player_id] = true
		print("Player " + str(player_id) + " is ready")
		check_all_ready()

func check_all_ready():
	# Check if all losers have picked powerups
	for player_id in players_ready.keys():
		if not players_ready[player_id]:
			return  # Someone still choosing
	
	print("All players ready! Respawning...")
	players_ready.clear()
	respawn_players()

@rpc("call_local", "reliable")
func close_all_popups():
	for player in players:
		if player != null:
			var player_id = int(player.name)
			if player.winner_popup:
				player.hide_winner_popup_rpc.rpc_id(player_id)
			if player.loser_popup:
				player.hide_loser_popup_rpc.rpc_id(player_id)

@rpc("any_peer", "call_local")
func show_victory_screen(winner_id: int):
	print("Game Over! Player " + str(winner_id) + " wins the match!")
	
	# Create and show victory screen
	if not victory_screen_instance:
		victory_screen_instance = VICTORY_SCREEN.instantiate()
		add_child(victory_screen_instance)
	
	victory_screen_instance.show_victory(winner_id, player_scores)
