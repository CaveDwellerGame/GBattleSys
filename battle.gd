extends Node

const team = preload("team.gd");


signal battle_ended(result);
signal post_turn();

func get_teams():
	var teams = [];
	for child in get_children():
		if (child as team):
			teams.append(child);
	return teams;
	
func play_turn():
	var actions = [];
	var ended = battle_ended();
	if ended:
		return ended;
		
	for team in get_teams():
		var action = team.play_turn();
		action = yield(action, "completed") if action is GDScriptFunctionState else action;
		actions.append_array(action);
	
	actions.sort_custom(self, "sort_turns");
	for action in actions:
		var gdfunc = process_action(action);
		if gdfunc is GDScriptFunctionState:
			yield(gdfunc, "completed")
			
		ended = battle_ended();
		if ended:
			return ended;
		
	var result = $TeamA.post_turn();
	if result is GDScriptFunctionState:
		yield(result, "completed");
	result = $TeamB.post_turn();
	if result is GDScriptFunctionState:
		yield(result, "completed");
	emit_signal("post_turn");
	return battle_ended();

func process_action(action):
	var gdfunc = _process_faints();
	if gdfunc is GDScriptFunctionState:
		yield(gdfunc, "completed")
	
	if action.is_valid():
		gdfunc = action.execute();
		if gdfunc is GDScriptFunctionState:
			yield(gdfunc, "completed");
			
	gdfunc = _process_faints();
	if gdfunc is GDScriptFunctionState:
		yield(gdfunc, "completed")
	
	for team in get_teams():
		gdfunc = team.post_action();
		if gdfunc is GDScriptFunctionState:
			yield(gdfunc, "completed");


func _process_faints():
	for team in get_teams():
		for actor in team.get_children():
			if actor.has_method("shouldfaint") && actor.shouldfaint():
				yield(actor.faint(), "completed");

enum BattleResult {
	BATTLE_LOST = -1,
	BATTLE_UNFINISHED,
	BATTLE_WON
}
# returns -1 if we won, 1 if we lost, 0 if the battle is still happening
func battle_ended():
	if $TeamA.has_lost():
		return BattleResult.BATTLE_LOST;
	if $TeamB.has_lost():
		return BattleResult.BATTLE_WON;
	return BattleResult.BATTLE_UNFINISHED;

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
	var result = 0;
	while true:
		result = play_turn();
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		if result != BattleResult.BATTLE_UNFINISHED:
			break;
	var state = $TeamA.post_battle(result);
	if state is GDScriptFunctionState:
		yield(state, "completed");
	state = $TeamA.post_battle(result);
	if state is GDScriptFunctionState:
		yield(state, "completed");
	emit_signal("battle_ended", result);
