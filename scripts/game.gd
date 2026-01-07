class_name Game
extends Node

const PLAYER = preload("res://Scenes/Player.tscn")

var players:Array[Player] = []
var player_scores: Dictionary = {}

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
		
		# Show popups to each player using RPC
		for player in players:
			if player != null:
				var player_id = int(player.name)
				if player.is_dead:
					# Call show_loser_popup on the losing player's machine
					print("Calling loser popup for player " + str(player_id))
					player.show_loser_popup_rpc.rpc_id(player_id)
				else:
					# Call show_winner_popup on the winning player's machine
					print("Calling winner popup for player " + str(player_id))
					player.show_winner_popup_rpc.rpc_id(player_id)
		
		# Award point to survivor
		if alive_count == 1 and survivor_id != -1:
			add_score.rpc(survivor_id, 1)
			print("Player " + str(survivor_id) + " wins the round!")
		
		# Clear all bullets from the scene
		var bullets = get_tree().get_nodes_in_group("Bullets")
		print ("Removing " + str(bullets.size()) + " bullets from scene")
		for bullet in bullets:
			# Stop any ongoing animations to prevent double deletion
			if bullet.has_node("AnimationPlayer"):
				bullet.get_node("AnimationPlayer").stop()
			if bullet.has_method("remove_bullet"):
				bullet.remove_bullet.rpc()

		respawn_players()
	else:
		print(str(alive_count) + " players still alive - round continues")

@rpc("authority", "call_local", "reliable")
func add_score(player_id: int, points: int):
	if not player_scores.has(player_id):
		player_scores[player_id] = 0
	
	player_scores[player_id] += points
	print("Player " + str(player_id) + " score: " + str(player_scores[player_id]))

func get_score(player_id: int) -> int:
		return player_scores.get(player_id, 0)

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

func respawn_players():	
	# Update scores for all players
	update_scores.rpc()
	for player in players:
		if player.has_method("respawn"):
			player.respawn.rpc()

@rpc("authority", "call_local", "reliable")
func update_scores():
	# Update score display for each player
	for i in range(players.size()):
		if i < players.size() and players[i] != null:
			var pid = int(players[i].name)
			var label_name = "Player" + str(pid) + "Score"
			if has_node("Points/" + label_name):
				$Points.get_node(label_name).text = "Player " + str(i + 1) + ": " + str(get_score(pid))
