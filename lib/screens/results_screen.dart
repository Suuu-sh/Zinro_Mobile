import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static const String routeName = '/results';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as GameResult?;
    final result = args ??
        const GameResult(
          settings: GameSettings(
            playerCount: 6,
            roles: RoleSettings(
              fenrir: 1,
              observerGod: 1,
              guardianGod: 1,
              mediumGod: 1,
              normalGod: 2,
            ),
          ),
          assignedRoles: [
            'フェンリル',
            '観測神',
            '守護神',
            '霊媒神',
            '普通神',
            '普通神'
          ],
          winner: '正統神陣営の勝利',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('リザルト'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.winner,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1B1A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '全員の役職',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1B1A),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: result.assignedRoles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
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
                          backgroundColor:
                              const Color(0xFF2F9C95).withOpacity(0.2),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0E1B1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'プレイヤー${index + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0E1B1A),
                            ),
                          ),
                        ),
                        Text(
                          result.assignedRoles[index],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F9C95),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    HomeScreen.routeName,
                    (route) => false,
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
                child: const Text('ホームへ戻る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
