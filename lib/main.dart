import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_count_screen.dart';
import 'screens/results_screen.dart';
import 'screens/role_reveal_screen.dart';
import 'screens/role_settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ZinroApp());
}

class ZinroApp extends StatelessWidget {
  const ZinroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '神狼ゲーム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFe94560),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0a0e27),
        fontFamily: 'NotoSansJP',
      ),
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        PlayerCountScreen.routeName: (context) => const PlayerCountScreen(),
        RoleSettingsScreen.routeName: (context) => const RoleSettingsScreen(),
        RoleRevealScreen.routeName: (context) => const RoleRevealScreen(),
        GameScreen.routeName: (context) => const GameScreen(),
        ResultsScreen.routeName: (context) => const ResultsScreen(),
      },
      initialRoute: HomeScreen.routeName,
    );
  }
}
