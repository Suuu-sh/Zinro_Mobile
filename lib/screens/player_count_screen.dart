import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class PlayerCountScreen extends StatefulWidget {
  const PlayerCountScreen({super.key});

  static const String routeName = '/player-count';

  @override
  State<PlayerCountScreen> createState() => _PlayerCountScreenState();
}

class _PlayerCountScreenState extends State<PlayerCountScreen> {
  static const int _minPlayers = 6;
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
      appBar: AppBar(
        title: const Text('人数を選択'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '何人でプレイしますか？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1B1A),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$_playerCount 人',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _playerCount > _minPlayers
                            ? () => _updateCount(_playerCount - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _playerCount < _maxPlayers
                            ? () => _updateCount(_playerCount + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _playerCount.toDouble(),
                    min: _minPlayers.toDouble(),
                    max: _maxPlayers.toDouble(),
                    divisions: _maxPlayers - _minPlayers,
                    label: '$_playerCount',
                    onChanged: (value) => _updateCount(value.round()),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RoleSettingsScreen.routeName,
                    arguments: RoleSettingsArgs(playerCount: _playerCount),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2F9C95),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('次へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
