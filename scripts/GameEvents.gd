extends Node

signal player_entered_box(box, body)
signal player_left_box(box, body)

func emit_player_entered_box(box_instance, body):
	player_entered_box.emit(box_instance, body)

func emit_player_left_box(box_instance, body):
	player_left_box.emit(box_instance, body)



#func has_connections(signalNname: String) -> bool:
	#return GameEvents.get_signal_connection_list(signal_name).size() > 0
