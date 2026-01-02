class RoleSettings {
  const RoleSettings({
    required this.fenrir,
    required this.observerGod,
    required this.guardianGod,
    required this.mediumGod,
    required this.atonementGod,
    required this.normalGod,
  });

  final int fenrir;
  final int observerGod;
  final int guardianGod;
  final int mediumGod;
  final int atonementGod;
  final int normalGod;

  int get total =>
      fenrir + observerGod + guardianGod + mediumGod + atonementGod + normalGod;

  RoleSettings copyWith({
    int? fenrir,
    int? observerGod,
    int? guardianGod,
    int? mediumGod,
    int? atonementGod,
    int? normalGod,
  }) {
    return RoleSettings(
      fenrir: fenrir ?? this.fenrir,
      observerGod: observerGod ?? this.observerGod,
      guardianGod: guardianGod ?? this.guardianGod,
      mediumGod: mediumGod ?? this.mediumGod,
      atonementGod: atonementGod ?? this.atonementGod,
      normalGod: normalGod ?? this.normalGod,
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
  });

  final GameSettings settings;
  final List<String> assignedRoles;
}

class GameResult {
  const GameResult({
    required this.settings,
    required this.assignedRoles,
    required this.winner,
  });

  final GameSettings settings;
  final List<String> assignedRoles;
  final String winner;
}
