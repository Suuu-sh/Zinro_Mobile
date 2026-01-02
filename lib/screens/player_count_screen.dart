import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class PlayerCountScreen extends StatefulWidget {
  const PlayerCountScreen({super.key});

  static const String routeName = '/player-count';

  @override
  State<PlayerCountScreen> createState() => _PlayerCountScreenState();
}

class _PlayerCountScreenState extends State<PlayerCountScreen> {
  static const int _minPlayers = 5;
  static const int _maxPlayers = 12;

  int _playerCount = 6;

  void _updateCount(int newValue) {
    setState(() {
      _playerCount = newValue.clamp(_minPlayers, _maxPlayers).toInt();
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
                  'プレイ人数',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '何人でプレイしますか？',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),
                // プレイヤー数表示
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFe94560).withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFe94560),
                              width: 3,
                            ),
                          ),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFe94560),
                                    Color(0xFFff6b9d),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  '$_playerCount',
                                  style: const TextStyle(
                                    fontSize: 96,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Text(
                                'プレイヤー',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        // ボタン
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CountButton(
                              icon: Icons.remove,
                              onPressed: _playerCount > _minPlayers
                                  ? () => _updateCount(_playerCount - 1)
                                  : null,
                            ),
                            const SizedBox(width: 32),
                            _CountButton(
                              icon: Icons.add,
                              onPressed: _playerCount < _maxPlayers
                                  ? () => _updateCount(_playerCount + 1)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // スライダー
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFe94560),
                              inactiveTrackColor:
                                  Colors.white.withOpacity(0.1),
                              thumbColor: const Color(0xFFe94560),
                              overlayColor:
                                  const Color(0xFFe94560).withOpacity(0.3),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12),
                              trackHeight: 6,
                            ),
                            child: Slider(
                              value: _playerCount.toDouble(),
                              min: _minPlayers.toDouble(),
                              max: _maxPlayers.toDouble(),
                              divisions: _maxPlayers - _minPlayers,
                              onChanged: (value) =>
                                  _updateCount(value.round()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_minPlayers 〜 $_maxPlayers 人',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 次へボタン
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RoleSettingsScreen.routeName,
                        arguments: RoleSettingsArgs(playerCount: _playerCount),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe94560),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFe94560).withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '次へ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: onPressed != null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFe94560),
                  Color(0xFFff6b9d),
                ],
              )
            : null,
        color: onPressed == null ? Colors.white.withOpacity(0.1) : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        color: Colors.white,
      ),
    );
  }
}
