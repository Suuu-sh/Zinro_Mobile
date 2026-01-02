import 'package:flutter/material.dart';

class RoleData {
  final String name;
  final String emoji;
  final String description;
  final String ability;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isEvil;

  const RoleData({
    required this.name,
    required this.emoji,
    required this.description,
    required this.ability,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isEvil,
  });
}

class RoleDatabase {
  static const fenrir = RoleData(
    name: '神狼 -フェンリル-',
    emoji: '🐺',
    description: '神々を滅ぼす邪悪な狼',
    ability: '毎晩、神を一人襲撃できる。能力を持つ神を襲撃すると、その能力を奪える。',
    primaryColor: Color(0xFFe94560),
    secondaryColor: Color(0xFF8B0000),
    isEvil: true,
  );

  static const observerGod = RoleData(
    name: '知恵神 -ミーミル-',
    emoji: '👁️',
    description: '全てを見通す神',
    ability: '毎晩、生存している神の役職を確認できる。',
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFF4A148C),
    isEvil: false,
  );

  static const guardianGod = RoleData(
    name: '門番神 -ヘイムダル-',
    emoji: '🛡️',
    description: '仲間を守る盾の神',
    ability: '毎晩、一人の神を守り、神狼の襲撃を無効化できる。',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF0D47A1),
    isEvil: false,
  );

  static const mediumGod = RoleData(
    name: '冥界神 -ヘル-',
    emoji: '🔮',
    description: '死者と対話する神',
    ability: '毎晩、死亡した神の役職を確認できる。',
    primaryColor: Color(0xFF673AB7),
    secondaryColor: Color(0xFF311B92),
    isEvil: false,
  );

  static const atonementGod = RoleData(
    name: '贖罪神 -イエス-',
    emoji: '🕊️',
    description: '贖罪を背負う神',
    ability: '投票で処刑されると即座に勝利する。',
    primaryColor: Color(0xFFF7C873),
    secondaryColor: Color(0xFFE09E3E),
    isEvil: false,
  );

  static const normalGod = RoleData(
    name: '普通神',
    emoji: '⭐',
    description: '特別な力を持たない神',
    ability: '特殊能力はないが、議論と投票で貢献できる。',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF1B5E20),
    isEvil: false,
  );

  static RoleData getRoleData(String roleName) {
    switch (roleName) {
      case '神狼 -フェンリル-':
        return fenrir;
      case '知恵神 -ミーミル-':
        return observerGod;
      case '門番神 -ヘイムダル-':
        return guardianGod;
      case '冥界神 -ヘル-':
        return mediumGod;
      case '贖罪神 -イエス-':
        return atonementGod;
      case '普通神':
        return normalGod;
      default:
        return normalGod;
    }
  }
}
