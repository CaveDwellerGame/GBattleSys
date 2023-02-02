extends "actor.gd";

export(Dictionary) var weights = Dictionary();
var RNG = RandomNumberGenerator.new();

func _play_turn():
	if weights.empty():
		return BattleAction.new(self);
		
	RNG.randomize();
		
	var choice = select_choice();
	var action = weights.keys()[choice];
	
	var target_team = get_parent() if action.get_alignment() > 0 else \
			get_parent().get_node(get_parent().enemy);
	match action.get_target_type():
		BattleAction.TargetType.TargetActor:

			var actors = target_team.get_children();
			for actor in actors:
				if !BattleAction.mode_applies_to_target(actor, action.get_target_mode()):
					actors.erase(actor);
			if actors.size() == 1:
				return action.new(self, actors[0]);
			if actors.size() <= 0:
				return BattleAction.new(self);
				
				
			return action.new(self, actors[RNG.randi() % actors.size()]);
		BattleAction.TargetType.TargetTeam:
			return action.new(self, target_team);
		_:
			return action.new(self);
	
func select_choice() -> int:
	randomize();
	var weight_sum = 0;
	var values = weights.values();
	for weight in values:
		weight_sum += weight;
	var random = RNG.randf_range(0, weight_sum);
	for i in weights.size():
		if random < values[i]:
			return i;
		random -= values[i];
	push_error("Could not find move");
	return 0;
	
