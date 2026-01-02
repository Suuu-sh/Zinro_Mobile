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
          roles: RoleSettings(
            fenrir: 1,
            observerGod: 1,
            guardianGod: 1,
            mediumGod: 1,
            normalGod: 2,
          ),
        );
    _assignedRoles = _buildRoles(_settings);
    _initialized = true;
  }

  List<String> _buildRoles(GameSettings settings) {
    final roles = <String>[];
    roles.addAll(List.filled(settings.roles.fenrir, 'フェンリル'));
    roles.addAll(List.filled(settings.roles.observerGod, '観測神'));
    roles.addAll(List.filled(settings.roles.guardianGod, '守護神'));
    roles.addAll(List.filled(settings.roles.mediumGod, '霊媒神'));
    roles.addAll(List.filled(settings.roles.normalGod, '普通神'));
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
      _currentIndex += 1;
    });
  }

  void _startGame() {
    Navigator.of(context).pushNamed(
      GameScreen.routeName,
      arguments: GameSetup(
        settings: _settings,
        assignedRoles: _assignedRoles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentIndex >= _assignedRoles.length - 1;
    final String role = _assignedRoles[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('役職確認（Night1）'),
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
              'この夜は役職確認のみです。\n他の人に見られないように確認してください。',
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
                onPressed: _revealed
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
                child: Text(isLast ? 'Day1へ' : '次の人へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
