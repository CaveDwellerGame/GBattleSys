extends "actor.gd";

export(Dictionary) var weights = Dictionary();

func _play_turn():
	if weights.empty():
		return BattleAction.new(self);
	var choice = select_choice();
	var action = weights.keys()[choice];
	
	var target_team = get_parent() if action.get_alignemnt() > 0 else null;
	if target_team == null:
		var teams:Array = get_parent().get_parent().get_teams();
		teams.erase(get_parent());
		if teams.size() != 0:
			target_team = teams[randi() % teams.size()];
		else:
			return BattleAction.new(self);
			
	if action.get_target_type() == BattleAction.TargetType.TargetActor:
		randomize();
		return action.new(self, target_team.get_child(randi() % target_team.get_child_count()));
	if action.get_target_type() == BattleAction.TargetType.TargetTeam:
		return action.new(self, target_team);
		
		
	return action.new(self);
	
func select_choice() -> int:
	randomize();
	var weight_sum = 0;
	var values = weights.values();
	for weight in values:
		weight_sum += weight;
	var random = rand_range(0, weight_sum);
	for i in weights.size():
		if random < values[i]:
			return i;
		random -= values[i];
	push_error("Could not find move");
	return 0;
	
