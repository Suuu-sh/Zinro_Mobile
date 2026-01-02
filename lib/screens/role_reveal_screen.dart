import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import 'game_screen.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  static const String routeName = '/role-reveal';

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  bool _initialized = false;
  late GameSettings _settings;
  late List<String> _assignedRoles;
  late List<int?> _targets;
  int _currentIndex = 0;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args = ModalRoute.of(context)?.settings.arguments as GameSettings?;
    _settings = args ??
        const GameSettings(
          playerCount: 6,
          roles: RoleSettings(werewolf: 1, seer: 1, guardian: 0, villager: 4),
        );
    _assignedRoles = _buildRoles(_settings);
    _targets = List<int?>.filled(_settings.playerCount, null);
    _initialized = true;
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

  void _showRole() {
    setState(() {
      _revealed = true;
    });
  }

  void _nextPlayer() {
    setState(() {
      _revealed = false;
      _targets[_currentIndex] = _selectedTarget;
      _currentIndex += 1;
    });
  }

  void _startGame() {
    _targets[_currentIndex] = _selectedTarget;
    final initialActions = <AbilityAction>[];
    for (var i = 0; i < _assignedRoles.length; i += 1) {
      final role = _assignedRoles[i];
      final target = _targets[i];
      if (_isAbilityRole(role) && target != null) {
        initialActions.add(
          AbilityAction(
            day: 1,
            actorIndex: i,
            role: role,
            targetIndex: target,
          ),
        );
      }
    }
    Navigator.of(context).pushNamed(
      GameScreen.routeName,
      arguments: GameSetup(
        settings: _settings,
        assignedRoles: _assignedRoles,
        initialActions: initialActions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentIndex >= _assignedRoles.length - 1;
    final String role = _assignedRoles[_currentIndex];
    final bool canUseAbility = _isAbilityRole(role);
    final bool canProceed = _revealed && (!canUseAbility || _selectedTarget != null);
    final bool isWerewolf = role == '人狼';
    final bool isSeer = role == '占い師';
    final bool isLastWerewolf = isWerewolf && _isLastWerewolf(_currentIndex);
    final List<_WolfSuggestion> wolfSuggestions =
        _getWolfSuggestions(_currentIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('役職確認'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プレイヤー ${_currentIndex + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1B1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '他の人に見られないように、\n画面を隠して確認してください。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5A59),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: _revealed
                        ? const Color(0xFF2F9C95)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF2F9C95).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _revealed ? Icons.visibility : Icons.visibility_off,
                        size: 36,
                        color: _revealed
                            ? Colors.white
                            : const Color(0xFF2F9C95),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _revealed ? role : 'ボタンで確認',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _revealed
                              ? Colors.white
                              : const Color(0xFF0E1B1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_revealed) ...[
              if (canUseAbility)
                _TargetSelector(
                  currentIndex: _currentIndex,
                  playerCount: _settings.playerCount,
                  selectedTarget: _selectedTarget,
                  onChanged: (value) {
                    setState(() {
                      _targets[_currentIndex] = value;
                    });
                  },
                  title: _targetTitle(role),
                )
              else
                const Text(
                  '能力はありません。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5A59),
                  ),
                ),
              if (isWerewolf && wolfSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _WolfSuggestionList(
                  suggestions: wolfSuggestions,
                  isFinalDecider: isLastWerewolf,
                ),
              ],
              if (isSeer && _selectedTarget != null) ...[
                const SizedBox(height: 12),
                _SeerResultCard(
                  targetName: 'プレイヤー${_selectedTarget! + 1}',
                  isWolf: _assignedRoles[_selectedTarget!] == '人狼',
                ),
              ],
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _revealed ? null : _showRole,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2F9C95),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('役職を見る'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canProceed
                    ? (isLast ? _startGame : _nextPlayer)
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF2F9C95),
                  side: const BorderSide(color: Color(0xFF2F9C95)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(isLast ? 'ゲーム開始' : '次の人へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAbilityRole(String role) =>
      role == '人狼' || role == '占い師' || role == '騎士';

  String _targetTitle(String role) {
    switch (role) {
      case '人狼':
        return _isLastWerewolf(_currentIndex) ? '襲撃する相手（最終決定）' : '襲撃する相手（提案）';
      case '占い師':
        return '占う相手';
      case '騎士':
        return '守る相手';
    }
    return '対象';
  }

  int? get _selectedTarget => _targets[_currentIndex];

  bool _isLastWerewolf(int index) {
    final wolfIndices = _assignedRoles
        .asMap()
        .entries
        .where((entry) => entry.value == '人狼')
        .map((entry) => entry.key)
        .toList();
    if (wolfIndices.isEmpty) return false;
    return wolfIndices.last == index;
  }

  List<_WolfSuggestion> _getWolfSuggestions(int index) {
    final suggestions = <_WolfSuggestion>[];
    for (var i = 0; i < _assignedRoles.length; i += 1) {
      if (_assignedRoles[i] != '人狼') continue;
      if (i >= index) continue;
      final target = _targets[i];
      if (target == null) continue;
      suggestions.add(
        _WolfSuggestion(
          proposer: '人狼${_wolfOrder(i)}',
          targetName: 'プレイヤー${target + 1}',
        ),
      );
    }
    return suggestions;
  }

  int _wolfOrder(int index) {
    var order = 0;
    for (var i = 0; i <= index; i += 1) {
      if (_assignedRoles[i] == '人狼') {
        order += 1;
      }
    }
    return order;
  }
}

class _TargetSelector extends StatelessWidget {
  const _TargetSelector({
    required this.currentIndex,
    required this.playerCount,
    required this.selectedTarget,
    required this.onChanged,
    required this.title,
  });

  final int currentIndex;
  final int playerCount;
  final int? selectedTarget;
  final ValueChanged<int?> onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0E1B1A),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(playerCount, (index) {
            if (index == currentIndex) {
              return const SizedBox.shrink();
            }
            return RadioListTile<int>(
              value: index,
              groupValue: selectedTarget,
              onChanged: onChanged,
              title: Text('プレイヤー${index + 1}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
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
            isFinalDecider ? '人狼の提案（参考）' : '先に選んだ人狼の提案',
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

class _SeerResultCard extends StatelessWidget {
  const _SeerResultCard({
    required this.targetName,
    required this.isWolf,
  });

  final String targetName;
  final bool isWolf;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$targetName の結果: ${isWolf ? '人狼' : '人狼ではない'}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0E1B1A),
        ),
      ),
    );
  }
}
