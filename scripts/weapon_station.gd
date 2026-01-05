extends Area2D
# Box.gd (attached to your Area2D box scene)

@export var box_id: String = ""
@export var box_type: String = "default"

func _ready():
	# Generate unique ID if not set
	if box_id.is_empty():
		box_id = "box_%s_%s" % [get_path(), Time.get_ticks_msec()]
	
	# Connect Area2D signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Debug
	#print("Box spawned: ", box_id)

func _on_body_entered(body):
	#print("Box %s entered by: %s" % [box_id, body.name])
	GameEvents.emit_player_entered_box(self, body)

func _on_body_exited(body):
	#print("Box %s exited by: %s" % [box_id, body.name])
	GameEvents.emit_player_left_box(self, body)

# Call this when player interacts with the box (e.g., presses a key)
#func interact(player_id: int):
	#print("Box %s interacted by player: %s" % [box_id, player_id])
	#GameEvents.emit_box_interacted(self, player_id)
