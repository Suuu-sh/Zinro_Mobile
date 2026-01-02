import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import 'results_screen.dart';

enum GamePhase { discussion, nightAction, voting, dayEnd, gameOver }

const String _roleFenrir = '神狼';
const String _roleObserverGod = '観測神';
const String _roleGuardianGod = '守護神';
const String _roleMediumGod = '霊媒神';
const String _roleNormalGod = '普通神';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const String routeName = '/game';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _initialized = false;
  late GameSettings _settings;
  late List<_PlayerState> _players;
  late List<String> _assignedRoles;
  GamePhase _phase = GamePhase.discussion;
  int _day = 1;
  bool _firstDayNoVote = true;

  List<int> _nightOrder = [];
  int _nightIndex = 0;
  late List<int?> _nightTargets;
  String _nightReport = '昨夜の結果: なし';
  bool _observerResultRevealed = false;

  List<int> _voteOrder = [];
  int _voteIndex = 0;
  late List<int?> _votes;
  String _lastExecution = '処刑なし';

  String _winner = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is GameSetup) {
      _settings = args.settings;
      _assignedRoles = args.assignedRoles;
    } else if (args is GameSettings) {
      _settings = args;
      _assignedRoles = _buildRoles(_settings);
    } else {
      _settings = const GameSettings(
        playerCount: 6,
        roles: RoleSettings(
          fenrir: 1,
          observerGod: 1,
          guardianGod: 1,
          mediumGod: 1,
          normalGod: 2,
        ),
      );
      _assignedRoles = _buildRoles(_settings);
    }
    _players = List.generate(
      _settings.playerCount,
      (index) => _PlayerState(
        name: 'プレイヤー${index + 1}',
        role: _assignedRoles[index],
      ),
    );
    _nightTargets = List<int?>.filled(_players.length, null);
    _votes = List<int?>.filled(_players.length, null);
    _initialized = true;
  }

  List<String> _buildRoles(GameSettings settings) {
    final roles = <String>[];
    roles.addAll(List.filled(settings.roles.fenrir, _roleFenrir));
    roles.addAll(List.filled(settings.roles.observerGod, _roleObserverGod));
    roles.addAll(List.filled(settings.roles.guardianGod, _roleGuardianGod));
    roles.addAll(List.filled(settings.roles.mediumGod, _roleMediumGod));
    roles.addAll(List.filled(settings.roles.normalGod, _roleNormalGod));
    roles.shuffle(Random());
    return roles;
  }

  String get _phaseLabel {
    switch (_phase) {
      case GamePhase.discussion:
        return '議論フェーズ';
      case GamePhase.nightAction:
        return '役職能力フェーズ';
      case GamePhase.voting:
        return '投票フェーズ';
      case GamePhase.dayEnd:
        return '${_day}日目終了';
      case GamePhase.gameOver:
        return 'ゲーム終了';
    }
  }

  String get _phaseHint {
    switch (_phase) {
      case GamePhase.discussion:
        return _firstDayNoVote
            ? 'Day1は議論のみで投票はありません。'
            : '議論後に投票を行います。';
      case GamePhase.nightAction:
        return 'スマホを回して各自が能力を使います。';
      case GamePhase.voting:
        return 'スマホを回して各自が投票します。';
      case GamePhase.dayEnd:
        return '次は役職能力フェーズです。';
      case GamePhase.gameOver:
        return _winner;
    }
  }

  String get _actionLabel {
    switch (_phase) {
      case GamePhase.discussion:
        return _firstDayNoVote ? '1日目終了へ' : '投票へ';
      case GamePhase.nightAction:
        return _isLastNightPlayer ? '議論へ' : '次の人へ';
      case GamePhase.voting:
        return _isLastVoter ? '${_day}日目終了へ' : '次の人へ';
      case GamePhase.dayEnd:
        return '夜へ';
      case GamePhase.gameOver:
        return 'リザルトへ';
    }
  }

  bool get _isLastNightPlayer => _nightIndex >= _nightOrder.length - 1;

  int get _currentNightPlayerIndex => _nightOrder[_nightIndex];

  _PlayerState get _currentNightPlayer => _players[_currentNightPlayerIndex];

  bool get _canAdvanceNight {
    if (_currentNightPlayer.role == _roleFenrir) {
      return _nightTargets[_currentNightPlayerIndex] != null;
    }
    if ((_currentNightPlayer.role == _roleObserverGod ||
            _currentNightPlayer.role == _roleGuardianGod ||
            _currentNightPlayer.role == _roleMediumGod) &&
        _currentNightPlayer.abilityActive) {
      if (_currentNightPlayer.role == _roleMediumGod) {
        return true;
      }
      if (_currentNightPlayer.role == _roleObserverGod) {
        return _nightTargets[_currentNightPlayerIndex] != null &&
            _observerResultRevealed;
      }
      return _nightTargets[_currentNightPlayerIndex] != null;
    }
    return true;
  }

  bool get _isLastVoter => _voteIndex >= _voteOrder.length - 1;

  int get _currentVoterIndex => _voteOrder[_voteIndex];

  bool get _canAdvanceVote => _votes[_currentVoterIndex] != null;

  void _advancePhase() {
    setState(() {
      switch (_phase) {
        case GamePhase.discussion:
          if (_firstDayNoVote) {
            _firstDayNoVote = false;
            _lastExecution = '処刑なし';
            _phase = GamePhase.dayEnd;
          } else {
            _startVoting();
            _phase = GamePhase.voting;
          }
          break;
        case GamePhase.nightAction:
          if (!_canAdvanceNight) return;
          if (_isLastNightPlayer) {
            _resolveNight();
            if (_checkWin()) {
              _phase = GamePhase.gameOver;
            } else {
              _phase = GamePhase.discussion;
            }
          } else {
            _nightIndex += 1;
            _observerResultRevealed = false;
          }
          break;
        case GamePhase.voting:
          if (!_canAdvanceVote) return;
          if (_isLastVoter) {
            _resolveVoting();
            if (_checkWin()) {
              _phase = GamePhase.gameOver;
            } else {
              _phase = GamePhase.dayEnd;
            }
          } else {
            _voteIndex += 1;
          }
          break;
        case GamePhase.dayEnd:
          _startNight();
          _phase = GamePhase.nightAction;
          break;
        case GamePhase.gameOver:
          Navigator.of(context).pushNamed(
            ResultsScreen.routeName,
            arguments: GameResult(
              settings: _settings,
              assignedRoles: _assignedRoles,
              winner: _winner,
            ),
          );
          break;
      }
    });
  }

  void _startNight() {
    _nightOrder = _aliveIndices;
    _nightIndex = 0;
    _observerResultRevealed = false;
    _nightTargets = List<int?>.filled(_players.length, null);
  }

  void _startVoting() {
    _voteOrder = _aliveIndices;
    _voteIndex = 0;
    _votes = List<int?>.filled(_players.length, null);
  }

  List<int> get _aliveIndices => _players
      .asMap()
      .entries
      .where((e) => e.value.alive)
      .map((e) => e.key)
      .toList();

  void _resolveNight() {
    final fenrirIndices = _nightOrder
        .where((index) => _players[index].role == _roleFenrir)
        .toList();
    int? finalAttacker;
    int? targetIndex;
    if (fenrirIndices.isNotEmpty) {
      for (final index in fenrirIndices) {
        if (_nightTargets[index] != null) {
          finalAttacker = index;
          targetIndex = _nightTargets[index];
        }
      }
    }

    int? guardedPlayer;
    final guardianIndices = _nightOrder
        .where((index) => _players[index].role == _roleGuardianGod)
        .toList();
    if (guardianIndices.isNotEmpty) {
      final lastGuardian = guardianIndices.last;
      guardedPlayer = _nightTargets[lastGuardian];
    }

    var death = false;
    if (targetIndex != null && targetIndex != guardedPlayer) {
      final target = _players[targetIndex];
      if (target.alive) {
        if (target.role == _roleObserverGod ||
            target.role == _roleGuardianGod ||
            target.role == _roleMediumGod) {
          if (target.abilityActive) {
            target.abilityActive = false;
            death = false;
            if (finalAttacker != null) {
              final attacker = _players[finalAttacker];
              attacker.fenrirHasStolenAbility = true;
              attacker.fenrirAbilityReadyDay = _day + 1;
            }
          } else {
            target.alive = false;
            death = true;
          }
        } else {
          target.alive = false;
          death = true;
        }
      }
    }

    _nightReport = death ? '昨夜の結果: 死者あり' : '昨夜の結果: 死者なし';
    _day += 1;
  }

  void _resolveVoting() {
    final tally = <int, int>{};
    for (final voterIndex in _voteOrder) {
      final target = _votes[voterIndex];
      if (target == null) continue;
      tally[target] = (tally[target] ?? 0) + 1;
    }
    if (tally.isEmpty) {
      _lastExecution = '処刑なし';
      return;
    }
    final entries = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    final sameTop = entries.where((e) => e.value == top.value).length;
    if (sameTop > 1) {
      _lastExecution = '処刑なし（同票）';
      return;
    }
    final executed = _players[top.key];
    executed.alive = false;
    _lastExecution = '${executed.name} を処刑';
  }

  bool _checkWin() {
    final aliveFenrir =
        _players.where((p) => p.alive && p.role == _roleFenrir).length;
    final aliveGods =
        _players.where((p) => p.alive && p.role != _roleFenrir).length;
    if (aliveFenrir == 0) {
      _winner = '正統神陣営の勝利';
      return true;
    }
    if (aliveFenrir >= aliveGods) {
      _winner = '神狼陣営の勝利';
      return true;
    }
    return false;
  }

  bool get _hasDeadPlayers => _players.any((player) => !player.alive);

  bool _isFinalFenrir(int index) {
    final fenrirIndices = _aliveIndices
        .where((playerIndex) => _players[playerIndex].role == _roleFenrir)
        .toList();
    if (fenrirIndices.isEmpty) return false;
    return fenrirIndices.last == index;
  }

  List<_WolfSuggestion> _fenrirSuggestions(int index) {
    final suggestions = <_WolfSuggestion>[];
    for (final playerIndex in _nightOrder) {
      if (playerIndex >= index) break;
      if (_players[playerIndex].role != _roleFenrir) continue;
      final target = _nightTargets[playerIndex];
      if (target == null) continue;
      suggestions.add(
        _WolfSuggestion(
          proposer: '神狼${_fenrirOrder(playerIndex)}',
          targetName: _players[target].name,
        ),
      );
    }
    return suggestions;
  }

  int _fenrirOrder(int index) {
    var order = 0;
    for (final playerIndex in _nightOrder) {
      if (_players[playerIndex].role == _roleFenrir) {
        order += 1;
      }
      if (playerIndex == index) {
        break;
      }
    }
    return order;
  }

  String _effectiveRoleLabel(_PlayerState target) {
    if ((target.role == _roleObserverGod ||
            target.role == _roleGuardianGod ||
            target.role == _roleMediumGod) &&
        !target.abilityActive) {
      return _roleNormalGod;
    }
    return target.role;
  }

  @override
  Widget build(BuildContext context) {
    final int displayDay =
        _phase == GamePhase.nightAction ? _day + 1 : _day;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0e27),
              Color(0xFF16213e),
              Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhaseCard(
                  phaseLabel: _phaseLabel,
                  hint: _phaseHint,
                  day: displayDay,
                ),
                const SizedBox(height: 16),
                _SettingsSummary(settings: _settings),
                const SizedBox(height: 16),
                if (_phase == GamePhase.discussion) ...[
                  _InfoCard(text: _nightReport),
                  const SizedBox(height: 12),
                  Text(
                    '生存プレイヤー',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _PlayerTile(player: _players[index]);
                      },
                    ),
                  ),
                ] else if (_phase == GamePhase.nightAction) ...[
                  _NightActionPanel(
                    day: _day + 1,
                    playerIndex: _currentNightPlayerIndex,
                    player: _currentNightPlayer,
                    players: _players,
                    selectedTarget: _nightTargets[_currentNightPlayerIndex],
                    onTargetChanged: (value) {
                      setState(() {
                        _nightTargets[_currentNightPlayerIndex] = value;
                        _observerResultRevealed = false;
                      });
                    },
                    isFinalFenrir: _isFinalFenrir(_currentNightPlayerIndex),
                    suggestions: _fenrirSuggestions(_currentNightPlayerIndex),
                    effectiveRoleLabel: _effectiveRoleLabel,
                    hasDeadPlayers: _hasDeadPlayers,
                    observerResultRevealed: _observerResultRevealed,
                    onObserverReveal: () {
                      setState(() {
                        _observerResultRevealed = true;
                      });
                    },
                  ),
                ] else if (_phase == GamePhase.voting) ...[
                  _VotePanel(
                    day: _day,
                    voterIndex: _currentVoterIndex,
                    players: _players,
                    selectedTarget: _votes[_currentVoterIndex],
                    onTargetChanged: (value) {
                      setState(() {
                        _votes[_currentVoterIndex] = value;
                      });
                    },
                  ),
                ] else if (_phase == GamePhase.dayEnd) ...[
                  _InfoCard(text: _lastExecution),
                  const SizedBox(height: 12),
                  _InfoCard(text: _nightReport),
                  const Spacer(),
                ] else if (_phase == GamePhase.gameOver) ...[
                  _InfoCard(text: _winner),
                  const Spacer(),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _phase == GamePhase.nightAction && !_canAdvanceNight
                        ? null
                        : _phase == GamePhase.voting && !_canAdvanceVote
                            ? null
                            : _advancePhase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe94560),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFe94560).withOpacity(0.5),
                      disabledBackgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _actionLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerState {
  _PlayerState({
    required this.name,
    required this.role,
  })  : alive = true,
        abilityActive = role == _roleObserverGod ||
            role == _roleGuardianGod ||
            role == _roleMediumGod,
        fenrirHasStolenAbility = false,
        fenrirAbilityReadyDay = null;

  final String name;
  final String role;
  bool alive;
  bool abilityActive;
  bool fenrirHasStolenAbility;
  int? fenrirAbilityReadyDay;
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phaseLabel,
    required this.hint,
    required this.day,
  });

  final String phaseLabel;
  final String hint;
  final int day;

  IconData get _phaseIcon {
    if (phaseLabel.contains('議論')) return Icons.forum;
    if (phaseLabel.contains('役職')) return Icons.nightlight;
    if (phaseLabel.contains('投票')) return Icons.how_to_vote;
    if (phaseLabel.contains('終了')) return Icons.bedtime;
    return Icons.info;
  }

  Color get _phaseColor {
    if (phaseLabel.contains('議論')) return const Color(0xFF2196F3);
    if (phaseLabel.contains('役職')) return const Color(0xFF673AB7);
    if (phaseLabel.contains('投票')) return const Color(0xFFe94560);
    if (phaseLabel.contains('終了')) return const Color(0xFF4CAF50);
    return const Color(0xFF2F9C95);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _phaseColor.withOpacity(0.3),
            _phaseColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _phaseColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _phaseColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _phaseColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _phaseIcon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$phaseLabel（$day日目）',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSummary extends StatelessWidget {
  const _SettingsSummary({required this.settings});

  final GameSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Color(0xFFe94560), size: 20),
              const SizedBox(width: 8),
              Text(
                '役職構成',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoleChip(emoji: '🐺', count: settings.roles.fenrir),
              _RoleChip(emoji: '👁️', count: settings.roles.observerGod),
              _RoleChip(emoji: '🛡️', count: settings.roles.guardianGod),
              _RoleChip(emoji: '🔮', count: settings.roles.mediumGod),
              _RoleChip(emoji: '⭐', count: settings.roles.normalGod),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '×$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isGoodNews = text.contains('なし') || text.contains('処刑なし');
    final isBadNews = text.contains('死者あり') || text.contains('を処刑');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBadNews
              ? [
                  const Color(0xFFe94560).withOpacity(0.3),
                  const Color(0xFFe94560).withOpacity(0.1),
                ]
              : isGoodNews
                  ? [
                      const Color(0xFF4CAF50).withOpacity(0.3),
                      const Color(0xFF4CAF50).withOpacity(0.1),
                    ]
                  : [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBadNews
              ? const Color(0xFFe94560)
              : isGoodNews
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBadNews
                ? Icons.warning
                : isGoodNews
                    ? Icons.check_circle
                    : Icons.info,
            color: isBadNews
                ? const Color(0xFFe94560)
                : isGoodNews
                    ? const Color(0xFF4CAF50)
                    : Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final _PlayerState player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: player.alive
              ? [
                  const Color(0xFF4CAF50).withOpacity(0.2),
                  const Color(0xFF4CAF50).withOpacity(0.05),
                ]
              : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: player.alive
              ? const Color(0xFF4CAF50).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: player.alive
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.name.substring(0, 1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: player.alive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFe94560),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              player.alive ? '生存' : '脱落',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NightActionPanel extends StatelessWidget {
  const _NightActionPanel({
    required this.day,
    required this.playerIndex,
    required this.player,
    required this.players,
    required this.selectedTarget,
    required this.onTargetChanged,
    required this.isFinalFenrir,
    required this.suggestions,
    required this.effectiveRoleLabel,
    required this.hasDeadPlayers,
    required this.observerResultRevealed,
    required this.onObserverReveal,
  });

  final int day;
  final int playerIndex;
  final _PlayerState player;
  final List<_PlayerState> players;
  final int? selectedTarget;
  final ValueChanged<int?> onTargetChanged;
  final bool isFinalFenrir;
  final List<_WolfSuggestion> suggestions;
  final String Function(_PlayerState) effectiveRoleLabel;
  final bool hasDeadPlayers;
  final bool observerResultRevealed;
  final VoidCallback onObserverReveal;

  bool get _hasAction {
    if (player.role == _roleFenrir) return true;
    if ((player.role == _roleObserverGod ||
            player.role == _roleGuardianGod ||
            player.role == _roleMediumGod) &&
        player.abilityActive) {
      return true;
    }
    return false;
  }

  String get _targetTitle {
    if (player.role == _roleFenrir) {
      return isFinalFenrir ? '襲撃する相手（最終決定）' : '襲撃する相手（提案）';
    }
    if (player.role == _roleObserverGod) return '観測する相手';
    if (player.role == _roleGuardianGod) return '守護する相手';
    if (player.role == _roleMediumGod) return '霊媒結果';
    return '対象';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Night$day  プレイヤー${playerIndex + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0E1B1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.role,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2F9C95),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (player.role == _roleObserverGod ||
                              player.role == _roleGuardianGod ||
                              player.role == _roleMediumGod) &&
                          !player.abilityActive
                      ? '能力喪失済み'
                      : 'スマホを回して確認します。',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5A59),
                  ),
                ),
                if (player.role == _roleFenrir && player.fenrirHasStolenAbility)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      player.fenrirAbilityReadyDay != null &&
                              player.fenrirAbilityReadyDay! <= day
                          ? '奪取した能力: 使用可能（効果は後日追加）'
                          : '奪取した能力: 次の夜から使用可能',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A5A59),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_hasAction)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _targetTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E1B1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (player.role == _roleMediumGod)
                    if (!hasDeadPlayers)
                      const Text(
                        '死者がいないため霊媒結果はありません。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A5A59),
                        ),
                      )
                    else
                      ...players.where((target) => !target.alive).map(
                            (target) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${target.name}: ${effectiveRoleLabel(target)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0E1B1A),
                                ),
                              ),
                            ),
                          )
                  else
                    ...List.generate(players.length, (index) {
                      final target = players[index];
                      if (index == playerIndex) return const SizedBox.shrink();
                      if (player.role == _roleFenrir &&
                          target.role == _roleFenrir) {
                        return const SizedBox.shrink();
                      }
                      if (player.role == _roleObserverGod && !target.alive) {
                        return const SizedBox.shrink();
                      }
                      if (player.role == _roleGuardianGod && !target.alive) {
                        return const SizedBox.shrink();
                      }
                      return RadioListTile<int>(
                        value: index,
                        groupValue: selectedTarget,
                        onChanged: player.role == _roleObserverGod &&
                                observerResultRevealed
                            ? null
                            : onTargetChanged,
                        title: Text(target.name),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  if (player.role == _roleObserverGod &&
                      selectedTarget != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: observerResultRevealed ? null : onObserverReveal,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: const Color(0xFF2F9C95),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('観測する'),
                      ),
                    ),
                    if (observerResultRevealed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '結果: ${players[selectedTarget!].name} は ${effectiveRoleLabel(players[selectedTarget!])}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E1B1A),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            )
          else
            const Text(
              '能力なし',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5A59),
              ),
            ),
          if (player.role == _roleFenrir && suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _WolfSuggestionList(
              suggestions: suggestions,
              isFinalDecider: isFinalFenrir,
            ),
          ],
        ],
      ),
    );
  }
}

class _VotePanel extends StatelessWidget {
  const _VotePanel({
    required this.day,
    required this.voterIndex,
    required this.players,
    required this.selectedTarget,
    required this.onTargetChanged,
  });

  final int day;
  final int voterIndex;
  final List<_PlayerState> players;
  final int? selectedTarget;
  final ValueChanged<int?> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day日目  投票者: プレイヤー${voterIndex + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0E1B1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '投票先を選んでください',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E1B1A),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(players.length, (index) {
                  final player = players[index];
                  if (!player.alive || index == voterIndex) {
                    return const SizedBox.shrink();
                  }
                  return RadioListTile<int>(
                    value: index,
                    groupValue: selectedTarget,
                    onChanged: onTargetChanged,
                    title: Text(player.name),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WolfSuggestion {
  const _WolfSuggestion({
    required this.proposer,
    required this.targetName,
  });

  final String proposer;
  final String targetName;
}

class _WolfSuggestionList extends StatelessWidget {
  const _WolfSuggestionList({
    required this.suggestions,
    required this.isFinalDecider,
  });

  final List<_WolfSuggestion> suggestions;
  final bool isFinalDecider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFinalDecider ? '神狼の提案（参考）' : '先に選んだ神狼の提案',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0E1B1A),
            ),
          ),
          const SizedBox(height: 6),
          ...suggestions.map(
            (item) => Text(
              '${item.proposer}: ${item.targetName}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5A59),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
