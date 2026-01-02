import 'player.dart';

class GameState {
  final String phase;
  final int day;
  final List<Player> players;
  final List<String> deadPlayers;

  GameState({
    required this.phase,
    required this.day,
    required this.players,
    required this.deadPlayers,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      phase: json['phase'] as String,
      day: json['day'] as int,
      players: (json['players'] as List)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      deadPlayers: (json['deadPlayers'] as List).cast<String>(),
    );
  }

  bool get isWaiting => phase == 'waiting';
  bool get isNight => phase == 'night';
  bool get isDay => phase == 'day';
  bool get isVoting => phase == 'voting';
  bool get isEnded => phase == 'ended';
}
