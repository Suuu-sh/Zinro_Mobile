import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_settings.dart';

enum GamePhase { ability, discussion, voting, dayEnd }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const String routeName = '/game';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _initialized = false;
  late GameSettings _settings;
  late List<_Player> _players;
  late List<String> _assignedRoles;
  final List<AbilityAction> _actionLog = [];
  GamePhase _phase = GamePhase.discussion;
  int _day = 1;
  bool _firstDayNoVote = true;
  int _abilityIndex = 0;
  bool _abilityRevealed = false;
  late List<int?> _abilityTargets;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is GameSetup) {
      _settings = args.settings;
      _assignedRoles = args.assignedRoles;
      _actionLog.addAll(args.initialActions);
    } else if (args is GameSettings) {
      _settings = args;
      _assignedRoles = _buildRoles(_settings);
    } else {
      _settings = const GameSettings(
        playerCount: 6,
        roles: RoleSettings(werewolf: 1, seer: 1, guardian: 0, villager: 4),
      );
      _assignedRoles = _buildRoles(_settings);
    }
    _players = List.generate(
      _settings.playerCount,
      (index) => _Player(name: 'プレイヤー${index + 1}'),
    );
    _abilityTargets = List<int?>.filled(_settings.playerCount, null);
    _initialized = true;
  }

  String get _phaseLabel {
    switch (_phase) {
      case GamePhase.ability:
        return '役職能力フェーズ';
      case GamePhase.discussion:
        return '議論フェーズ';
      case GamePhase.voting:
        return '投票フェーズ';
      case GamePhase.dayEnd:
        return '${_day}日目終了';
    }
  }

  String get _phaseHint {
    switch (_phase) {
      case GamePhase.ability:
        return 'スマホを回して各自が能力を使います。';
      case GamePhase.discussion:
        return _firstDayNoVote
            ? '全員で議論します（初回は投票なし）。'
            : '全員で議論します。';
      case GamePhase.voting:
        return 'スマホを回して各自が投票します。';
      case GamePhase.dayEnd:
        return '$_day日目が終了しました。次は能力使用です。';
    }
  }

  String get _actionLabel {
    switch (_phase) {
      case GamePhase.ability:
        return _isLastAbilityPlayer ? '議論へ' : '次の人へ';
      case GamePhase.discussion:
        return _firstDayNoVote ? '1日目終了へ' : '投票へ';
      case GamePhase.voting:
        return '${_day}日目終了へ';
      case GamePhase.dayEnd:
        return '次の能力へ';
    }
  }

  void _advancePhase() {
    setState(() {
      switch (_phase) {
        case GamePhase.ability:
          if (!_canAdvanceAbility) return;
          if (_isLastAbilityPlayer) {
            _commitAbilityActions();
            _phase = GamePhase.discussion;
          } else {
            _abilityIndex += 1;
            _abilityRevealed = false;
          }
          break;
        case GamePhase.discussion:
          if (_firstDayNoVote) {
            _phase = GamePhase.dayEnd;
            _firstDayNoVote = false;
          } else {
            _phase = GamePhase.voting;
          }
          break;
        case GamePhase.voting:
          _phase = GamePhase.dayEnd;
          break;
        case GamePhase.dayEnd:
          _day += 1;
          _resetAbilityPhase();
          _phase = GamePhase.ability;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム進行'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhaseCard(
              phaseLabel: _phaseLabel,
              hint: _phaseHint,
              day: _day,
            ),
            const SizedBox(height: 16),
            _SettingsSummary(settings: _settings),
            const SizedBox(height: 16),
            if (_phase == GamePhase.ability) ...[
              _AbilityPanel(
                day: _day,
                playerIndex: _abilityIndex,
                role: _currentRole,
                revealed: _abilityRevealed,
                onReveal: _revealAbilityRole,
                targetCount: _settings.playerCount,
                selectedTarget: _abilityTargets[_abilityIndex],
                onTargetChanged: (value) {
                  setState(() {
                    _abilityTargets[_abilityIndex] = value;
                  });
                },
              ),
            ] else ...[
              const Text(
                'プレイヤー一覧',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E1B1A),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return _PlayerTile(player: player);
                  },
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _phase == GamePhase.ability && !_canAdvanceAbility
                    ? null
                    : _advancePhase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2F9C95),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _buildRoles(GameSettings settings) {
    final roles = <String>[];
    roles.addAll(List.filled(settings.roles.werewolf, '人狼'));
    roles.addAll(List.filled(settings.roles.seer, '占い師'));
    roles.addAll(List.filled(settings.roles.guardian, '騎士'));
    roles.addAll(List.filled(settings.roles.villager, '村人'));
    roles.shuffle(Random());
    return roles;
  }

  bool get _isLastAbilityPlayer =>
      _abilityIndex >= _settings.playerCount - 1;

  String get _currentRole => _assignedRoles[_abilityIndex];

  bool get _canAdvanceAbility {
    if (!_abilityRevealed) return false;
    if (_currentRole == '人狼' ||
        _currentRole == '占い師' ||
        _currentRole == '騎士') {
      return _abilityTargets[_abilityIndex] != null;
    }
    return true;
  }

  void _revealAbilityRole() {
    setState(() {
      _abilityRevealed = true;
    });
  }

  void _resetAbilityPhase() {
    _abilityIndex = 0;
    _abilityRevealed = false;
    _abilityTargets = List<int?>.filled(_settings.playerCount, null);
  }

  void _commitAbilityActions() {
    for (var i = 0; i < _assignedRoles.length; i += 1) {
      final role = _assignedRoles[i];
      final target = _abilityTargets[i];
      if ((role == '人狼' || role == '占い師' || role == '騎士') &&
          target != null) {
        _actionLog.add(
          AbilityAction(
            day: _day,
            actorIndex: i,
            role: role,
            targetIndex: target,
          ),
        );
      }
    }
  }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2F9C95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dark_mode_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$phaseLabel（$day日目）',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E1B1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5A59),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '役職構成',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0E1B1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '人狼 ${settings.roles.werewolf} / 占い師 ${settings.roles.seer} / '
            '騎士 ${settings.roles.guardian} / 村人 ${settings.roles.villager}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A5A59)),
          ),
        ],
      ),
    );
  }
}

class _Player {
  _Player({required this.name, this.alive = true});

  final String name;
  final bool alive;
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final _Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2F9C95).withOpacity(0.2),
            child: Text(
              player.name.substring(0, 1),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1B1A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0E1B1A),
              ),
            ),
          ),
          Text(
            player.alive ? '生存' : '脱落',
            style: TextStyle(
              fontSize: 12,
              color: player.alive
                  ? const Color(0xFF2F9C95)
                  : const Color(0xFFE37064),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbilityPanel extends StatelessWidget {
  const _AbilityPanel({
    required this.day,
    required this.playerIndex,
    required this.role,
    required this.revealed,
    required this.onReveal,
    required this.targetCount,
    required this.selectedTarget,
    required this.onTargetChanged,
  });

  final int day;
  final int playerIndex;
  final String role;
  final bool revealed;
  final VoidCallback onReveal;
  final int targetCount;
  final int? selectedTarget;
  final ValueChanged<int?> onTargetChanged;

  bool get _hasAbility => role == '人狼' || role == '占い師' || role == '騎士';

  String get _targetTitle {
    switch (role) {
      case '人狼':
        return '襲撃する相手';
      case '占い師':
        return '占う相手';
      case '騎士':
        return '守る相手';
    }
    return '対象';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day日目  プレイヤー${playerIndex + 1}',
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
                  revealed ? role : '役職を確認してください',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: revealed
                        ? const Color(0xFF2F9C95)
                        : const Color(0xFF0E1B1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'スマホを回して確認し、能力があれば行動を選びます。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5A59),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: revealed ? null : onReveal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF2F9C95),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('役職を見る'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (revealed && _hasAbility)
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
                  ...List.generate(targetCount, (index) {
                    if (index == playerIndex) {
                      return const SizedBox.shrink();
                    }
                    return RadioListTile<int>(
                      value: index,
                      groupValue: selectedTarget,
                      onChanged: onTargetChanged,
                      title: Text('プレイヤー${index + 1}'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            )
          else if (revealed)
            const Text(
              '能力はありません。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5A59),
              ),
            ),
        ],
      ),
    );
  }
}
