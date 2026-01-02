import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../models/role_data.dart';
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
    final assignedTotal = _fenrir + _observerGod + _guardianGod + _mediumGod;
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
          _observerGod = (_observerGod + delta).clamp(0, _playerCount).toInt();
          break;
        case 'guardian':
          _guardianGod = (_guardianGod + delta).clamp(0, _playerCount).toInt();
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
                // 戻るボタン
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 24),
                // タイトル
                const Text(
                  '役職設定',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'プレイ人数: $_playerCount 人',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                // 合計表示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isValid
                        ? const Color(0xFF4CAF50).withOpacity(0.2)
                        : const Color(0xFFe94560).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isValid
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFe94560),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isValid ? Icons.check_circle : Icons.warning,
                        color: _isValid
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFe94560),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isValid
                              ? '合計: $_total / $_playerCount ✓'
                              : '合計: $_total / $_playerCount (調整が必要)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 役職リスト
                Expanded(
                  child: ListView(
                    children: [
                      _RoleCard(
                        roleData: RoleDatabase.fenrir,
                        count: _fenrir,
                        onMinus: () => _changeRole('fenrir', -1),
                        onPlus: () => _changeRole('fenrir', 1),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        roleData: RoleDatabase.observerGod,
                        count: _observerGod,
                        onMinus: () => _changeRole('observer', -1),
                        onPlus: () => _changeRole('observer', 1),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        roleData: RoleDatabase.guardianGod,
                        count: _guardianGod,
                        onMinus: () => _changeRole('guardian', -1),
                        onPlus: () => _changeRole('guardian', 1),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        roleData: RoleDatabase.mediumGod,
                        count: _mediumGod,
                        onMinus: () => _changeRole('medium', -1),
                        onPlus: () => _changeRole('medium', 1),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        roleData: RoleDatabase.normalGod,
                        count: _normalGod,
                        onMinus: () => _changeRole('normal', -1),
                        onPlus: () => _changeRole('normal', 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 開始ボタン
                SizedBox(
                  width: double.infinity,
                  height: 64,
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
                      backgroundColor: const Color(0xFFe94560),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFe94560).withOpacity(0.5),
                      disabledBackgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '役職確認へ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 24),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.roleData,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  final RoleData roleData;
  final int count;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleData.primaryColor.withOpacity(0.2),
            roleData.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: roleData.primaryColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // 絵文字
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: roleData.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                roleData.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 役職情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleData.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleData.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // カウンター
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onMinus,
                  icon: const Icon(Icons.remove, color: Colors.white),
                  iconSize: 20,
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onPlus,
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
