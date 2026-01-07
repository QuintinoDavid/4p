extends CanvasLayer

@onready var winner_label = $ColorRect/VBoxContainer/WinnerLabel
@onready var scores_label = $ColorRect/VBoxContainer/ScoresLabel

func _ready():
	hide()

func show_victory(winner_id: int, scores: Dictionary):
	# Show the victory screen
	visible = true
	
	# Update winner text
	winner_label.text = "PLAYER " + str(winner_id) + " WINS!"
	
	# Build scores text - sort by score descending
	var scores_text = "FINAL SCORES:\n\n"
	
	# Create array of [player_id, score] pairs for sorting
	var score_pairs = []
	for player_id in scores.keys():
		score_pairs.append([player_id, scores[player_id]])
	
	# Sort by score (highest first)
	score_pairs.sort_custom(func(a, b): return a[1] > b[1])
	
	# Build formatted text
	for pair in score_pairs:
		var player_id = pair[0]
		var score = pair[1]
		var prefix = "👑 " if player_id == winner_id else "   "
		scores_text += prefix + "Player " + str(player_id) + ": " + str(score) + "\n"
	
	scores_label.text = scores_text

func _on_main_menu_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
