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
  late int _fenrir;
  late int _observerGod;
  late int _guardianGod;
  late int _mediumGod;
  late int _normalGod;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as RoleSettingsArgs?;
    _playerCount = args?.playerCount ?? 6;
    _fenrir = (_playerCount / 4).round().clamp(1, 3).toInt();
    _observerGod = 1;
    _guardianGod = 1;
    _mediumGod = 1;
    final assignedTotal =
        _fenrir + _observerGod + _guardianGod + _mediumGod;
    _normalGod = (_playerCount - assignedTotal).clamp(0, _playerCount).toInt();
    _initialized = true;
  }

  int get _total =>
      _fenrir + _observerGod + _guardianGod + _mediumGod + _normalGod;

  bool get _isValid => _total == _playerCount && _fenrir >= 1;

  void _changeRole(String role, int delta) {
    setState(() {
      switch (role) {
        case 'fenrir':
          _fenrir = (_fenrir + delta).clamp(1, _playerCount).toInt();
          break;
        case 'observer':
          _observerGod =
              (_observerGod + delta).clamp(0, _playerCount).toInt();
          break;
        case 'guardian':
          _guardianGod =
              (_guardianGod + delta).clamp(0, _playerCount).toInt();
          break;
        case 'medium':
          _mediumGod = (_mediumGod + delta).clamp(0, _playerCount).toInt();
          break;
        case 'normal':
          _normalGod = (_normalGod + delta).clamp(0, _playerCount).toInt();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              '役職の人数を調整してください。\n合計が人数と一致するようにしてください。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5A59),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _RoleRow(
              label: '神狼（フェンリル）',
              description: '夜に襲撃を行う',
              count: _fenrir,
              onMinus: () => _changeRole('fenrir', -1),
              onPlus: () => _changeRole('fenrir', 1),
            ),
            const SizedBox(height: 12),
            _RoleRow(
              label: '観測神',
              description: '夜に生存している神の役職を確認',
              count: _observerGod,
              onMinus: () => _changeRole('observer', -1),
              onPlus: () => _changeRole('observer', 1),
            ),
            const SizedBox(height: 12),
            _RoleRow(
              label: '守護神',
              description: '夜に襲撃を無効化',
              count: _guardianGod,
              onMinus: () => _changeRole('guardian', -1),
              onPlus: () => _changeRole('guardian', 1),
            ),
            const SizedBox(height: 12),
            _RoleRow(
              label: '霊媒神',
              description: '夜に死亡済みの神の役職を確認',
              count: _mediumGod,
              onMinus: () => _changeRole('medium', -1),
              onPlus: () => _changeRole('medium', 1),
            ),
            const SizedBox(height: 12),
            _StaticRoleRow(
              label: '普通神',
              description: '能力なし',
              count: _normalGod,
              onMinus: () => _changeRole('normal', -1),
              onPlus: () => _changeRole('normal', 1),
            ),
            const SizedBox(height: 12),
            Text(
              '合計: $_total / $_playerCount',
              style: const TextStyle(color: Color(0xFF2F9C95)),
            ),
            const SizedBox(height: 8),
            if (_total != _playerCount)
              const Text(
                '役職の合計が人数と一致していません。',
                style: TextStyle(color: Color(0xFFE37064)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid
                    ? () {
                        final roles = RoleSettings(
                          fenrir: _fenrir,
                          observerGod: _observerGod,
                          guardianGod: _guardianGod,
                          mediumGod: _mediumGod,
                          normalGod: _normalGod,
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
