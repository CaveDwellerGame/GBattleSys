extends Node

const team = preload("team.gd");
const actor = preload("actor.gd");

signal battle_ended(winner);
signal pre_turn;
signal pre_action(action);
signal post_action(action);
signal post_turn;

func get_teams():
	var teams = [];
	for child in get_children():
		if (child as team):
			teams.append(child);
	return teams;
	
func play_turn():
	yield(_call_event("pre_turn"), "completed");
	
	var actions = [];
	var winner = battle_winner();
	if winner:
		return winner;
	
	
	for team in get_teams():
		var action = team.play_turn();
		action = yield(action, "completed") if action is GDScriptFunctionState else action;
		actions.append_array(action);
	
	actions.sort_custom(self, "sort_turns");
	for action in actions:
		winner = process_action(action);
		if winner is GDScriptFunctionState:
			winner = yield(winner, "completed");
		if winner:
			return winner;
			
	yield(_call_event("post_turn"), "completed");
	return null;

func process_action(action):
	var gdfunc = _process_faints();
	if gdfunc is GDScriptFunctionState:
		yield(gdfunc, "completed")
	
	var winner = null;
	winner = battle_winner();
	if winner:
		return winner;
	
	if action.is_valid():
		yield(_call_event("pre_action", [action]), "completed");
		
		gdfunc = action.execute();
		if gdfunc is GDScriptFunctionState:
			yield(gdfunc, "completed");
			
		yield(_call_event("post_action", [action]), "completed");
	gdfunc = _process_faints();
	if gdfunc is GDScriptFunctionState:
		yield(gdfunc, "completed")
	
	winner = battle_winner();
	return winner;

func sort_turns(a, b):
	return a.priority < b.priority;


func _call_event(event:String, params = []):
	var array = [event];
	array.append_array(params)
	callv("emit_signal", array);
	
	for team in get_teams():
		var gdfunc = team.callv(event, params);
		if gdfunc is GDScriptFunctionState:
			yield(gdfunc, "completed");
	
	if has_method("_" + event):
		var gdfunc = callv("_" + event, params);
		if gdfunc is GDScriptFunctionState:
			yield(gdfunc, "completed");
	yield(get_tree(), "idle_frame");


func _process_faints():
	for team in get_teams():
		for actor in team.get_children():
			if actor.has_method("shouldfaint") && actor.shouldfaint():
				yield(actor.faint(), "completed");
				

func get_remaining_teams() -> Array:
	var teams = get_teams();
	for team in teams:
		if !team.is_active():
			teams.erase(team);
	return teams;
	
func battle_winner() -> team:
	var teams = get_remaining_teams();
	if teams.size() == 1:
		return teams[0];
	return null;

export(PackedScene) var return_scene = null;
func _ready():
	if has_method("_start_battle"):
		var start = call("_start_battle");
		if start is GDScriptFunctionState:
			yield(start, "completed");
	yield(battle_loop(), "completed");

func battle_loop():
	yield(get_tree(), "idle_frame");
	# Loop through until the battle ends
	var winner = null;
	Physics2DServer.set_active(false);
	PhysicsServer.set_active(false);
	
	while true:
		winner = play_turn();
		if winner is GDScriptFunctionState:
			winner = yield(winner, "completed");
		if winner != null:
			break;
			
	Physics2DServer.set_active(true);
	PhysicsServer.set_active(true);
	
	for team in get_teams():
		var result = team.post_battle(winner);
		if result is GDScriptFunctionState:
			yield(result, "completed");
	get_tree().root.set_physics_process(true);
	emit_signal("battle_ended", winner);
	 
