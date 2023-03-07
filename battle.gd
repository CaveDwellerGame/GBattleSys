extends Node

const team = preload("team.gd");
const actor = preload("actor.gd");


# warning-ignore-all:unused_signal
signal pre_battle();
signal post_battle(winner);

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
	var sfunc = _process_faints();
	if sfunc is GDScriptFunctionState:
		yield(sfunc, "completed")
	
	
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
	
	if action.is_valid():
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
		if team.has_method(event):
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
export(bool) var auto_begin_battle = true;


func _ready():
	if auto_begin_battle:
		yield(battle_loop(), "completed");

func battle_loop():
	yield(get_tree(), "idle_frame");
	
	# Loop through until the battle ends
	var winner = null;
	
	yield(_call_event("pre_battle"), "completed");
	while true:
		winner = play_turn();
		if winner is GDScriptFunctionState:
			winner = yield(winner, "completed");
		if winner != null:
			break;
	_call_event("post_battle", [winner]);
	
