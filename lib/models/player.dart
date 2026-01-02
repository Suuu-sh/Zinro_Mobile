class Player {
  final String id;
  final String name;
  final bool alive;

  Player({
    required this.id,
    required this.name,
    required this.alive,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      alive: json['alive'] as bool,
    );
  }
}

class PlayerInfo {
  final String id;
  final String name;
  final Role role;
  final bool alive;
  final List<Player>? werewolfTeam;

  PlayerInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.alive,
    this.werewolfTeam,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      role: Role.fromJson(json['role'] as Map<String, dynamic>),
      alive: json['alive'] as bool,
      werewolfTeam: json['werewolfTeam'] != null
          ? (json['werewolfTeam'] as List)
              .map((e) => Player.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class Role {
  final String id;
  final String name;
  final String team;
  final String description;
  final bool nightAction;

  Role({
    required this.id,
    required this.name,
    required this.team,
    required this.description,
    required this.nightAction,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      name: json['name'] as String,
      team: json['team'] as String,
      description: json['description'] as String,
      nightAction: json['nightAction'] as bool,
    );
  }

  bool get isWerewolf => team == 'werewolf';
  bool get isVillage => team == 'village';
}
