import 'package:flutter/material.dart';

import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_count_screen.dart';
import 'screens/role_reveal_screen.dart';
import 'screens/role_settings_screen.dart';

void main() {
  runApp(const ZinroApp());
}

class ZinroApp extends StatelessWidget {
  const ZinroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zinro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F9C95),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F3ED),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F3ED),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF0E1B1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        PlayerCountScreen.routeName: (context) => const PlayerCountScreen(),
        RoleSettingsScreen.routeName: (context) => const RoleSettingsScreen(),
        RoleRevealScreen.routeName: (context) => const RoleRevealScreen(),
        GameScreen.routeName: (context) => const GameScreen(),
      },
      initialRoute: HomeScreen.routeName,
    );
  }
}
