import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import 'role_reveal_screen.dart';

class RoleSettingsArgs {
  const RoleSettingsArgs({required this.playerCount});

  final int playerCount;
}

class RoleSettingsScreen extends StatefulWidget {
  const RoleSettingsScreen({super.key});

  static const String routeName = '/role-settings';

  @override
  State<RoleSettingsScreen> createState() => _RoleSettingsScreenState();
}

class _RoleSettingsScreenState extends State<RoleSettingsScreen> {
  bool _initialized = false;
  late int _playerCount;
  late int _werewolf;
  late int _seer;
  late int _guardian;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as RoleSettingsArgs?;
    _playerCount = args?.playerCount ?? 6;
    final defaultWerewolf =
        (_playerCount / 4).round().clamp(1, 3).toInt();
    _werewolf = defaultWerewolf;
    _seer = 1;
    _guardian = _playerCount >= 7 ? 1 : 0;
    _normalizeRoles();
    _initialized = true;
  }

  int get _specialTotal => _werewolf + _seer + _guardian;

  int get _villager =>
      (_playerCount - _specialTotal).clamp(0, _playerCount).toInt();

  bool get _isValid => _specialTotal <= _playerCount && _werewolf >= 1;

  void _normalizeRoles() {
    var overflow = _specialTotal - _playerCount;
    if (overflow <= 0) return;

    if (_guardian > 0) {
      final reduced = _guardian.clamp(0, overflow).toInt();
      _guardian -= reduced;
      overflow -= reduced;
    }
    if (overflow > 0 && _seer > 0) {
      final reduced = _seer.clamp(0, overflow).toInt();
      _seer -= reduced;
      overflow -= reduced;
    }
    if (overflow > 0 && _werewolf > 1) {
      final reduced = (_werewolf - 1).clamp(0, overflow).toInt();
      _werewolf -= reduced;
      overflow -= reduced;
    }
  }

  void _changeRole(String role, int delta) {
    setState(() {
      switch (role) {
        case 'werewolf':
          _werewolf = (_werewolf + delta).clamp(1, _playerCount).toInt();
          break;
        case 'seer':
          _seer = (_seer + delta).clamp(0, _playerCount).toInt();
          break;
        case 'guardian':
          _guardian = (_guardian + delta).clamp(0, _playerCount).toInt();
          break;
      }
      _normalizeRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _playerCount - _specialTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('役職設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プレイ人数: $_playerCount 人',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1B1A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '役職の人数を調整してください。\n残りは村人になります。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5A59),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _RoleRow(
              label: '人狼',
              description: '夜に襲撃を行う',
              count: _werewolf,
              onMinus: () => _changeRole('werewolf', -1),
              onPlus: () => _changeRole('werewolf', 1),
            ),
            const SizedBox(height: 12),
            _RoleRow(
              label: '占い師',
              description: '夜に正体を占う',
              count: _seer,
              onMinus: () => _changeRole('seer', -1),
              onPlus: () => _changeRole('seer', 1),
            ),
            const SizedBox(height: 12),
            _RoleRow(
              label: '騎士',
              description: '夜に守る',
              count: _guardian,
              onMinus: () => _changeRole('guardian', -1),
              onPlus: () => _changeRole('guardian', 1),
            ),
            const SizedBox(height: 12),
            _StaticRoleRow(
              label: '村人',
              description: '特別な能力なし',
              count: _villager,
            ),
            const SizedBox(height: 12),
            if (remaining < 0)
              const Text(
                '役職の合計が人数を超えています。',
                style: TextStyle(color: Color(0xFFE37064)),
              )
            else
              Text(
                '残り: $remaining 人',
                style: const TextStyle(color: Color(0xFF2F9C95)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid
                    ? () {
                        final roles = RoleSettings(
                          werewolf: _werewolf,
                          seer: _seer,
                          guardian: _guardian,
                          villager: _villager,
                        );
                        Navigator.of(context).pushNamed(
                          RoleRevealScreen.routeName,
                          arguments: GameSettings(
                            playerCount: _playerCount,
                            roles: roles,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2F9C95),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('ゲーム開始'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.label,
    required this.description,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String description;
  final int count;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E1B1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5A59),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _StaticRoleRow extends StatelessWidget {
  const _StaticRoleRow({
    required this.label,
    required this.description,
    required this.count,
  });

  final String label;
  final String description;
  final int count;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E1B1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5A59),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
