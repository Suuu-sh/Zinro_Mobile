import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../models/role_data.dart';
import 'game_screen.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  static const String routeName = '/role-reveal';

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  late GameSettings _settings;
  late List<String> _assignedRoles;
  int _currentIndex = 0;
  bool _revealed = false;
  bool _handover = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
            atonementGod: 0,
            normalGod: 2,
          ),
        );
    _assignedRoles = _buildRoles(_settings);
    _initialized = true;
  }

  List<String> _buildRoles(GameSettings settings) {
    final roles = <String>[];
    roles.addAll(List.filled(settings.roles.fenrir, '神狼 -フェンリル-'));
    roles.addAll(List.filled(settings.roles.observerGod, '知恵神 -ミーミル-'));
    roles.addAll(List.filled(settings.roles.guardianGod, '門番神 -ヘイムダル-'));
    roles.addAll(List.filled(settings.roles.mediumGod, '冥界神 -ヘル-'));
    roles.addAll(List.filled(settings.roles.atonementGod, '贖罪神 -イエス-'));
    roles.addAll(List.filled(settings.roles.normalGod, '普通神'));
    roles.shuffle(Random());
    return roles;
  }

  void _showRole() {
    setState(() {
      _revealed = true;
    });
  }

  void _prepareHandover() {
    setState(() {
      _handover = true;
    });
  }

  void _advanceAfterHandover(bool isLast) {
    if (isLast) {
      _startGame();
      return;
    }
    setState(() {
      _handover = false;
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
    final roleData = RoleDatabase.getRoleData(role);

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
            child: _handover
                ? _HandoverPanel(
                    isLast: isLast,
                    onContinue: () => _advanceAfterHandover(isLast),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ヘッダー
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFe94560),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'プレイヤー ${_currentIndex + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_assignedRoles.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFe94560),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '他の人に見られないように確認してください',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 役職カード
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _revealed
                                ? _RoleCard(roleData: roleData)
                                : _HiddenCard(
                                    pulseController: _pulseController,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ボタン
                      if (!_revealed)
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _showRole,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe94560),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFFe94560).withOpacity(0.5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  '役職を見る',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _prepareHandover,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe94560),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFFe94560).withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'ゲーム開始へ' : '次の人へ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  isLast
                                      ? Icons.play_arrow
                                      : Icons.arrow_forward,
                                  size: 24,
                                ),
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

class _HandoverPanel extends StatelessWidget {
  const _HandoverPanel({
    required this.isLast,
    required this.onContinue,
  });

  final bool isLast;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📱',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                isLast ? '準備ができたら開始' : '次の人に渡してください',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLast
                    ? '全員の確認が終わったら開始します'
                    : '次のプレイヤーが確認できる状態にしてください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe94560),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: const Color(0xFFe94560).withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLast ? 'ゲーム開始' : '次の人が準備OK',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isLast ? Icons.play_arrow : Icons.check_circle,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HiddenCard extends StatelessWidget {
  const _HiddenCard({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (pulseController.value * 0.05),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFe94560).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFe94560).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '❓',
                  style: TextStyle(fontSize: 100),
                ),
                const SizedBox(height: 24),
                const Text(
                  'あなたの役職',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'タップして確認',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.roleData});

  final RoleData roleData;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              roleData.primaryColor,
              roleData.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: roleData.primaryColor.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 絵文字
            Text(
              roleData.emoji,
              style: const TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 24),
            // 役職名
            Text(
              roleData.name,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            // 説明
            Text(
              roleData.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // 能力
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '能力',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleData.ability,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
