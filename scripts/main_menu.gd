extends Node2D

var local_port: int = 7777

var enet_peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene


func _on_host_pressed() -> void:
	enet_peer.create_server(local_port, 4)
	multiplayer.multiplayer_peer = enet_peer
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")
	print("Local host created on port " + str(local_port))

func _on_join_pressed() -> void:
	enet_peer.create_client("localhost", local_port)
	multiplayer.multiplayer_peer = enet_peer
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")
	print("Connecting to host...")


func _on_options_pressed() -> void:
	pass # Replace with function body.Working on it

func _on_quit_pressed() -> void:
	get_tree().quit()
