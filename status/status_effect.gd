extends Node

func is_curse():
	return false;

func is_crippling():
	return false;

func _play_turn(turn):
	return turn;
	
func _pre_turn():
	pass;
	
func _post_turn():
	pass;
	
func _pre_action(action):
	pass;
	
func _post_action(action):
	pass;


func _post_battle():
	pass;
	
func _effect_stat(stat:String, current):
	return current;

func _faint() -> bool:
	return true;

func get_icon() -> Texture:
	return preload("res://game/treasure/placeholder_treasure.png");
