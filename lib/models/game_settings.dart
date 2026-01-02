class RoleSettings {
  const RoleSettings({
    required this.werewolf,
    required this.seer,
    required this.guardian,
    required this.villager,
  });

  final int werewolf;
  final int seer;
  final int guardian;
  final int villager;

  int get total => werewolf + seer + guardian + villager;

  RoleSettings copyWith({
    int? werewolf,
    int? seer,
    int? guardian,
    int? villager,
  }) {
    return RoleSettings(
      werewolf: werewolf ?? this.werewolf,
      seer: seer ?? this.seer,
      guardian: guardian ?? this.guardian,
      villager: villager ?? this.villager,
    );
  }
}

class GameSettings {
  const GameSettings({
    required this.playerCount,
    required this.roles,
  });

  final int playerCount;
  final RoleSettings roles;
}

class GameSetup {
  const GameSetup({
    required this.settings,
    required this.assignedRoles,
    required this.initialActions,
  });

  final GameSettings settings;
  final List<String> assignedRoles;
  final List<AbilityAction> initialActions;
}

class AbilityAction {
  const AbilityAction({
    required this.day,
    required this.actorIndex,
    required this.role,
    required this.targetIndex,
  });

  final int day;
  final int actorIndex;
  final String role;
  final int targetIndex;
}
